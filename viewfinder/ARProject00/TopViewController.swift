//
//  TopViewController.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/6/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/** TopViewController - is a class which represent upper layer of app.
    It shows all the statuses and WitMarkers. Can be used to
    represent additional GUI */
class TopViewController: UIViewController, SceneEventsDelegate, DeviceCalibrateDelegate, RotationManagerDelegate, WitMarkerDelegate {
  
    enum AppStatus {
        case GettingLocation
        case GettingHeading
        case ShowingScene
        case Unknown
    }
    
    var appStatus: AppStatus = .Unknown
    
    let DEFAULT_CALIBRATING_TIME = 5
    var sceneController: GameViewController! = nil
    
    //array of wit markers
    var witMarkers: [WitMarker] = [WitMarker]()
    
    //heading calibration
    var calibrationTime: Int = 5
    var calibrateTimer: NSTimer! = nil
    var isStable: Bool = false
    var calibratedHeading: CLLocationDirection = CLLocationDirection()
    
    var markerPos: Int = 120
    
    var debugInfo: DebugInfoClass = DebugInfoClass()
    
    @IBOutlet weak var debugView: UIView!
    @IBOutlet weak var markerView: WitMarkersView!
    @IBOutlet weak var detailsView: UIView!
    
    //details view 
    var smallDetailsView: UIView! = nil
    var detailsHeader: UILabel! = nil
    var detailsDescription: UILabel! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //load settings
        SettingManager.sharedInstance.loadSettings()
        
        sceneController = self.childViewControllers.first! as! GameViewController
        sceneController.eventDelegate = self
        initDebugViewLayer()
        initDetailsView()
        //start location manager
        ViewFinderManager.sharedInstance.startLocationManager()
        ViewFinderManager.sharedInstance.locationManager.calibrateHeadingDelegate = self
        ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate = debugInfo
        ViewFinderManager.sharedInstance.motionManager.rotationDelegate = self
       
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("orientationChanged:"), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    func initDebugViewLayer() {
        var orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
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
        self.debugView.addSubview(debugInfo.debugInfoView)
    }
    
    func initDetailsView() {
        var screenCenterX: CGFloat = UIScreen.mainScreen().bounds.width/2
        var screenCenterY: CGFloat = UIScreen.mainScreen().bounds.height/2
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
        
        var button: UIButton = UIButton(frame: CGRectMake(0, 0, self.detailsView.frame.width, self.detailsView.frame.height))
        button.addTarget(self, action: Selector("handleDetailsButton"), forControlEvents: .TouchUpInside)
        
        self.detailsView.addSubview(smallDetailsView)
        self.detailsView.addSubview(button)
        self.detailsView.bringSubviewToFront(button)
        self.detailsView.hidden = true
        
    }

    func retrieveInitialLocation() {
        debugInfo.retrievingLocationStatus("Retrieving location...")
        self.appStatus = .GettingLocation
    }
    
    func initLocationReceived() {
        //we received our location
        if appStatus == .GettingLocation {
           self.retrieveInitialHeading()
        }
    }
    
    func retrieveInitialHeading() {
        //start calibrating heding of device
        debugInfo.singleStatus("Don`t shake device")
        self.appStatus = .GettingHeading
    }
    
    func headingUpdated(heading: CLLocationDirection) {
        //if we are in proper status - try to get accurate heading
        if appStatus == .GettingHeading {
            if abs(calibratedHeading - heading) < 5 {
                //device become stable start timer
                if !isStable {
                    isStable = true
                    startHeadingDataGatheringTimer()
                }
            }
            else {
                isStable = false
                //device is not stable. stop timer
                stopHeadingDataGatheringTimer()
                debugInfo.singleStatus("Don`t shake device")
            }
            calibratedHeading = heading
        }
        
    }
    
    func startHeadingDataGatheringTimer() {
        //start timer to count statble time of device
        calibrationTime = DEFAULT_CALIBRATING_TIME
        if calibrateTimer == nil {
           calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeUpdate"), userInfo: nil, repeats: true)
        }
        else {
           calibrateTimer.invalidate()
           calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeUpdate"), userInfo: nil, repeats: true)
        }
        
    }
    
    func stopHeadingDataGatheringTimer() {
        //invalidating timer
        if calibrateTimer != nil {
           calibrateTimer.invalidate()
        }
    }
    
