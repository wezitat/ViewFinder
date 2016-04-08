//
//  WitObject.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

let  WITOBJECT_BIGGEST_SIZE: Double = 20
let WITOBJECT_SMALLEST_SIZE: Double = 1

class WitObject {
    
    var witCoordinat: WitCoordinate = WitCoordinate(lat: 0, lon: 0, alt: 0)
    
    var objectGeometry: SCNNode = SCNNode()
    var objectElement: SCNBox = SCNBox()
    
    var        witName: String = ""
    var witDescription: String = ""
    var         author: String = ""
    
    var      is3D: Bool = false
    var isClaimed: Bool = false
    
    
    init(coord: WitCoordinate) {
        witCoordinat = coord

        let diceRoll = Int(arc4random_uniform(2))
        if diceRoll == 0 {
            self.makeImage()
        }
        else {
        //self.makeImage()
            self.makeBox()
        }
    }
    
    func makeBox() {
        is3D = true
        let texture  = SCNMaterial()
        texture.diffuse.contents = UIColor.whiteColor()
        objectElement = SCNBox(width: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE)),
                               height: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE)),
                               length: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE)),
                               chamferRadius: 1.0)
        objectElement.materials = [texture]
        objectGeometry = SCNNode(geometry: objectElement)
        objectGeometry.position = SCNVector3Make(Float(witCoordinat.point2d.x), Float(witCoordinat.point2d.y), Float(witCoordinat.alt))
    }
    
    func makeImage() {
        let texture  = SCNMaterial()
        
        texture.diffuse.contents = UIImage(named: "minion")
        texture.locksAmbientWithDiffuse = true
        texture.doubleSided = true
        texture.lightingModelName = SCNLightingModelConstant
        
        let clearMaterial = SCNMaterial()
        
        clearMaterial.diffuse.contents = UIColor.clearColor()
        clearMaterial.locksAmbientWithDiffuse = true;
        
        objectElement = SCNBox(width: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE)),
                               height: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE*1.5)),
                               length: CGFloat(LocationMath.sharedInstance.metersToCoordinate(WITOBJECT_BIGGEST_SIZE)),
                               chamferRadius: 1.0)
        objectElement.materials = [texture, texture, texture, texture, clearMaterial, clearMaterial]
        objectGeometry = SCNNode(geometry: objectElement)
        objectGeometry.position = SCNVector3Make(Float(witCoordinat.point2d.x), Float(witCoordinat.point2d.y), Float(witCoordinat.alt))
        objectGeometry.rotation = SCNVector4(x: 1, y: 0, z: 0, w: Float(LocationMath.sharedInstance.DegreesToRadians(90)))
    }
    
    func updateWitObjectSize(userLocation: CLLocation) {
        let         distance: Double = userLocation.distanceFromLocation(CLLocation(latitude: self.witCoordinat.lat,
                                                                                    longitude: self.witCoordinat.lon))
        let     nearDistance: Double = Double(SettingsManager.sharedInstance.getHereNumberValue())
        let     deltaOfSizes: Double = WITOBJECT_BIGGEST_SIZE - WITOBJECT_SMALLEST_SIZE
        let scalePerDistance: Double = nearDistance/deltaOfSizes
        
        var     stepsBetween: Double = distance/scalePerDistance
        
        if stepsBetween < 1 {
            stepsBetween = 1
        }
        
        if distance < nearDistance {
            if is3D {
               objectElement.length = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
               objectElement.width = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
               objectElement.height = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
            } else {
               objectElement.length = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
               objectElement.width = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
               objectElement.height = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween*1.5))
            }
        }
        else {
            stepsBetween = WITOBJECT_BIGGEST_SIZE
            
            if is3D {
                objectElement.length = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
                objectElement.width = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
                objectElement.height = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
            } else {
                objectElement.length = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
                objectElement.width = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween))
                objectElement.height = CGFloat(LocationMath.sharedInstance.metersToCoordinate(stepsBetween*1.5))
            }
        }
    }
}
