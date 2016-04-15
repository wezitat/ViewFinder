//
//  LocationDebugViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/12/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation

class LocationDebugViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var compassImageView: UIImageView!
    
    @IBOutlet weak var latitudeLabel:  UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel:  UILabel!
    @IBOutlet weak var headingLabel:   UILabel!
    @IBOutlet weak var locationUpdateLabel: UILabel!
    @IBOutlet weak var headingUpdateLabel: UILabel!
    @IBOutlet weak var backButton: UIBarButtonItem!
    @IBOutlet weak var distanceAccuraceLabel: UILabel!
    @IBOutlet weak var headingFilterLabel: UILabel!
    @IBOutlet weak var distanceFilterLabel: UILabel!

    var debugLocationManager: DebugLocationManager! = DebugLocationManager()
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        compassImageView.image = UIImage(named: "compass")
        
        debugLocationManager.locationManager!.delegate = self
        
        debugLocationManager.setStandardProperties()
    
        debugLocationManager.locationManager!.headingFilter = 0.5
        
        headingFilterLabel.text = "\((debugLocationManager.locationManager!.headingFilter)) angles"
        distanceAccuraceLabel.text = "Best"
        distanceFilterLabel.text = "None (any movement)"
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        if parent == nil {
            debugLocationManager.invalidateTimers()
            debugLocationManager = nil
        }
    }
    
    // MARK: - Location Manager Delegate
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        
        debugLocationManager.timePassedFromLastHeadingUpdate = 0
        
        headingUpdateLabel.text = "0 seconds"
        
        debugLocationManager.headingTimer?.invalidate()
        
        debugLocationManager.headingTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                       target: self,
                                                       selector: #selector(headingInformationUpdated),
                                                       userInfo: nil,
                                                       repeats: true)
        
        if newHeading.headingAccuracy < 0 {
            return
        }
        
        let heading: CLLocationDirection = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)
        
        headingLabel.text = "\(heading)"
        
        print("heading = \(heading)")
        
        compassImageView.transform = CGAffineTransformMakeRotation(-CGFloat((heading*M_PI)/180.0))
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        debugLocationManager.timePassedFromLastLocationUpdate = 0
        
        locationUpdateLabel.text = "0 seconds"
        
        debugLocationManager.locationTimer?.invalidate()
        debugLocationManager.locationTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                               target: self,
                                                               selector: #selector(locationInformationUpdated),
                                                               userInfo: nil,
                                                               repeats: true)
        
        let location: CLLocation = locations.last!
        
        altitudeLabel.text = "\(location.altitude)"
        latitudeLabel.text = "\(location.coordinate.latitude)"
        longitudeLabel.text = "\(location.coordinate.longitude)"
        
        print("Altitude  = \(location.altitude)")
        print("Latitude  = \(location.coordinate.latitude)")
        print("Longitude = \(location.coordinate.longitude)")
    }

    // MARK: - Selectors
    
    func headingInformationUpdated() {
        debugLocationManager.timePassedFromLastHeadingUpdate += 1
        headingUpdateLabel.text = "\(debugLocationManager.timePassedFromLastHeadingUpdate) seconds"
    }
    
    func locationInformationUpdated() {
        debugLocationManager.timePassedFromLastLocationUpdate += 1
        locationUpdateLabel.text = "\(debugLocationManager.timePassedFromLastLocationUpdate) seconds"
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
