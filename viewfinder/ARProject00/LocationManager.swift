//
//  LocationManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import CoreLocation
import LocationKit

let kDistanceFilter: Double = 25
let kHeadingFilter: Double = 1

protocol LocationManagerDelegate {
    func locationDelegateAltitudeUpdated(altitude: CLLocationDistance)
    func locationDelegateLocationUpdated(location: CLLocation)
}

protocol InfoLocationDelegate {
    func locationUpdated(location: String)
    func locationDistanceUpdated(distance: String)
    func altitudeUpdated(altitude: Int)
    func accuracyUpdated(accuracy: Int)
    func lastTimeLocationUpdate(timeUpdate: Int)
}

protocol DeviceCalibrateDelegate {
    func headingUpdated(heading: CLLocationDirection)
    func initLocationReceived()
}

/** This is custom wrapper arround IOS LocationManager */
class LocationManager: HardwareManager {
    
    let LOCATION_ACCURACCY: CLLocationAccuracy = SettingsManager.sharedInstance.getAccuracyValue()
    
    var locationManagerDelegate: LocationManagerDelegate! = nil
    var deviceCalibrateDelegate: DeviceCalibrateDelegate! = nil
    var    infoLocationDelegate: InfoLocationDelegate!    = nil

    var manager: LKLocationManager = LKLocationManager()
    
    var previousLocation: CLLocation! = nil
    
    var timerAfterUpdate: NSTimer! = nil
    
    var timePassed: Int = 0
    
    override func initManager() {
        
//        let locationManager = LKLocationManager()
        // The debug flag is not necessary (and should not be enabled in prod)
        // but does help to ensure things are working correctly
        manager.debug = true
        manager.apiToken = "b93e57618fcbd8d4"
//        locationManager.startUpdatingLocation()

        manager.advancedDelegate = Brain.sharedInstance
        
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kDistanceFilter
        manager.headingFilter = kHeadingFilter
        
        startUpdating()
    }
    
    override func startUpdating() {
        timePassed = 0
        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(timeUpdate),
                                                                  userInfo: nil,
                                                                  repeats: true)
        if #available(iOS 9.0, *) {
            manager.requestLocation()
        } else {
            manager.startUpdatingLocation()
        }
        
        manager.startUpdatingHeading()
    }
    
    func timeUpdate() {
        timePassed += 1
        
        infoLocationDelegate?.lastTimeLocationUpdate(timePassed)
    }
    
    override func stopUpdating() {
        previousLocation = nil
        
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    func resetTimer() {
        timePassed = 0
        
        if timerAfterUpdate != nil {
            timerAfterUpdate.invalidate()
        }
        
        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(timeUpdate),
                                                                  userInfo: nil,
                                                                  repeats: true)
    }
}
