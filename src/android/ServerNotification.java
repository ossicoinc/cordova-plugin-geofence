package com.cowbell.cordova.geofence;

import android.location.Location;

import com.google.gson.annotations.Expose;

import org.json.JSONObject;

public class ServerNotification {

    @Expose public double latitude;
    @Expose public double longitude;
    @Expose public float accuracy;
    @Expose public GeoNotification notification;
    @Expose public int transitionType;

    public ServerNotification(Location triggerLocation, GeoNotification geoNotif) {
        this.latitude = triggerLocation.getLatitude();
        this.longitude = triggerLocation.getLongitude();
        this.accuracy = triggerLocation.getAccuracy();
        this.notification = geoNotif;
        this.transitionType = geoNotif.transitionType;
    }

    public String toJson() {
        return Gson.get().toJson(this);
    }

    public static GeofencePluginMetadata fromJson(String json) {
        if (json == null) return null;
        return Gson.get().fromJson(json, GeofencePluginMetadata.class);
    }

}
