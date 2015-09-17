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


let WIT_MARKER_SIZE: CGFloat = 60

protocol WitMarkerDelegate {
    func showObjectDetails(wObject: WitObject)
}

class WitMarker: NSObject {
    
    enum ScreenPos {
        case Right
        case Left
        case Top
        case Bottom
    }
    
    let HERE: Int = SettingManager.sharedInstance.getHereNumberValue()
    let NEAR: Int = SettingManager.sharedInstance.getNearNumberValue()
    
    var delegate: WitMarkerDelegate! = nil
    var currentDistance: CLLocationDistance = 0
    var wObject: WitObject! = nil
    var view: UIView! = nil
    var pointerView: UIView! = nil
    var triangle: UIView! = nil
    var label: UILabel! = nil
    
    var screenPosition: ScreenPos = .Right
    
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
        let centerLocation: CLLocation = userLocation
        
        if wObject != nil {
            let wLocation: CLLocation = CLLocation(latitude: wObject.witCoordinat.lat, longitude: wObject.witCoordinat.lon)
            currentDistance = wLocation.distanceFromLocation(centerLocation)
        }
        if label != nil {
            dispatch_async(dispatch_get_main_queue(), {
                let distance: Int = Int(Utils.convertToFeet(self.currentDistance))
                self.label.text = ("\(distance) ft")
                
                if distance < self.HERE {
                    self.witPostitioning = .Here
                    self.label.backgroundColor = UIColor.greenColor()
                    self.triangle.backgroundColor = UIColor.greenColor()
                }
                if distance >= self.HERE && distance < self.NEAR {
                    self.witPostitioning = .Near
                    self.label.backgroundColor = UIColor.yellowColor()
                    self.triangle.backgroundColor = UIColor.yellowColor()
                }
                if distance >= self.NEAR {
                    self.witPostitioning = .There
                    self.label.backgroundColor = UIColor.redColor()
                    self.triangle.backgroundColor = UIColor.redColor()
                }
            })
        }
    }
    
    func createView() -> UIView {
        self.view = UIView(frame: CGRectMake(0, 0, WIT_MARKER_SIZE, WIT_MARKER_SIZE))
        
        self.pointerView = UIView(frame: CGRectMake(0, 0, WIT_MARKER_SIZE, WIT_MARKER_SIZE))
        self.triangle = UIView(frame: CGRectMake(WIT_MARKER_SIZE/2, 10, WIT_MARKER_SIZE/2, WIT_MARKER_SIZE - 20))
        
        let path: UIBezierPath = UIBezierPath()
        path.moveToPoint(CGPoint(x: 0, y: 0))
        path.addLineToPoint(CGPoint(x: WIT_MARKER_SIZE/2, y: (WIT_MARKER_SIZE - 20)/2))
        path.addLineToPoint(CGPoint(x: 0, y: WIT_MARKER_SIZE - 20))
        path.addLineToPoint(CGPoint(x: 0, y: 0))
        
        // Create a CAShapeLayer with this triangular path
        // Same size as the original imageView
        let mask: CAShapeLayer = CAShapeLayer()
        mask.frame = self.pointerView.bounds;
        mask.path = path.CGPath;
        
        // Mask the imageView's layer with this shape
        self.triangle.layer.mask = mask
        self.pointerView.addSubview(triangle)
        
        self.label = UILabel(frame: CGRectMake(10, 10, WIT_MARKER_SIZE - 20, WIT_MARKER_SIZE - 20))
        self.label.clipsToBounds = true
        self.label.layer.cornerRadius = (WIT_MARKER_SIZE - 20)/2
        self.label.backgroundColor = UIColor.whiteColor()
        self.view.addSubview(self.pointerView)
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
    
    func updateAngle(angle: Double) {
        dispatch_async(dispatch_get_main_queue()) {
            self.label.transform = CGAffineTransformMakeRotation(CGFloat(angle))
        }
    }
    
    func updatePointerAngle(angle: Double) {
        let origin: CGPoint = self.view.frame.origin
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        var offSet: Double = 0
        
        if origin.x == 0 {
            offSet = 180
        }
        if origin.x >= CGFloat(screenWidth) - WIT_MARKER_SIZE - 5 {
            offSet = 0
        }
        if origin.y == 0 {
            offSet = 270
        }
        if origin.y >= CGFloat(screenHeight) - WIT_MARKER_SIZE  - 5{
            offSet = 90
        }
        
        if origin.x == 0 && origin.y == 0 {
           offSet = 135
        }
        
        if origin.x == 0 &&  origin.y >= CGFloat(screenHeight) - WIT_MARKER_SIZE - 5  {
            offSet = 225
        }
        
        if origin.x >= CGFloat(screenWidth) - WIT_MARKER_SIZE - 5 && origin.y == 0 {
            offSet = 45
        }
        
        if origin.x >= CGFloat(screenWidth) - WIT_MARKER_SIZE - 5 && origin.y >= CGFloat(screenHeight) - WIT_MARKER_SIZE - 5 {
            offSet = 315
        }
        
        
        /*var centerPoint: Point2D = Point2D(xPos: Double(self.view.frame.origin.x + WIT_MARKER_SIZE/2), yPos: Double(self.view.frame.origin.y + WIT_MARKER_SIZE/2))
        var autoPoint: Point2D = Point2D(xPos: Double(self.view.frame.origin.x + WIT_MARKER_SIZE/2 + 1000), yPos:Double(self.view.frame.origin.y + WIT_MARKER_SIZE/2))

        
        var line1: Line2D = Line2D(point1: centerPoint, point2: autoPoint)
        var line2: Line2D = Line2D(point1: centerPoint, point2: point)

        var angle: Double = Utils.angleBetween2DotsWithCenter(centerPoint, point1: autoPoint, point2: point)*/
        let offsetRad: Double = Utils.DegreesToRadians(offSet)
        dispatch_async(dispatch_get_main_queue()) {
            self.pointerView.transform = CGAffineTransformMakeRotation(CGFloat(offsetRad))
        }
    }
}