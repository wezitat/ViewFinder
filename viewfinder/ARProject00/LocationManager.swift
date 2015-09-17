//
//  LocationManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation

let kDistanceFilter: Double = 25
let kHeadingFilter: Double = 0

protocol LocationManagerDelegate {
    func altitudeUpdated(altitude: CLLocationDistance)
    func locationUpdated(location: CLLocation)
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
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let LOCATION_ACCURACCY:CLLocationAccuracy = SettingManager.sharedInstance.getAccuracyValue()
    
    var delegate: LocationManagerDelegate! = nil
    var calibrateHeadingDelegate: DeviceCalibrateDelegate! = nil
    var infoLocationDelegate: InfoLocationDelegate! = nil

    var manager: CLLocationManager = CLLocationManager()
    var previousLocation: CLLocation! = nil
    
    var timerAfterUpdate: NSTimer! = nil
    var timePassed: Int = 0
    
    func initLocatioManager() {
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kDistanceFilter
        manager.headingFilter = kHeadingFilter
        
        startUpdates()
    }
    
    func startUpdates() {
        timePassed = 0
        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeUpdate"), userInfo: nil, repeats: true)
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    func timeUpdate() {
        timePassed++
        if infoLocationDelegate != nil {
            infoLocationDelegate.lastTimeLocationUpdate(timePassed)
        }
    }
    
    func stopUpdates() {
        previousLocation = nil
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if timerAfterUpdate != nil {
            timePassed = 0
            timerAfterUpdate.invalidate()
            timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeUpdate"), userInfo: nil, repeats: true)
        }
        else {
            timePassed = 0
            timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("timeUpdate"), userInfo: nil, repeats: true)
        }
        
        let newLocation: CLLocation = locations.last! as CLLocation
        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        if locationAge > 10.0 {
            return
        }
        
        if(newLocation.verticalAccuracy > 0) {
            if delegate != nil {
                delegate.altitudeUpdated(newLocation.altitude)
            }
            if infoLocationDelegate != nil {
                infoLocationDelegate.altitudeUpdated(Int(newLocation.altitude))
            }
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        if infoLocationDelegate != nil {
            infoLocationDelegate.accuracyUpdated(Int(newLocation.horizontalAccuracy))
        }
        
        if previousLocation == nil {
            if newLocation.horizontalAccuracy <= LOCATION_ACCURACCY {
                if calibrateHeadingDelegate != nil {
                    ViewFinderManager.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                    if(newLocation.verticalAccuracy > 0) {
                        ViewFinderManager.sharedInstance.centerAltitude = newLocation.altitude
                        calibrateHeadingDelegate.initLocationReceived()
                        previousLocation = newLocation
                    }
                    if infoLocationDelegate != nil {
                        let distance: Double = newLocation.distanceFromLocation(previousLocation)
                        infoLocationDelegate.locationDistanceUpdated("\(Int(distance))")
                        let curPoint: String = "lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)"
                        infoLocationDelegate.locationUpdated(curPoint)
                    }
                }
 
            }
        }
        else {
            if newLocation.horizontalAccuracy <= LOCATION_ACCURACCY {
                
                if delegate != nil {
                    delegate.locationUpdated(newLocation)
                    ViewFinderManager.sharedInstance.userLocation = newLocation
                }
                if infoLocationDelegate != nil {
                    let distance: Double = newLocation.distanceFromLocation(previousLocation)
                    infoLocationDelegate.locationDistanceUpdated("\(Int(distance))")
                    let curPoint: String = "lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)"
                    infoLocationDelegate.locationUpdated(curPoint)
                }
                previousLocation = newLocation
            }
            else {
                if infoLocationDelegate != nil {
                    infoLocationDelegate.locationDistanceUpdated("ignoring")
                    let curPoint: String = "ignoring"
                    infoLocationDelegate.locationUpdated(curPoint)
                }
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        let theHeading: CLLocationDirection = ((newHeading.trueHeading > 0) ?
            newHeading.trueHeading : newHeading.magneticHeading)
        
        if calibrateHeadingDelegate != nil {
            calibrateHeadingDelegate.headingUpdated(theHeading)
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        return true
    }
}