//
//  DebugInfoClass.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/25/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import UIKit

/** Class that show relevant data on device screen*/
class DebugInfoClass: NSObject, InfoLocationDelegate {

    let DEBUG_HEIGHT: CGFloat = 200
    let DEBUG_WIDTH: CGFloat = 120
    
    enum DebugStatus {
        case GettingLocation
        case SingleMessage
        case FullInfo
    }

    var debugInfoView: UIView! = nil
    var debugInfoLabel: UILabel! = nil
    var debugInfo: String = ""
    
    var generalStatus: String = "" //general message to show
    var initialPoint: String = "" //coordinates in Lat/Lon of (0,0) 3d scene point
    var currentPosition: String = "" //current position of user and camera
    var altitude: String = "" //current altitude of user and camera
    var distance: String = "" //distance from last detected location
    var updateTime: String = "" //time since last location update
    var accuracyTime: String = "" //accuracy of detected location
    
    var fullMessageToShow: String = ""
    
    var debugStatus: DebugStatus = .FullInfo
    
    func initDebugViewPortraitOriented() {
        var screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        var screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        debugInfoView = UIView(frame: CGRectMake(CGFloat(screenRight - 20 - DEBUG_WIDTH), CGFloat(screenBottom - 20 - DEBUG_HEIGHT), DEBUG_WIDTH, DEBUG_HEIGHT))
        debugInfoLabel = UILabel(frame: CGRectMake(4, 4, DEBUG_WIDTH - 8, DEBUG_HEIGHT - 8))
        debugInfoLabel.numberOfLines = 0
        debugInfoLabel.font = UIFont.systemFontOfSize(10)
        debugInfoLabel.text = debugInfo
        debugInfoLabel.textAlignment = .Center
        debugInfoLabel.textColor = UIColor.whiteColor()
        debugInfoView.alpha = 0.5
        debugInfoView.addSubview(debugInfoLabel)
    }
    
    func initDebugViewLandscapeOriented() {
        var screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        var screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        debugInfoView = UIView(frame: CGRectMake(CGFloat(screenBottom - 20 - DEBUG_HEIGHT), CGFloat(screenRight - 20 - DEBUG_WIDTH), DEBUG_WIDTH, DEBUG_HEIGHT))
        debugInfoLabel = UILabel(frame: CGRectMake(4, 4, DEBUG_WIDTH - 8, DEBUG_HEIGHT - 8))
        debugInfoLabel.numberOfLines = 0
        debugInfoLabel.font = UIFont.systemFontOfSize(10)
        debugInfoLabel.text = debugInfo
        debugInfoLabel.textAlignment = .Center
        debugInfoLabel.textColor = UIColor.whiteColor()
        debugInfoView.alpha = 0.5
        debugInfoView.addSubview(debugInfoLabel)
    }
    
    func reorientPortrait() {
        if debugInfoView != nil {
            var screenRight: CGFloat = UIScreen.mainScreen().bounds.width
            var screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
            debugInfoView.transform = CGAffineTransformMakeRotation(0);
            debugInfoView.frame = CGRectMake(CGFloat(screenRight - 20 - DEBUG_WIDTH), CGFloat(screenBottom - 20 - DEBUG_HEIGHT), DEBUG_WIDTH, DEBUG_HEIGHT)
        }
    }
    
    func reorientLanscape() {
        var screenRight: CGFloat = UIScreen.mainScreen().bounds.width
        var screenBottom: CGFloat = UIScreen.mainScreen().bounds.height
        if debugInfoView != nil {
            debugInfoView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2));
            debugInfoView.frame = CGRectMake(CGFloat(screenRight - 20 - DEBUG_HEIGHT), CGFloat(screenBottom - 20 - DEBUG_WIDTH), debugInfoView.frame.width, debugInfoView.frame.height)
        }
    }
    
    func updateDebugInfo() {
        if debugInfoLabel != nil {
            dispatch_async(dispatch_get_main_queue(), {
                var attrString: NSMutableAttributedString = NSMutableAttributedString(string: " \(self.fullMessageToShow) ")
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
            var initialPoint: String = "lat:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.latitude) lon:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.longitude) alt:\(ViewFinderManager.sharedInstance.centerPoint.coordinate.latitude)"
            fullMessageToShow = "Init.Point: \(initialPoint)\n\nCur.point: \(currentPosition)\n\nDistance: \(distance)\n\nCur.Altitute: \(altitude)\n\nAccuracy: \(accuracyTime)\n\nLast update: \(updateTime)"
        }

        updateDebugInfo()
    }
}