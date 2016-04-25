//
//  TopViewController.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 8/6/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation

/** TopViewController - is a class which represent upper layer of app.
    It shows all the statuses and WitMarkers. Can be used to
    represent additional GUI */

class TopViewController: WrapperBaseViewController {
    
    @IBOutlet weak var refreshSceneButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshSceneButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        
        if parent == nil {
            Brain.sharedInstance.resetManager()
        }
    }
    
    override func refreshStage() {
        //reset whole information in app
        self.refreshSceneButton.enabled = false
        //self.sceneController.resetScene()
        
        super.refreshStage()
    }
    
    override func initializeScene() {
        super.initializeScene()
        
        if Brain.sharedInstance.getGameViewController() != nil {
            refreshSceneButton.enabled = true
        }
    }
    
    @IBAction func handleDebugButton(sender: UIButton) {
        debugView.hidden = !debugView.hidden
        refreshSceneButton.hidden = !refreshSceneButton.hidden
        
        if debugView.hidden {
            sender.backgroundColor = UIColor.darkGrayColor()
        } else {
            sender.backgroundColor = UIColor.redColor()
        }
    }
    
    @IBAction func handleRefreshButton(sender: UIButton) {
        self.refreshStage()
    }
    
}