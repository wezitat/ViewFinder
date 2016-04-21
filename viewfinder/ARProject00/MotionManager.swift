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
    func rotationChanged(orientation: SCNQuaternion)
    func drasticDeviceMove()
}

protocol RotationManagerDelegate {
    func rotationAngleUpdated(angle: Double)
}

var max_acc: Double = -1000000.0

/** This is custom cover arround IOS MotionManager */
class MotionManager {
    
    var   motionManagerDelegate: MotionManagerDelegate! = nil
    var rotationManagerDelegate: RotationManagerDelegate! = nil

    let motionManager = CMMotionManager()
    
    func initMotionManger() {
        motionManager.accelerometerUpdateInterval = 0.2
        motionManager.gyroUpdateInterval = 0.2
        
        play()
        trackLocation()
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
    
    func trackLocation() {
        if motionManager.accelerometerAvailable {
            motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue(), withHandler: { (data: CMAccelerometerData?, error: NSError?) in
                if let acceleration = data?.acceleration {
                    let rotation = atan2(acceleration.x, acceleration.y) - M_PI
                    print("x = \(acceleration.x)")
                    print("y = \(acceleration.y)")
                    print("z = \(acceleration.z)")
                    
                    if max_acc < acceleration.x {
                        max_acc = acceleration.x
                    }
                    
                    print("max x = \(max_acc)")
                }
            })
        }
    }
    
    func outputAccelerationData(acceleration:CMAcceleration) {
    }
    
    func outputDeviceMotion(motion: CMDeviceMotion) {
        motionManagerDelegate?.rotationChanged(self.orientationFromCMQuaternion(motion.attitude))
        
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
