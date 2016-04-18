//
//  ViewFinderManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

private let _ViewFinderManager = ViewFinderManager()

class ViewFinderManager: InfoLocationDelegate, LocationManagerDelegate, MotionManagerDelegate, RotationManagerDelegate, DeviceCalibrateDelegate, SceneEventsDelegate, WitMarkerDelegate {
    static let sharedInstance = ViewFinderManager()
    
    var feetSystem: Bool = false
    
    var   motionManager: MotionManager   = MotionManager()
    var locationManager: LocationManager = LocationManager()
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance
    
//    var gameViewController: GameViewController? = nil
//    var  topViewController: TopViewController? = nil
    
    var wrapperSceneDelegate: WrapperSceneDelegate? = nil
    var renderingSceneDelegate: RenderingSceneDelegate? = nil
    
//    var scene3DViewController: Scene3DViewController? = nil
//    var rendering3DViewController: Rendering3DViewController? = nil
    
    //initial location of user (based on this LL point 3D scene is builing)
    var  centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var centerAltitude: CLLocationDistance = CLLocationDistance()
    
    func startMotionManager() {
         motionManager.initMotionManger()
    }
    
    func startLocationManager() {
        locationManager.initLocatioManager()
    }
    
    func resetManager() {
        motionManager.pause()
        locationManager.stopUpdates()
        
        ViewFinderManager.sharedInstance.motionManager.rotationManagerDelegate = nil
        ViewFinderManager.sharedInstance.motionManager.motionManagerDelegate = nil
        
        ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate = nil
        ViewFinderManager.sharedInstance.locationManager.deviceCalibrateDelegate = nil
        ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate = nil
        
        ViewFinderManager.sharedInstance.wrapperSceneDelegate = nil
        
        ViewFinderManager.sharedInstance.renderingSceneDelegate!.setEventDelegate(nil)
        ViewFinderManager.sharedInstance.renderingSceneDelegate = nil
        
//        scene3DViewController = nil
//        rendering3DViewController = nil
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
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        renderingSceneDelegate?.setCameraNodePosition(SCNVector3Make((renderingSceneDelegate?.getCameraNode().position.x)!,
                                                                (renderingSceneDelegate?.getCameraNode().position.y)!,
                                                                Float(altitude * DEFAULT_METR_SCALE)))
        SCNTransaction.commit()
    }
    
    func locationUpdated(location: CLLocation) {
        //user location updated. move camera on new position in 3d scene
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        let point: Point2D = LocationMath.sharedInstance.convertLLtoXY(ViewFinderManager.sharedInstance.centerPoint, newLocation: location)
        
        renderingSceneDelegate?.setCameraNodePosition(SCNVector3Make(Float(point.x), Float(point.y), (renderingSceneDelegate?.getCameraNode().position.z)!))
        
        let showingObject: [WitObject] = (renderingSceneDelegate?.getShowingObject())!
        
        for object in showingObject {
            object.updateWitObjectSize(location)
        }
        
        SCNTransaction.commit()
        
//        gameViewController!.eventDelegate?.locationUpdated(location)
    }

    //MARK: - MotionManagerDelegate
    
    func rotationChanged(orientation: SCNQuaternion) {
        //user moved camera and pointing of camera changed
        //gameViewController!.cameraNode.orientation = orientation
        //gameViewController!.eventDelegate?.cameraMoved()
        renderingSceneDelegate?.rotationChanged(orientation)
    }
    
    func drasticDeviceMove() {
        
    }
    
    //MARK: - DeviceCalibrateDelegate
    
    func headingUpdated(heading: CLLocationDirection) {
        //if we are in proper status - try to get accurate heading
        if wrapperSceneDelegate?.getAppStatus() == .GettingHeading {
            if abs((wrapperSceneDelegate?.getCalibratedHeading())! - heading) < 5 {
                //device become stable start timer
                if !(wrapperSceneDelegate?.isHeadingStable())! {
                    wrapperSceneDelegate?.setStable(true)
                    wrapperSceneDelegate?.startWrapperHeadingDataGatheringTimer()
                }
            } else {
                wrapperSceneDelegate?.setStable(false)
                
                //device is not stable. stop timer
                wrapperSceneDelegate?.stopWrapperHeadingDataGatheringTimer()
                debugInfo.singleStatus("Don`t shake device!")
            }
            
            wrapperSceneDelegate?.setWrapperCalibratedHeading(heading)
        }
        
        debugInfo.angleUpdated(CGFloat(heading))
    }
    
    func initLocationReceived() {
        //we received our location
        if wrapperSceneDelegate?.getAppStatus() == .GettingLocation {
            wrapperSceneDelegate?.retrieveWrapperInitialHeading()
        }
    }
    
    //MARK: - RotationManagerDelegate
    
    func rotationAngleUpdated(angle: Double) {
        //device has moved - update witMarker position
        
        let witMarkers: [WitMarker] = (wrapperSceneDelegate?.getWitMarkers())!
        
        for marker in witMarkers {
            marker.updateAngle(angle)
        }
    }
    
    //MARK: - SceneEventsDelegate (and WitMarkerDelegate for the 1st method)
    
    func showObjectDetails(wObject: WitObject) {
        dispatch_async(dispatch_get_main_queue()) {
            ViewFinderManager.sharedInstance.wrapperSceneDelegate?.setDetailsHeaderText(wObject.witName)
            
            var claimed: String = "NO"
            
            if wObject.isClaimed {
                claimed = "YES"
            }
            
            ViewFinderManager.sharedInstance.wrapperSceneDelegate?.setDetailsDescriptionText("\(wObject.witDescription)\n\nBy: \(wObject.author) Claimed: \(claimed)")
        }
        
        wrapperSceneDelegate?.setDetailsViewHidden(false)
    }
    
    func showTopInfo(string: String) {
        
    }
    
    func addNewWitMarker(wObject: WitObject) {
        // add new witmarker on screen
        let marker: WitMarker = WitMarker()
        
        marker.registerObject(wObject)
        marker.delegate = ViewFinderManager.sharedInstance
        
        wrapperSceneDelegate?.witMarkersAppend(marker)
        wrapperSceneDelegate?.markerViewAddSubview(marker.view)
    }
    
    func filterWitMarkers() {
        //check if we have number limitation of witmarkers
        
        let maxNumber = SettingsManager.sharedInstance.getWitMarkerNumberValue()
        
        wrapperSceneDelegate?.setWrapperWitMarkers((wrapperSceneDelegate?.getWitMarkers().sort({ $0.currentDistance < $1.currentDistance }))!)
        
//        topViewController!.witMarkers.sortInPlace({ $0.currentDistance < $1.currentDistance })
        
        let witMarkers: [WitMarker] = (wrapperSceneDelegate?.getWitMarkers())!
        
        for i in 0..<witMarkers.count {
            let marker = (wrapperSceneDelegate?.getWitMarkers())![i]
            
            if i < maxNumber {
                marker.isShowMarker = true
            } else {
                marker.isShowMarker = false
            }
        }
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
        let witMarkers: [WitMarker] = (wrapperSceneDelegate?.getWitMarkers())!
        
        for marker in witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.updateDistance(location)
            }
        }
        
        filterWitMarkers()
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
