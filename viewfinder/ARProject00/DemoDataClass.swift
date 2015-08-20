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
        //objects = self.generateLvivDemoObjects()
        objects = self.generateUSDemoObjects()
    }
    
    func generateLvivDemoObjects() -> [WitObject] {
        var opera: CLLocation = CLLocation(latitude: 49.843698, longitude: 24.026441)
        var ratusha: CLLocation = CLLocation(latitude: 49.841835, longitude: 24.031209)
        var danylo: CLLocation = CLLocation(latitude: 49.839453, longitude: 24.032518)
        var arsenal: CLLocation = CLLocation(latitude: 49.841353, longitude: 24.035234)
        var ibis: CLLocation = CLLocation(latitude: 49.837170, longitude: 24.034747)
        
        var objects: [WitObject] = [WitObject]()
        
        var coor: WitCoordinate = WitCoordinate(lat: opera.coordinate.latitude, lon: opera.coordinate.longitude, alt: 0)
        var witObject: WitObject = WitObject(coord: coor)
        witObject.witName = "Opera"
        witObject.witDescription = "Main opera house of Lviv"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: ratusha.coordinate.latitude, lon: ratusha.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "Ratusha"
        witObject.witDescription = "City Inn building"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: danylo.coordinate.latitude, lon: danylo.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "Danylo Galytskyi Monument"
        witObject.witDescription = "Monument of Lviv city founder"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: arsenal.coordinate.latitude, lon: arsenal.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "Arsenal"
        witObject.witDescription = "Main defensive structure of old Lviv"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: ibis.coordinate.latitude, lon: ibis.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "Ibis"
        witObject.witDescription = "Hotel"
        objects.append(witObject)
        
        return objects
    }
    
    func generateUSDemoObjects() -> [WitObject] {
        var hooverTower: CLLocation = CLLocation(latitude: -122.1669495, longitude: 37.427604)
        var rodin: CLLocation = CLLocation(latitude: -122.1695673, longitude: 37.4278341)
        var memChurch: CLLocation = CLLocation(latitude: -122.170479299999, longitude: 37.4268883)
        var volleyballLawn: CLLocation = CLLocation(latitude: -122.1692241, longitude: 37.4305689)
        var myLocation: CLLocation = CLLocation(latitude: -122.170093099999, longitude: 37.4280726)
        var samuels: CLLocation = CLLocation(latitude: -122.1630764, longitude: 37.420072)
        var hospital: CLLocation = CLLocation(latitude: -122.1768522, longitude: 37.432886)
        var home: CLLocation = CLLocation(latitude: -122.155652, longitude: 37.4198675)
        var ducks: CLLocation = CLLocation(latitude: -122.1763802, longitude: 37.4234802)
        var dSchool: CLLocation = CLLocation(latitude: -122.1719491, longitude: 37.4264112)
        var markOffice: CLLocation = CLLocation(latitude: -122.1688056, longitude: 37.4270119)
        var mamaOffice: CLLocation = CLLocation(latitude: -122.1633554, longitude: 37.4282856)
        var shops: CLLocation = CLLocation(latitude: -122.1716595, longitude: 37.4447443)
        var schoolField: CLLocation = CLLocation(latitude: -122.1529055, longitude: 37.4350672)
        var bench: CLLocation = CLLocation(latitude: -122.1704471, longitude: 37.4281493)
        var oval: CLLocation = CLLocation(latitude: -122.1696854, longitude: 37.4291717)
        
        var objects: [WitObject] = [WitObject]()
        
        var coor: WitCoordinate = WitCoordinate(lat: hooverTower.coordinate.latitude, lon: hooverTower.coordinate.longitude, alt: 0)
        var witObject: WitObject = WitObject(coord: coor)
        witObject.witName = "w1"
        witObject.witDescription = "hoover tower"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: rodin.coordinate.latitude, lon: rodin.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w2"
        witObject.witDescription = "rodin"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: memChurch.coordinate.latitude, lon: memChurch.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w3"
        witObject.witDescription = "memChurch"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: volleyballLawn.coordinate.latitude, lon: volleyballLawn.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w4"
        witObject.witDescription = "volleyballLawn"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: myLocation.coordinate.latitude, lon: myLocation.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w5"
        witObject.witDescription = "myLocation"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: samuels.coordinate.latitude, lon: samuels.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w6"
        witObject.witDescription = "samuels"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: hospital.coordinate.latitude, lon: hospital.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w7"
        witObject.witDescription = "hospital"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: home.coordinate.latitude, lon: home.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w8"
        witObject.witDescription = "home"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: ducks.coordinate.latitude, lon: ducks.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w9"
        witObject.witDescription = "ducks"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: dSchool.coordinate.latitude, lon: dSchool.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w10"
        witObject.witDescription = "rodin"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: markOffice.coordinate.latitude, lon: markOffice.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w11"
        witObject.witDescription = "markOffice"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: mamaOffice.coordinate.latitude, lon: mamaOffice.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w12"
        witObject.witDescription = "mamaOffice"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: shops.coordinate.latitude, lon: shops.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w13"
        witObject.witDescription = "shops"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: schoolField.coordinate.latitude, lon: schoolField.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w14"
        witObject.witDescription = "schoolField"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: bench.coordinate.latitude, lon: bench.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w15"
        witObject.witDescription = "bench"
        objects.append(witObject)
        
        coor = WitCoordinate(lat: oval.coordinate.latitude, lon: oval.coordinate.longitude, alt: 0)
        witObject = WitObject(coord: coor)
        witObject.witName = "w16"
        witObject.witDescription = "oval"
        objects.append(witObject)
        
        return objects
        
    }
}