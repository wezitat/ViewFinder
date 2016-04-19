//
//  CustomLocationViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/14/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation

class CustomLocationViewController: UIViewController, CLLocationManagerDelegate {

    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var altitudeTextField: UITextField!
    
    @IBOutlet weak var getCoordsButton: UIButton!
    @IBOutlet weak var goTo3DSceneButton: UIButton!
    
    var debugLocationManager: DebugLocationManager! = DebugLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        debugLocationManager.locationManager!.delegate = self
        debugLocationManager.setStandardProperties()
        debugLocationManager.locationManager!.headingFilter = 0.5
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func getCoordsButtonPressed(sender: AnyObject) {
        
        latitudeTextField.text = "\((debugLocationManager.locationManager?.location?.coordinate.latitude)!)"
        longitudeTextField.text = "\((debugLocationManager.locationManager?.location?.coordinate.longitude)!)"
        altitudeTextField.text = "\((debugLocationManager.locationManager?.location?.altitude)!)"
        
    }
    
    //MARK: - IBActions
    
    @IBAction func goTo3DScene(sender: AnyObject) {
        
        if Float(latitudeTextField.text!) == nil || Float(longitudeTextField.text!) == nil || Float(altitudeTextField.text!) == nil  ||
            Float(latitudeTextField.text!)! < -90.0 || Float(latitudeTextField.text!)! > 90 || Float(longitudeTextField.text!)! < -180.0 ||
            Float(longitudeTextField.text!)! > 180.0 {
            
            let alertController: UIAlertController = UIAlertController(title: "Bad coords", message: "Enter correct coordinates", preferredStyle: .Alert)
            
            let okAction = UIAlertAction(title: "Ok", style: .Default) { (okAction) in
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            
            alertController.addAction(okAction)
            presentViewController(alertController, animated: true, completion: nil)
        } else {
            performSegueWithIdentifier("show3DScene", sender: self)
        }
    }
    
    //MARK: - Gesture recognizers
    
    @IBAction func viewTapped(sender: AnyObject) {
        view.endEditing(true)
    }
    
    //MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! Scene3DViewController
        
        let coords = CLLocationCoordinate2D(latitude: Double(latitudeTextField.text!)!,
                                            longitude: Double(longitudeTextField.text!)!)
        
        let location = CLLocation(coordinate: coords,
                                  altitude: Double(altitudeTextField.text!)!,
                                  horizontalAccuracy: (debugLocationManager.locationManager?.location?.horizontalAccuracy)!,
                                  verticalAccuracy: (debugLocationManager.locationManager?.location?.verticalAccuracy)!,
                                  timestamp: NSDate())
        
        vc.customLocation = location
    }
    
    
}
