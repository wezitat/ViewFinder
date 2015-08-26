//
//  GameViewController.swift
//  ARProject00
//
//  Created by Anton Semenyuk on 7/28/15.
//  Copyright (c) 2015 Techmagic. All rights reserved.
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
    func cameraMoved()
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func initialize3DSceneWithHeading(heading: CLLocationDirection) {
        //initialize everything with calibrated heading
        initializeCamera()
        initializeScene(heading)
    }
    
    func initializeCamera() {
        //capture video input in an AVCaptureLayerVideoPreviewLayer
        let captureSession = AVCaptureSession()
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        
        if let videoDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            var err: NSError? = nil
            if let videoIn : AVCaptureDeviceInput = AVCaptureDeviceInput.deviceInputWithDevice(videoDevice, error: &err) as? AVCaptureDeviceInput {
                if(err == nil){
                    if (captureSession.canAddInput(videoIn as AVCaptureInput)){
                        captureSession.addInput(videoIn as AVCaptureDeviceInput)
                    }
                    else {
                        println("Failed add video input.")
                    }
                }
                else {
                    println("Failed to create video input.")
                }
            }
            else {
                println("Failed to create video capture device.")
            }
        }
        captureSession.startRunning()        //add AVCaptureVideoPreviewLayer as sublayer of self.view.layer
        previewLayer.frame = self.view.bounds
        self.view.layer.addSublayer(previewLayer)

        //create a SceneView with a clear background color and add it as a subview of self.view
        sceneView = SCNView()
        sceneView.frame = self.view.bounds
        sceneView.backgroundColor = UIColor.clearColor()
        previewLayer.frame = self.view.bounds
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
        var angle: Float = (Float(M_PI) / 180.0) * Float(-currentHeading)
        geometryNode.pivot = SCNMatrix4MakeRotation(angle, 0, 0, 1)
        
        
        scene.rootNode.addChildNode(geometryNode)
        sceneView.scene = scene
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000000 //to draw objects very far from camera
        cameraNode.position = SCNVector3Make(0, 0, 0)
        scene.rootNode.addChildNode(cameraNode)
        
        ViewFinderManager.sharedInstance.startMotionManager()
        ViewFinderManager.sharedInstance.motionManager.delegate = self
        
        // add a tap gesture recognizer to reconize when user taps on objects
        let tapGesture = UITapGestureRecognizer(target: self, action: "handleTap:")
        var gestureRecognizers = [AnyObject]()
        gestureRecognizers.append(tapGesture)
        if let existingGestureRecognizers = sceneView.gestureRecognizers {
            gestureRecognizers.extend(existingGestureRecognizers)
        }
        sceneView.gestureRecognizers = gestureRecognizers
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(sceneView)
        if let hitResults = sceneView.hitTest(p, options: nil) {
            if hitResults.count > 0 {
                // retrieved the first clicked object
                let result: SCNHitTestResult! = hitResults[0] as! SCNHitTestResult
               
                //check what object user tapped and then show info about it
                for object in showingObject {
                    if result.node == object.objectGeometry {
                        if self.eventDelegate != nil {
                            self.eventDelegate.showObjectDetails(object)    
                        }
                    }
                }
            }
        }
    }
    
    func rotationChanged(orientation: SCNQuaternion) {
        cameraNode.orientation = orientation
        
        if self.eventDelegate != nil {
            self.eventDelegate.cameraMoved()
        }
    }
    
    func drasticDeviceMove() {
        //magic! somehow SceneKit rotates scene everytime we move the phone, so we need to rotate it back. We need to investigate in future if its scene rotating or camera.orientation (device.orientation) gives us always angle mistake
        //geometryNode.runAction(SCNAction.rotateByAngle(0.00022, aroundAxis: SCNVector3Make(0, 0, 1), duration: 0.1))
    }
    
    func altitudeUpdated(altitude: CLLocationDistance) {
        //altitude is ignored for a moment
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        cameraNode.position = SCNVector3Make(cameraNode.position.x , cameraNode.position.y, 0) //Float(altitude * DEFAULT_METR_SCALE))
        SCNTransaction.commit()
    }
    
    func locationUpdated(location: CLLocation) {
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        var point: Point2D = Utils.convertLLtoXY(ViewFinderManager.sharedInstance.centerPoint, newLocation: location)
        cameraNode.position = SCNVector3Make(Float(point.x) , Float(point.y), cameraNode.position.z)
        SCNTransaction.commit()
    }
    
    //display info text
    func showLocationInfo(string: String) {
        if eventDelegate != nil {
            eventDelegate.showTopInfo(string)
        }
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> Int {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return Int(UIInterfaceOrientationMask.AllButUpsideDown.rawValue)
        } else {
            return Int(UIInterfaceOrientationMask.All.rawValue)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func addWitObjects() {
        //init demo datas
        demoData.initData()
        showingObject = demoData.objects
        
        //add wit markers for objects
        for object in showingObject {
            
            if !object.is3D {
                var constraint:SCNTransformConstraint = SCNTransformConstraint(inWorldSpace: true, withBlock: { (node:SCNNode!, snmatrix:SCNMatrix4) -> SCNMatrix4 in
                    return snmatrix
                })
                object.objectGeometry.constraints = [SCNLookAtConstraint(target: cameraNode), constraint]
            }
            
            geometryNode.addChildNode(object.objectGeometry)
            if self.eventDelegate != nil {
                self.eventDelegate.addNewWitMarker(object)
            }
        }
        
        //add north pointer
        /*let redMaterial  = SCNMaterial()
        redMaterial.diffuse.contents = UIColor.redColor()
        redMaterial.locksAmbientWithDiffuse = true;
        
        var northGeometry: SCNNode = SCNNode()
        let sphere: SCNBox = SCNBox(width: 40, height: 40, length: 40, chamferRadius: 10)
        sphere.materials = [redMaterial]
        northGeometry = SCNNode(geometry: sphere)
        northGeometry.position = SCNVector3Make(0, 2000, 0)
        
        geometryNode.addChildNode(northGeometry)*/
    }
    
    
    func isNodeOnScreen(node: SCNNode) -> Bool {
        return sceneView.isNodeInsideFrustum(node, withPointOfView: cameraNode)
    }
    
    func sideOfNodeFromCamera(node: SCNNode) -> Bool {
        var leftSide: Bool = false
        
        
        var frontPoint: Point2D = Point2D()
        frontPoint.x = Double(0)
        frontPoint.y = Double(0)
        
        var backPoint: Point2D = Point2D()
        backPoint.x = -frontPoint.x
        backPoint.y = -frontPoint.y
        
        var nodePoint: Point2D = Point2D()
        nodePoint.x = Double(node.position.x)
        nodePoint.y = Double(node.position.y)
        
        leftSide = Utils.isPointLeft(frontPoint, b: backPoint, c: nodePoint)
        return leftSide
    }
}
