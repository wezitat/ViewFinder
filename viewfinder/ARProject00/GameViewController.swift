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
    func showTopInfo(strign: String)
    func showObjectDetails(wObject: WitObject)
    func addNewWitMarker(wObject: WitObject)
    func filterWitMarkers()
    func cameraMoved()
    func locationUpdated(location: CLLocation)
}

/** GameViewController - class that draws all the 3D scene.
    */

class GameViewController: UIViewController, MotionManagerDelegate, LocationManagerDelegate {

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
        self.altitudeUpdated(ViewFinderManager.sharedInstance.centerAltitude)
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
                if(err == nil){
                    if (captureSession.canAddInput(videoIn as AVCaptureInput)){
                        captureSession.addInput(videoIn as AVCaptureDeviceInput)
                    }
                    else {
                        print("Failed add video input.")
                    }
                }
                else {
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
        let angle: Float = (Float(M_PI) / 180.0) * Float(-currentHeading)
        geometryNode.pivot = SCNMatrix4MakeRotation(angle, 0, 0, 1)
        
        
        scene.rootNode.addChildNode(geometryNode)
        sceneView.scene = scene
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000000 //to draw objects very far from camera
        cameraNode.position = SCNVector3Make(0, 0, Float(ViewFinderManager.sharedInstance.centerAltitude))
        scene.rootNode.addChildNode(cameraNode)
        
        ViewFinderManager.sharedInstance.startMotionManager()
        ViewFinderManager.sharedInstance.motionManager.delegate = self
        
        // add a tap gesture recognizer to reconize when user taps on objects
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
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
                        if self.eventDelegate != nil {
                            object.isClaimed = true
                            self.eventDelegate.showObjectDetails(object)
                        }
                    }
                }
            }
        }
    }
    
    func rotationChanged(orientation: SCNQuaternion) {
        //user moved camera and pointing of camera changed
        cameraNode.orientation = orientation
        
        if self.eventDelegate != nil {
            self.eventDelegate.cameraMoved()
        }
    }
    
    func altitudeUpdated(altitude: CLLocationDistance) {
        //altitude of user location is updated
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        cameraNode.position = SCNVector3Make(cameraNode.position.x , cameraNode.position.y, Float(altitude * DEFAULT_METR_SCALE))
        SCNTransaction.commit()
    }
    
    func locationUpdated(location: CLLocation) {
        //user location updated. move camera on new position in 3d scene
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        let point: Point2D = Utils.convertLLtoXY(ViewFinderManager.sharedInstance.centerPoint, newLocation: location)
        cameraNode.position = SCNVector3Make(Float(point.x) , Float(point.y), cameraNode.position.z)
        for object in showingObject {
            object.updateWitObjectSize(location)
        }
        SCNTransaction.commit()
        if eventDelegate != nil {
            eventDelegate.locationUpdated(location)
        }
    }
    
    //display info text
    func showLocationInfo(string: String) {
        if eventDelegate != nil {
            eventDelegate.showTopInfo(string)
        }
    }
    
    func addWitObjects() {
        //init demo datas
        demoData.initData()
        showingObject = demoData.objects
        
        //add wit markers for objects
        for object in showingObject {
            
            geometryNode.addChildNode(object.objectGeometry)
            if self.eventDelegate != nil {
                self.eventDelegate.addNewWitMarker(object)
            }
        }
        if self.eventDelegate != nil {
            self.eventDelegate.filterWitMarkers()
        }
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
        let point: Point3D = Point3D(xPos:  Double(pos.x), yPos: Double(pos.y), zPos: Double(pos.z))
        return point
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
    
    func drasticDeviceMove() {
    }
}
