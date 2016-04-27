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

class Brain: NSObject, InfoLocationDelegate, LocationManagerDelegate, MotionManagerDelegate, RotationManagerDelegate, DeviceCalibrateDelegate, SceneEventsDelegate, WitMarkerDelegate, LKLocationManagerDelegate {
    static let sharedInstance = Brain()
    
    var feetSystem: Bool = false
    
    var   motionManager: MotionManager   = MotionManager()
    var locationManager: LocationManager = LocationManager()
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance
    
    var screenViewController: LocationBaseViewController? = nil
    var renderingViewController: RenderingBaseViewController? = nil
    
    var demoData = DemoDataClass()
    
    //initial location of user (based on this LL point 3D scene is builing)
    var  centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var centerAltitude: CLLocationDistance = CLLocationDistance()
    
    func addWits() {
        
        demoData.initData()
        
        renderingViewController?.addWitObjects(demoData.objects)
        (screenViewController as? ScreenBaseViewController)?.addWitMarkers(demoData.objects)
        
    }
    
    func startMotionManager() {
         motionManager.initManager()
    }
    
    func startLocationManager() {
        locationManager.initManager()
    }
    
    func resetManager() {
        motionManager.stopUpdating()
        locationManager.stopUpdating()
        
        motionManager.rotationManagerDelegate = nil
        motionManager.motionManagerDelegate = nil
        
        locationManager.locationManagerDelegate = nil
        locationManager.deviceCalibrateDelegate = nil
        locationManager.infoLocationDelegate = nil
        
        screenViewController = nil
        
        renderingViewController!.setEventDelegate(nil)
        renderingViewController = nil
    }
    
    func setupCenterPoint(lat: Double, lon: Double) {
        centerPoint  = CLLocation(latitude: lat, longitude: lon)
        userLocation = CLLocation(latitude: lat, longitude: lon)
    }
    
    //MARK: - InfoLocationDelegate
    
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

    //MARK: - LocationManagerDelegate
    
    func locationDelegateAltitudeUpdated(altitude: CLLocationDistance) {
        //altitude of user location is updated
        renderingViewController?.altitudeUpdated(altitude)
    }
    
    func locationDelegateLocationUpdated(location: CLLocation) {
        let point: Point2D = LocationMath.sharedInstance.convertLLtoXY(Brain.sharedInstance.centerPoint, newLocation: location)
        renderingViewController?.locationUpdated(point, location: location)
    }

    //MARK: - MotionManagerDelegate
    
    func rotationChanged(orientation: CMQuaternion) {
        //user moved camera and pointing of camera changed
        renderingViewController?.rotationChanged(orientation)
    }
    
    func drasticDeviceMove() {
        
    }
    
    //MARK: - DeviceCalibrateDelegate
    
    func headingUpdated(heading: CLLocationDirection) {
        (screenViewController as! ScreenBaseViewController).headingUpdated(heading)
    }
    
    func initLocationReceived() {
        (screenViewController as! ScreenBaseViewController).initLocationReceived()
    }
    
    //MARK: - RotationManagerDelegate
    
    func rotationAngleUpdated(angle: Double) {
        (screenViewController as! ScreenBaseViewController).rotationAngleUpdated(angle)
    }
    
    //MARK: - SceneEventsDelegate (and WitMarkerDelegate for the 1st method)
    
    func showObjectDetails(wObject: WitObject) {
        (screenViewController as! ScreenBaseViewController).showObjectDetails(wObject)
    }
    
    func addNewWitMarker(wObject: WitObject) {
        (screenViewController as! ScreenBaseViewController).addNewWitMarker(wObject)
    }
    
    func filterWitMarkers() {
        (screenViewController as! ScreenBaseViewController).filterWitMarkers()
    }
    
