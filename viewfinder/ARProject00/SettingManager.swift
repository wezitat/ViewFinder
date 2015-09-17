//
//  SettingManager.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/28/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation

class SettingManager {
    let ACCURACY: String = "LocationAccuracy"
    let EMAIL: String = "ClaimingEmail"
    let MARKER_NUMBER: String = "WitMarkersNumber"
    let OBJECTS_FILE: String = "WitObjectsFileName"
    let NEAR: String = "DistanceNear"
    let HERE: String = "DistanceHere"
    let HIDE_THERE_MARKERS = "HideThereMarkers"
    
    var settings: NSDictionary = NSDictionary()
    
    static let sharedInstance = SettingManager()
    
    func loadSettings() {
        let path: String = NSBundle.mainBundle().pathForResource("settings", ofType: "plist")!
        settings = NSDictionary(contentsOfFile: path)!
    }
    
    func getAccuracyValue() -> Double {
        if let accuracy = settings.objectForKey(ACCURACY) as? Double {
            return  accuracy
        }
        return 0
    }
    
    func getEmailValue() -> String {
        if let value = settings.objectForKey(EMAIL) as? String {
            return  value
        }
        return ""
    }
    
    func getObjectFileValue() -> String {
        if let value = settings.objectForKey(OBJECTS_FILE) as? String {
            return  value
        }
        return ""
    }
    
    func getWitMarkerNumberValue() -> Int {
        if let value = settings.objectForKey(MARKER_NUMBER) as? Int {
            return  value
        }
        return 0
    }
    
    func getNearNumberValue() -> Int {
        if let value = settings.objectForKey(NEAR) as? Int {
            return  value
        }
        return 0
    }
    
    func getHereNumberValue() -> Int {
        if let value = settings.objectForKey(HERE) as? Int {
            return  value
        }
        return 0
    }
    
    func getHideThereMarkesValue() -> Bool {
        if let value = settings.objectForKey(HIDE_THERE_MARKERS) as? Bool {
            return  value
        }
        return false
    }
    
    
}