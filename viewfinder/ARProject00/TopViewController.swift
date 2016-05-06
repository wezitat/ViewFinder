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
    It shows all the statuses and WitMarkers. Can be used to represent additional GUI */

class TopViewController: ScreenBaseViewController, UIProtocol {
    
    @IBOutlet weak var refreshSceneButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshSceneButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Brain.sharedInstance.setTopViewController(self)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        
        if parent == nil {
            Brain.sharedInstance.resetManager()
        }
    }
    
    override func refreshStage() {
        //reset whole information in app
        self.refreshSceneButton.enabled = false
        //self.sceneController.resetScene()
        
        super.refreshStage()
    }
    
    override func initializeScene() {
        super.initializeScene()
        
        if Brain.sharedInstance.getGameViewController() != nil {
            refreshSceneButton.enabled = true
        }
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
    
    //MARK: - UIProtocol
    
    func applicationLaunched() {
        
    }
    
    func locationUpdated(newLocation: CLLocation) {
        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        
        if locationAge > 10.0 {
            return
        }
        
        if newLocation.verticalAccuracy > 0 {
            
            Brain.sharedInstance.locationManager.locationManagerDelegate?.locationDelegateAltitudeUpdated(newLocation.altitude) // rendering
            Brain.sharedInstance.locationManager.infoLocationDelegate?.altitudeUpdated(Int(newLocation.altitude))
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        Brain.sharedInstance.locationManager.infoLocationDelegate?.accuracyUpdated(Int(newLocation.horizontalAccuracy))
        
        if Brain.sharedInstance.locationManager.previousLocation == nil {
            if newLocation.horizontalAccuracy <= Brain.sharedInstance.locationManager.LOCATION_ACCURACCY && Brain.sharedInstance.locationManager.deviceCalibrateDelegate != nil{
                Brain.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                
                if newLocation.verticalAccuracy > 0 {
                    Brain.sharedInstance.centerAltitude = newLocation.altitude
                    Brain.sharedInstance.locationManager.deviceCalibrateDelegate.initLocationReceived() // rendering
                    Brain.sharedInstance.locationManager.previousLocation = newLocation
                }
                
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(Brain.sharedInstance.locationManager.previousLocation)))")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
            }
        }
        else {
            if newLocation.horizontalAccuracy <= Brain.sharedInstance.locationManager.LOCATION_ACCURACCY {
                if Brain.sharedInstance.locationManager.locationManagerDelegate != nil {
                    Brain.sharedInstance.locationManager.locationManagerDelegate.locationDelegateLocationUpdated(newLocation) // rendering
                    Brain.sharedInstance.userLocation = newLocation
                }
                
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(Brain.sharedInstance.locationManager.previousLocation)))")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
                
                Brain.sharedInstance.locationManager.previousLocation = newLocation
            } else {
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("ignoring")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("ignoring")
            }
        }
    }
    
    func headingDirectionUpdated(newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        print("heading = \((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)")
        
        Brain.sharedInstance.locationManager.deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
}