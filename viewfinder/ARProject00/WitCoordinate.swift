//
//  WitCoordinate.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation

class WitCoordinate {
    var lat: Double = 0
    var lon: Double = 0
    var alt: Double = 0
    
    var point2d: Point2D = Point2D()
    
    init(lat: Double, lon: Double, alt: Double) {
        self.lat   = lat
        self.lon   = lon
        self.alt   = alt
        
        var newLocation: CLLocation = CLLocation(latitude: lat, longitude: lon)
        var centerLocation: CLLocation = ViewFinderManager.sharedInstance.centerPoint
    
        point2d = Utils.convertLLtoXY(centerLocation, newLocation: newLocation)
    }
}