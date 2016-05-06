//
//  UIProtocol.swift
//  ARProject00
//
//  Created by Ihor on 5/5/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import Foundation
import CoreMotion

@objc protocol UIProtocol {
    
    func applicationLaunched()
    func locationUpdated(location: CLLocation)
    func headingDirectionUpdated(heading: CLHeading)
    
    optional func updateSceneAltitude(altitude: CLLocationDistance)
    optional func updateSceneLocation(location: CLLocation)
    optional func changeSceneRotation(orientation: CMQuaternion)
}