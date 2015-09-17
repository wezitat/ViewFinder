//
//  MotionManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreMotion
import GLKit
import SceneKit

protocol MotionManagerDelegate {
    func rotationChanged(orientation: SCNQuaternion)
    func drasticDeviceMove()
}

protocol RotationManagerDelegate {
    func rotationAngleUpdated(angle: Double)
}

/** This is custom cover arround IOS MotionManager */
class MotionManager {
    
    var delegate: MotionManagerDelegate! = nil
    var rotationDelegate: RotationManagerDelegate! = nil

    let motionManager = CMMotionManager()
    
    func initMotionManger() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2
        play()
        
    }
    
    func pause() {
        motionManager.stopDeviceMotionUpdates()
    }
    
    func play() {
        self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(CMAttitudeReferenceFrame.XArbitraryCorrectedZVertical, toQueue: NSOperationQueue()) { (motion, error) -> Void in
            // translate the attitude
            self.outputDeviceMotion(motion!)
        }
    }
    
    func outputAccelerationData(acceleration:CMAcceleration) {
    }
    
    func outputDeviceMotion(motion: CMDeviceMotion) {
        if self.delegate != nil {
            self.delegate.rotationChanged(self.orientationFromCMQuaternion(motion.attitude))
            if self.deviceMadeDrasticMove(motion) {
                self.delegate.drasticDeviceMove()
            }
        }
        
        if self.rotationDelegate != nil {
            let rotation: Double = atan2(motion.gravity.x, motion.gravity.y) - M_PI
            self.rotationDelegate.rotationAngleUpdated(rotation)
        }
    }

    func deviceMadeDrasticMove(motion: CMDeviceMotion) -> Bool {
        //somehow moving camera rotates scene to small angle - this is the way to update rotation only when device moved
        return abs(motion.rotationRate.x) > 0.1 || abs(motion.rotationRate.y) > 0.1 || abs(motion.rotationRate.z) > 0.1
    }
    
    func orientationFromCMQuaternion(attitude:CMAttitude) -> SCNQuaternion {
        let q: CMQuaternion = attitude.quaternion
        var rq: CMQuaternion = CMQuaternion()
        rq.x = q.x
        rq.y = q.y
        rq.z = q.z
        rq.w = q.w
        
        return SCNVector4Make(Float(rq.x), Float(rq.y), Float(rq.z), Float(rq.w))
    }
 
}