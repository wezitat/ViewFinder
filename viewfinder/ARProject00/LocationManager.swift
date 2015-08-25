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
    func showLocationInfo(string: String)
}

protocol DeviceCalibrateDelegate {
    func headingUpdated(heading: CLLocationDirection)
    func initLocationReceived()
}

/** This is custom cover arround IOS LocationManager */
class LocationManager: NSObject, CLLocationManagerDelegate {
    
    let LOCATION_ACCURACCY:CLLocationAccuracy = 100
    
    var delegate: LocationManagerDelegate! = nil
    var calibrateHeadingDelegate: DeviceCalibrateDelegate! = nil

    var manager: CLLocationManager = CLLocationManager()
    var previousLocation: CLLocation! = nil
    
    func initLocatioManager() {
        manager.delegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.distanceFilter = kDistanceFilter
        manager.headingFilter = kHeadingFilter
        
        startUpdates()
    }
    
    func startUpdates() {
        manager.startUpdatingLocation()
        manager.startUpdatingHeading()
    }
    
    func stopUpdates() {
        manager.stopUpdatingLocation()
        manager.stopUpdatingHeading()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        var newLocation: CLLocation = locations.last as! CLLocation
        var locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        if locationAge > 10.0 {
            return
        }
        
        if(newLocation.verticalAccuracy > 0) {
            if delegate != nil {
                delegate.altitudeUpdated(newLocation.altitude)
                println("distance from previous location: \(newLocation.altitude)")
            }
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        println("accuracy: \(newLocation.horizontalAccuracy)")
        if previousLocation == nil {
            if newLocation.horizontalAccuracy < LOCATION_ACCURACCY {
                if delegate != nil {
                    let str = NSString(format: "%.6f", previousLocation.coordinate.latitude)
                    let stry = NSString(format: "%.6f", previousLocation.coordinate.longitude)
                    delegate.showLocationInfo("lat: \(str)  lon: \(stry)")
                    
                }
                
                if calibrateHeadingDelegate != nil {
                    ViewFinderManager.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                    if(newLocation.verticalAccuracy > 0) {
                        ViewFinderManager.sharedInstance.centerAltitude = newLocation.altitude
                        calibrateHeadingDelegate.initLocationReceived()
                        previousLocation = newLocation
                    }
                }
 
            }
        }
        else {
            var distance: Double = newLocation.distanceFromLocation(previousLocation)
            println("distance from previous location: \(distance)")
            if newLocation.horizontalAccuracy < LOCATION_ACCURACCY {
                if delegate != nil {
                    let str = NSString(format: "%.6f", newLocation.coordinate.latitude)
                    let stry = NSString(format: "%.6f", newLocation.coordinate.longitude)
                    let str1 = NSString(format: "%.6f", previousLocation.coordinate.latitude)
                    let stry1 = NSString(format: "%.6f", previousLocation.coordinate.longitude)
                    delegate.showLocationInfo("lat: \(str)  lon: \(stry) \nlat: \(str1)  lon: \(stry1) \n")
                }
                var distance: Double = newLocation.distanceFromLocation(previousLocation)
                var bearing: Double = newLocation.bearingToLocationRadian(previousLocation)
                if delegate != nil {
                    delegate.locationUpdated(newLocation)
                    ViewFinderManager.sharedInstance.userLocation = newLocation
                }
                previousLocation = newLocation
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateHeading newHeading: CLHeading!) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        var theHeading: CLLocationDirection = ((newHeading.trueHeading > 0) ?
            newHeading.trueHeading : newHeading.magneticHeading)
        
        if calibrateHeadingDelegate != nil {
            calibrateHeadingDelegate.headingUpdated(theHeading)
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager!) -> Bool {
        return true
    }
}