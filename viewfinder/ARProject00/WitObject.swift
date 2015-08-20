//
//  WitObject.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import SceneKit

class WitObject {
    
    var witCoordinat: WitCoordinate = WitCoordinate(lat: 0, lon: 0, alt: 0)
    var objectGeometry: SCNNode = SCNNode()
    var witName: String = ""
    var witDescription: String = ""
    
    init(coord: WitCoordinate) {
        witCoordinat = coord
        
        let boxGeometry = SCNBox(width: CGFloat(Utils.metersToCoordinate(20)), height: CGFloat(Utils.metersToCoordinate(20)), length: CGFloat(Utils.metersToCoordinate(20)), chamferRadius: 1.0)
        objectGeometry = SCNNode(geometry: boxGeometry)
        objectGeometry.position = SCNVector3Make(Float(witCoordinat.point2d.x), Float(witCoordinat.point2d.y), 0)
    }
}