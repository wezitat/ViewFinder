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

class Brain: InfoLocationDelegate, LocationManagerDelegate, MotionManagerDelegate, RotationManagerDelegate, DeviceCalibrateDelegate, SceneEventsDelegate, WitMarkerDelegate {
    static let sharedInstance = Brain()
    
    var feetSystem: Bool = false
    
    var   motionManager: MotionManager   = MotionManager()
    var locationManager: LocationManager = LocationManager()
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance
    
    var wrapperSceneDelegate: WrapperSceneDelegate? = nil
    var renderingSceneDelegate: RenderingSceneDelegate? = nil
    
    //initial location of user (based on this LL point 3D scene is builing)
    var  centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var centerAltitude: CLLocationDistance = CLLocationDistance()
    
    func startMotionManager() {
         motionManager.initManager()
    }
    
    func startLocationManager() {
        locationManager.initManager()
    }
    
    func resetManager() {
        motionManager.stopUpdating()
        locationManager.stopUpdating()
        
        Brain.sharedInstance.motionManager.rotationManagerDelegate = nil
        Brain.sharedInstance.motionManager.motionManagerDelegate = nil
        
        Brain.sharedInstance.locationManager.locationManagerDelegate = nil
        Brain.sharedInstance.locationManager.deviceCalibrateDelegate = nil
        Brain.sharedInstance.locationManager.infoLocationDelegate = nil
        
        Brain.sharedInstance.wrapperSceneDelegate = nil
        
        Brain.sharedInstance.renderingSceneDelegate!.setEventDelegate(nil)
        Brain.sharedInstance.renderingSceneDelegate = nil
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
    
    func altitudeUpdated(altitude: CLLocationDistance) {
        //altitude of user location is updated
        renderingSceneDelegate?.altitudeUpdated(altitude)
    }
    
    func locationUpdated(location: CLLocation) {
        let point: Point2D = LocationMath.sharedInstance.convertLLtoXY(Brain.sharedInstance.centerPoint, newLocation: location)
        renderingSceneDelegate?.locationUpdated(point, location: location)
    }

    //MARK: - MotionManagerDelegate
    
    func rotationChanged(orientation: CMQuaternion) {
        //user moved camera and pointing of camera changed
        renderingSceneDelegate?.rotationChanged(orientation)
    }
    
    func drasticDeviceMove() {
        
    }
    
    //MARK: - DeviceCalibrateDelegate
    
    func headingUpdated(heading: CLLocationDirection) {
        wrapperSceneDelegate?.headingUpdated(heading)
    }
    
    func initLocationReceived() {
        wrapperSceneDelegate?.initLocationReceived()
    }
    
    //MARK: - RotationManagerDelegate
    
    func rotationAngleUpdated(angle: Double) {
        wrapperSceneDelegate?.rotationAngleUpdated(angle)
    }
    
    //MARK: - SceneEventsDelegate (and WitMarkerDelegate for the 1st method)
    
    func showObjectDetails(wObject: WitObject) {
        wrapperSceneDelegate?.showObjectDetails(wObject)
    }
    
    func addNewWitMarker(wObject: WitObject) {
        wrapperSceneDelegate?.addNewWitMarker(wObject)
    }
    
    func filterWitMarkers() {
        wrapperSceneDelegate?.filterWitMarkers()
    }
    
    func cameraMoved() {
        
        //if camera moved we neeed to update witmarkers on screen. For that we will need what is object coordinates based on screen coordinates
        
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let  screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        
        let witMarkers: [WitMarker] = (wrapperSceneDelegate?.getWitMarkers())!
        
        for marker in witMarkers {
            
            if renderingSceneDelegate!.isNodeOnMotionScreen(marker.wObject.objectGeometry) {
                marker.showMarker(false)
            } else {
                marker.showMarker(true)
            }
            
            var point: Point3D = renderingSceneDelegate!.nodePosToScreenMotionCoordinates(marker.wObject.objectGeometry)
            
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
                point = (wrapperSceneDelegate?.updateWrapperPointIfObjectIsBehind(point))!
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
        wrapperSceneDelegate?.distanceUpdated(location)
    }

    //MARK: - Methods, setting Delegates
    
    func setGameViewController(gameVC: RenderingSceneDelegate!) {
        renderingSceneDelegate = gameVC
    }
    
    func setTopViewController(topVC: WrapperSceneDelegate!) {
        wrapperSceneDelegate = topVC
    }
    
    func setGameViewControllerDelegate(delegate: SceneEventsDelegate) {
        renderingSceneDelegate?.setEventDelegate(delegate)
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
    
    func getGameViewController() -> RenderingSceneDelegate? {
        return renderingSceneDelegate
    }
    
    func getTopViewController() -> WrapperSceneDelegate? {
        return wrapperSceneDelegate
    }
    
    func getLocationManager() -> LocationManager {
        return locationManager
    }
}
