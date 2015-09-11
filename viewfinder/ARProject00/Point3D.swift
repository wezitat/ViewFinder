//
//  Point3D.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 9/11/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation

class Point3D {
    var x: Double = 0
    var y: Double = 0
    var z: Double = 0
    
    init(xPos: Double, yPos: Double, zPos: Double) {
        self.x = xPos
        self.y = yPos
        self.z = zPos
    }
}