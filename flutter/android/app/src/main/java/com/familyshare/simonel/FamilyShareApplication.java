package com.familyshare.simonel;

import android.app.Application;
import android.os.RemoteException;

import com.amap.api.location.AMapLocationClient;
import com.amap.api.maps.MapsInitializer;

/** Initializes the local AMap SDK before Flutter creates the platform view. */
public final class FamilyShareApplication extends Application {
    @Override
    public void onCreate() {
        super.onCreate();
        AMapLocationClient.updatePrivacyShow(this, true, true);
        AMapLocationClient.updatePrivacyAgree(this, true);
        try {
            MapsInitializer.initialize(this);
        } catch (RemoteException ignored) {
            // The map view will expose its own error state if the key is invalid.
        }
    }
}
