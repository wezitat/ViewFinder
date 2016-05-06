//
//  LocationDebugViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/12/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation
import LocationKit

class LocationDebugViewController: UIViewController, UIProtocol {

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

    var locationTimer: NSTimer? = nil
    var headingTimer:  NSTimer? = nil
    
    var timePassedFromLastHeadingUpdate: Int = 0
    var timePassedFromLastLocationUpdate: Int = 0
    
    @IBAction func backButtonPressed(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        Brain.sharedInstance.setTopViewController(self)
        
        Brain.sharedInstance.startLocationManager()
        Brain.sharedInstance.locationManager.startUpdating()
        
        compassImageView.image = UIImage(named: "compass")
        
        headingFilterLabel.text = "\((Brain.sharedInstance.locationManager.manager.headingFilter)) angles"
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
            invalidateTimers()
            Brain.sharedInstance.locationManager.stopUpdating()
        }
    }
    
    func invalidateTimers() {
        locationTimer?.invalidate()
        headingTimer?.invalidate()
        
        locationTimer = nil
        headingTimer = nil
    }

    //MARK: - UIProtocol
    
    func applicationLaunched() {
        
    }
    
    func headingDirectionUpdated(newHeading: CLHeading) {
        
        timePassedFromLastHeadingUpdate = 0
        
        headingUpdateLabel.text = "0 seconds"
        
        headingTimer?.invalidate()
        headingTimer = NSTimer.scheduledTimerWithTimeInterval(1,
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
    
    func locationUpdated(location: CLLocation) {
        
        timePassedFromLastLocationUpdate = 0
        
        locationUpdateLabel.text = "0 seconds"
        
        locationTimer?.invalidate()
        locationTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                               target: self,
                                                               selector: #selector(locationInformationUpdated),
                                                               userInfo: nil,
                                                               repeats: true)
        
        altitudeLabel.text = "\(location.altitude)"
        latitudeLabel.text = "\(location.coordinate.latitude)"
        longitudeLabel.text = "\(location.coordinate.longitude)"
        
        print("Altitude  = \(location.altitude)")
        print("Latitude  = \(location.coordinate.latitude)")
        print("Longitude = \(location.coordinate.longitude)")
    }
    
    // MARK: - Location Manager Delegate
    
//    func locationManager(manager: LKLocationManager, didUpdateHeading newHeading: CLHeading) {
//        
//        debugLocationManager?.timePassedFromLastHeadingUpdate = 0
//        
//        headingUpdateLabel.text = "0 seconds"
//        
//        debugLocationManager?.headingTimer?.invalidate()
//        
//        debugLocationManager?.headingTimer = NSTimer.scheduledTimerWithTimeInterval(1,
//                                                       target: self,
//                                                       selector: #selector(headingInformationUpdated),
//                                                       userInfo: nil,
//                                                       repeats: true)
//        
//        if newHeading.headingAccuracy < 0 {
//            return
//        }
//        
//        let heading: CLLocationDirection = ((newHeading.trueHeading > 0) ? newHeading.trueHeading : newHeading.magneticHeading)
//        
//        headingLabel.text = "\(heading)"
//        
//        print("heading = \(heading)")
//        
//        compassImageView.transform = CGAffineTransformMakeRotation(-CGFloat((heading*M_PI)/180.0))
//    }
//    
//    func locationManager(manager: LKLocationManager, didUpdateLocations locations: [CLLocation]) {
//        
//        debugLocationManager?.timePassedFromLastLocationUpdate = 0
//        
//        locationUpdateLabel.text = "0 seconds"
//        
//        debugLocationManager?.locationTimer?.invalidate()
//        debugLocationManager?.locationTimer = NSTimer.scheduledTimerWithTimeInterval(1,
//                                                               target: self,
//                                                               selector: #selector(locationInformationUpdated),
//                                                               userInfo: nil,
//                                                               repeats: true)
//        
//        let location: CLLocation = locations.last!
//        
//        altitudeLabel.text = "\(location.altitude)"
//        latitudeLabel.text = "\(location.coordinate.latitude)"
//        longitudeLabel.text = "\(location.coordinate.longitude)"
//        
//        print("Altitude  = \(location.altitude)")
//        print("Latitude  = \(location.coordinate.latitude)")
//        print("Longitude = \(location.coordinate.longitude)")
//    }

    // MARK: - Selectors
    
    func headingInformationUpdated() {
        timePassedFromLastHeadingUpdate += 1
        headingUpdateLabel.text = "\(timePassedFromLastHeadingUpdate) seconds"
    }
    
    func locationInformationUpdated() {
        timePassedFromLastLocationUpdate += 1
        locationUpdateLabel.text = "\(timePassedFromLastLocationUpdate) seconds"
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
