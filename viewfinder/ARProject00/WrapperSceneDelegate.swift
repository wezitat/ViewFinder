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
    func getAppStatus() -> AppStatus
    func getCalibratedHeading() -> CLLocationDirection
    func isHeadingStable() -> Bool
    func setStable(stable: Bool)
    func startWrapperHeadingDataGatheringTimer()
    func stopWrapperHeadingDataGatheringTimer()
    func setWrapperCalibratedHeading(heading: CLLocationDirection)
    func retrieveWrapperInitialHeading()
    func getWitMarkers() -> [WitMarker]
    func setDetailsHeaderText(string: String)
    func setDetailsDescriptionText(string: String)
    func setDetailsViewHidden(bool: Bool)
    func witMarkersAppend(marker: WitMarker)
    func markerViewAddSubview(view: UIView)
    func setWrapperWitMarkers(wits: [WitMarker])
    func updateWrapperPointIfObjectIsBehind(point: Point3D) -> Point3D
}
