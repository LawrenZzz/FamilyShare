package com.familyshare.simonel;

import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.familyshare.simonel.map.AmapMapViewFactory;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public final class MainActivity extends FlutterActivity {
    private static final String TAG = "FamilyShareBoot";
    private AmapMapViewFactory mapFactory;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        bootLog("MainActivity.onCreate started; startPaused="
                + getIntent().getBooleanExtra("start-paused", false)
                + ", hasVmServicePort=" + getIntent().hasExtra("vm-service-port"));
        super.onCreate(savedInstanceState);
        bootLog("MainActivity.onCreate completed");
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        bootLog("configureFlutterEngine started");
        try {
            super.configureFlutterEngine(flutterEngine);
            mapFactory = new AmapMapViewFactory(
                    this, flutterEngine.getDartExecutor().getBinaryMessenger());
            flutterEngine.getPlatformViewsController().getRegistry()
                    .registerViewFactory("familyshare/amap", mapFactory);
            MethodChannel channel = new MethodChannel(
                    flutterEngine.getDartExecutor().getBinaryMessenger(), "familyshare/map");
            channel.setMethodCallHandler((call, result) -> {
                if ("updateMarkers".equals(call.method) && call.arguments instanceof List) {
                    mapFactory.updateMembers((List<?>) call.arguments);
                    result.success(null);
                } else if ("recenter".equals(call.method)) {
                    mapFactory.recenter();
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
            bootLog("configureFlutterEngine completed; AMap channel registered");
        } catch (RuntimeException error) {
            Log.e(TAG, "configureFlutterEngine failed", error);
            throw error;
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        bootLog("MainActivity.onResume");
        if (mapFactory != null) mapFactory.onResume();
    }

    @Override
    protected void onPause() {
        bootLog("MainActivity.onPause");
        if (mapFactory != null) mapFactory.onPause();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        bootLog("MainActivity.onDestroy");
        if (mapFactory != null) mapFactory.disposeCurrent();
        super.onDestroy();
    }

    private static void bootLog(String message) {
        if (BuildConfig.DEBUG) Log.i(TAG, message);
    }
}
