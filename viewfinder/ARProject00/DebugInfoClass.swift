//
//  DebugInfoClass.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/25/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import UIKit

/** Class that show relevant data on device screen*/
class DebugInfoClass: NSObject, InfoLocationDelegate {

    let DEBUG_HEIGHT: CGFloat = 200
    let DEBUG_WIDTH: CGFloat = 200
    
    enum DebugStatus {
        case GettingLocation
        case SingleMessage
        case FullInfo
    }

    var debugInfoView: UIView! = nil
    var debugInfoLabel: UILabel! = nil
    var debugInfo: String = ""
    var isPortrait: Bool = false
    var generalStatus: String = "" //general message to show
    var initialPoint: String = "" //coordinates in Lat/Lon of (0,0) 3d scene point
    var currentPosition: String = "" //current position of user and camera
    var altitude: String = "" //current altitude of user and camera
    var distance: String = "" //distance from last detected location
    var updateTime: String = "" //time since last location update
    var accuracyTime: String = "" //accuracy of detected location
    
    var debugCompassView: UIImageView! = nil
    
    var fullMessageToShow: String = ""
    
    var debugStatus: DebugStatus = .FullInfo
    
    func initDebugViewPortraitOriented() {
        let screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        let screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        debugInfoView = UIView(frame: CGRectMake(CGFloat(screenRight - 20 - DEBUG_WIDTH), CGFloat(screenBottom - 20 - DEBUG_HEIGHT), DEBUG_WIDTH, DEBUG_HEIGHT))
        debugInfoLabel = UILabel(frame: CGRectMake(92, 4, DEBUG_WIDTH - 88, DEBUG_HEIGHT - 8))
        debugInfoLabel.numberOfLines = 0
        debugCompassView = UIImageView(frame: CGRectMake(0, 120, 80, 80))
        debugCompassView.contentMode = .ScaleAspectFit
        debugCompassView.image = UIImage(named: "compass")
        debugInfoLabel.font = UIFont.systemFontOfSize(10)
        debugInfoLabel.text = debugInfo
        debugInfoLabel.textAlignment = .Center
        debugInfoLabel.textColor = UIColor.whiteColor()
        debugInfoView.alpha = 0.5
        debugInfoView.addSubview(debugInfoLabel)
        debugInfoView.addSubview(debugCompassView)
        isPortrait = true
    }
    
    func initDebugViewLandscapeOriented() {
        let screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        let screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        debugInfoView = UIView(frame: CGRectMake(CGFloat(screenBottom - 20 - DEBUG_HEIGHT), CGFloat(screenRight - 20 - DEBUG_WIDTH), DEBUG_WIDTH, DEBUG_HEIGHT))
        debugInfoLabel = UILabel(frame: CGRectMake(92, 4, DEBUG_WIDTH - 88, DEBUG_HEIGHT - 8))
        debugInfoLabel.numberOfLines = 0
        debugCompassView = UIImageView(frame: CGRectMake(0, 120, 80, 80))
        debugCompassView.contentMode = .ScaleAspectFit
        debugCompassView.image = UIImage(named: "compass")
        debugInfoLabel.font = UIFont.systemFontOfSize(10)
        debugInfoLabel.text = debugInfo
        debugInfoLabel.textAlignment = .Center
        debugInfoLabel.textColor = UIColor.whiteColor()
        debugInfoView.alpha = 0.5
        debugInfoView.addSubview(debugInfoLabel)
        debugInfoView.addSubview(debugCompassView)
        isPortrait = false
    }
    
    func reorientPortrait() {
        isPortrait = true
        if debugInfoView != nil {
            let screenRight: CGFloat = UIScreen.mainScreen().bounds.width
            let screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
            debugInfoView.transform = CGAffineTransformMakeRotation(0);
            debugInfoView.frame = CGRectMake(CGFloat(screenRight - 20 - DEBUG_WIDTH), CGFloat(screenBottom - 20 - DEBUG_HEIGHT), DEBUG_WIDTH, DEBUG_HEIGHT)
        }
    }
    
    func reorientLanscape() {
        isPortrait = false
        let screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        let screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        if debugInfoView != nil {
            debugInfoView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
            debugInfoView.frame = CGRectMake(CGFloat(screenRight - 20 - DEBUG_HEIGHT), CGFloat(screenBottom - 20 - DEBUG_WIDTH), debugInfoView.frame.width, debugInfoView.frame.height)
        }
    }
    
    func updateDebugInfo() {
        if debugInfoLabel != nil {
            dispatch_async(dispatch_get_main_queue(), {
                let attrString: NSMutableAttributedString = NSMutableAttributedString(string: " \(self.fullMessageToShow) ")
                attrString.addAttribute(NSBackgroundColorAttributeName, value: UIColor.blackColor(), range: NSMakeRange(0, attrString.length))
                self.debugInfoLabel.attributedText = attrString
            })
        }
    }
    
    func locationUpdated(location: String) {
        currentPosition = location
        generateDebugMessage()
    }
    func locationDistanceUpdated(dist: String) {
        distance = "\(dist) m"
        generateDebugMessage()
    }
    func altitudeUpdated(alt: Int) {
        altitude = "\(alt) m"
        generateDebugMessage()
    }
    func accuracyUpdated(acc: Int) {
        accuracyTime = "\(acc) m"
        generateDebugMessage()
    }
    func lastTimeLocationUpdate(timeUpdate: Int) {
        updateTime = "\(timeUpdate) sec"
        generateDebugMessage()
    }
    
    func retrievingLocationStatus(string: String) {
        generalStatus = string
        debugStatus = .GettingLocation
        generateDebugMessage()
    }
    
    func singleStatus(string: String) {
        generalStatus = string
        debugStatus = .SingleMessage
        generateDebugMessage()
    }
    
    func angleUpdated(angle: CGFloat) {
        let ang: CGFloat = 360 - angle
        let angleR: CGFloat = CGFloat(Utils.DegreesToRadians(Double(ang)))
        dispatch_async(dispatch_get_main_queue()) {
            self.debugCompassView.transform = CGAffineTransformMakeRotation(angleR)
        }
    }
    
    func fullInfo() {
        debugStatus = .FullInfo
        generateDebugMessage()
    }
    
    func generateDebugMessage() {
        if debugStatus == .GettingLocation {
           fullMessageToShow = "\(generalStatus) \n Accuracy: \(accuracyTime)\n Last update: \(updateTime)"
        }
        if debugStatus == .SingleMessage {
           fullMessageToShow = "\(generalStatus)"
        }
        if debugStatus == .FullInfo {
            let initialPoint: String = "\nlat:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.latitude)\n lon:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.longitude)\n alt:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.latitude)"
            fullMessageToShow = "Init.Point: \(initialPoint)\n\nCur.point: \n\(currentPosition)\n\nDistance: \(distance)\n\nCur.Altitute: \(altitude)\n\nAccuracy: \(accuracyTime)\n\nLast update: \(updateTime)"
        }

        updateDebugInfo()
    }
}