    func cameraMoved() {
        
        //if camera moved we neeed to update witmarkers on screen. For that we will need what is object coordinates based on screen coordinates
        
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let  screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        
//        let witMarkers: [WitMarker] = (screenViewController?.getWitMarkers())!
        
        let witMarkers: [WitMarker] = (screenViewController as! ScreenBaseViewController).witMarkers
        
        for marker in witMarkers {
            
            if renderingViewController!.isNodeOnMotionScreen(marker.wObject.objectGeometry) {
                marker.showMarker(false)
            } else {
                marker.showMarker(true)
            }
            
            var point: Point3D = (renderingViewController?.nodePosToScreenMotionCoordinates(marker.wObject.objectGeometry))!
            
            point.x -= 30
            point.y -= 30
            
            if  point.x < 0 {
                point.x = 0
            }
            
            if point.y < 0 {
                point.y = 0
            }
            
            if point.x > screenWidth - Double(WIT_MARKER_SIZE) {
                point.x = Double(screenWidth) - Double(WIT_MARKER_SIZE)
            }
            
            if point.y > screenHeight - Double(WIT_MARKER_SIZE) {
                point.y = screenHeight - Double(WIT_MARKER_SIZE)
            }
            
            //check if element is behind - if yes our point will be inside the screen
            if (point.z > 1) {
                point = ((screenViewController as! ScreenBaseViewController).updatePointIfObjectIsBehind(point))
                //originalPoint = Point2D(xPos: point.x, yPos: point.y)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                marker.view.frame = CGRectMake(CGFloat(point.x), CGFloat(point.y), WIT_MARKER_SIZE, WIT_MARKER_SIZE)
                marker.updatePointerAngle(0)
            }
        }
    }
    
    func distanceUpdated(location: CLLocation) {
        
        // move to wrapperSceneDelegate
        (screenViewController as! ScreenBaseViewController).distanceUpdated(location)
    }

    //MARK: - Methods, setting Delegates
    
    func setGameViewController(gameVC: RenderingBaseViewController!) {
        renderingViewController = gameVC
    }
    
    func setTopViewController(topVC: ScreenBaseViewController!) {
        screenViewController = topVC
    }
    
    func setGameViewControllerDelegate(delegate: SceneEventsDelegate) {
        renderingViewController?.setEventDelegate(delegate)
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
    
    func getGameViewController() -> RenderingBaseViewController? {
        return renderingViewController
    }
    
    func getTopViewController() -> ScreenBaseViewController? {
        return screenViewController as? ScreenBaseViewController
    }
    
    func getLocationManager() -> LocationManager {
        return locationManager
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        self.locationManager.resetTimer()
        
        /*
         
         Here we have to work only with presentVC: we have to send a message to ScreenVC and RenderingVC about changes
         We have to create a Base class for these VC and they will handle this message on their own, we don't know what exactly object is this
         
        */
        
        screenViewController?.locationUpdated(locations.last! as CLLocation)
//        renderingViewController?.locationUpdated(locations.last! as CLLocation)
        
//        let newLocation: CLLocation = locations.last! as CLLocation
//        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
//        
//        if locationAge > 10.0 {
//            return
//        }
//        
//        if newLocation.verticalAccuracy > 0 {
//            
//            self.locationManager.locationManagerDelegate?.locationDelegateAltitudeUpdated(newLocation.altitude)
//            self.locationManager.infoLocationDelegate?.altitudeUpdated(Int(newLocation.altitude))
//        }
//        
//        if newLocation.horizontalAccuracy < 0 {
//            return
//        }
//        
//        self.locationManager.infoLocationDelegate?.accuracyUpdated(Int(newLocation.horizontalAccuracy))
//        
//        if self.locationManager.previousLocation == nil {
//            if newLocation.horizontalAccuracy <= self.locationManager.LOCATION_ACCURACCY && self.locationManager.deviceCalibrateDelegate != nil{
//                Brain.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
//                
//                if newLocation.verticalAccuracy > 0 {
//                    Brain.sharedInstance.centerAltitude = newLocation.altitude
//                    self.locationManager.deviceCalibrateDelegate.initLocationReceived()
//                    self.locationManager.previousLocation = newLocation
//                }
//                
//                self.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(self.locationManager.previousLocation)))")
//                self.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
//            }
//        }
//        else {
//            if newLocation.horizontalAccuracy <= self.locationManager.LOCATION_ACCURACCY {
//                if self.locationManager.locationManagerDelegate != nil {
//                    self.locationManager.locationManagerDelegate.locationDelegateLocationUpdated(newLocation)
//                    Brain.sharedInstance.userLocation = newLocation
//                }
//                
//                self.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(self.locationManager.previousLocation)))")
//                self.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
//                
//                self.locationManager.previousLocation = newLocation
//            }
//            else {
//                self.locationManager.infoLocationDelegate?.locationDistanceUpdated("ignoring")
//                self.locationManager.infoLocationDelegate?.locationUpdated("ignoring")
//            }
//        }
    }
    
    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        print("heading = \((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)")
        
        self.locationManager.deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: LKLocationManager) -> Bool {
        return true
    }
}
