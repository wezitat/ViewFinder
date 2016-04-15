//
//  Scene3DViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/15/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation

enum AppStatus {
    case GettingLocation
    case GettingHeading
    case ShowingScene
    case Unknown
}

protocol WrapperSceneDelegate {
    func getAppStatus() -> AppStatus
    func getCalibratedHeading() -> CLLocationDirection
    func isHeadingStable() -> Bool
    func setStable(stable: Bool)
    func startWrapperHeadingDataGatheringTimer()
    func stopWrapperHeadingDataGatheringTimer()
    func setWrapperCalibratedHeading(heading: CLLocationDirection)
    func retrieveWrapperInitialHeading()
    func getWitMarkers() -> [WitMarker]
    func setDetailsHeaderText(string: String)
    func setDetailsDescriptionText(string: String)
    func setDetailsViewHidden(bool: Bool)
    func witMarkersAppend(marker: WitMarker)
    func markerViewAddSubview(view: UIView)
    func setWrapperWitMarkers(wits: [WitMarker])
    func updateWrapperPointIfObjectIsBehind(point: Point3D) -> Point3D
}

class Scene3DViewController: UIViewController, WrapperSceneDelegate, CLLocationManagerDelegate {
    
    var customLocation: CLLocation = CLLocation()
    
    var appStatus: AppStatus = .Unknown
    
    let DEFAULT_CALIBRATING_TIME = 5
    
    //array of wit markers
    var witMarkers: [WitMarker] = [WitMarker]()
    
    //heading calibration
    var calibrationTime: Int = 5
    var calibrateTimer: NSTimer! = nil
    var isStable: Bool = false
    var calibratedHeading: CLLocationDirection = CLLocationDirection()
    
    var markerPos: Int = 120
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance
    
//    @IBOutlet weak var refreshSceneButton: UIButton!
//    @IBOutlet weak var debugView: UIView!
    @IBOutlet weak var markerView: WitMarkersView!
//    @IBOutlet weak var detailsView: UIView!
    
    //details view
    var smallDetailsView: UIView! = nil
    var detailsHeader: UILabel! = nil
    var detailsDescription: UILabel! = nil
    
    //    var viewFinderManager = ViewFinderManager.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        refreshSceneButton.enabled = false
        
        //load settings
        SettingsManager.sharedInstance.loadSettings()
        
        ViewFinderManager.sharedInstance.setGameViewController(self.childViewControllers.first! as! Rendering3DViewController)
        ViewFinderManager.sharedInstance.setGameViewControllerDelegate(ViewFinderManager.sharedInstance)
        
        ViewFinderManager.sharedInstance.centerPoint = customLocation
        ViewFinderManager.sharedInstance.userLocation = customLocation
        
        initDebugViewLayer()
        initDetailsView()
        
        //start location manager
        ViewFinderManager.sharedInstance.startLocationManager()
        
        ViewFinderManager.sharedInstance.locationManager.manager.delegate = self
        
        ViewFinderManager.sharedInstance.locationManager.startLocationUpdating()
        ViewFinderManager.sharedInstance.locationManager.startHeadingUpdating()
        
