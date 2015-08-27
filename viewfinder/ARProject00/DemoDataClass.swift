//
//  DemoDataClass.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation

class DemoDataClass {
    
    let LVIV_ALTITUDE: Double = 280
    
    var objects: [WitObject] = [WitObject]()
    
    func initData() {
        //objects = self.generateLvivDemoObjects()
        objects = self.generateUSDemoObjects()
    }
    
    func generateLvivDemoObjects() -> [WitObject] {
        var objects:[WitObject] = [WitObject]()
        if let path = NSBundle.mainBundle().pathForResource("lviv_objects", ofType: "json")
        {
            if let jsonData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
            {
                if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
                {
                    var wits: NSArray = jsonResult["wits"] as! NSArray
                    return getWitObjectsFromJSONDict(wits)
                }
            }
        }
        
        return objects
    }
    
    func generateUSDemoObjects() -> [WitObject] {
        var objects:[WitObject] = [WitObject]()
        if let path = NSBundle.mainBundle().pathForResource("us_objects", ofType: "json")
        {
            if let jsonData = NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe, error: nil)
            {
                if let jsonResult: NSDictionary = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary
                {
                    var wits: NSArray = jsonResult["wits"] as! NSArray
                    return getWitObjectsFromJSONDict(wits)
                }
            }
        }
        return objects
    }
    
    func getWitObjectsFromJSONDict(elements: NSArray) -> [WitObject] {
        var objects:[WitObject] = [WitObject]()
        
        for var i: Int = 0; i < elements.count; i++ {
            var dict: NSDictionary = elements.objectAtIndex(i) as! NSDictionary
            var lat: Double = dict["lat"] as! Double
            var lon: Double = dict["lon"] as! Double
            var alt: Double = dict["alt"] as! Double
            var metric: String = dict["altMeasure"] as! String
            
            if metric == "f" {
                alt = Utils.covertToMeters(alt)
            }
            
            var coord: WitCoordinate = WitCoordinate(lat: lat, lon: lon, alt: alt)
            var wit: WitObject = WitObject(coord: coord)
            wit.witName = dict["name"] as! String
            wit.witDescription = dict["description"] as! String
            wit.author = dict["author"] as! String
            objects.append(wit)
        }

        return objects
    }
}