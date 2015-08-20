//
//  Utils.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation

//value which represents scale in 3d scene
let DEFAULT_METR_SCALE: Double = 100
let FEET: Double = 3.28084
class Utils {
    
    //one meter ~ coordinate points
    static func metersToCoordinate(metr: Double) -> Float {
        return Float(metr * DEFAULT_METR_SCALE)
    }
  
    //convert LL to XY having center (0,0) in specific LL location
    static func convertLLtoXY(origin: CLLocation, newLocation: CLLocation) -> Point2D {
        var angle: Double = DegreesToRadians(0)
        
        var x: Double = (newLocation.coordinate.longitude - origin.coordinate.longitude)*meterDegLon(origin.coordinate.latitude)
        var y: Double = (newLocation.coordinate.latitude - origin.coordinate.latitude)*meterDegLat(origin.coordinate.latitude)
        
        var r: Double = sqrt(x*x + y*y)
        if r > 0 {
            var ct: Double = x/r
            var st: Double = y/r
            x = r*((ct * cos(angle)) + (st * sin(angle)))
            y = r*((st * cos(angle)) - (ct * sin(angle)))
        }
        
        var point = Point2D()
        
        point.x = x * DEFAULT_METR_SCALE
        point.y = y * DEFAULT_METR_SCALE
        
        return point
    }
    
    static func meterDegLon(x: Double) -> Double {
        var d2r = DegreesToRadians(x)
        var part1: Double = cos(d2r)
        var part2: Double = (94.55 * cos(3.0*d2r))
        var part3: Double = (0.12 * cos(5.0*d2r))
        return ((111415.13 * part1) - part2 + part3)
    }
    
    static func meterDegLat(x: Double) -> Double {
        var d2r = DegreesToRadians(x)
        
        var part1: Double = (566.05 * cos(2.0*d2r))
        var part2: Double = (1.20 * cos(4.0*d2r))
        var part3: Double = (0.002 * cos(6.0*d2r))
        
        return (111132.09 - part1 + part2 - part3)
    }

    static func DegreesToRadians(degrees: Double ) -> Double {
        return degrees * M_PI / 180
    }
    
    static func RadiansToDegrees(radians: Double) -> Double {
        return radians * 180 / M_PI
    }
    
    
    static func convertToFeet(meters: Double) -> Double {
        return meters * FEET
    }
    
    static func isPointLeft(a: Point2D, b: Point2D, c: Point2D) -> Bool {
        var value: Double = ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x))
        return value < 0
    }
}
