//
//  Scene3DViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/15/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation
import LocationKit

class Scene3DViewController: WrapperBaseViewController, LKLocationManagerDelegate {
    
    var customLocation: CLLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - LKLocationManagerDelegate
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        Brain.sharedInstance.locationManager.timePassed = 0
        Brain.sharedInstance.locationManager.timerAfterUpdate?.invalidate()
        Brain.sharedInstance.locationManager.timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
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
            
            Brain.sharedInstance.locationManager.locationManagerDelegate?.altitudeUpdated(newLocation.altitude)
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
                    Brain.sharedInstance.locationManager.deviceCalibrateDelegate.initLocationReceived()
                    Brain.sharedInstance.locationManager.previousLocation = newLocation
                }
                
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(Brain.sharedInstance.locationManager.previousLocation)))")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
            }
        }
        else {
            if newLocation.horizontalAccuracy <= Brain.sharedInstance.locationManager.LOCATION_ACCURACCY {
                if Brain.sharedInstance.locationManager.locationManagerDelegate != nil {
                    Brain.sharedInstance.locationManager.locationManagerDelegate.locationUpdated(newLocation)
                    Brain.sharedInstance.userLocation = newLocation
                }
                
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(Brain.sharedInstance.locationManager.previousLocation)))")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
                
                Brain.sharedInstance.locationManager.previousLocation = newLocation
            }
            else {
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationDistanceUpdated("ignoring")
                Brain.sharedInstance.locationManager.infoLocationDelegate?.locationUpdated("ignoring")
            }
        }
    }
    
    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        print("heading = \((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)")
        
        Brain.sharedInstance.locationManager.deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
}