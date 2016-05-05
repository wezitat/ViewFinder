//
//  UIProtocol.swift
//  ARProject00
//
//  Created by Ihor on 5/5/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import Foundation

protocol UIProtocol {
    func applicationLaunched()
    func locationUpdated(location: CLLocation)
    func headingDirectionUpdated(heading: CLHeading)
}