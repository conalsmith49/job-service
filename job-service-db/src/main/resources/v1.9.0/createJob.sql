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
 *  Name: create_job
 *
 *  Description:  Create a new row in the job table.
 */
CREATE OR REPLACE FUNCTION create_job(in_job_id VARCHAR(48), in_name VARCHAR(255), in_description TEXT, in_data TEXT, in_job_hash INT)
  RETURNS VOID AS $$
BEGIN

  --  Raise exception if job identifier has not been specified.
  IF in_job_id IS NULL OR in_job_id = '' THEN
    RAISE EXCEPTION 'Job identifier has not been specified' USING ERRCODE = '02000'; -- sqlstate no data;
  END IF;

  -- Create new row in job and return the job_id.
  insert into public.job (job_id, name, description, data, create_date, status, percentage_complete, failure_details, job_hash)
  values (in_job_id, in_name, in_description, in_data, now() AT TIME ZONE 'UTC', 'Waiting', 0.00, null, in_job_hash);

END
$$ LANGUAGE plpgsql;