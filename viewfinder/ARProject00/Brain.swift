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
                       SceneEventsDelegate,     // don't know, maybe remove?
                       WitMarkerDelegate,       // wit is a UI part so we can remove
                       LKLocationManagerDelegate { // leave here
    
    static let sharedInstance = Brain()
    
    var feetSystem: Bool = false
    
    var   motionManager: MotionManager   = MotionManager() // leave here
    var locationManager: LocationManager = LocationManager() // leave here
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance // leave here
    
    var screenViewController: UIProtocol? = nil // leave here
    var renderingViewController: RenderingBaseViewController? = nil // remove from here
    
    var demoData = DemoDataClass() // leave here
    
    //initial location of user (based on this LL point 3D scene is builing)
    var  centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0) // remove from here
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0) // remove from here
    
    var centerAltitude: CLLocationDistance = CLLocationDistance() // remove from here
    
    var wit3DModels: [Wit3DModel]! = nil // remove from here
    
    func addWits() { // remove
        
        demoData.initData()

        wit3DModels = [Wit3DModel]()
        
        for object in demoData.objects {
            
            let wit3DModel = Wit3DModel(wit: object)
            
            (screenViewController as? ScreenBaseViewController)?.addNewWitMarkerWithWitModel(wit3DModel)
            
            renderingViewController?.geometryNode.addChildNode(wit3DModel.objectGeometry)
            
            wit3DModels.append(wit3DModel)
        }
    }
    
    func initialize3DSceneWithHeading(calibratedHeading: CLLocationDirection) { // remove
        renderingViewController?.initialize3DSceneWithHeading(calibratedHeading)
        addWits()
    }
    
    func update3DModels(location: CLLocation) { // remove
        for object in wit3DModels {
            object.updateWitObjectSize(location)
        }
    }
    
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
        
        renderingViewController!.setEventDelegate(nil)
        renderingViewController = nil
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
        renderingViewController?.altitudeUpdated(altitude)
    }
    
    func locationDelegateLocationUpdated(location: CLLocation) {
        let point: Point2D = LocationMath.sharedInstance.convertLLtoXY(Brain.sharedInstance.centerPoint, newLocation: location)
        
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        renderingViewController?.setCameraNodePosition(SCNVector3Make(Float(point.x), Float(point.y), (renderingViewController?.getCameraNode().position.z)!))
        update3DModels(location)
        
        SCNTransaction.commit()
        
//        renderingViewController?.redrawModels(point)
    }

    //MARK: - MotionManagerDelegate leave
    
    func rotationChanged(orientation: CMQuaternion) {
        //user moved camera and pointing of camera changed
        renderingViewController?.rotationChanged(orientation)
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
    
    //MARK: - SceneEventsDelegate remove
    
    func showObjectDetails(result: SCNHitTestResult) {
        
        for object in wit3DModels {
            if result.node == object.objectGeometry {
                (screenViewController as! ScreenBaseViewController).showObjectDetails(object.wObject)
            }
        }
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
            
            if renderingViewController!.isNodeOnScreen(marker.wit3DModel.objectGeometry) {
                marker.showMarker(false)
            } else {
                marker.showMarker(true)
            }
            
            var point: Point3D = (renderingViewController?.nodePosToScreenCoordinates(marker.wit3DModel.objectGeometry))!
            
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
    
    func setTopViewController(topVC: UIProtocol!) {
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
    
    //MARK: - LKLocationManagerDelegate
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.resetTimer()
        
        /*
         
         Here we have to work only with presentVC: we have to send a message to ScreenVC and RenderingVC about changes
         We have to create a Base class for these VC and they will handle this message on their own, we don't know what exactly object is this
         
        */
        
        screenViewController?.locationUpdated(locations.last! as CLLocation)
//        renderingViewController?.locationUpdated(locations.last! as CLLocation)
        
    }
    
    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
        screenViewController?.headingDirectionUpdated(newHeading)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: LKLocationManager) -> Bool {
        return true
    }
}
