package com.hpe.caf.services.job.api;

import com.hpe.caf.services.job.configuration.AppConfig;
import com.hpe.caf.services.job.exceptions.BadRequestException;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.powermock.api.mockito.PowerMockito;
import org.powermock.core.classloader.annotations.PowerMockIgnore;
import org.powermock.core.classloader.annotations.PrepareForTest;
import org.powermock.modules.junit4.PowerMockRunner;

import java.util.HashMap;

@RunWith(PowerMockRunner.class)
@PrepareForTest({JobsGetById.class, DatabaseHelper.class, AppConfig.class})
@PowerMockIgnore("javax.management.*")
public final class JobsGetByIdTest {

    @Mock
    private DatabaseHelper mockDatabaseHelper;

    @Before
    public void setup() throws Exception {
        //  Mock DatabaseHelper calls.
        Mockito.doNothing().when(mockDatabaseHelper).deleteJob(Mockito.anyString());
        PowerMockito.whenNew(DatabaseHelper.class).withArguments(Mockito.any()).thenReturn(mockDatabaseHelper);

        HashMap<String, String> newEnv  = new HashMap<>();
        newEnv.put("CAF_DATABASE_URL","testUrl");
        newEnv.put("CAF_DATABASE_USERNAME","testUserName");
        newEnv.put("CAF_DATABASE_PASSWORD","testPassword");
        TestUtil.setSystemEnvironmentFields(newEnv);
    }

    @Test
    public void testGetJob_Success() throws Exception {
        //  Test successful run of job retrieval.
        JobsGetById.getJob("067e6162-3b6f-4ae2-a171-2470b63dff00");

        Mockito.verify(mockDatabaseHelper, Mockito.times(1)).getJob(Mockito.anyString());
    }

    @Test(expected = BadRequestException.class)
    public void testGetJob_Failure_EmptyJobId() throws Exception {
        //  Test failed run of job retrieval with empty job id.
        JobsGetById.getJob("");

        Mockito.verify(mockDatabaseHelper, Mockito.times(0)).getJob(Mockito.anyString());
    }

    @Test(expected = BadRequestException.class)
    public void testGetJob_Failure_InvalidJobId_Period() throws Exception {
        //  Test failed run of job retrieval with job id containing invalid characters.
        JobsGetById.getJob("067e6162-3b6f-4ae2-a171-2470b.3dff00");

        Mockito.verify(mockDatabaseHelper, Mockito.times(0)).getJob(Mockito.anyString());
    }

    @Test(expected = BadRequestException.class)
    public void testGetJob_Failure_InvalidJobId_Asterisk() throws Exception {
        //  Test failed run of job retrieval with job id containing invalid characters.
        JobsGetById.getJob("067e6162-3b6f-4ae2-a171-2470b*3dff00");

        Mockito.verify(mockDatabaseHelper, Mockito.times(0)).getJob(Mockito.anyString());
    }

}
