package com.familyshare.simonel;

import androidx.annotation.NonNull;

import com.familyshare.simonel.map.AmapMapViewFactory;

import java.util.List;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public final class MainActivity extends FlutterActivity {
    private AmapMapViewFactory mapFactory;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        mapFactory = new AmapMapViewFactory(this, flutterEngine.getDartExecutor().getBinaryMessenger());
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
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mapFactory != null) mapFactory.onResume();
    }

    @Override
    protected void onPause() {
        if (mapFactory != null) mapFactory.onPause();
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        if (mapFactory != null) mapFactory.disposeCurrent();
        super.onDestroy();
    }
}
