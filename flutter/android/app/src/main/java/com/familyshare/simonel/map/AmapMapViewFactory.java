package com.familyshare.simonel.map;

import android.app.Activity;
import android.util.Log;

import androidx.annotation.NonNull;

import com.familyshare.simonel.BuildConfig;

import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

public final class AmapMapViewFactory extends PlatformViewFactory {
    private static final String TAG = "FamilyShareBoot";
    private final Activity activity;
    private final BinaryMessenger messenger;
    private AmapMapView current;

    public AmapMapViewFactory(Activity activity, BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.activity = activity;
        this.messenger = messenger;
    }

    @NonNull
    @Override
    public PlatformView create(@NonNull android.content.Context context, int id,
                               Object args) {
        if (BuildConfig.DEBUG) Log.i(TAG, "AMap PlatformView factory create; id=" + id);
        current = new AmapMapView(activity, messenger, id);
        return current;
    }

    public void updateMembers(List<?> members) {
        if (current != null) current.updateMembers(members);
    }

    public void recenter() {
        if (current != null) current.recenter();
    }

    public void focusTrajectory(String deviceId) {
        if (current != null) current.focusTrajectory(deviceId);
    }

    public void focusMember(String deviceId) {
        if (current != null) current.focusMember(deviceId);
    }

    public void onResume() {
        if (current != null) current.onResume();
    }

    public void onPause() {
        if (current != null) current.onPause();
    }

    public void disposeCurrent() {
        if (current != null) {
            current.dispose();
            current = null;
        }
    }
}
