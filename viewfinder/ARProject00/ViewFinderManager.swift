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
    
    var gameViewController: GameViewController? = nil
    
    var  topViewController: TopViewController? = nil
    
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
        
        ViewFinderManager.sharedInstance.topViewController = nil
        
        ViewFinderManager.sharedInstance.gameViewController!.eventDelegate = nil
        ViewFinderManager.sharedInstance.gameViewController = nil
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
        
        gameViewController?.cameraNode.position = SCNVector3Make(gameViewController!.cameraNode.position.x,
                                                                gameViewController!.cameraNode.position.y,
                                                                Float(altitude * DEFAULT_METR_SCALE))
        SCNTransaction.commit()
    }
    
    func locationUpdated(location: CLLocation) {
        //user location updated. move camera on new position in 3d scene
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        let point: Point2D = LocationMath.sharedInstance.convertLLtoXY(ViewFinderManager.sharedInstance.centerPoint, newLocation: location)
        
        gameViewController!.cameraNode.position = SCNVector3Make(Float(point.x), Float(point.y), gameViewController!.cameraNode.position.z)
        
        for object in gameViewController!.showingObject {
            object.updateWitObjectSize(location)
        }
        
        SCNTransaction.commit()
        
//        gameViewController!.eventDelegate?.locationUpdated(location)
    }

    //MARK: - MotionManagerDelegate
    
    func rotationChanged(orientation: SCNQuaternion) {
        //user moved camera and pointing of camera changed
        gameViewController!.cameraNode.orientation = orientation
        gameViewController!.eventDelegate?.cameraMoved()
    }
    
    func drasticDeviceMove() {
        
    }
    
    //MARK: - DeviceCalibrateDelegate
    
    func headingUpdated(heading: CLLocationDirection) {
        //if we are in proper status - try to get accurate heading
        if topViewController!.appStatus == .GettingHeading {
            if abs(topViewController!.calibratedHeading - heading) < 5 {
                //device become stable start timer
                if !topViewController!.isStable {
                    topViewController!.isStable = true
                    topViewController!.startHeadingDataGatheringTimer()
                }
            } else {
                topViewController!.isStable = false
                
                //device is not stable. stop timer
                topViewController!.stopHeadingDataGatheringTimer()
                debugInfo.singleStatus("Don`t shake device")
            }
            
            topViewController!.calibratedHeading = heading
        }
        
        debugInfo.angleUpdated(CGFloat(heading))
    }
    
    func initLocationReceived() {
        //we received our location
        if topViewController!.appStatus == .GettingLocation {
            topViewController!.retrieveInitialHeading()
        }
    }
    
    //MARK: - RotationManagerDelegate
    
    func rotationAngleUpdated(angle: Double) {
        //device has moved - update witMarker position
        for marker in topViewController!.witMarkers {
            marker.updateAngle(angle)
        }
    }
    
    //MARK: - SceneEventsDelegate (and WitMarkerDelegate for the 1st method)
    
    func showObjectDetails(wObject: WitObject) {
        dispatch_async(dispatch_get_main_queue()) {
            ViewFinderManager.sharedInstance.topViewController!.detailsHeader.text = wObject.witName
            
            var claimed: String = "NO"
            
            if wObject.isClaimed {
                claimed = "YES"
            }
            
            ViewFinderManager.sharedInstance.topViewController!.detailsDescription.text = "\(wObject.witDescription)\n\nBy: \(wObject.author) Claimed: \(claimed)"
        }
        
        topViewController!.detailsView.hidden = false
    }
    
    func showTopInfo(string: String) {
        
    }
    
    func addNewWitMarker(wObject: WitObject) {
        // add new witmarker on screen
        let marker: WitMarker = WitMarker()
        
        marker.registerObject(wObject)
        marker.delegate = ViewFinderManager.sharedInstance
        
        topViewController!.witMarkers.append(marker)
        topViewController!.markerView.addSubview(marker.view)
    }
    
    func filterWitMarkers() {
        //check if we have number limitation of witmarkers
        
        let maxNumber = SettingsManager.sharedInstance.getWitMarkerNumberValue()
        
        topViewController!.witMarkers.sortInPlace({ $0.currentDistance < $1.currentDistance })
        
        for i in 0..<topViewController!.witMarkers.count {
            let marker = topViewController!.witMarkers[i]
            
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
        
        for marker in topViewController!.witMarkers {
            
            if gameViewController!.isNodeOnScreen(marker.wObject.objectGeometry) {
                marker.showMarker(false)
            } else {
                marker.showMarker(true)
            }
            
            var point: Point3D = gameViewController!.nodePosToScreenCoordinates(marker.wObject.objectGeometry)
            
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
                point = topViewController!.updatePointIfObjectIsBehind(point)
                //originalPoint = Point2D(xPos: point.x, yPos: point.y)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                marker.view.frame = CGRectMake(CGFloat(point.x), CGFloat(point.y), WIT_MARKER_SIZE, WIT_MARKER_SIZE)
                marker.updatePointerAngle(0)
            }
        }
    }
    
    func distanceUpdated(location: CLLocation) {
        for marker in topViewController!.witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.updateDistance(location)
            }
        }
        
        filterWitMarkers()
    }

    //MARK: - Methods, setting Delegates
    
    func setGameViewController(gameVC: GameViewController!) {
        gameViewController = gameVC
    }
    
    func setTopViewController(topVC: TopViewController!) {
        topViewController = topVC
    }
    
    func setGameViewControllerDelegate(delegate: SceneEventsDelegate) {
        gameViewController?.eventDelegate = delegate
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
    
    func getGameViewController() -> GameViewController? {
        return gameViewController
    }
    
    func getTopViewController() -> TopViewController? {
        return topViewController
    }
    
    func getLocationManager() -> LocationManager {
        return locationManager
    }
}
