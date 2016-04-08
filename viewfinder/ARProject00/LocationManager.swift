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
    
    let LOCATION_ACCURACCY: CLLocationAccuracy = SettingsManager.sharedInstance.getAccuracyValue()
    
    var locationManagerDelegate: LocationManagerDelegate! = nil
    var deviceCalibrateDelegate: DeviceCalibrateDelegate! = nil
    var    infoLocationDelegate: InfoLocationDelegate!    = nil

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
        
        infoLocationDelegate?.lastTimeLocationUpdate(timePassed)
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
            timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                      target: self,
                                                                      selector: #selector(timeUpdate),
                                                                      userInfo: nil,
                                                                      repeats: true)
        } else {
            timePassed = 0
            timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                      target: self,
                                                                      selector: #selector(timeUpdate),
                                                                      userInfo: nil,
                                                                      repeats: true)
        }
        
        let newLocation: CLLocation = locations.last! as CLLocation
        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        
        if locationAge > 10.0 {
            return
        }
        
        if(newLocation.verticalAccuracy > 0) {
            
            locationManagerDelegate?.altitudeUpdated(newLocation.altitude)
            
            infoLocationDelegate?.altitudeUpdated(Int(newLocation.altitude))
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        infoLocationDelegate?.accuracyUpdated(Int(newLocation.horizontalAccuracy))
        
        if previousLocation == nil {
            if newLocation.horizontalAccuracy <= LOCATION_ACCURACCY && deviceCalibrateDelegate != nil{
                ViewFinderManager.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                
                if(newLocation.verticalAccuracy > 0) {
                    ViewFinderManager.sharedInstance.centerAltitude = newLocation.altitude
                    deviceCalibrateDelegate.initLocationReceived()
                    previousLocation = newLocation
                }
                
                infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(previousLocation)))")
                infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
            }
        }
        else {
            if newLocation.horizontalAccuracy <= LOCATION_ACCURACCY {
                if locationManagerDelegate != nil {
                    locationManagerDelegate.locationUpdated(newLocation)
                    ViewFinderManager.sharedInstance.userLocation = newLocation
                }
                
                infoLocationDelegate?.locationDistanceUpdated("\(Int(newLocation.distanceFromLocation(previousLocation)))")
                infoLocationDelegate?.locationUpdated("lat: \(newLocation.coordinate.latitude) \nlon: \(newLocation.coordinate.longitude)")
                
                previousLocation = newLocation
            }
            else {
                infoLocationDelegate?.locationDistanceUpdated("ignoring")
                infoLocationDelegate?.locationUpdated("ignoring")
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: CLLocationManager) -> Bool {
        return true
    }
}