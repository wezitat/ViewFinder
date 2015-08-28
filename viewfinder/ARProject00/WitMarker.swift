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



protocol WitMarkerDelegate {
    func showObjectDetails(wObject: WitObject)
}

class WitMarker: NSObject {
    
    let HERE: Int = SettingManager.sharedInstance.getHereNumberValue()
    let NEAR: Int = SettingManager.sharedInstance.getNearNumberValue()
    
    var delegate: WitMarkerDelegate! = nil
    var currentDistance: CLLocationDistance = 0
    var wObject: WitObject! = nil
    var view: UIView! = nil
    var label: UILabel! = nil
    
    var isShowMarker: Bool = true
    var witPostitioning: Position = .Here
    enum Position {
        case Here
        case Near
        case There
    }
    
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
                
                if distance < self.HERE {
                    self.witPostitioning = .Here
                    self.label.backgroundColor = UIColor.greenColor()
                }
                if distance >= self.HERE && distance < self.NEAR {
                    self.witPostitioning = .Near
                    self.label.backgroundColor = UIColor.yellowColor()
                }
                if distance >= self.NEAR {
                    self.witPostitioning = .There
                    self.label.backgroundColor = UIColor.redColor()
                }
            })
        }
    }
    
    func createView() -> UIView {
        self.view = UIView(frame: CGRectMake(0, 0, 60, 60))
        self.label = UILabel(frame: CGRectMake(0, 0, 60, 60))
        self.view.clipsToBounds = true
        self.view.layer.cornerRadius = 30
        self.label.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.label)
        self.label.font = UIFont.systemFontOfSize(9)
        self.label.textAlignment = .Center
        self.label.userInteractionEnabled = false
        
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("showDetailsInfo"))
        self.view.addGestureRecognizer(tapGesture)
        
        return self.view
    }
    
    func showMarker(show: Bool) {
        if !show {
            self.view.hidden = true
        }
        else {
            if isShowMarker {
                self.view.hidden = false
            }
            else {
                self.view.hidden = true
            }
        }
        
        if SettingManager.sharedInstance.getHideThereMarkesValue() {
            if self.witPostitioning == .There {
                self.view.hidden = true
            }
        }
    }
    
    func showDetailsInfo() {
        if delegate != nil {
            delegate.showObjectDetails(self.wObject)
        }
    }
}