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
    func rotationChanged(orientation: CMQuaternion)
    func altitudeUpdated(altitude: CLLocationDistance)
}