        ViewFinderManager.sharedInstance.setLocationManagerDeviceCalibrateDelegate(ViewFinderManager.sharedInstance)
        ViewFinderManager.sharedInstance.setLocationManagerInfoLocationDelegate(ViewFinderManager.sharedInstance)
        ViewFinderManager.sharedInstance.setMotionManagerRotationManagerDelegate(ViewFinderManager.sharedInstance)
        
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(orientationChanged),
                                                         name: UIDeviceOrientationDidChangeNotification,
                                                         object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ViewFinderManager.sharedInstance.setTopViewController(self)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        
        if parent == nil {
            ViewFinderManager.sharedInstance.resetManager()
        }
    }
    
    func refreshStage() {
        //reset whole information in app
//        self.refreshSceneButton.enabled = false
        //self.sceneController.resetScene()
        
        ViewFinderManager.sharedInstance.getGameViewController()!.resetMotionScene()
        
        for marker in witMarkers {
            marker.view.removeFromSuperview()
        }
        
        witMarkers = [WitMarker]()
        
        ViewFinderManager.sharedInstance.setLocationManagerDelegate(nil)
        
        ViewFinderManager.sharedInstance.getLocationManager().stopUpdates()
        ViewFinderManager.sharedInstance.getLocationManager().startUpdates()
        
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
    }
    
    func initDebugViewLayer() {
        //if user rotates the screen we should update positions of debug infos
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        switch (orientation)
        {
        case .Portrait:
            debugInfo.initDebugViewPortraitOriented()
            break;
        case .LandscapeLeft:
            debugInfo.initDebugViewLandscapeOriented()
            break;
        case .LandscapeRight:
            debugInfo.initDebugViewLandscapeOriented()
            break;
        default:
            debugInfo.initDebugViewPortraitOriented()
            break;
        }
        
//        self.debugView.addSubview(debugInfo.debugInfoView)
    }
    
    func initDetailsView() {
        //manually create debug infos on screen
        let screenCenterX: CGFloat = UIScreen.mainScreen().bounds.width/2
        let screenCenterY: CGFloat = UIScreen.mainScreen().bounds.height/2
        
        smallDetailsView = UIView(frame: CGRectMake(screenCenterX - 100, screenCenterY - 100, 200, 200))
        smallDetailsView.backgroundColor = UIColor.whiteColor()
        
        detailsHeader = UILabel(frame: CGRectMake(5, 5, 190, 35))
        detailsHeader.font = UIFont.systemFontOfSize(22)
        detailsHeader.textAlignment = .Center
        
        smallDetailsView.addSubview(detailsHeader)
        
        detailsDescription = UILabel(frame: CGRectMake(0, 35, 190, 155))
        detailsDescription.font = UIFont.systemFontOfSize(15)
        detailsDescription.numberOfLines = 99
        detailsDescription.textAlignment = .Center
        
        smallDetailsView.addSubview(detailsDescription)
        
//        let button: UIButton = UIButton(frame: CGRectMake(0, 0, self.detailsView.frame.width, self.detailsView.frame.height))
//        
//        button.addTarget(self, action: #selector(handleDetailsButton), forControlEvents: .TouchUpInside)
//        
//        self.detailsView.addSubview(smallDetailsView)
//        self.detailsView.addSubview(button)
//        
//        self.detailsView.bringSubviewToFront(button)
//        self.detailsView.hidden = true
    }
    
    func retrieveInitialLocation() {
        debugInfo.retrievingLocationStatus("Retrieving location...")
        self.appStatus = .GettingLocation
    }
    
    func retrieveInitialHeading() {
        //start calibrating heding of device
        debugInfo.singleStatus("Don`t shake device")
        self.appStatus = .GettingHeading
    }
    
    func startHeadingDataGatheringTimer() {
        //start timer to count statble time of device
        calibrationTime = DEFAULT_CALIBRATING_TIME
        
        calibrateTimer?.invalidate()
        calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                target: self,
                                                                selector: #selector(timeUpdate),
                                                                userInfo: nil,
                                                                repeats: true)
    }
    
    func stopHeadingDataGatheringTimer() {
        //invalidating timer
        
        calibrateTimer?.invalidate()
    }
    
    func timeUpdate() {
        //one seconds passed. check if we can stop calibration
        if calibrationTime > 0 {
            let currentText: String = "Calibrating data. Don`t shake Device for"
            
            debugInfo.singleStatus(currentText + " \(self.calibrationTime) seconds")
            calibrationTime -= 1
        } else {
            stopHeadingDataGatheringTimer()
            
            //if device was stable for some amount of time - we can end calibration
            endCalibration()
        }
    }
    
    /** Function to prepare everything before building scene
     */
    func endCalibration() {
        if appStatus == .GettingHeading {
            appStatus = .ShowingScene
            initializeScene()
        }
    }
    
    /** Function to start builing scene based on gathered data
     */
    func initializeScene() {
        
        if ViewFinderManager.sharedInstance.getGameViewController() != nil {
            
//            self.refreshSceneButton.enabled = true
            
            debugInfo.fullInfo()
            
            ViewFinderManager.sharedInstance.setLocationManagerDelegate(ViewFinderManager.sharedInstance)
            ViewFinderManager.sharedInstance.getGameViewController()!.initialize3DSceneMotionWithHeading(calibratedHeading)
        }
    }
    
    ////////WitMarkers
    
    func handleDetailsButton() {
        //show details about wit
//        detailsView.hidden = true
    }
    
    func updatePointIfObjectIsBehind(point: Point3D) -> Point3D {
        //find screen quarter
        let newPoint: Point3D = Point3D(xPos: 0, yPos: 0, zPos: 0)
        
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let screenWidth:  Double = Double(UIScreen.mainScreen().bounds.width)
        
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        if orientation == .Portrait || orientation == .PortraitUpsideDown {
            if point.x > screenWidth/2 {
                point.x = 0
            } else {
                point.x = screenWidth - Double(WIT_MARKER_SIZE)
            }
            newPoint.y = screenHeight/2
        }
        
        if orientation == .LandscapeLeft || orientation == .LandscapeRight {
            if point.y > screenHeight/2 {
                point.y = 0
            } else {
                point.y = screenHeight - Double(WIT_MARKER_SIZE)
            }
            
            newPoint.x = screenWidth/2
        }
        
        return newPoint
    }
    
    //// Show info on top and bottom labels
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    func orientationChanged(notification: NSNotification) {
        
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        switch (orientation) {
        case .Portrait:
            reorientPortrait()
            break;
        case .LandscapeLeft:
            reorientLandscape()
            break;
        case .LandscapeRight:
            reorientLandscape()
            break;
        default:
            reorientPortrait()
            break;
        }
    }
    
    func reorientPortrait() {
        debugInfo.reorientPortrait()
        
        smallDetailsView?.transform = CGAffineTransformMakeRotation(0)
    }
    
    func reorientLandscape() {
        debugInfo.reorientLanscape()
        
        smallDetailsView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
    }
    
    @IBAction func handleDebugButton(sender: UIButton) {
//        debugView.hidden = !debugView.hidden
//        refreshSceneButton.hidden = !refreshSceneButton.hidden
//        
//        if debugView.hidden {
//            sender.backgroundColor = UIColor.darkGrayColor()
//        } else {
//            sender.backgroundColor = UIColor.redColor()
//        }
    }
    
    @IBAction func handleRefreshButton(sender: UIButton) {
        self.refreshStage()
    }
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //MARK: - WrapperSceneDelegate
    
    func getAppStatus() -> AppStatus {
        return appStatus
    }
    
    func getCalibratedHeading() -> CLLocationDirection {
        return calibratedHeading
    }
    
    func isHeadingStable() -> Bool {
        return isStable
    }
    
    func setStable(stable: Bool) {
        isStable = stable
    }
    
    func startWrapperHeadingDataGatheringTimer() {
        startHeadingDataGatheringTimer()
    }
    
    func stopWrapperHeadingDataGatheringTimer() {
        stopHeadingDataGatheringTimer()
    }
    
    func setWrapperCalibratedHeading(heading: CLLocationDirection) {
        calibratedHeading = heading
    }
    
    func retrieveWrapperInitialHeading() {
        retrieveInitialHeading()
    }
    
    func getWitMarkers() -> [WitMarker] {
        return witMarkers
    }
    
    func setDetailsHeaderText(string: String) {
        detailsHeader.text = string
    }
    
    func setDetailsDescriptionText(string: String) {
        detailsDescription.text = string
    }
    
    func setDetailsViewHidden(bool: Bool) {
//        detailsView.hidden = bool
    }
    
    func witMarkersAppend(marker: WitMarker) {
        witMarkers.append(marker)
    }
    
    func markerViewAddSubview(view: UIView) {
        markerView?.addSubview(view)
    }
    
    func setWrapperWitMarkers(wits: [WitMarker]) {
        witMarkers = wits
    }
    
    func updateWrapperPointIfObjectIsBehind(point: Point3D) -> Point3D {
        return updatePointIfObjectIsBehind(point)
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        ViewFinderManager.sharedInstance.locationManager.timePassed = 0
        
        if ViewFinderManager.sharedInstance.locationManager.timerAfterUpdate != nil {
            ViewFinderManager.sharedInstance.locationManager.timerAfterUpdate.invalidate()
        }
        
        ViewFinderManager.sharedInstance.locationManager.timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(timeUpdate),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
//        <+49.84045208,+24.03292691> +/- 65.00m (speed -1.00 mps / course -1.00) @ 4/15/16, 7:20:52 PM Eastern European Summer Time
//<+49.84047534,+24.03296899> +/- 65.00m (speed -1.00 mps / course -1.00) @ 1/1/01, 2:00:00 AM Eastern European Standard Time
        
        let newLocation: CLLocation = customLocation
        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        
        if locationAge > 10.0 {
            return
        }
        
        if newLocation.verticalAccuracy > 0 {
            
            ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate?.altitudeUpdated(newLocation.altitude)
            
            ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.altitudeUpdated(Int(newLocation.altitude))
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.accuracyUpdated(Int(newLocation.horizontalAccuracy))
        
        if ViewFinderManager.sharedInstance.locationManager.previousLocation == nil {
            if newLocation.horizontalAccuracy <= ViewFinderManager.sharedInstance.locationManager.LOCATION_ACCURACCY && ViewFinderManager.sharedInstance.locationManager.deviceCalibrateDelegate != nil{
                ViewFinderManager.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                
                if newLocation.verticalAccuracy > 0 {
                    ViewFinderManager.sharedInstance.centerAltitude = newLocation.altitude
                    ViewFinderManager.sharedInstance.locationManager.deviceCalibrateDelegate.initLocationReceived()
                    ViewFinderManager.sharedInstance.locationManager.previousLocation = newLocation
                }
                
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(ViewFinderManager.sharedInstance.locationManager.previousLocation)))")
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
            }
        }
        else {
            if newLocation.horizontalAccuracy <= ViewFinderManager.sharedInstance.locationManager.LOCATION_ACCURACCY {
                if ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate != nil {
                    ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate.locationUpdated(newLocation)
                    ViewFinderManager.sharedInstance.userLocation = newLocation
                }
                
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(ViewFinderManager.sharedInstance.locationManager.previousLocation)))")
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
                
                ViewFinderManager.sharedInstance.locationManager.previousLocation = newLocation
            }
            else {
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("ignoring")
                ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("ignoring")
            }
        }

        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        print("heading = \((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)")
        
        ViewFinderManager.sharedInstance.locationManager.deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
}