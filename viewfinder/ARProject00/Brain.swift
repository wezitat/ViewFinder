//
//  Brain.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import CoreLocation
import CoreMotion
import SceneKit
import LocationKit

class Brain: NSObject, InfoLocationDelegate,    // remove?
                       LocationManagerDelegate, // leave here
                       MotionManagerDelegate,   // leave here
                       RotationManagerDelegate, // leave here
                       DeviceCalibrateDelegate, // leave here
                       WitMarkerDelegate,       // wit is a UI part so we can remove
                       LKLocationManagerDelegate { // leave here
    
    static let sharedInstance = Brain()
    
    var feetSystem: Bool = false
    
    var   motionManager: MotionManager   = MotionManager() // leave here
    var locationManager: LocationManager = LocationManager() // leave here
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance // leave here
    
    var screenViewController: UIProtocol? = nil // leave here
     // remove from here
    
//    var demoData = DemoDataClass() // leave here
    
    //initial location of user (based on this LL point 3D scene is builing)
    var  centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0) // remove from here
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0) // remove from here
    
    var centerAltitude: CLLocationDistance = CLLocationDistance() // remove from here
    
     // remove from here
    
    func startMotionManager() { // leave
         motionManager.initManager()
    }
    
    func startLocationManager() { // leave
        locationManager.initManager()
    }
    
    func resetManager() { // leave
        motionManager.stopUpdating()
        locationManager.stopUpdating()
        
        motionManager.rotationManagerDelegate = nil
        motionManager.motionManagerDelegate = nil
        
        locationManager.locationManagerDelegate = nil
        locationManager.deviceCalibrateDelegate = nil
        locationManager.infoLocationDelegate = nil
        
        screenViewController = nil
    }
    
    func setupCenterPoint(lat: Double, lon: Double) {
        centerPoint  = CLLocation(latitude: lat, longitude: lon)
        userLocation = CLLocation(latitude: lat, longitude: lon)
    }
    
    //MARK: - InfoLocationDelegate ???
    
    func locationUpdated(location: String) {
        debugInfo.currentPosition = location
        debugInfo.generateDebugMessage()
    }
    
    func locationDistanceUpdated(dist: String) {
        debugInfo.distance = "\(dist) m"
        debugInfo.generateDebugMessage()
    }
    
    func altitudeUpdated(alt: Int) {
        debugInfo.altitude = "\(alt) m"
        debugInfo.generateDebugMessage()
    }
    
    func accuracyUpdated(acc: Int) {
        debugInfo.accuracyTime = "\(acc) m"
        debugInfo.generateDebugMessage()
    }
    
    func lastTimeLocationUpdate(timeUpdate: Int) {
        debugInfo.updateTime = "\(timeUpdate) sec"
        debugInfo.generateDebugMessage()
    }

    //MARK: - LocationManagerDelegate leave
    
    func locationDelegateAltitudeUpdated(altitude: CLLocationDistance) {
        //altitude of user location is updated
        screenViewController?.updateSceneAltitude!(altitude)
    }
    
    func locationDelegateLocationUpdated(location: CLLocation) {
        
        // remove to UIProtocol
        
        screenViewController?.updateSceneLocation!(location)
    }

    //MARK: - MotionManagerDelegate leave
    
    func rotationChanged(orientation: CMQuaternion) {
        //user moved camera and pointing of camera changed
        screenViewController?.changeSceneRotation!(orientation)
    }
    
    func drasticDeviceMove() {
        
    }
    
    //MARK: - DeviceCalibrateDelegate leave
    
    func headingUpdated(heading: CLLocationDirection) {
        (screenViewController as! ScreenBaseViewController).headingUpdated(heading)
    }
    
    func initLocationReceived() {
        (screenViewController as! ScreenBaseViewController).initLocationReceived()
    }
    
    //MARK: - RotationManagerDelegate leave
    
    func rotationAngleUpdated(angle: Double) {
        (screenViewController as! ScreenBaseViewController).rotationAngleUpdated(angle)
    }
    
    //MARK: - WitMarkerDelegate remove
    
    func showObjectDetails(wObject: WitObject) {
        (screenViewController as! ScreenBaseViewController).showObjectDetails(wObject)
    }

    //MARK: - Methods, setting Delegates
    
    func setTopViewController(topVC: UIProtocol!) {
        screenViewController = topVC
    }
    
    func setLocationManagerDelegate(delegate: AnyObject?) {
        locationManager.locationManagerDelegate = delegate as? LocationManagerDelegate
    }
    
    func setLocationManagerDeviceCalibrateDelegate(delegate: AnyObject?) {
        locationManager.deviceCalibrateDelegate = delegate as? DeviceCalibrateDelegate
    }
    
    func setLocationManagerInfoLocationDelegate(delegate: AnyObject?) {
        locationManager.infoLocationDelegate = delegate as? InfoLocationDelegate
    }
    
    func setMotionManagerDelegate(delegate: AnyObject?) {
        motionManager.motionManagerDelegate = delegate as? MotionManagerDelegate
    }
    
    func setMotionManagerRotationManagerDelegate(delegate: AnyObject?) {
        motionManager.rotationManagerDelegate = delegate as? RotationManagerDelegate
    }
    
    func getTopViewController() -> ScreenBaseViewController? {
        return screenViewController as? ScreenBaseViewController
    }
    
    func getLocationManager() -> LocationManager {
        return locationManager
    }
    
    //MARK: - LKLocationManagerDelegate
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.resetTimer()
        
        /*
         
         Here we have to work only with presentVC: we have to send a message to ScreenVC and RenderingVC about changes
         We have to create a Base class for these VC and they will handle this message on their own, we don't know what exactly object is this
         
        */
        
        screenViewController?.locationUpdated(locations.last! as CLLocation)
    }
    
    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
        screenViewController?.headingDirectionUpdated(newHeading)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: LKLocationManager) -> Bool {
        return true
    }
}
