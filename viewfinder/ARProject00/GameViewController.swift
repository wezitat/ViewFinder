//
//  GameViewController.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Wezitat. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import CoreMotion
import CoreLocation
import AVFoundation

protocol SceneEventsDelegate {
    func showTopInfo(string: String)
    func showObjectDetails(wObject: WitObject)
    func addNewWitMarker(wObject: WitObject)
    func filterWitMarkers()
    func cameraMoved()
    func locationUpdated(location: CLLocation)
}

/** GameViewController - class that draws all the 3D scene.
    */

class GameViewController: UIViewController {

    var eventDelegate: SceneEventsDelegate! = nil
    
    var demoData: DemoDataClass = DemoDataClass()
    var showingObject: [WitObject] = [WitObject]()
    
    // Geometry
    
    //main node of scene
    var geometryNode: SCNNode = SCNNode()
    
    //node of camera
    var cameraNode: SCNNode = SCNNode()
    var sceneView: SCNView = SCNView()
    
    var deviceCameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ViewFinderManager.sharedInstance.setGameViewController(self)
    }
    
    //function which reset scene (removes all objects from 3d scene)
    func resetScene() {
        deviceCameraLayer.removeFromSuperlayer()
        
        let scene = SCNScene()
        
        sceneView.scene = scene
    }
    
    func initialize3DSceneWithHeading(heading: CLLocationDirection) {
        //initialize everything with calibrated heading
        initializeCamera()
        initializeScene(heading)
        
        //update altitude
        ViewFinderManager.sharedInstance.altitudeUpdated(ViewFinderManager.sharedInstance.centerAltitude)
    }
    
    func initializeCamera() {
        //capture video input in an AVCaptureLayerVideoPreviewLayer
        let captureSession = AVCaptureSession()
        
        deviceCameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        deviceCameraLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            let err: NSError? = nil
            do {
                guard let videoIn : AVCaptureDeviceInput = try AVCaptureDeviceInput(device: videoDevice) else { return }
                if err == nil {
                    if captureSession.canAddInput(videoIn as AVCaptureInput) {
                        captureSession.addInput(videoIn as AVCaptureDeviceInput)
                    } else {
                        print("Failed add video input.")
                    }
                } else {
                    print("Failed to create video input.")
                }
            } catch {
                print("Failed to create video capture device.")
            }
        }
        
        captureSession.startRunning()        //add AVCaptureVideoPreviewLayer as sublayer of self.view.layer
        
        deviceCameraLayer.frame = self.view.bounds
        
        self.view.layer.addSublayer(deviceCameraLayer)

        //create a SceneView with a clear background color and add it as a subview of self.view
        sceneView = SCNView()
        sceneView.frame = self.view.bounds
        sceneView.backgroundColor = UIColor.clearColor()
        
        deviceCameraLayer.frame = self.view.bounds
        
        self.view.addSubview(sceneView)
    }
   
    func initializeScene(currentHeading: CLLocationDirection) {
        //now you could begin to build your scene with the device's camera video as your background
        let scene = SCNScene()
        
        sceneView.autoenablesDefaultLighting = true
        sceneView.allowsCameraControl = false
        
        //add all wits on scene
        addWitObjects()
        
        //rotate all scene based on heading so Oy will be heading on north
        let angle: Float = (Float(M_PI)/180.0)*Float(-currentHeading)
        
        geometryNode.pivot = SCNMatrix4MakeRotation(angle, 0, 0, 1)
        
        
        scene.rootNode.addChildNode(geometryNode)
        
        sceneView.scene = scene
        
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000000 //to draw objects very far from camera
        cameraNode.position = SCNVector3Make(0, 0, Float(ViewFinderManager.sharedInstance.centerAltitude))
        
        scene.rootNode.addChildNode(cameraNode)
        
        ViewFinderManager.sharedInstance.startMotionManager()
        ViewFinderManager.sharedInstance.setMotionManagerDelegate(ViewFinderManager.sharedInstance)
        
        // add a tap gesture recognizer to reconize when user taps on objects
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        var gestureRecognizers = [AnyObject]()
        
        gestureRecognizers.append(tapGesture)
        
        if let existingGestureRecognizers = sceneView.gestureRecognizers {
            gestureRecognizers.append(existingGestureRecognizers)
        }
        
        sceneView.gestureRecognizers = gestureRecognizers as? [UIGestureRecognizer]
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(sceneView)
        
        if let hitResults: [SCNHitTestResult]? = sceneView.hitTest(p, options: nil) {
            if hitResults!.count > 0 {
                // retrieved the first clicked object
                let result: SCNHitTestResult! = hitResults![0]
               
                //check what object user tapped and then show info about it
                for object in showingObject {
                    if result.node == object.objectGeometry {
                        if eventDelegate != nil {
                            object.isClaimed = true
                            eventDelegate.showObjectDetails(object)
                        }
                    }
                }
            }
        }
    }
    
    //display info text
    func showLocationInfo(string: String) {
        eventDelegate?.showTopInfo(string)
    }
    
    func addWitObjects() {
        //init demo datas
        demoData.initData()
        showingObject = demoData.objects
        
        //add wit markers for objects
        for object in showingObject {
            
            geometryNode.addChildNode(object.objectGeometry)
            
            eventDelegate?.addNewWitMarker(object)
        }
        
        eventDelegate?.filterWitMarkers()
    }
    
    
    func isNodeOnScreen(node: SCNNode) -> Bool {
        //chech if node is visible for a user
        return sceneView.isNodeInsideFrustum(node, withPointOfView: cameraNode)
    }
    
    func nodePosToScreenCoordinates(node: SCNNode) -> Point3D {
        //get position of object in screen coordinates
        let worldMat: SCNMatrix4 = node.worldTransform
        let worldPos: SCNVector3 = SCNVector3(x: worldMat.m41, y: worldMat.m42, z: worldMat.m43)

        let pos: SCNVector3 = sceneView.projectPoint(worldPos)
        
        return Point3D(xPos:  Double(pos.x), yPos: Double(pos.y), zPos: Double(pos.z))
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

}
