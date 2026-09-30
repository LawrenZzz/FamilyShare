package com.familyshare.simonel;

import android.app.Application;
import android.os.RemoteException;
import android.util.Log;

import com.amap.api.location.AMapLocationClient;
import com.amap.api.maps.MapsInitializer;

/** Initializes the local AMap SDK before Flutter creates the platform view. */
public final class FamilyShareApplication extends Application {
    private static final String TAG = "FamilyShareBoot";

    @Override
    public void onCreate() {
        super.onCreate();
        bootLog("Application.onCreate started");
        try {
            AMapLocationClient.updatePrivacyShow(this, true, true);
            AMapLocationClient.updatePrivacyAgree(this, true);
            bootLog("AMap privacy state initialized");
            MapsInitializer.initialize(this);
            bootLog("AMap SDK initialized");
        } catch (RemoteException error) {
            Log.e(TAG, "AMap SDK initialization failed", error);
        } catch (RuntimeException error) {
            Log.e(TAG, "Application initialization failed", error);
            throw error;
        }
        bootLog("Application.onCreate completed");
    }

    private static void bootLog(String message) {
        if (BuildConfig.DEBUG) Log.i(TAG, message);
    }
}
