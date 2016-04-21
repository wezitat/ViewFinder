//
//  WrapperSceneDelegate.swift
//  ARProject00
//
//  Created by Ihor on 4/18/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import Foundation
import CoreLocation
import UIKit

protocol WrapperSceneDelegate {
    func getWitMarkers() -> [WitMarker]
    func updateWrapperPointIfObjectIsBehind(point: Point3D) -> Point3D
    func headingUpdated(heading: CLLocationDirection)
    func initLocationReceived()
    func rotationAngleUpdated(angle: Double)
    func showObjectDetails(wObject: WitObject)
    func addNewWitMarker(wObject: WitObject)
    func filterWitMarkers()
    func distanceUpdated(location: CLLocation)
}
