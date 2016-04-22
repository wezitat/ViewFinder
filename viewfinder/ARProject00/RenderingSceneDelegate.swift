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
import CoreMotion

protocol RenderingSceneDelegate{
    func setEventDelegate(object: SceneEventsDelegate?)
    func getCameraNode() -> SCNNode
    func getShowingObject() -> [WitObject]
    func rotationChanged(orientation: CMQuaternion)
    func isNodeOnMotionScreen(node: SCNNode) -> Bool
    func nodePosToScreenMotionCoordinates(node: SCNNode) -> Point3D
    func resetMotionScene()
    func initialize3DSceneMotionWithHeading(calibratedHeading: CLLocationDirection)
    func altitudeUpdated(altitude: CLLocationDistance)
    func locationUpdated(point: Point2D, location: CLLocation)
}
