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

let kDistanceFilter: Double = 1
let kHeadingFilter: Double = 1

protocol LocationManagerDelegate {
    func locationDelegateAltitudeUpdated(altitude: CLLocationDistance)
    func locationDelegateLocationUpdated(location: CLLocation)
}

protocol InfoLocationDelegate {
    func locationUpdatedInfo(location: String)
    func locationDistanceUpdatedInfo(distance: String)
    func altitudeUpdatedInfo(altitude: Int)
    func accuracyUpdatedInfo(accuracy: Int)
    func lastTimeLocationUpdateInfo(timeUpdate: Int)
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

        manager.advancedDelegate = Brain.sharedInstance
        
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kDistanceFilter
        manager.headingFilter = kHeadingFilter
    }
    
    override func startUpdating() {
        timePassed = 0
        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(timeUpdate),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func timeUpdate() {
        timePassed += 1
        
        infoLocationDelegate?.lastTimeLocationUpdateInfo(timePassed)
    }
    
    override func stopUpdating() {
        previousLocation = nil
        
        timerAfterUpdate?.invalidate()
        timerAfterUpdate = nil
        
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    func resetTimer() {
        timePassed = 0
        
//        if timerAfterUpdate != nil {
//            timerAfterUpdate.invalidate()
//        }
        
        timerAfterUpdate?.invalidate()
        timerAfterUpdate = nil
        
//        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
//                                                                  target: self,
//                                                                  selector: #selector(timeUpdate),
//                                                                  userInfo: nil,
//                                                                  repeats: true)
    }
}
