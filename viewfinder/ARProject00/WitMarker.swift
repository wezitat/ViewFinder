//
//  WitMarker.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/17/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

let HERE: Int = 1000
let NEAR: Int = 5000

class WitMarker {
    var currentDistance: CLLocationDistance = 0
    var wObject: WitObject! = nil
    var view: UIView! = nil
    var label: UILabel! = nil
    
    func registerObject(object: WitObject) {
        self.wObject = object
        self.createView()
        self.updateDistance(ViewFinderManager.sharedInstance.centerPoint)
    }
    
    func updateDistance(userLocation: CLLocation) {
        var centerLocation: CLLocation = userLocation
        
        if wObject != nil {
            var wLocation: CLLocation = CLLocation(latitude: wObject.witCoordinat.lat, longitude: wObject.witCoordinat.lon)
            currentDistance = wLocation.distanceFromLocation(centerLocation)
        }
        if label != nil {
            dispatch_async(dispatch_get_main_queue(), {
                var distance: Int = Int(Utils.convertToFeet(self.currentDistance))
                self.label.text = ("\(distance) ft")
                
                if distance < HERE {
                    self.label.backgroundColor = UIColor.greenColor()
                }
                if distance >= HERE && distance < NEAR {
                    self.label.backgroundColor = UIColor.yellowColor()
                }
                if distance >= NEAR {
                    self.label.backgroundColor = UIColor.redColor()
                }
            })
        }
    }
    
    func createView() -> UIView {
        self.view = UIView(frame: CGRectMake(0, 0, 60, 20))
        self.label = UILabel(frame: CGRectMake(0, 0, 60, 20))
        self.label.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.label)
        self.label.font = UIFont.systemFontOfSize(9)
        self.label.textAlignment = .Center
        return self.view
    }
}