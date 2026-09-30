package com.familyshare.simonel;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.Network;
import android.net.NetworkCapabilities;
import android.os.BatteryManager;

final class DeviceSnapshot {
    private DeviceSnapshot() {}

    static int battery(Context context) {
        BatteryManager manager = (BatteryManager) context.getSystemService(Context.BATTERY_SERVICE);
        if (manager == null) return -1;
        int value = manager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY);
        return value >= 0 && value <= 100 ? value : -1;
    }

    static String network(Context context) {
        try {
            ConnectivityManager manager = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
            if (manager == null) return "未知";
            Network active = manager.getActiveNetwork();
            NetworkCapabilities capabilities = manager.getNetworkCapabilities(active);
            if (capabilities == null) return "无网络";
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)) return "WiFi";
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR)) return "移动网络";
            if (capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET)) return "以太网";
            return "其他网络";
        } catch (RuntimeException ignored) {
            return "未知";
        }
    }
}
