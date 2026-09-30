package com.familyshare.simonel;

import android.Manifest;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.PowerManager;
import android.app.Activity;
import android.provider.Settings;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.app.NotificationManagerCompat;
import androidx.core.content.ContextCompat;

import com.familyshare.simonel.map.AmapMapViewFactory;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public final class MainActivity extends FlutterActivity {
    private static final String TAG = "FamilyShareBoot";
    private AmapMapViewFactory mapFactory;
    private AmapLocator locator;
    private static final int AVATAR_PICK_REQUEST = 6021;
    private final ExecutorService avatarExecutor = Executors.newSingleThreadExecutor();
    private MethodChannel.Result avatarResult;

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
                } else if ("focusTrajectory".equals(call.method) && call.arguments instanceof String) {
                    mapFactory.focusTrajectory((String) call.arguments);
                    result.success(null);
                } else if ("focusMember".equals(call.method) && call.arguments instanceof String) {
                    mapFactory.focusMember((String) call.arguments);
                    result.success(null);
                } else {
                    result.notImplemented();
                }
            });
            locator = new AmapLocator(this);
            MethodChannel deviceChannel = new MethodChannel(
                    flutterEngine.getDartExecutor().getBinaryMessenger(), "familyshare/device");
            deviceChannel.setMethodCallHandler((call, result) -> {
                switch (call.method) {
                    case "getCurrentLocation":
                        locator.request(new AmapLocator.Callback() {
                            @Override
                            public void onSuccess(Map<String, Object> location) {
                                result.success(location);
                            }

                            @Override
                            public void onError(String message) {
                                result.error("LOCATION_FAILED", message, null);
                            }
                        });
                        break;
                    case "permissionStatus":
                        result.success(permissionStatus());
                        break;
                    case "pickAvatar":
                        if (avatarResult != null) {
                            result.error("PICKER_BUSY", "图片选择器已打开", null);
                            break;
                        }
                        avatarResult = result;
                        try {
                            Intent pick = new Intent(Intent.ACTION_GET_CONTENT);
                            pick.setType("image/*");
                            pick.addCategory(Intent.CATEGORY_OPENABLE);
                            startActivityForResult(Intent.createChooser(pick, "选择头像"), AVATAR_PICK_REQUEST);
                        } catch (RuntimeException error) {
                            avatarResult = null;
                            result.error("PICKER_FAILED", error.getMessage(), null);
                        }
                        break;
                    case "startTracking":
                        try {
                            boolean hasLocation = ContextCompat.checkSelfPermission(this,
                                    Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED
                                    || ContextCompat.checkSelfPermission(this,
                                    Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED;
                            if (!hasLocation) {
                                result.error("LOCATION_PERMISSION", "请先授予定位权限", null);
                                break;
                            }
                            Intent start = new Intent(this, LocationForegroundService.class);
                            start.setAction(LocationForegroundService.ACTION_START);
                            start.putExtra(LocationForegroundService.EXTRA_DEVICE_ID,
                                    (String) call.argument(LocationForegroundService.EXTRA_DEVICE_ID));
                            start.putExtra(LocationForegroundService.EXTRA_FAMILY_ID,
                                    (String) call.argument(LocationForegroundService.EXTRA_FAMILY_ID));
                            Number interval = call.argument(LocationForegroundService.EXTRA_INTERVAL);
                            start.putExtra(LocationForegroundService.EXTRA_INTERVAL,
                                    interval == null ? 300000L : interval.longValue());
                            ContextCompat.startForegroundService(this, start);
                            result.success(null);
                        } catch (RuntimeException error) {
                            result.error("TRACKING_FAILED", error.getMessage(), null);
                        }
                        break;
                    case "stopTracking":
                        stopService(new Intent(this, LocationForegroundService.class));
                        result.success(null);
                        break;
                    case "openLocationSettings":
                        openAppDetails();
                        result.success(null);
                        break;
                    case "openBatterySettings":
                        openBatterySettings();
                        result.success(null);
                        break;
                    case "openAutoStartSettings":
                        openAutoStartSettings();
                        result.success(null);
                        break;
                    default:
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
        if (locator != null) locator.cancel();
        if (mapFactory != null) mapFactory.disposeCurrent();
        avatarExecutor.shutdownNow();
        super.onDestroy();
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode != AVATAR_PICK_REQUEST || avatarResult == null) return;
        MethodChannel.Result pending = avatarResult;
        avatarResult = null;
        if (resultCode != Activity.RESULT_OK || data == null || data.getData() == null) {
            pending.success(null);
            return;
        }
        Uri uri = data.getData();
        avatarExecutor.execute(() -> {
            try {
                byte[] jpeg = AvatarPicker.readJpeg(this, uri);
                runOnUiThread(() -> pending.success(jpeg));
            } catch (Exception error) {
                runOnUiThread(() -> pending.error("AVATAR_READ_FAILED", error.getMessage(), null));
            }
        });
    }

    private Map<String, Object> permissionStatus() {
        Map<String, Object> status = new HashMap<>();
        status.put("preciseLocation", ContextCompat.checkSelfPermission(this,
                Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED);
        status.put("backgroundLocation", Build.VERSION.SDK_INT < Build.VERSION_CODES.Q
                || ContextCompat.checkSelfPermission(this,
                Manifest.permission.ACCESS_BACKGROUND_LOCATION) == PackageManager.PERMISSION_GRANTED);
        status.put("notifications", NotificationManagerCompat.from(this).areNotificationsEnabled());
        PowerManager power = (PowerManager) getSystemService(POWER_SERVICE);
        status.put("batteryUnrestricted", power != null
                && power.isIgnoringBatteryOptimizations(getPackageName()));
        return status;
    }

    private void openAppDetails() {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:" + getPackageName()));
        startActivity(intent);
    }

    private void openBatterySettings() {
        PowerManager power = (PowerManager) getSystemService(POWER_SERVICE);
        if (power != null && power.isIgnoringBatteryOptimizations(getPackageName())) return;
        Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS,
                Uri.parse("package:" + getPackageName()));
        try {
            startActivity(intent);
        } catch (RuntimeException error) {
            startActivity(new Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS));
        }
    }

    private void openAutoStartSettings() {
        String brand = Build.MANUFACTURER.toLowerCase(java.util.Locale.ROOT);
        String[] candidates;
        if (brand.contains("xiaomi") || brand.contains("redmi")) {
            candidates = new String[]{"com.miui.securitycenter/com.miui.permcenter.autostart.AutoStartManagementActivity"};
        } else if (brand.contains("oppo") || brand.contains("realme")) {
            candidates = new String[]{"com.coloros.safecenter/com.coloros.safecenter.permission.startup.StartupAppListActivity"};
        } else if (brand.contains("vivo")) {
            candidates = new String[]{"com.vivo.permissionmanager/com.vivo.permissionmanager.activity.BgStartUpManagerActivity"};
        } else if (brand.contains("huawei") || brand.contains("honor")) {
            candidates = new String[]{"com.huawei.systemmanager/com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity"};
        } else {
            candidates = new String[0];
        }
        for (String candidate : candidates) {
            Intent intent = new Intent();
            intent.setComponent(ComponentName.unflattenFromString(candidate));
            try {
                startActivity(intent);
                return;
            } catch (RuntimeException ignored) {
                // Vendor settings are not present on every firmware version.
            }
        }
        openAppDetails();
    }

    private static void bootLog(String message) {
        if (BuildConfig.DEBUG) Log.i(TAG, message);
    }
}
