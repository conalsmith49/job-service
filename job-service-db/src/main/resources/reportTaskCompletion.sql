--
-- Copyright 2015-2017 Hewlett Packard Enterprise Development LP.
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--      http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--

/*
 *  Name: internal_report_task_completion
 *
 *  Description:  Recursively propagate progress status to parent tasks and job.
 *                Internal - used in report_progress().
 */
CREATE OR REPLACE FUNCTION internal_report_task_completion(in_task_table_name varchar(63))
RETURNS VOID AS $$
DECLARE
  v_parent_table_name VARCHAR(63);
  v_percentage_completed DOUBLE PRECISION;
  v_task_id VARCHAR(58);
  v_job_id VARCHAR(48);
  v_temp SMALLINT;
  v_final_task_received SMALLINT;
BEGIN

  --  Raise exception if task identifier has not been specified.
  IF in_task_table_name IS NULL OR in_task_table_name = '' THEN
    RAISE EXCEPTION 'Task table name has not been specified';
  END IF;

  --  Identify percentage of rows in current table with status Completed.
  --  Percentage will need adjusted though if final sub-task has not yet arrived.
  EXECUTE format('SELECT 1 FROM %1$I WHERE is_final = true', in_task_table_name) INTO v_final_task_received;
  IF v_final_task_received IS NOT NULL THEN
    EXECUTE format('
    SELECT round(((select count(task_id) from %1$I WHERE status = ''Completed'') * 100)::numeric / (select count(*) from %1$I), 2) AS completed_percentage',
                   in_task_table_name) INTO v_percentage_completed;
  ELSE
    --  Final sub-task has not yet arrived. Adjust percentage to allow for one more entry to arrive.
    EXECUTE format('
    SELECT round(((select count(task_id) from %1$I WHERE status = ''Completed'') * 100)::numeric / (select count(*)+1 from %1$I), 2) AS completed_percentage',
                   in_task_table_name) INTO v_percentage_completed;
  END IF;

  --  Identify parent table to target from task table name.
  --  If dot separator does not exist though in the specified task table name then we are dealing with the job table.
  IF position('.' in in_task_table_name) = 0 THEN
    --  Extract job id from task table name (i.e. strip task_ prefix).
    v_job_id = substring(in_task_table_name from 6);

    PERFORM 1 FROM job WHERE job_id = v_job_id FOR UPDATE;
    UPDATE job
    SET percentage_complete = v_percentage_completed,
        status = CASE WHEN v_percentage_completed = 100.00 THEN 'Completed'
                 ELSE status
                 END
    WHERE job_id = v_job_id;

    --  If job has completed, then remove task tables associated with the job.
    IF v_percentage_completed = 100.00 THEN
      PERFORM internal_delete_task_table(v_job_id, false);
    END IF;

  ELSE
    v_parent_table_name = substring(in_task_table_name, 1, internal_get_last_position(in_task_table_name, '.')-1);

    --  Identify task id from task table name (i.e. strip task_ prefix) to determine which row in the parent table to target.
    v_task_id = substring(in_task_table_name from 6);

    --  Modify parent target table and update it's status and % completed.
    EXECUTE format('SELECT 1 FROM %1$I WHERE task_id = %2$L FOR UPDATE', v_parent_table_name, v_task_id) INTO v_temp;
    EXECUTE format('
      UPDATE %1$I
      SET percentage_complete = %2$L,
          status =  CASE WHEN %2$L = 100.00 THEN ''Completed''
                    ELSE status
                    END
      WHERE task_id = %3$L
      ',
      v_parent_table_name, v_percentage_completed, v_task_id);

    -- Recursively call the same function for the specified v_parent_table_name
    PERFORM internal_report_task_completion(v_parent_table_name);
  END IF;

END
$$ LANGUAGE plpgsql;