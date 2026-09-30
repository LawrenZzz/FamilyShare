package com.familyshare.simonel;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.ImageDecoder;
import android.net.Uri;
import android.os.Build;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

final class AvatarPicker {
    private AvatarPicker() {}

    static byte[] readJpeg(Context context, Uri uri) throws IOException {
        Bitmap source;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            source = ImageDecoder.decodeBitmap(
                    ImageDecoder.createSource(context.getContentResolver(), uri),
                    (decoder, info, ignored) -> {
                        int max = Math.max(info.getSize().getWidth(), info.getSize().getHeight());
                        decoder.setTargetSampleSize(Math.max(1, max / 1024));
                        decoder.setAllocator(ImageDecoder.ALLOCATOR_SOFTWARE);
                    });
        } else {
            BitmapFactory.Options bounds = new BitmapFactory.Options();
            bounds.inJustDecodeBounds = true;
            try (InputStream stream = context.getContentResolver().openInputStream(uri)) {
                BitmapFactory.decodeStream(stream, null, bounds);
            }
            BitmapFactory.Options options = new BitmapFactory.Options();
            options.inSampleSize = Math.max(1,
                    Math.max(bounds.outWidth, bounds.outHeight) / 1024);
            try (InputStream stream = context.getContentResolver().openInputStream(uri)) {
                source = BitmapFactory.decodeStream(stream, null, options);
            }
        }
        if (source == null) throw new IOException("无法读取所选图片");
        int side = Math.min(source.getWidth(), source.getHeight());
        Bitmap square = Bitmap.createBitmap(source,
                (source.getWidth() - side) / 2,
                (source.getHeight() - side) / 2, side, side);
        Bitmap scaled = Bitmap.createScaledBitmap(square, 512, 512, true);
        ByteArrayOutputStream output = new ByteArrayOutputStream();
        for (int quality = 88; quality >= 58; quality -= 10) {
            output.reset();
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, output);
            if (output.size() <= 1_048_576) break;
        }
        if (output.size() > 1_048_576) throw new IOException("图片压缩后仍超过 1 MB");
        return output.toByteArray();
    }
}
