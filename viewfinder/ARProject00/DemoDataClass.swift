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
    var objects: [WitObject] = [WitObject]()
    
    func initData() {
        let fileName: String = SettingManager.sharedInstance.getObjectFileValue()
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "json")
        {
            if let jsonData = try? NSData(contentsOfFile: path, options: .DataReadingMappedIfSafe)
            {
                if let jsonResult: NSDictionary = (try? NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions.MutableContainers)) as? NSDictionary
                {
                    let wits: NSArray = jsonResult["wits"] as! NSArray
                    objects = getWitObjectsFromJSONDict(wits)
                }
            }
        }

    }

    func getWitObjectsFromJSONDict(elements: NSArray) -> [WitObject] {
        var objects:[WitObject] = [WitObject]()
        
        for var i: Int = 0; i < 1; i++ {
            let dict: NSDictionary = elements.objectAtIndex(i) as! NSDictionary
            let lat: Double = dict["lat"] as! Double
            let lon: Double = dict["lon"] as! Double
            var alt: Double = dict["alt"] as! Double
            let metric: String = dict["altMeasure"] as! String
            
            if metric == "f" {
                alt = Utils.covertToMeters(alt)
            }
            
            let coord: WitCoordinate = WitCoordinate(lat: lat, lon: lon, alt: alt)
            let wit: WitObject = WitObject(coord: coord)
            wit.witName = dict["name"] as! String
            wit.witDescription = dict["description"] as! String
            wit.author = dict["author"] as! String
            objects.append(wit)
        }

        return objects
    }
}