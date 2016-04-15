//
//  DebugLocationManager.swift
//  ARProject00
//
//  Created by Ihor on 4/15/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation

class DebugLocationManager: NSObject, CLLocationManagerDelegate {

    var locationManager: CLLocationManager? = CLLocationManager()
    
    var locationTimer: NSTimer? = nil
    var headingTimer:  NSTimer? = nil
    
    var timePassedFromLastHeadingUpdate: Int = 0
    var timePassedFromLastLocationUpdate: Int = 0
    
    func setStandardProperties() {
        
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = kCLDistanceFilterNone
        
        if CLLocationManager.headingAvailable() {
            locationManager?.startUpdatingHeading()
        }

        locationManager?.startUpdatingLocation()
    }
    
    func invalidateTimers() {
        locationTimer?.invalidate()
        headingTimer?.invalidate()
        
        locationTimer = nil
        headingTimer = nil
    }
    
}
