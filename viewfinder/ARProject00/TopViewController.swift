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
    
    var screenHeight = UIScreen.mainScreen().bounds.height
    var screenWidth = UIScreen.mainScreen().bounds.width
    
    
    @IBOutlet weak var markerView: UIView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var topInfoLabel: UILabel!
    
    //info screen
    @IBOutlet weak var detailsButton: UIButton!
    @IBOutlet weak var detailsText: UITextView!
    @IBOutlet weak var detailsHeader: UILabel!
    @IBOutlet weak var detailsView: UIView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        infoLabel.text = ""
        sceneController = self.childViewControllers.first! as! GameViewController
        sceneController.eventDelegate = self
        
        //start location manager
        ViewFinderManager.sharedInstance.startLocationManager()
        ViewFinderManager.sharedInstance.locationManager.calibrateHeadingDelegate = self
        ViewFinderManager.sharedInstance.motionManager.rotationDelegate = self
        detailsText.text = ""
        detailsHeader.text = ""
        
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
    }
    
    func retrieveInitialLocation() {
        self.topInfoLabel.text = "Retrieving location..."
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
        self.topInfoLabel.text = "Don`t shake device..."
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
                dispatch_async(dispatch_get_main_queue(), {
                    self.topInfoLabel.text = "Don`t shake Device"
                })
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
            dispatch_async(dispatch_get_main_queue(), {
                var currentText: String = "Calibrating data. Don`t shake Device for"
                self.topInfoLabel.text = currentText + " \(self.calibrationTime) seconds"
            })
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
        dispatch_async(dispatch_get_main_queue(), {
            self.topInfoLabel.text = "Showing scene"
        })
        ViewFinderManager.sharedInstance.locationManager.delegate = sceneController
        sceneController.initialize3DSceneWithHeading(calibratedHeading)
    }
    
////////WitMarkers
    
    @IBAction func handleDetailsButton(sender: UIButton) {
        //show details about wit
        detailsView.hidden = true
    }
    
    func showObjectDetails(wObject: WitObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.detailsHeader.text = wObject.witName
            self.detailsText.text = wObject.witDescription
        }
        detailsView.hidden = false
    }
    
    func addNewWitMarker(wObject: WitObject) {
        // add new witmarker on screen
        var marker: WitMarker = WitMarker()
        marker.registerObject(wObject)
        marker.delegate = self
        self.witMarkers.append(marker)
        
        marker.view.frame = CGRectMake(CGFloat(30), CGFloat(markerPos), marker.view.frame.size.width, marker.view.frame.size.height)
        markerPos += 70
        self.markerView.addSubview(marker.view)
    }
    
    func rotationAngleUpdated(angle: Double) {
        //device has moved - update witMarker position
        for marker in self.witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.view.transform = CGAffineTransformMakeRotation(CGFloat(angle))
            }
        }
        self.alignMarkersOnScreen(angle)
    }
    
    func cameraMoved() {
        for marker in self.witMarkers {
            if sceneController.isNodeOnScreen(marker.wObject.objectGeometry) {
                marker.view.hidden = true
            }
            else {
                marker.view.hidden = false
            }
            
            /*
            var isLeft: Bool = sceneController.sideOfNodeFromCamera(marker.wObject.objectGeometry)
            
            if isLeft {
                marker.view.frame = CGRectMake(screenWidth - CGFloat(60), CGFloat(markerPos), marker.view.frame.size.width, marker.view.frame.size.height)
            }
            else {
                marker.view.frame = CGRectMake(CGFloat(30), CGFloat(markerPos), marker.view.frame.size.width, marker.view.frame.size.height)
            }*/
        }
    }
    
    func alignMarkersOnScreen(angle: Double) {
        /*
        var degree: Double = Utils.RadiansToDegrees(angle)
        
        dispatch_async(dispatch_get_main_queue()) {
            var absValue: Int = Int(abs(degree))
            println("degree: \(absValue)")
            var newX: Int = 0
            var newY: Int = 0
            
            if UIDevice.currentDevice().orientation == .Portrait || UIDevice.currentDevice().orientation == .PortraitUpsideDown {
                newX = 20
                newY = Int(self.screenHeightCenter)
            }
            else if UIDevice.currentDevice().orientation == .LandscapeLeft || UIDevice.currentDevice().orientation == .LandscapeRight{
                newX = 20
                newY = Int(self.screenWidthCenter)
            }
            
            for marker in self.witMarkers {
                var rect: CGRect = marker.view.frame
                marker.view.frame = CGRectMake(CGFloat(newX), CGFloat(newY), rect.width, rect.height)
            }
        }*/
    }
    
    
//// Show info on top and bottom labels
    func showInfo(string: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.infoLabel.text = string
        })
    }
    
    func showTopInfo(strign: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.topInfoLabel.text = strign
        })
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

}