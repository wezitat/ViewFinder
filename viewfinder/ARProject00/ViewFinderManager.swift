//
//  ViewFinderManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation

private let _ViewFinderManager = ViewFinderManager()

class ViewFinderManager {
    static let sharedInstance = ViewFinderManager()
    
    var feetSystem: Bool = false
    
    var motionManager: MotionManager = MotionManager()
    var locationManager: LocationManager = LocationManager()
    
    //initial location of user (based on this LL point 3D scene is builing)
    var centerPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var userLocation: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var centerAltitude: CLLocationDistance = CLLocationDistance()
    
    func startMotionManager() {
         motionManager.initMotionManger()
    }
    
    func startLocationManager() {
        locationManager.initLocatioManager()
    }
    
    func setupCenterPoint(lat: Double, lon: Double) {
        centerPoint = CLLocation(latitude: lat, longitude: lon)
        userLocation = CLLocation(latitude: lat, longitude: lon)
    }
}
