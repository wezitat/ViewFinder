//
//  TopViewController.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/6/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/** TopViewController - is a class which represent upper layer of app.
    It shows all the statuses and WitMarkers. Can be used to
    represent additional GUI */


class TopViewController: UIViewController {
  
    enum AppStatus {
        case GettingLocation
        case GettingHeading
        case ShowingScene
        case Unknown
    }
    
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
    
    @IBOutlet weak var refreshSceneButton: UIButton!
    @IBOutlet weak var debugView: UIView!
    @IBOutlet weak var markerView: WitMarkersView!
    @IBOutlet weak var detailsView: UIView!
    
    //details view 
    var smallDetailsView: UIView! = nil
    var detailsHeader: UILabel! = nil
    var detailsDescription: UILabel! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refreshSceneButton.enabled = false
        
        //load settings
        SettingsManager.sharedInstance.loadSettings()
        
        ViewFinderManager.sharedInstance.gameViewController = self.childViewControllers.first! as! GameViewController
        ViewFinderManager.sharedInstance.gameViewController.eventDelegate = ViewFinderManager.sharedInstance
        
        // do we need special interface to get access to other classes (to get access implicitly)?
        
//        ViewFinderManager.sharedInstance.setGameViewControllerDelegate(ViewFinderManager.sharedInstance)
//        ViewFinderManager.sharedInstance.setGameViewController(self.childViewControllers.first! as! GameViewController)
        
        initDebugViewLayer()
        initDetailsView()
        
        //start location manager
        ViewFinderManager.sharedInstance.startLocationManager()
        ViewFinderManager.sharedInstance.locationManager.deviceCalibrateDelegate = ViewFinderManager.sharedInstance
        ViewFinderManager.sharedInstance.locationManager.infoLocationDelegate = ViewFinderManager.sharedInstance
        ViewFinderManager.sharedInstance.motionManager.rotationManagerDelegate = ViewFinderManager.sharedInstance
       
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(orientationChanged), name: UIDeviceOrientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ViewFinderManager.sharedInstance.topViewController = self
    }
    
    func refreshStage() {
        //reset whole information in app
        self.refreshSceneButton.enabled = false
        //self.sceneController.resetScene()
        
        ViewFinderManager.sharedInstance.gameViewController.resetScene()
        
        for marker in witMarkers {
            marker.view.removeFromSuperview()
        }
        
        witMarkers = [WitMarker]()
        
        ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate = nil
        ViewFinderManager.sharedInstance.locationManager.stopUpdates()
        ViewFinderManager.sharedInstance.locationManager.startUpdates()
        
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
        
        self.debugView.addSubview(debugInfo.debugInfoView)
    }
    
    func initDetailsView() {
        //manually create create debug infos on screen
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
        
        let button: UIButton = UIButton(frame: CGRectMake(0, 0, self.detailsView.frame.width, self.detailsView.frame.height))
        
        button.addTarget(self, action: #selector(handleDetailsButton), forControlEvents: .TouchUpInside)
        
        self.detailsView.addSubview(smallDetailsView)
        self.detailsView.addSubview(button)
        
        self.detailsView.bringSubviewToFront(button)
        self.detailsView.hidden = true
        
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
        calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(timeUpdate), userInfo: nil, repeats: true)
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
        self.refreshSceneButton.enabled = true
        
        debugInfo.fullInfo()
        
        ViewFinderManager.sharedInstance.locationManager.locationManagerDelegate = ViewFinderManager.sharedInstance
        ViewFinderManager.sharedInstance.gameViewController.initialize3DSceneWithHeading(calibratedHeading)
    }
    
////////WitMarkers
    
    func handleDetailsButton() {
        //show details about wit
        detailsView.hidden = true
    }
    
    func updatePointIfObjectIsBehind(point: Point3D) -> Point3D { 
        //find screen quarter
        let newPoint: Point3D = Point3D(xPos: 0, yPos: 0, zPos: 0)
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        
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
        debugView.hidden = !debugView.hidden
        refreshSceneButton.hidden = !refreshSceneButton.hidden
        
        if debugView.hidden {
            sender.backgroundColor = UIColor.darkGrayColor()
        } else {
            sender.backgroundColor = UIColor.redColor()
        }
    }
    @IBAction func handleRefreshButton(sender: UIButton) {
        self.refreshStage()
    }
    
}