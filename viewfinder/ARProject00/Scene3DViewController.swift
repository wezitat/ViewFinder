//
//  Scene3DViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/15/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation

class Scene3DViewController: WrapperBaseViewController, CLLocationManagerDelegate {
    
    var customLocation: CLLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        ViewFinderManager.sharedInstance.locationManager.timePassed = 0
        ViewFinderManager.sharedInstance.locationManager.timerAfterUpdate?.invalidate()
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