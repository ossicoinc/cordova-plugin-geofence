package com.cowbell.cordova.geofence;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.location.Location;
import android.util.Log;
import android.os.AsyncTask;
import com.goebl.david.Response;
import com.goebl.david.Webb;

import org.json.JSONObject;

import java.util.*;

public class TransitionReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        Logger.setLogger(new Logger(GeofencePlugin.TAG, context, false));
        Logger logger = Logger.getLogger();

        String error = intent.getStringExtra("error");

        if (error != null) {
            //handle error
            logger.log(Log.DEBUG, error);
        } else {
            String geofencesJson = intent.getStringExtra("transitionData");
            Location triggerLocation = intent.getParcelableExtra("triggerLocation");
            PostLocationTask task = new TransitionReceiver.PostLocationTask(GeofencePluginMetadata.getCurrent(context), triggerLocation);
            task.execute(geofencesJson);
        }
    }

    private class PostLocationTask extends AsyncTask<String, Void, String> {

        private GeofencePluginMetadata prefs;
        private Location triggerLocation;

        public PostLocationTask(GeofencePluginMetadata prefs, Location triggerLocation) {
            this.prefs = prefs;
            this.triggerLocation = triggerLocation;
        }

        @Override
        protected String doInBackground(String... geofencesJson) {
            try {

                Log.println(Log.DEBUG, GeofencePlugin.TAG, "Executing PostLocationTask#doInBackground");

                GeoNotification[] geoNotifications = Gson.get().fromJson(geofencesJson[0], GeoNotification[].class);

                if (prefs.geoTransitionURL != null) {

                    Webb webb = Webb.create();
                    if (prefs.accessToken != null) {
                        webb.setDefaultHeader(Webb.HDR_AUTHORIZATION, "Bearer " + prefs.accessToken);
                    }
                    for (int i = 0; i < geoNotifications.length; i++) {
                        GeoNotification geoNotification = geoNotifications[i];

                        ServerNotification serverNotif = new ServerNotification(triggerLocation, geoNotification);
                        Response<String> response = webb
                                .post(prefs.geoTransitionURL)
                                .body(new JSONObject(serverNotif.toJson()))
                                .asString();

                        if (response.isSuccess()) {
                            Log.println(Log.DEBUG, GeofencePlugin.TAG, "Reponse OK");
                        } else {
                            Log.println(Log.DEBUG, GeofencePlugin.TAG, "Reponse KO");
                        }
/*
                    DefaultHttpClient httpClient = new DefaultHttpClient();
                    HttpPost request = new HttpPost(geoNotification.url);

                    StringEntity se = new StringEntity(geoNotification.toJson());
                    request.setEntity(se);
                    request.setHeader("Accept", "application/json");
                    request.setHeader("Content-type", "application/json");

                    for (Map.Entry<String, String> entry : geoNotification.headers.entrySet()) {
                        request.setHeader(entry.getKey(), entry.getValue());
                    }

                    HttpResponse response = httpClient.execute(request);

                    Log.println(Log.DEBUG, GeofencePlugin.TAG,  "Response received"+ response.getStatusLine());
                    if (response.getStatusLine().getStatusCode() == 200) {
                        Log.println(Log.DEBUG, GeofencePlugin.TAG,  "Reponse OK");
                    } else {
                        Log.println(Log.DEBUG, GeofencePlugin.TAG,  "Reponse KO");
                    }
                    */
                    }
                }
            } catch (Throwable e) {
                Log.println(Log.ERROR, GeofencePlugin.TAG, "Exception posting geofence: " + e);
            }

            return "Executed";
        }

        @Override
        protected void onPostExecute(String result) {

        }
    }
}