    func timeUpdate() {
        //one seconds passed. check if we can stop calibration
        if calibrationTime > 0 {
            var currentText: String = "Calibrating data. Don`t shake Device for"
            debugInfo.singleStatus(currentText + " \(self.calibrationTime) seconds")
            calibrationTime--
        }
        else {
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
        debugInfo.fullInfo()
        ViewFinderManager.sharedInstance.locationManager.delegate = sceneController
        sceneController.initialize3DSceneWithHeading(calibratedHeading)
    }
    
////////WitMarkers
    
    func handleDetailsButton() {
        //show details about wit
        detailsView.hidden = true
    }
    
    func showObjectDetails(wObject: WitObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.detailsHeader.text = wObject.witName
            
            var claimed: String = "NO"
            if wObject.isClaimed {
                claimed = "YES"
            }
            
            self.detailsDescription.text = "\(wObject.witDescription)\n\nBy: \(wObject.author) Claimed: \(claimed)"
        }
        detailsView.hidden = false
    }
    
    func addNewWitMarker(wObject: WitObject) {
        // add new witmarker on screen
        var marker: WitMarker = WitMarker()
        marker.registerObject(wObject)
        marker.delegate = self
        self.witMarkers.append(marker)
        self.markerView.addSubview(marker.view)
    }
    
    func rotationAngleUpdated(angle: Double) {
        //device has moved - update witMarker position
        for marker in self.witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.label.transform = CGAffineTransformMakeRotation(CGFloat(angle))
            }
        }
    }
    
    func locationUpdated(location: CLLocation) {
        for marker in self.witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.updateDistance(location)
            }
        }
        filterWitMarkers()
    }
    
    func cameraMoved() {
        var screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        var screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)

        for marker in self.witMarkers {

            if sceneController.isNodeOnScreen(marker.wObject.objectGeometry) {
                marker.showMarker(false)
            }
            else {
                marker.showMarker(true)
            }
            var point: Point2D = sceneController.nodePosToScreenCoordinates(marker.wObject.objectGeometry)
            
            point.x -= 30
            point.y -= 30
            
            if  point.x < 0 {
                point.x = 0
            }
            
            if point.y < 0 {
                point.y = 0
            }
            
            if point.x > screenWidth - 60 {
                point.x = Double(screenWidth) - 60
            }
            
            if point.y > screenHeight - 60 {
                point.y = screenHeight - 60
            }
            
            //check if element is behind - if yes our point will be inside the screen
            if (point.x > 0 && point.x < screenWidth - 60 && point.y > 0 && point.y < screenHeight - 60) {
                point = updatePointIfObjectIsBehind(point)
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                marker.view.frame = CGRectMake(CGFloat(point.x), CGFloat(point.y), 60, 60)
            }
        }
    }
    
    func updatePointIfObjectIsBehind(point: Point2D) -> Point2D {
        //find screen quarter
        var newPoint: Point2D = Point2D()
        var screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        var screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        
        var orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        if orientation == .Portrait || orientation == .PortraitUpsideDown {
            if point.x > screenWidth/2 {
                point.x = 0
            }
            else {
                point.x = screenWidth - 60
            }
            newPoint.y = point.y
        }
        if orientation == .LandscapeLeft || orientation == .LandscapeRight {
            if point.y > screenHeight/2 {
                point.y = 0
            }
            else {
                point.y = screenHeight - 60
            }
            newPoint.x = point.x
        }
        
        

        return newPoint
    }
    
    func filterWitMarkers() {
        var maxNumber = SettingManager.sharedInstance.getWitMarkerNumberValue()
        witMarkers.sort({ $0.currentDistance < $1.currentDistance })
        
        var i = 0
        for marker in witMarkers {
            if i < maxNumber {
                marker.isShowMarker = true
            }
            else {
                marker.isShowMarker = false
            }
            i++
        }

    }
    
    
//// Show info on top and bottom labels    
    func showTopInfo(strign: String) {
        /*dispatch_async(dispatch_get_main_queue(), {
            self.topInfoLabel.text = strign
        })*/
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }

    func orientationChanged(notification: NSNotification) {
        
        var orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        switch (orientation)
        {
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
        if smallDetailsView != nil {
           smallDetailsView.transform = CGAffineTransformMakeRotation(0)
        }

    }
    
    func reorientLandscape() {
        debugInfo.reorientLanscape()
        if smallDetailsView != nil {
            smallDetailsView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        }
    }

    @IBAction func handleDebugButton(sender: UIButton) {
        debugView.hidden = !debugView.hidden
        
        if debugView.hidden {
            sender.backgroundColor = UIColor.darkGrayColor()
        }
        else {
            sender.backgroundColor = UIColor.redColor()
        }
    }
    
}