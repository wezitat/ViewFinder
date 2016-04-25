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
class LocationManager: HardwareManager, LKLocationManagerDelegate {
    
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

        manager.advancedDelegate = self
        manager.requestAlwaysAuthorization()
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
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
    
    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
        timePassed = 0
        
        if timerAfterUpdate != nil {
            timerAfterUpdate.invalidate()
        }
        
        timerAfterUpdate = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                  target: self,
                                                                  selector: #selector(timeUpdate),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        let newLocation: CLLocation = locations.last! as CLLocation
        let locationAge: NSTimeInterval = -newLocation.timestamp.timeIntervalSinceNow
        
        if locationAge > 10.0 {
            return
        }
        
        if newLocation.verticalAccuracy > 0 {
            
            locationManagerDelegate?.altitudeUpdated(newLocation.altitude)
        
            infoLocationDelegate?.altitudeUpdated(Int(newLocation.altitude))
        }
        
        if newLocation.horizontalAccuracy < 0 {
            return
        }
        
        infoLocationDelegate?.accuracyUpdated(Int(newLocation.horizontalAccuracy))
        
        if previousLocation == nil {
            if newLocation.horizontalAccuracy <= LOCATION_ACCURACCY && deviceCalibrateDelegate != nil{
                Brain.sharedInstance.setupCenterPoint(newLocation.coordinate.latitude, lon: newLocation.coordinate.longitude)//CLLocation(latitude: 49.840210, longitude:  24.032991)//previousLocation
                
                if newLocation.verticalAccuracy > 0 {
                    Brain.sharedInstance.centerAltitude = newLocation.altitude
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
                    Brain.sharedInstance.userLocation = newLocation
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
    
    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        // Use the true heading if it is valid.
        
        print("heading = \((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)")
        
        deviceCalibrateDelegate?.headingUpdated(((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading))
    }
    
    func locationManagerShouldDisplayHeadingCalibration(manager: LKLocationManager) -> Bool {
        return true
    }
}
