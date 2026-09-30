package com.familyshare.simonel;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.Nullable;
import androidx.core.app.NotificationCompat;

import org.json.JSONObject;

import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public final class LocationForegroundService extends Service {
    static final String ACTION_START = "com.familyshare.simonel.START_TRACKING";
    static final String ACTION_STOP = "com.familyshare.simonel.STOP_TRACKING";
    static final String EXTRA_DEVICE_ID = "deviceId";
    static final String EXTRA_FAMILY_ID = "familyId";
    static final String EXTRA_INTERVAL = "intervalMs";
    private static final String CHANNEL_ID = "familyshare_location";
    private static final int NOTIFICATION_ID = 2101;

    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newSingleThreadExecutor();
    private AmapLocator locator;
    private String deviceId = "";
    private String familyId = "";
    private long intervalMs = 300000;
    private boolean running;
    private final Runnable report = this::reportOnce;

    @Override
    public void onCreate() {
        super.onCreate();
        locator = new AmapLocator(this);
        NotificationManager manager = getSystemService(NotificationManager.class);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && manager != null) {
            manager.createNotificationChannel(new NotificationChannel(
                    CHANNEL_ID, "家庭位置共享", NotificationManager.IMPORTANCE_LOW));
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent == null || ACTION_STOP.equals(intent.getAction())) {
            stopSelf();
            return START_NOT_STICKY;
        }
        deviceId = intent.getStringExtra(EXTRA_DEVICE_ID);
        familyId = intent.getStringExtra(EXTRA_FAMILY_ID);
        if (deviceId == null || deviceId.isEmpty() || familyId == null || familyId.isEmpty()) {
            stopSelf();
            return START_NOT_STICKY;
        }
        intervalMs = Math.max(60000, intent.getLongExtra(EXTRA_INTERVAL, 300000));
        startForeground(NOTIFICATION_ID, notification());
        running = true;
        main.removeCallbacks(report);
        locator.cancel();
        main.postDelayed(report, intervalMs);
        return START_NOT_STICKY;
    }

    private Notification notification() {
        Intent open = new Intent(this, MainActivity.class);
        PendingIntent pending = PendingIntent.getActivity(this, 0, open,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE);
        return new NotificationCompat.Builder(this, CHANNEL_ID)
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("家庭共享正在共享位置")
                .setContentText("点击返回应用管理位置共享")
                .setContentIntent(pending)
                .setOngoing(true)
                .setPriority(NotificationCompat.PRIORITY_LOW)
                .build();
    }

    private void reportOnce() {
        if (!running) return;
        locator.request(new AmapLocator.Callback() {
            @Override
            public void onSuccess(Map<String, Object> location) {
                String currentDevice = deviceId;
                String currentFamily = familyId;
                executor.execute(() -> postLocation(currentDevice, currentFamily, location));
                scheduleNext();
            }

            @Override
            public void onError(String message) {
                Log.w("FamilyShareLocation", message);
                scheduleNext();
            }
        });
    }

    private void scheduleNext() {
        if (running) main.postDelayed(report, intervalMs);
    }

    private void postLocation(String currentDevice, String currentFamily, Map<String, Object> location) {
        HttpURLConnection connection = null;
        try {
            JSONObject body = new JSONObject(location);
            body.put(EXTRA_DEVICE_ID, currentDevice);
            body.put(EXTRA_FAMILY_ID, currentFamily);
            connection = (HttpURLConnection) new URL(
                    BuildConfig.SERVER_URL + "/api/location/report").openConnection();
            connection.setRequestMethod("POST");
            connection.setRequestProperty("X-Api-Token", BuildConfig.API_TOKEN);
            connection.setRequestProperty("Content-Type", "application/json; charset=utf-8");
            connection.setConnectTimeout(15000);
            connection.setReadTimeout(15000);
            connection.setDoOutput(true);
            connection.getOutputStream().write(body.toString().getBytes(StandardCharsets.UTF_8));
            int status = connection.getResponseCode();
            if (status < 200 || status >= 300) Log.w("FamilyShareLocation", "上报失败 HTTP " + status);
        } catch (Exception error) {
            Log.w("FamilyShareLocation", "位置上报失败", error);
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    @Override
    public void onDestroy() {
        running = false;
        main.removeCallbacks(report);
        locator.cancel();
        executor.shutdownNow();
        super.onDestroy();
    }

    @Nullable
    @Override
    public IBinder onBind(Intent intent) { return null; }
}
