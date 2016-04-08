//
//  File.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 9/10/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation

class Line2D {
    var startPoint: Point2D = Point2D(xPos: 0, yPos: 0)
    var   endPoint: Point2D = Point2D(xPos: 0, yPos: 0)
    
    init(point1: Point2D, point2: Point2D) {
        self.startPoint = point1
        self.endPoint = point2
    }
}