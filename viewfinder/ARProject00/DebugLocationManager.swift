//
//  DebugLocationManager.swift
//  ARProject00
//
//  Created by Ihor on 4/15/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation
import LocationKit

class DebugLocationManager: NSObject, LKLocationManagerDelegate {

    var locationManager: LKLocationManager? = LKLocationManager()
    
    var locationTimer: NSTimer? = nil
    var headingTimer:  NSTimer? = nil
    
    var timePassedFromLastHeadingUpdate: Int = 0
    var timePassedFromLastLocationUpdate: Int = 0
    
    func setStandardProperties() {
        
        locationManager?.requestAlwaysAuthorization()
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        locationManager?.distanceFilter = kCLDistanceFilterNone
        
        if LKLocationManager.headingAvailable() {
            locationManager?.startUpdatingHeading()
        }

        locationManager?.debug = true
        locationManager?.apiToken = "b93e57618fcbd8d4"
        
        locationManager?.startUpdatingLocation()
    }
    
    func invalidateTimers() {
        locationTimer?.invalidate()
        headingTimer?.invalidate()
        
        locationTimer = nil
        headingTimer = nil
    }
    
}
