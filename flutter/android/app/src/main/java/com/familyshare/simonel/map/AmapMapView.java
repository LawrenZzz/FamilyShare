package com.familyshare.simonel.map;

import android.app.Activity;
import android.graphics.Color;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

/** A small bridge around the local Lite3DMap SDK. */
public final class AmapMapView extends FrameLayout implements PlatformView {
    private final MapView mapView;
    private AMap map;
    private final MethodChannel channel;
    private final Map<String, Marker> markers = new HashMap<>();
    private List<?> pendingMembers;
    private boolean hasCentered;
    private boolean disposed;

    public AmapMapView(Activity activity, BinaryMessenger messenger, int viewId) {
        super(activity);
        setBackgroundColor(Color.rgb(232, 238, 246));
        channel = new MethodChannel(messenger, "familyshare/map/" + viewId);
        mapView = new MapView(activity);
        mapView.onCreate(null);
        mapView.onResume();
        addView(mapView, new FrameLayout.LayoutParams(
                LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        // Lite3DMap exposes the map asynchronously. Updates received before
        // this callback are kept and applied as soon as the renderer is ready.
        mapView.getMapAsyn(readyMap -> {
            map = readyMap;
            map.setMapType(AMap.MAP_TYPE_NORMAL);
            map.getUiSettings().setAllGesturesEnabled(true);
            map.setOnMarkerClickListener(marker -> {
                Object object = marker.getObject();
                if (object != null) {
                    channel.invokeMethod("memberTap", String.valueOf(object));
                }
                return true;
            });
            if (pendingMembers != null) {
                List<?> initial = pendingMembers;
                pendingMembers = null;
                updateMembers(initial);
            }
        });
    }

    @NonNull
    @Override
    public View getView() {
        return this;
    }

    public void updateMembers(List<?> rawMembers) {
        if (disposed || rawMembers == null) return;
        if (map == null) {
            pendingMembers = rawMembers;
            return;
        }
        Set<String> incoming = new HashSet<>();
        LatLng first = null;
        for (Object raw : rawMembers) {
            if (!(raw instanceof Map)) continue;
            Map<?, ?> member = (Map<?, ?>) raw;
            String id = stringValue(member.get("deviceId"));
            double lat = numberValue(member.get("lat"));
            double lng = numberValue(member.get("lng"));
            if (id.isEmpty() || lat == 0 && lng == 0) continue;
            incoming.add(id);
            if (first == null) first = new LatLng(lat, lng);
            Marker marker = markers.get(id);
            LatLng point = new LatLng(lat, lng);
            String name = stringValue(member.get("name"));
            if (marker == null) {
                marker = map.addMarker(new MarkerOptions()
                        .position(point)
                        .title(name.isEmpty() ? "Family member" : name)
                        .snippet(stringValue(member.get("address"))));
                marker.setObject(id);
                markers.put(id, marker);
            } else {
                marker.setPosition(point);
                marker.setTitle(name.isEmpty() ? "Family member" : name);
            }
        }
        for (String id : new HashSet<>(markers.keySet())) {
            if (!incoming.contains(id)) {
                Marker marker = markers.remove(id);
                if (marker != null) marker.remove();
            }
        }
        if (!hasCentered && first != null) {
            hasCentered = true;
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(first, 15f));
        }
    }

    public void recenter() {
        if (disposed || map == null) return;
        Marker first = markers.isEmpty() ? null : markers.values().iterator().next();
        if (first != null) map.animateCamera(CameraUpdateFactory.newLatLngZoom(first.getPosition(), 15f));
    }

    public void onResume() { mapView.onResume(); }

    public void onPause() { mapView.onPause(); }

    @Override
    public void dispose() {
        if (disposed) return;
        disposed = true;
        markers.clear();
        mapView.onDestroy();
    }

    private static String stringValue(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private static double numberValue(Object value) {
        return value instanceof Number ? ((Number) value).doubleValue() : 0d;
    }
}
