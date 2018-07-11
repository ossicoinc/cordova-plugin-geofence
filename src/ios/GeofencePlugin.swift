//
//  GeofencePlugin.swift
//  ionic-geofence
//
//  Created by tomasz on 07/10/14.
//
//

import Foundation
import AudioToolbox
import WebKit

let TAG = "GeofencePlugin"
let iOS8 = floor(NSFoundationVersionNumber) > floor(NSFoundationVersionNumber_iOS_7_1)
let iOS7 = floor(NSFoundationVersionNumber) <= floor(NSFoundationVersionNumber_iOS_7_1)


func log(_ message: String){
    NSLog("%@ - %@", TAG, message)
}

func log(_ messages: [String]) {
    for message in messages {
        log(message);
    }
}

let defaults = UserDefaults.standard

@available(iOS 8.0, *)
@objc(HWPGeofencePlugin) class GeofencePlugin : CDVPlugin {
    let priority = DispatchQoS.QoSClass.default
    override func pluginInitialize () {
        DispatchQueue.main.async {
            let (ok, warnings, errors) = GeofenceManager.sharedInstance.checkRequirements()
        }
    }

    func initialize(_ command: CDVInvokedUrlCommand) {
        log("BWLOC Plugin initialization")
        //        let faker = GeofenceFaker(manager: geofenceManager)
        //




        DispatchQueue.main.async {

            let permsOk = GeofenceManager.sharedInstance.registerPermissions()


            let (ok, warnings, errors) = GeofenceManager.sharedInstance.checkRequirements()

            log(warnings)
            log(errors)

            let result: CDVPluginResult

            if ok {
                result = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: warnings.joined(separator: "\n"))
            } else {
                result = CDVPluginResult(
                    status: CDVCommandStatus_ILLEGAL_ACCESS_EXCEPTION,
                    messageAs: (errors + warnings).joined(separator: "\n")
                )
            }
            self.commandDelegate!.send(result, callbackId: command.callbackId)
        }

    }

    func deviceReady(_ command: CDVInvokedUrlCommand) {
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func ping(_ command: CDVInvokedUrlCommand) {
        log("Ping")
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func hasPermission(_ command: CDVInvokedUrlCommand) {
        log("hasPermission")
        let isOk = CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways
        var message = [AnyHashable : Any](minimumCapacity: 1)
        message["isEnabled"] = isOk
        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: message)
        commandDelegate!.send(pluginResult, callbackId: command.callbackId)
    }

    func saveMetaData(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: priority).async {
            log("Saving metadata")
            log("\(command.arguments)")
            if let arg = command.arguments?.first {
                let data = JSON(arg)
                log("\(data)")
                if let uid = data["uid"].string {
                    defaults.set(uid, forKey: "uid")
                }
                if let accessToken = data["accessToken"].string {
                    defaults.set(accessToken, forKey: "accessToken")
                }
                if let geoTransitionURL = data["geoTransitionURL"].string {
                    defaults.set(geoTransitionURL, forKey: "geoTransitionURL")
                }
                if let locationUpdateURL = data["locationUpdateURL"].string {
                    defaults.set(locationUpdateURL, forKey: "locationUpdateURL")
                }
                if let trackEventURL = data["trackEventURL"].string {
                    defaults.set(trackEventURL, forKey: "trackEventURL")
                }
            }

            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    func addOrUpdate(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: priority).async {
            // do some task
            for geo in command.arguments {
                GeofenceManager.sharedInstance.addOrUpdateGeoNotification(JSON(geo))
            }
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    func getWatched(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: priority).async {
            let watched = GeofenceManager.sharedInstance.getWatchedGeoNotifications()!
            let watchedJsonString = watched.description
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: watchedJsonString)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    func remove(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: priority).async {
            for id in command.arguments {
                GeofenceManager.sharedInstance.removeGeoNotification(id as! String)
            }
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    func removeAll(_ command: CDVInvokedUrlCommand) {
        DispatchQueue.global(qos: priority).async {
            GeofenceManager.sharedInstance.removeAllGeoNotifications()
            DispatchQueue.main.async {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
                self.commandDelegate!.send(pluginResult, callbackId: command.callbackId)
            }
        }
    }

    func evaluateJs (_ script: String) {
        if let webView = webView {
            if let uiWebView = webView as? UIWebView {
                uiWebView.stringByEvaluatingJavaScript(from: script)
            } else if let wkWebView = webView as? WKWebView {
                wkWebView.evaluateJavaScript(script, completionHandler: nil)
            }
        } else {
            log("webView is nil")
        }
    }
}

// class for faking crossing geofences
@available(iOS 8.0, *)
class GeofenceFaker {
    let priority = DispatchQoS.QoSClass.default
    let geofenceManager: GeofenceManager

    init(manager: GeofenceManager) {
        geofenceManager = manager
    }

    func start() {
        DispatchQueue.global(qos: priority).async {
            while (true) {
                log("FAKER")
                let notify = arc4random_uniform(4)
                if notify == 0 {
                    log("FAKER notify chosen, need to pick up some region")
                    var geos = GeofenceManager.sharedInstance.getWatchedGeoNotifications()!
                    if geos.count > 0 {
                        //WTF Swift??
                        let index = arc4random_uniform(UInt32(geos.count))
                        let geo = geos[Int(index)]
                        let id = geo["id"].stringValue
                        DispatchQueue.main.async {
                            if let region = GeofenceManager.sharedInstance.getMonitoredRegion(id) {
                                log("FAKER Trigger didEnterRegion")
                                GeofenceManager.sharedInstance.locationManager(
                                    GeofenceManager.sharedInstance.locationManager,
                                    didEnterRegion: region
                                )
                            }
                        }
                    }
                }
                Thread.sleep(forTimeInterval: 3)
            }
        }
    }

    func stop() {

    }
}

@available(iOS 8.0, *)
@objc class GeofenceManager : NSObject, CLLocationManagerDelegate, URLSessionDelegate {
    static let sharedInstance = GeofenceManager()
    let locationManager = CLLocationManager()
    let store = GeoNotificationStore()
    var dialogPending = false

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: "GeofencingSession")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = false
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    lazy var dateJSONFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone?
        formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX") as Locale?
        return formatter
    }()

    private override init() {
        log("BWLOC geofenceManager init")
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    /*:
     This delegate method is called once when response is recieved. This is the place where
     you can perform initialization or other related tasks before start recieviing data
     from response
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                           didReceiveResponse response: URLResponse,
                           completionHandler: (URLSession.ResponseDisposition) -> Void) {
        log("BWLOC Session received first response!")
//        self.response = HttpResponse(response: response as! NSHTTPURLResponse)
        // It is necessary to call completionHandler, otherwise request
        // will not progress one way or the other
        completionHandler(URLSession.ResponseDisposition.allow)
    }
    /*:
     This delegate method is called when session task is finished. Check for presence
     of NSError object to decide if call was successful or not
     */
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        log("BWLOC sessiontask finished")
//        // When session task is complete, this delegate method will be called.
//        // If there is no error then NSError object will nil, otherwise NSError
//        // will contain information about the error.
//        if let errorInfo = error{
//            print("Session error: \(errorInfo.description)")
//            self.response?.error = error
//        }
//        else{
//            print("Request - complete!")
//            self.response?.responseUrl = task.response?.URL
//            self.response?.statusCode = (task.response as! NSHTTPURLResponse).statusCode
//        }
//        if let compHandler = completionHandler{
//            compHandler(self.response!)
//        }
    }
    /*:
     This delegate method is called when response data is recieved in chunks or
     in one shot.
     */
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceiveData data: Data) {
//        response?.responseData.appendData(data)
        log("BWLOC response complete")
    }


    func registerPermissions() -> Bool {
        if iOS8 {
            //locationManager.stopUpdatingLocation()
            //locationManager.stopMonitoringSignificantLocationChanges()

            let authStatus = CLLocationManager.authorizationStatus()
            locationManager.requestAlwaysAuthorization()
            if (authStatus == CLAuthorizationStatus.notDetermined) {
                // we need to wait for the dialog to return
                self.dialogPending = true
                return false;
            } else {
                //locationManager.startMonitoringSignificantLocationChanges()
                locationManager.delegate = self
                return true;
            }
        }
        return true;
    }

    func addOrUpdateGeoNotification(_ geoNotification: JSON) {
        log("BWLOC geofenceManager addOrUpdate")

        let (_, warnings, errors) = checkRequirements()

        log(warnings)
        log(errors)

        let location = CLLocationCoordinate2DMake(
            geoNotification["latitude"].doubleValue,
            geoNotification["longitude"].doubleValue
        )
        log("AddOrUpdate geo: \(geoNotification)")
        let radius = geoNotification["radius"].doubleValue as CLLocationDistance
        let id = geoNotification["id"].stringValue

        let region = CLCircularRegion(center: location, radius: radius, identifier: id)

        var transitionType = 0
        if let i = geoNotification["transitionType"].int {
            transitionType = i
        }
        region.notifyOnEntry = 0 != transitionType & 1
        region.notifyOnExit = 0 != transitionType & 2

        //store
        store.addOrUpdate(geoNotification)
        locationManager.startMonitoring(for: region)
    }

    func checkRequirements() -> (Bool, [String], [String]) {
        var errors = [String]()
        let warnings = [String]()

        if (!CLLocationManager.isMonitoringAvailable(for: CLRegion.self)) {
            errors.append("Geofencing not available")
        }

        if (!CLLocationManager.locationServicesEnabled()) {
            errors.append("Error: Locationservices not enabled")
        }

        let authStatus = CLLocationManager.authorizationStatus()

        if (authStatus != CLAuthorizationStatus.authorizedAlways) {
            errors.append("Warning: Location always permissions not granted")
        }

        let ok = (errors.count == 0)

        return (ok, warnings, errors)
    }

    func getWatchedGeoNotifications() -> [JSON]? {
        return store.getAll()
    }

    func getMonitoredRegion(_ id: String) -> CLRegion? {
        for object in locationManager.monitoredRegions {
            let region = object

            if (region.identifier == id) {
                return region
            }
        }
        return nil
    }

    func removeGeoNotification(_ id: String) {
        store.remove(id)
        let region = getMonitoredRegion(id)
        if (region != nil) {
            log("BWLOC Stoping monitoring region \(id)")
            locationManager.stopMonitoring(for: region!)
        }
    }

    func removeAllGeoNotifications() {
        store.clear()
        let (ok, _, _) = GeofenceManager.sharedInstance.checkRequirements()
        if (ok) {
            for object in locationManager.monitoredRegions {
                let region = object
                log("BWLOC Stoping monitoring region \(region.identifier)")
                locationManager.stopMonitoring(for: region)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        log("BWLOC changed authorization status")
        guard status != .notDetermined else {
            return
        }
        var statusDescription = ""
        if (status == .denied) {
            statusDescription = "Denied"
        } else if (status == .authorizedAlways) {
            statusDescription = "Always"
        } else if (status == .authorizedWhenInUse) {
            statusDescription = "In Use"
        } else if (status == .notDetermined) {
            statusDescription = "Not Determined"
        } else if (status == .restricted) {
            statusDescription = "Restricted"
        }

        guard let urlString = defaults.string(forKey: "trackEventURL"), let uid = defaults.string(forKey: "uid"), status != .notDetermined else {
            return
        }

        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let accessToken = defaults.string(forKey: "accessToken") {
                request.setValue("Bearer" + accessToken, forHTTPHeaderField: "Authorization")
            }

            let jsonData: JSON = ["user_id": uid, "event": "location-change-access", "properties": ["level": statusDescription]]

            request.httpBody = try! jsonData.rawData()

            let task = self.urlSession.dataTask(with: request)
            task.resume()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        log("BWLOC update location")
        guard let urlString = defaults.string(forKey: "locationUpdateURL"), let uid = defaults.string(forKey: "uid") else {
            return
        }

        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let accessToken = defaults.string(forKey: "accessToken") {
                request.setValue("Bearer" + accessToken, forHTTPHeaderField: "Authorization")
            }
            if let lastLocation = locations.last {
                let timestampString = dateJSONFormatter.string(from: lastLocation.timestamp)
                let jsonData: JSON = ["location": ["latitude": lastLocation.coordinate.latitude, "longitude": lastLocation.coordinate.longitude], "user_id": uid, "speed": lastLocation.speed, "direction": lastLocation.course, "altitude": lastLocation.altitude, "horizontal_accuracy": lastLocation.horizontalAccuracy, "vertical_accuracy": lastLocation.verticalAccuracy, "timestamp": timestampString]

                request.httpBody = try! jsonData.rawData()
                let task = self.urlSession.dataTask(with: request)
//                let task = self.urlSession.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
//                    guard error == nil else {
//                        print("Error: ", error!)
//                        return
//                    }
//
//                    if let data = data, data.count > 0 {
//                        DispatchQueue.global().async {
//                            self.removeAllGeoNotifications()
//                            let geoFencesJson = JSON(data: data)
//                            log("JSON: \(geoFencesJson)")
//                            for geoFenceJson in geoFencesJson {
//                                log("\(geoFenceJson.1)")
//                                self.addOrUpdateGeoNotification(geoFenceJson.1)
//                            }
//                        }
//                    }
//                })
                task.resume()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        log("BWLOC fail with error: \(error)")

//        guard let urlString = defaults.string(forKey: "trackEventURL") else {
//            return
//        }
//
//        let url = URL(string: urlString)!
//        let session = URLSession.shared
//        var request = URLRequest(url: url)
//
//        log("Sending error info to server at url \(url)")
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        if let accessToken = defaults.string(forKey: "accessToken") {
//            request.setValue("Bearer" + accessToken, forHTTPHeaderField: "Authorization")
//        }
//
//        var jsonData: JSON = ["event": "didFailWithError", "properties": ["error": error.localizedDescription]]
//        request.httpBody = try! jsonData.rawData()
//
//        let task = urlSession.dataTask(with: request, completionHandler: { (_, response, error) -> Void in
//            print("Response from server: \(response), errors: \(error)")
//        })
//
//        task.resume()
    }

    func locationManager(_ manager: CLLocationManager, didFinishDeferredUpdatesWithError error: Error?) {
        log("BWLOC deferred fail error: \(error?.localizedDescription)")

//        guard let urlString = defaults.string(forKey: "trackEventURL") else {
//            return
//        }
//
//        let url = URL(string: urlString)!
//        let session = URLSession.shared
//        var request = URLRequest(url: url)
//
//        log("Sending error info to server at url \(url)")
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        if let accessToken = defaults.string(forKey: "accessToken") {
//            request.setValue("Bearer" + accessToken, forHTTPHeaderField: "Authorization")
//        }
//
//        var jsonData: JSON = ["event": "didFinishDeferredUpdatesWithError", "properties": ["error": error?.localizedDescription]]
//        request.httpBody = try! jsonData.rawData()
//
//        let task = urlSession.dataTask(with: request, completionHandler: { (_, response, error) -> Void in
//            print("Response from server: \(response), errors: \(error)")
//        })
//
//        task.resume()
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        log("BWLOC Entering region \(region.identifier)")
        handleTransition(region, transitionType: 1)
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        log("BWLOC Exiting region \(region.identifier)")
        handleTransition(region, transitionType: 2)
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region is CLCircularRegion {
            let lat = (region as! CLCircularRegion).center.latitude
            let lng = (region as! CLCircularRegion).center.longitude
            let radius = (region as! CLCircularRegion).radius

            log("BWLOC Starting monitoring for region \(region) lat \(lat) lng \(lng) of radius \(radius)")


        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        log("BWLOC State for region " + region.identifier)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        log("BWLOC Monitoring region " + region!.identifier + " failed " + error.localizedDescription)
    }

    func handleTransition(_ region: CLRegion!, transitionType: Int) {
        if var geoNotification = store.findById(region.identifier) {
            geoNotification["transitionType"].int = transitionType

            sendTransitionToServer(geoNotification)
        }
    }

    func sendTransitionToServer(_ geo: JSON) {
        log("BWLOC Looking for url to send transition info to server \(geo)")
        guard let urlString = defaults.string(forKey: "geoTransitionURL") else {
            return
        }

        let url = URL(string: urlString)!
        var request = URLRequest(url: url)

        log("BWLOC Sending transition info to server at url \(url)")
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let accessToken = defaults.string(forKey: "accessToken") {
            request.setValue("Bearer" + accessToken, forHTTPHeaderField: "Authorization")
        }

        var jsonData: JSON = geo
        jsonData["transitionType"] = geo["transitionType"]
        request.httpBody = try! jsonData.rawData()

        let task = urlSession.dataTask(with: request)
        task.resume()
    }
}

class GeoNotificationStore {
    init() {
        createDBStructure()
    }

    func createDBStructure() {
        let (tables, err) = SD.existingTables()

        if (err != nil) {
            log("Cannot fetch sqlite tables: \(err)")
            return
        }

        if (tables.filter { $0 == "GeoNotifications" }.count == 0) {
            if let err = SD.executeChange("CREATE TABLE GeoNotifications (ID TEXT PRIMARY KEY, Data TEXT)") {
                //there was an error during this function, handle it here
                log("Error while creating GeoNotifications table: \(err)")
            } else {
                //no error, the table was created successfully
                log("GeoNotifications table was created successfully")
            }
        }
    }

    func addOrUpdate(_ geoNotification: JSON) {
        if (findById(geoNotification["id"].stringValue) != nil) {
            update(geoNotification)
        }
        else {
            add(geoNotification)
        }
    }

    func add(_ geoNotification: JSON) {
        let id = geoNotification["id"].stringValue
        let err = SD.executeChange("INSERT INTO GeoNotifications (Id, Data) VALUES(?, ?)",
                                   withArgs: [id as AnyObject, geoNotification.description as AnyObject])

        if err != nil {
            log("Error while adding \(id) GeoNotification: \(err)")
        }
    }

    func update(_ geoNotification: JSON) {
        let id = geoNotification["id"].stringValue
        let err = SD.executeChange("UPDATE GeoNotifications SET Data = ? WHERE Id = ?",
                                   withArgs: [geoNotification.description as AnyObject, id as AnyObject])

        if err != nil {
            log("Error while adding \(id) GeoNotification: \(err)")
        }
    }

    func findById(_ id: String) -> JSON? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM GeoNotifications WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching \(id) GeoNotification table: \(err)")
            return nil
        } else {
            if (resultSet.count > 0) {
                let jsonString = resultSet[0]["Data"]!.asString()!
                return JSON(data: jsonString.data(using: String.Encoding.utf8)!)
            }
            else {
                return nil
            }
        }
    }

    func getAll() -> [JSON]? {
        let (resultSet, err) = SD.executeQuery("SELECT * FROM GeoNotifications")

        if err != nil {
            //there was an error during the query, handle it here
            log("Error while fetching from GeoNotifications table: \(err)")
            return nil
        } else {
            var results = [JSON]()
            for row in resultSet {
                if let data = row["Data"]?.asString() {
                    results.append(JSON(data: data.data(using: String.Encoding.utf8)!))
                }
            }
            return results
        }
    }

    func remove(_ id: String) {
        let err = SD.executeChange("DELETE FROM GeoNotifications WHERE Id = ?", withArgs: [id as AnyObject])

        if err != nil {
            log("Error while removing \(id) GeoNotification: \(err)")
        }
    }

    func clear() {
        let err = SD.executeChange("DELETE FROM GeoNotifications")

        if err != nil {
            log("Error while deleting all from GeoNotifications: \(err)")
        }
    }
}
