package com.familyshare.simonel;

import android.Manifest;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Handler;
import android.os.Looper;

import androidx.core.content.ContextCompat;

import com.amap.api.location.AMapLocation;
import com.amap.api.location.AMapLocationClient;
import com.amap.api.location.AMapLocationClientOption;

import java.util.HashMap;
import java.util.Map;

final class AmapLocator {
    interface Callback {
        void onSuccess(Map<String, Object> location);
        void onError(String message);
    }

    private final Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private AMapLocationClient client;
    private Callback callback;

    AmapLocator(Context context) {
        this.context = context.getApplicationContext();
    }

    void request(Callback callback) {
        main.post(() -> {
            Callback replaced = this.callback;
            cancel();
            if (replaced != null) replaced.onError("已被新的定位请求取代");
            this.callback = callback;
            if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED
                    && ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION)
                    != PackageManager.PERMISSION_GRANTED) {
                finishError("请先授予定位权限");
                return;
            }
            try {
                client = new AMapLocationClient(context);
                AMapLocationClientOption option = new AMapLocationClientOption();
                option.setLocationMode(AMapLocationClientOption.AMapLocationMode.Hight_Accuracy);
                option.setOnceLocation(true);
                option.setOnceLocationLatest(true);
                option.setNeedAddress(true);
                option.setLocationCacheEnable(false);
                option.setHttpTimeOut(15000);
                client.setLocationOption(option);
                client.setLocationListener(location -> {
                    if (this.callback == null) return;
                    if (location == null || location.getErrorCode() != 0) {
                        finishError(location == null ? "定位无结果" : location.getErrorInfo());
                        return;
                    }
                    finishSuccess(location);
                });
                client.startLocation();
                main.postDelayed(timeout, 20000);
            } catch (Exception error) {
                finishError("高德定位启动失败：" + error.getMessage());
            }
        });
    }

    private final Runnable timeout = () -> finishError("定位超时，请检查定位开关和网络");

    private void finishSuccess(AMapLocation location) {
        Callback pending = callback;
        if (pending == null) return;
        callback = null;
        main.removeCallbacks(timeout);
        Map<String, Object> data = new HashMap<>();
        data.put("lat", location.getLatitude());
        data.put("lng", location.getLongitude());
        data.put("accuracy", location.getAccuracy());
        data.put("ts", System.currentTimeMillis());
        data.put("address", address(location));
        data.put("battery", DeviceSnapshot.battery(context));
        data.put("network", DeviceSnapshot.network(context));
        releaseClient();
        pending.onSuccess(data);
    }

    private void finishError(String message) {
        Callback pending = callback;
        if (pending == null) return;
        callback = null;
        main.removeCallbacks(timeout);
        releaseClient();
        pending.onError(message == null ? "定位失败" : message);
    }

    private static String address(AMapLocation location) {
        String full = location.getAddress();
        if (full != null && !full.isEmpty() && !"未知".equals(full)) return full;
        StringBuilder value = new StringBuilder();
        String province = location.getProvince();
        String city = location.getCity();
        String district = location.getDistrict();
        String street = location.getStreet();
        if (province != null) value.append(province);
        if (city != null && !city.equals(province)) value.append(city);
        if (district != null) value.append(district);
        if (street != null) value.append(street);
        return value.toString();
    }

    void cancel() {
        main.removeCallbacks(timeout);
        callback = null;
        releaseClient();
    }

    private void releaseClient() {
        if (client == null) return;
        try {
            client.stopLocation();
            client.onDestroy();
        } catch (RuntimeException ignored) {
            // The SDK may already have disposed the one-shot client.
        }
        client = null;
    }
}
