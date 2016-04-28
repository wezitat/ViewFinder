//
//  RenderingBaseViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/21/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation
import CoreMotion
import SceneKit
import AVFoundation

protocol SceneEventsDelegate {
    func showObjectDetails(result: SCNHitTestResult)
    func addNewWitMarker(wObject: WitObject)
    func filterWitMarkers()
    func cameraMoved()
    func distanceUpdated(location: CLLocation)
}

class RenderingBaseViewController: UIViewController, RenderingSceneDelegate {

    var eventDelegate: SceneEventsDelegate! = nil
    
    // Geometry
    
    //main node of scene
    var geometryNode: SCNNode = SCNNode()
    
    //node of camera
    var cameraNode: SCNNode = SCNNode()
    var sceneView: SCNView = SCNView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
    
    var deviceCameraLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Brain.sharedInstance.setGameViewController(self)
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
        altitudeUpdated(Brain.sharedInstance.centerAltitude)
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
        
        //rotate all scene based on heading so Oy will be heading on north
        let angle: Float = (Float(M_PI)/180.0)*Float(-currentHeading)
        
        geometryNode.pivot = SCNMatrix4MakeRotation(angle, 0, 0, 1)
        
        
        scene.rootNode.addChildNode(geometryNode)
        
        sceneView.scene = scene
        
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.zFar = 1000000 //to draw objects very far from camera
        cameraNode.position = SCNVector3Make(0, 0, Float(Brain.sharedInstance.centerAltitude))
        
        scene.rootNode.addChildNode(cameraNode)
        
        Brain.sharedInstance.startMotionManager()
        Brain.sharedInstance.setMotionManagerDelegate(Brain.sharedInstance)
        
        // add a tap gesture recognizer to reconize when user taps on objects
        addTapGestureRecognizer()
    }
    
    func addTapGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        
        if sceneView.gestureRecognizers == nil {
            sceneView.gestureRecognizers = [UIGestureRecognizer]()
        }
        
        sceneView.gestureRecognizers!.append(tapGesture as UIGestureRecognizer)
    }
    
    func handleTap(gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        // check what nodes are tapped
        let p = gestureRecognize.locationInView(sceneView)
        
        if let hitResults: [SCNHitTestResult]? = sceneView.hitTest(p, options: nil) {
            if hitResults!.count > 0 {
                // retrieved the first clicked object
                let result: SCNHitTestResult! = hitResults![0]
                
                eventDelegate?.showObjectDetails(result)
            }
        }
    }
    
    func altitudeUpdated(altitude: CLLocationDistance) {
        
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        setCameraNodePosition(SCNVector3Make(getCameraNode().position.x, getCameraNode().position.y, Float(altitude*DEFAULT_METR_SCALE)))
        SCNTransaction.commit()
    }
    
    func setCameraNodePosition(vector: SCNVector3) {
        cameraNode.position = vector
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
    
    //MARK: - RenderingSceneDelegate
    
    func setEventDelegate(object: SceneEventsDelegate?) {
        eventDelegate = object
    }
    
    func getCameraNode() -> SCNNode {
        return cameraNode
    }
    
    func rotationChanged(orientation: CMQuaternion) {
        cameraNode.orientation = LocationMath.sharedInstance.orientationFromCMQuaternion(orientation)
        eventDelegate?.cameraMoved()
    }
    
    func isNodeOnMotionScreen(node: SCNNode) -> Bool {
        return isNodeOnScreen(node)
    }
    
    func nodePosToScreenMotionCoordinates(node: SCNNode) -> Point3D {
        return nodePosToScreenCoordinates(node)
    }
    
    func resetMotionScene() {
        resetScene()
    }
    
    func initialize3DSceneMotionWithHeading(calibratedHeading: CLLocationDirection) {
        initialize3DSceneWithHeading(calibratedHeading)
    }
    
    // change this method to "redrawModels" because 3D can't react on changes, it just draws the scene when we want
    
    func redrawModels(point: Point2D) {
        //user location updated. move camera on new position in 3d scene
        SCNTransaction.begin()
        SCNTransaction.setDisableActions(true)
        
        setCameraNodePosition(SCNVector3Make(Float(point.x), Float(point.y), cameraNode.position.z))
        
        SCNTransaction.commit()
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
