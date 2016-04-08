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
let               FEET: Double = 3.28084

class Utils {
    
    //one meter ~ coordinate points
    static func metersToCoordinate(metr: Double) -> Float {
        return Float(metr*DEFAULT_METR_SCALE)
    }
  
    //convert LL to XY having center (0,0) in specific LL location
    static func convertLLtoXY(origin: CLLocation, newLocation: CLLocation) -> Point2D {
        let angle: Double = DegreesToRadians(0)
        
        var x: Double = (newLocation.coordinate.longitude - origin.coordinate.longitude)*meterDegLon(origin.coordinate.latitude)
        var y: Double = (newLocation.coordinate.latitude - origin.coordinate.latitude)*meterDegLat(origin.coordinate.latitude)
        
        let r: Double = sqrt(x*x + y*y)
        
        if r > 0 {
            let ct: Double = x/r
            let st: Double = y/r
            x = r*((ct * cos(angle)) + (st * sin(angle)))
            y = r*((st * cos(angle)) - (ct * sin(angle)))
        }
        
//        let point = Point2D(xPos: x * DEFAULT_METR_SCALE, yPos: y * DEFAULT_METR_SCALE)
        
        return Point2D(xPos: x * DEFAULT_METR_SCALE, yPos: y * DEFAULT_METR_SCALE)
    }
    
    static func meterDegLon(x: Double) -> Double {
        let d2r = DegreesToRadians(x)
        
        let part1: Double = cos(d2r)
        let part2: Double = (94.55*cos(3.0*d2r))
        let part3: Double = (0.120*cos(5.0*d2r))
        
        return 111415.13*part1 - part2 + part3
    }
    
    static func meterDegLat(x: Double) -> Double {
        let d2r = DegreesToRadians(x)
        
        let part1: Double = (566.05*cos(2.0*d2r))
        let part2: Double = (1.2000*cos(4.0*d2r))
        let part3: Double = (0.0020*cos(6.0*d2r))
        
        return 111132.09 - part1 + part2 - part3
    }

    static func DegreesToRadians(degrees: Double) -> Double {
        return degrees*M_PI/180.0
    }
    
    static func RadiansToDegrees(radians: Double) -> Double {
        return radians*180.0/M_PI
    }
    
    
    static func convertToFeet(meters: Double) -> Double {
        return meters*FEET
    }
    
    static func covertToMeters(feet: Double) -> Double {
        return feet/FEET
    }
    
    static func isPointLeft(a: Point2D, b: Point2D, c: Point2D) -> Bool {
        let value: Double = ((b.x - a.x)*(c.y - a.y) - (b.y - a.y)*(c.x - a.x))
        
        return value < 0
    }
    
    static func angleBetween2Lines(line1: Line2D, line2: Line2D) -> Double {
        let angle1 = atan2(line1.startPoint.y - line1.endPoint.y, line1.startPoint.x - line1.endPoint.x)
        let angle2 = atan2(line2.startPoint.y - line2.endPoint.y, line2.startPoint.x - line2.endPoint.x)
        
        return angle1 - angle2
    }
    
    static func angleBetween2DotsWithCenter(centerPoint: Point2D, point1: Point2D, point2: Point2D) -> Double {
        let subPoint1: Point2D = Point2D(xPos: point1.x, yPos: point1.y)
        let subPoint2: Point2D = Point2D(xPos: point2.x, yPos: point2.y)
        
        subPoint1.x -= centerPoint.x
        subPoint1.y -= centerPoint.y
        subPoint2.x -= centerPoint.x
        subPoint2.y -= centerPoint.y
        
        let line1: Line2D = Line2D(point1: centerPoint, point2: subPoint1)
        let line2: Line2D = Line2D(point1: centerPoint, point2: subPoint2)
        
        return angleBetween2Lines(line1, line2: line2)
    }
}
