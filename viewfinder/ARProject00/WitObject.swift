//
//  WitObject.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/12/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

let  WITOBJECT_BIGGEST_SIZE: Double = 20
let WITOBJECT_SMALLEST_SIZE: Double = 1

class WitObject {
    
    var witCoordinat: WitCoordinate = WitCoordinate(lat: 0, lon: 0, alt: 0)
    
    
    
    var        witName: String = ""
    var witDescription: String = ""
    var         author: String = ""
    
    
    
    
    init(coord: WitCoordinate) {
        witCoordinat = coord

    }
}
