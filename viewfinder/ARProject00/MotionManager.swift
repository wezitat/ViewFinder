//
//  MotionManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import CoreMotion
import GLKit
import SceneKit

protocol MotionManagerDelegate {
    func rotationChanged(orientation: CMQuaternion)
    func drasticDeviceMove()
}

protocol RotationManagerDelegate {
    func rotationAngleUpdated(angle: Double)
}

var max_acc: Double = -1000000.0

/** This is custom cover arround IOS MotionManager */
class MotionManager: HardwareManager {
    
    var   motionManagerDelegate: MotionManagerDelegate! = nil
    var rotationManagerDelegate: RotationManagerDelegate! = nil

    let motionManager = CMMotionManager()
    
    override func initManager() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2
        
        startUpdating()
    }
    
    override func stopUpdating() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    override func startUpdating() {
        self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryCorrectedZVertical, toQueue: NSOperationQueue()) { (motion, error) -> Void in
            // translate the attitude
            self.outputDeviceMotion(motion!)
        }
    }
    
    func outputAccelerationData(acceleration:CMAcceleration) {
    }
    
    func outputDeviceMotion(motion: CMDeviceMotion) {
        motionManagerDelegate?.rotationChanged(motion.attitude.quaternion)
        
        if deviceMadeDrasticMove(motion) {
            motionManagerDelegate?.drasticDeviceMove()
        }
        
        rotationManagerDelegate?.rotationAngleUpdated(atan2(motion.gravity.x, motion.gravity.y) - M_PI)
    }

    func deviceMadeDrasticMove(motion: CMDeviceMotion) -> Bool {
        //somehow moving camera rotates scene to small angle - this is the way to update rotation only when device moved
        return abs(motion.rotationRate.x) > 0.1 ||
               abs(motion.rotationRate.y) > 0.1 ||
               abs(motion.rotationRate.z) > 0.1
    }
    
}
