package com.familyshare.simonel.map;

import android.app.Activity;
import android.graphics.Color;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;

import androidx.annotation.NonNull;

import com.amap.api.maps.AMap;
import com.amap.api.maps.CameraUpdateFactory;
import com.amap.api.maps.MapView;
import com.amap.api.maps.model.LatLng;
import com.amap.api.maps.model.LatLngBounds;
import com.amap.api.maps.model.Marker;
import com.amap.api.maps.model.MarkerOptions;
import com.amap.api.maps.model.BitmapDescriptorFactory;
import com.amap.api.maps.model.Polyline;
import com.amap.api.maps.model.PolylineOptions;
import com.familyshare.simonel.BuildConfig;

import java.util.ArrayList;
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
    private static final String TAG = "FamilyShareBoot";
    private final MapView mapView;
    private final int viewId;
    private AMap map;
    private final MethodChannel channel;
    private final Map<String, Marker> markers = new HashMap<>();
    private final Map<String, String> markerAvatarKeys = new HashMap<>();
    private final MarkerAvatarLoader avatarLoader;
    private final Map<String, Polyline> tracks = new HashMap<>();
    private final Map<String, List<LatLng>> routes = new HashMap<>();
    private List<?> pendingMembers;
    private int centeredMemberCount;
    private boolean disposed;

    public AmapMapView(Activity activity, BinaryMessenger messenger, int viewId) {
        super(activity);
        this.viewId = viewId;
        avatarLoader = new MarkerAvatarLoader(activity);
        bootLog("AMap view constructor started");
        setBackgroundColor(Color.rgb(232, 238, 246));
        channel = new MethodChannel(messenger, "familyshare/map/" + viewId);
        mapView = new MapView(activity);
        bootLog("AMap MapView allocated");
        mapView.onCreate(null);
        bootLog("AMap MapView.onCreate completed");
        mapView.onResume();
        addView(mapView, new FrameLayout.LayoutParams(
                LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT));
        bootLog("AMap MapView attached");
        // Lite3DMap exposes the map asynchronously. Updates received before
        // this callback are kept and applied as soon as the renderer is ready.
        mapView.getMapAsyn(readyMap -> {
            if (readyMap == null) {
                Log.e(TAG, "AMap async callback returned null; viewId=" + viewId);
                return;
            }
            map = readyMap;
            bootLog("AMap renderer ready");
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
            bootLog("marker update queued until renderer is ready; count=" + rawMembers.size());
            return;
        }
        Set<String> incoming = new HashSet<>();
        Set<String> incomingRoutes = new HashSet<>();
        Set<String> incomingTracks = new HashSet<>();
        for (Object raw : rawMembers) {
            if (!(raw instanceof Map)) continue;
            Map<?, ?> member = (Map<?, ?>) raw;
            String id = stringValue(member.get("deviceId"));
            double lat = numberValue(member.get("lat"));
            double lng = numberValue(member.get("lng"));
            if (id.isEmpty() || lat == 0 && lng == 0) continue;
            incoming.add(id);
            Marker marker = markers.get(id);
            LatLng point = new LatLng(lat, lng);
            String name = stringValue(member.get("name"));
            if (marker == null) {
                marker = map.addMarker(new MarkerOptions()
                        .position(point)
                        .title(name.isEmpty() ? "家庭成员" : name)
                        .snippet(stringValue(member.get("address"))));
                marker.setObject(id);
                markers.put(id, marker);
            } else {
                marker.setPosition(point);
                marker.setTitle(name.isEmpty() ? "家庭成员" : name);
            }
            applyMarkerIcon(id, marker, name, stringValue(member.get("avatar")));
            List<LatLng> route = parseRoute(member.get("trajectory"));
            if (Boolean.TRUE.equals(member.get("track")) && !route.isEmpty()) {
                incomingRoutes.add(id);
                routes.put(id, route);
                if (Boolean.TRUE.equals(member.get("showTrajectory")) && route.size() >= 2) {
                    incomingTracks.add(id);
                    Polyline line = tracks.get(id);
                    if (line == null) {
                        line = map.addPolyline(new PolylineOptions()
                                .addAll(route).width(9f).color(routeColor(id)));
                        tracks.put(id, line);
                    } else {
                        line.setPoints(route);
                    }
                }
            }
        }
        for (String id : new HashSet<>(markers.keySet())) {
            if (!incoming.contains(id)) {
                Marker marker = markers.remove(id);
                markerAvatarKeys.remove(id);
                if (marker != null) marker.remove();
            }
        }
        for (String id : new HashSet<>(tracks.keySet())) {
            if (!incomingTracks.contains(id)) {
                Polyline line = tracks.remove(id);
                if (line != null) line.remove();
            }
        }
        for (String id : new HashSet<>(routes.keySet())) {
            if (!incomingRoutes.contains(id)) routes.remove(id);
        }
        if (markers.size() > centeredMemberCount) {
            centeredMemberCount = markers.size();
            mapView.post(() -> showAllMembers(false));
        }
    }

    public void recenter() {
        mapView.post(() -> showAllMembers(true));
    }

    public void focusMember(String deviceId) {
        if (disposed || map == null) return;
        Marker marker = markers.get(deviceId);
        if (marker != null) {
            map.animateCamera(CameraUpdateFactory.newLatLngZoom(marker.getPosition(), 16f));
        }
    }

    private void showAllMembers(boolean animate) {
        if (disposed || map == null || markers.isEmpty()) return;
        if (mapView.getWidth() == 0 || mapView.getHeight() == 0) {
            mapView.postDelayed(() -> showAllMembers(animate), 100);
            return;
        }
        if (markers.size() == 1) {
            LatLng point = markers.values().iterator().next().getPosition();
            if (animate) map.animateCamera(CameraUpdateFactory.newLatLngZoom(point, 15f));
            else map.moveCamera(CameraUpdateFactory.newLatLngZoom(point, 15f));
            return;
        }
        LatLngBounds.Builder bounds = LatLngBounds.builder();
        for (Marker marker : markers.values()) bounds.include(marker.getPosition());
        if (animate) map.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds.build(), 90));
        else map.moveCamera(CameraUpdateFactory.newLatLngBounds(bounds.build(), 90));
    }

    public void focusTrajectory(String deviceId) {
        if (disposed || map == null) return;
        List<LatLng> route = routes.get(deviceId);
        if (route == null || route.isEmpty()) return;
        if (route.size() == 1) {
            map.animateCamera(CameraUpdateFactory.newLatLngZoom(route.get(0), 15f));
            return;
        }
        LatLngBounds.Builder bounds = LatLngBounds.builder();
        for (LatLng point : route) bounds.include(point);
        map.animateCamera(CameraUpdateFactory.newLatLngBounds(bounds.build(), 80));
    }

    public void onResume() { mapView.onResume(); }

    public void onPause() { mapView.onPause(); }

    @Override
    public void dispose() {
        if (disposed) return;
        disposed = true;
        bootLog("AMap view disposed");
        markers.clear();
        markerAvatarKeys.clear();
        avatarLoader.close();
        tracks.clear();
        routes.clear();
        mapView.onDestroy();
    }

    private void bootLog(String message) {
        if (BuildConfig.DEBUG) Log.i(TAG, message + "; viewId=" + viewId);
    }

    private static String stringValue(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private static double numberValue(Object value) {
        return value instanceof Number ? ((Number) value).doubleValue() : 0d;
    }

    private static List<LatLng> parseRoute(Object value) {
        List<LatLng> result = new ArrayList<>();
        if (!(value instanceof List)) return result;
        for (Object raw : (List<?>) value) {
            if (!(raw instanceof Map)) continue;
            Map<?, ?> point = (Map<?, ?>) raw;
            double lat = numberValue(point.get("lat"));
            double lng = numberValue(point.get("lng"));
            if (lat != 0 || lng != 0) result.add(new LatLng(lat, lng));
        }
        return result;
    }

    private static int routeColor(String deviceId) {
        int[] colors = {
                Color.rgb(0, 137, 123), Color.rgb(39, 105, 195),
                Color.rgb(215, 91, 77), Color.rgb(147, 79, 168),
                Color.rgb(198, 137, 22)
        };
        return colors[Math.floorMod(deviceId.hashCode(), colors.length)];
    }

    private void applyMarkerIcon(String id, Marker marker, String name, String avatar) {
        String key = name + "\u0000" + avatar;
        if (key.equals(markerAvatarKeys.get(id))) return;
        markerAvatarKeys.put(id, key);
        int color = routeColor(id);
        marker.setIcon(BitmapDescriptorFactory.fromBitmap(avatarLoader.fallback(name, color)));
        if (avatar.isEmpty()) return;
        avatarLoader.load(avatar, name, color, icon -> {
            if (!disposed && marker == markers.get(id) && key.equals(markerAvatarKeys.get(id))) {
                marker.setIcon(BitmapDescriptorFactory.fromBitmap(icon));
            }
        });
    }
}
