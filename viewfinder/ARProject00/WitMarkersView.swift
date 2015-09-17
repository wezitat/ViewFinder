//
//  WitMarkersView.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/27/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
//

import Foundation
import UIKit

class WitMarkersView: UIView {
 
    override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
        let hitView: UIView = super.hitTest(point, withEvent: event)! 
        
        if hitView == self {
            return nil
        }
        return hitView
    }
}