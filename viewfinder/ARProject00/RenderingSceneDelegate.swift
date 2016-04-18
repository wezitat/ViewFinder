//
//  RenderingSceneDelegate.swift
//  ARProject00
//
//  Created by Ihor on 4/18/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

protocol RenderingSceneDelegate{
    func setEventDelegate(object: SceneEventsDelegate?)
    func getCameraNode() -> SCNNode
    func setCameraNodePosition(vector: SCNVector3)
    func getShowingObject() -> [WitObject]
    func rotationChanged(orientation: SCNQuaternion)
    func isNodeOnMotionScreen(node: SCNNode) -> Bool
    func nodePosToScreenMotionCoordinates(node: SCNNode) -> Point3D
    func resetMotionScene()
    func initialize3DSceneMotionWithHeading(calibratedHeading: CLLocationDirection)
}
