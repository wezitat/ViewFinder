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
    var is3D: Bool = false
    
    init(coord: WitCoordinate) {
        witCoordinat = coord
        
        var diceRoll = Int(arc4random_uniform(2))
        if diceRoll == 0 {
            self.makeBox()
        }
        else {
            self.makeImage()
        }
    }
    
    func makeBox() {
        is3D = true
        let boxGeometry = SCNBox(width: CGFloat(Utils.metersToCoordinate(20)), height: CGFloat(Utils.metersToCoordinate(20)), length: CGFloat(Utils.metersToCoordinate(20)), chamferRadius: 1.0)
        objectGeometry = SCNNode(geometry: boxGeometry)
        objectGeometry.position = SCNVector3Make(Float(witCoordinat.point2d.x), Float(witCoordinat.point2d.y), Float(witCoordinat.alt))
    }
    
    func makeImage() {
        let texture  = SCNMaterial()
        texture.diffuse.contents = UIImage(named: "minion")
        texture.locksAmbientWithDiffuse = false
        texture.doubleSided = true
        texture.lightingModelName = SCNLightingModelConstant
        
        let clearMaterial = SCNMaterial()
        clearMaterial.diffuse.contents = UIColor.clearColor()
        clearMaterial.locksAmbientWithDiffuse = true;
        
        let boxGeometry = SCNBox(width: CGFloat(Utils.metersToCoordinate(20)), height: CGFloat(Utils.metersToCoordinate(30)), length: CGFloat(Utils.metersToCoordinate(0)), chamferRadius: 1.0)
        boxGeometry.materials = [texture, clearMaterial, clearMaterial, clearMaterial, clearMaterial, clearMaterial]
        objectGeometry = SCNNode(geometry: boxGeometry)
        objectGeometry.position = SCNVector3Make(Float(witCoordinat.point2d.x), Float(witCoordinat.point2d.y), Float(witCoordinat.alt))
    }
}