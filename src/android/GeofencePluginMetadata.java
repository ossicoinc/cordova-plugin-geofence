package com.cowbell.cordova.geofence;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.annotations.Expose;

import org.json.JSONObject;

public class GeofencePluginMetadata {

    @Expose public String uid;
    @Expose public String accessToken;
    @Expose public String geoTransitionURL;
    @Expose public String locationUpdateURL;
    @Expose public String trackEventURL;

    public static GeofencePluginMetadata getCurrent(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(GeofencePlugin.PREFS, Context.MODE_PRIVATE);
        String objStr = prefs.getString(GeofencePlugin.METADATA, null);
        if (objStr != null) {
            return fromJson(objStr);
        }
        return new GeofencePluginMetadata();
    }

    public static GeofencePluginMetadata setCurrent(Context context, JSONObject object) {
        GeofencePluginMetadata metadata = fromJson(object.toString());
        SharedPreferences prefs = context.getSharedPreferences(GeofencePlugin.PREFS, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(GeofencePlugin.METADATA, metadata.toJson());
        editor.apply();
        return metadata;
    }

    public String toJson() {
        return Gson.get().toJson(this);
    }

    public static GeofencePluginMetadata fromJson(String json) {
        if (json == null) return null;
        return Gson.get().fromJson(json, GeofencePluginMetadata.class);
    }

}
