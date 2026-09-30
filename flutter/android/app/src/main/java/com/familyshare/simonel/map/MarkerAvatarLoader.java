package com.familyshare.simonel.map;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Path;
import android.graphics.Rect;
import android.graphics.RectF;
import android.graphics.Typeface;
import android.os.Handler;
import android.os.Looper;

import com.familyshare.simonel.BuildConfig;

import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

final class MarkerAvatarLoader {
    interface Callback { void onReady(Bitmap icon); }

    private final Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService executor = Executors.newFixedThreadPool(2);
    private final Map<String, Bitmap> cache = new ConcurrentHashMap<>();

    MarkerAvatarLoader(Context context) {
        this.context = context.getApplicationContext();
    }

    Bitmap fallback(String name, int color) {
        return render(null, name, color);
    }

    void load(String avatar, String name, int color, Callback callback) {
        Bitmap cached = cache.get(avatar);
        if (cached != null) {
            callback.onReady(render(cached, name, color));
            return;
        }
        executor.execute(() -> {
            Bitmap image = download(avatar);
            if (image == null) return;
            cache.put(avatar, image);
            Bitmap icon = render(image, name, color);
            main.post(() -> callback.onReady(icon));
        });
    }

    private Bitmap download(String avatar) {
        HttpURLConnection connection = null;
        try {
            String url = avatar.startsWith("http")
                    ? avatar : BuildConfig.SERVER_URL + "/" + avatar.replaceFirst("^/", "");
            connection = (HttpURLConnection) new URL(url).openConnection();
            connection.setRequestProperty("X-Api-Token", BuildConfig.API_TOKEN);
            connection.setConnectTimeout(10000);
            connection.setReadTimeout(10000);
            if (connection.getResponseCode() != 200) return null;
            return BitmapFactory.decodeStream(connection.getInputStream());
        } catch (Exception ignored) {
            return null;
        } finally {
            if (connection != null) connection.disconnect();
        }
    }

    private Bitmap render(Bitmap avatar, String name, int color) {
        int size = Math.round(52 * context.getResources().getDisplayMetrics().density);
        Bitmap output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888);
        Canvas canvas = new Canvas(output);
        Paint paint = new Paint(Paint.ANTI_ALIAS_FLAG);
        float center = size / 2f;
        float radius = center - 2;
        paint.setColor(Color.WHITE);
        canvas.drawCircle(center, center, radius, paint);
        float inner = radius - Math.max(2, size * 0.07f);
        paint.setColor(color);
        canvas.drawCircle(center, center, inner, paint);
        if (avatar != null) {
            int side = Math.min(avatar.getWidth(), avatar.getHeight());
            Rect source = new Rect((avatar.getWidth() - side) / 2,
                    (avatar.getHeight() - side) / 2,
                    (avatar.getWidth() + side) / 2,
                    (avatar.getHeight() + side) / 2);
            RectF target = new RectF(center - inner, center - inner,
                    center + inner, center + inner);
            Path clip = new Path();
            clip.addCircle(center, center, inner, Path.Direction.CW);
            canvas.save();
            canvas.clipPath(clip);
            canvas.drawBitmap(avatar, source, target, paint);
            canvas.restore();
        } else {
            paint.setColor(Color.WHITE);
            paint.setTypeface(Typeface.create(Typeface.DEFAULT, Typeface.BOLD));
            paint.setTextAlign(Paint.Align.CENTER);
            paint.setTextSize(size * 0.43f);
            String initial = name.isEmpty() ? "?" : name.substring(0, 1);
            canvas.drawText(initial, center,
                    center - (paint.ascent() + paint.descent()) / 2f, paint);
        }
        return output;
    }

    void close() {
        executor.shutdownNow();
        cache.clear();
    }
}
