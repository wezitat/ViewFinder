//
//  Point2D.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation

class Point2D {
    var x: Double = 0
    var y: Double = 0
    
    init (xPos: Double, yPos: Double) {
        self.x = xPos
        self.y = yPos
    }
    
    func printPoint() {
        print("point x: \(x) y: \(y)")
    }
}