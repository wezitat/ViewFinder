//
//  WrapperBaseViewController.swift
//  ARProject00
//
//  Created by Ihor on 4/21/16.
//  Copyright © 2016 Techmagic. All rights reserved.
//

import UIKit
import CoreLocation
import SceneKit
import SwiftyBeaver

enum AppStatus {
    case GettingLocation
    case GettingHeading
    case ShowingScene
    case Unknown
}

class ScreenBaseViewController: UIViewController, SceneEventsDelegate, WitMarkerDelegate, InfoLocationDelegate {

    @IBOutlet weak var debugView: UIView!
    @IBOutlet weak var markerView: WitMarkersView!
    @IBOutlet weak var detailsView: UIView!
    
    var appStatus: AppStatus = .Unknown
    
    let DEFAULT_CALIBRATING_TIME = 5

    
    //array of wit markers
    var witMarkers: [WitMarker] = [WitMarker]()
    
    // array of wit models
    var wit3DModels: [Wit3DModel]! = nil
    
    //heading calibration
    var calibrationTime: Int = 5
    var calibrateTimer: NSTimer! = nil
    var isStable: Bool = false
    var calibratedHeading: CLLocationDirection = CLLocationDirection()
    
    var markerPos: Int = 120
    
    var debugInfo: DebugInfoClass = DebugInfoClass.sharedInstance
    
    // details view
    var smallDetailsView: UIView! = nil
    var detailsHeader: UILabel! = nil
    var detailsDescription: UILabel! = nil
    
    //    var Brain = Brain.sharedInstance
    
    var renderingViewController: RenderingBaseViewController? = nil
    
    var demoData = DemoDataClass()
    
    override func viewDidLoad() {
        sblog.info ("DidLoad screenbaseViewController")
        super.viewDidLoad()
        
//        refreshSceneButton.enabled = false
        
        renderingViewController = self.childViewControllers.first! as? RenderingBaseViewController
        renderingViewController?.setEventDelegate(self)
        
        initDebugViewLayer()
        initDetailsView()
        
        //start location manager
        Brain.sharedInstance.startLocationManager()
        Brain.sharedInstance.locationManager.startUpdating()
        
        Brain.sharedInstance.setLocationManagerDeviceCalibrateDelegate(Brain.sharedInstance)
        Brain.sharedInstance.setLocationManagerInfoLocationDelegate(self)
        Brain.sharedInstance.setMotionManagerRotationManagerDelegate(Brain.sharedInstance)
        
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(orientationChanged),
                                                         name: UIDeviceOrientationDidChangeNotification,
                                                         object: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
//        Brain.sharedInstance.setTopViewController(self)
    }
    
    override func willMoveToParentViewController(parent: UIViewController?) {
        
        if parent == nil {
            Brain.sharedInstance.resetManager()
            
            if renderingViewController != nil {
                renderingViewController!.setEventDelegate(nil)
                renderingViewController = nil
            }
        }
    }
    
    func refreshStage() {
        //reset whole information in app
        //self.refreshSceneButton.enabled = false
        //self.sceneController.resetScene()
        
        renderingViewController?.resetScene()
        
        for marker in witMarkers {
            marker.view.removeFromSuperview()
        }
        
        witMarkers = [WitMarker]()
        
        Brain.sharedInstance.setLocationManagerDelegate(nil)
        
        Brain.sharedInstance.getLocationManager().stopUpdating()
        Brain.sharedInstance.getLocationManager().startUpdating()
        
        //First step we need to retrieve accurate location. This can take a while (depends on accuracy which we choosed in LocationManager)
        self.retrieveInitialLocation()
    }
    
    func initDebugViewLayer() {
        //if user rotates the screen we should update positions of debug infos
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        switch (orientation)
        {
        case .Portrait:
            debugInfo.initDebugViewPortraitOriented()
            break;
        case .LandscapeLeft:
            debugInfo.initDebugViewLandscapeOriented()
            break;
        case .LandscapeRight:
            debugInfo.initDebugViewLandscapeOriented()
            break;
        default:
            debugInfo.initDebugViewPortraitOriented()
            break;
        }
        
        self.debugView.addSubview(debugInfo.debugInfoView)
    }
    
    func initDetailsView() {
        //manually create debug infos on screen
        let screenCenterX: CGFloat = UIScreen.mainScreen().bounds.width/2
        let screenCenterY: CGFloat = UIScreen.mainScreen().bounds.height/2
        
        smallDetailsView = UIView(frame: CGRectMake(screenCenterX - 100, screenCenterY - 100, 200, 200))
        smallDetailsView.backgroundColor = UIColor.whiteColor()
        
        detailsHeader = UILabel(frame: CGRectMake(5, 5, 190, 35))
        detailsHeader.font = UIFont.systemFontOfSize(22)
        detailsHeader.textAlignment = .Center
        
        smallDetailsView.addSubview(detailsHeader)
        
        detailsDescription = UILabel(frame: CGRectMake(0, 35, 190, 155))
        detailsDescription.font = UIFont.systemFontOfSize(15)
        detailsDescription.numberOfLines = 99
        detailsDescription.textAlignment = .Center
        
        smallDetailsView.addSubview(detailsDescription)
        
        let button: UIButton = UIButton(frame: CGRectMake(0, 0, self.detailsView.frame.width, self.detailsView.frame.height))
        
        button.addTarget(self, action: #selector(handleDetailsButton), forControlEvents: .TouchUpInside)
        
        self.detailsView.addSubview(smallDetailsView)
        self.detailsView.addSubview(button)
        
        self.detailsView.bringSubviewToFront(button)
        self.detailsView.hidden = true
    }
    
    func retrieveInitialLocation() {
        debugInfo.retrievingLocationStatus("Retrieving location...")
        self.appStatus = .GettingLocation
    }
    
    func retrieveInitialHeading() {
        debugView.hidden = false
        //start calibrating heding of device
        debugInfo.singleStatus("Don`t shake device!")
        self.appStatus = .GettingHeading
    }
    
    func startHeadingDataGatheringTimer() {
        //start timer to count statble time of device
        calibrationTime = DEFAULT_CALIBRATING_TIME
        
        calibrateTimer?.invalidate()
        calibrateTimer = NSTimer.scheduledTimerWithTimeInterval(1,
                                                                target: self,
                                                                selector: #selector(timeUpdate),
                                                                userInfo: nil,
                                                                repeats: true)
    }
    
    func stopHeadingDataGatheringTimer() {
        //invalidating timer
        calibrateTimer?.invalidate()
    }
    
    func timeUpdate() {
        //one seconds passed. check if we can stop calibration
        if calibrationTime > 0 {
            let currentText: String = "Calibrating data. Don`t shake Device for"
            
            debugInfo.singleStatus(currentText + " \(self.calibrationTime) seconds")
            calibrationTime -= 1
        } else {
            stopHeadingDataGatheringTimer()
            
            //if device was stable for some amount of time - we can end calibration
            endCalibration()
        }
    }
    
    /** Function to prepare everything before building scene
     */
    func endCalibration() {
        if appStatus == .GettingHeading {
            appStatus = .ShowingScene
            initializeScene()
        }
    }
    
    /** Function to start builing scene based on gathered data
     */
    func initializeScene() {
        
        if renderingViewController != nil {
            
//            self.refreshSceneButton.enabled = true
            
            debugInfo.fullInfo()
            
            Brain.sharedInstance.setLocationManagerDelegate(Brain.sharedInstance)
            initialize3DSceneWithHeading(calibratedHeading)
        }
    }
    
    ////////WitMarkers
    
    func handleDetailsButton() {
        //show details about wit
        detailsView.hidden = true
    }
    
    func updatePointIfObjectIsBehind(point: Point3D) -> Point3D {
        //find screen quarter
        let newPoint: Point3D = Point3D(xPos: 0, yPos: 0, zPos: 0)
        
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let screenWidth:  Double = Double(UIScreen.mainScreen().bounds.width)
        
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        if orientation == .Portrait || orientation == .PortraitUpsideDown {
            if point.x > screenWidth/2 {
                point.x = 0
            } else {
                point.x = screenWidth - Double(WIT_MARKER_SIZE)
            }
            newPoint.y = screenHeight/2
        }
        
        if orientation == .LandscapeLeft || orientation == .LandscapeRight {
            if point.y > screenHeight/2 {
                point.y = 0
            } else {
                point.y = screenHeight - Double(WIT_MARKER_SIZE)
            }
            
            newPoint.x = screenWidth/2
        }
        
        return newPoint
    }
    
    //// Show info on top and bottom labels
    
    override func shouldAutorotate() -> Bool {
        return true
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
            return UIInterfaceOrientationMask.AllButUpsideDown
        } else {
            return UIInterfaceOrientationMask.All
        }
    }
    
    func orientationChanged(notification: NSNotification) {
        
        let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
        
        switch (orientation) {
        case .Portrait:
            reorientPortrait()
            break;
        case .LandscapeLeft:
            reorientLandscape()
            break;
        case .LandscapeRight:
            reorientLandscape()
            break;
        default:
            reorientPortrait()
            break;
        }
    }
    
    func reorientPortrait() {
        debugInfo.reorientPortrait()
        
        smallDetailsView?.transform = CGAffineTransformMakeRotation(0)
    }
    
    func reorientLandscape() {
        debugInfo.reorientLanscape()
        
        smallDetailsView?.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
    }
    
    //MARK: - WrapperSceneDelegate
    
    func getWitMarkers() -> [WitMarker] {
        return witMarkers
    }
    
    func updateWrapperPointIfObjectIsBehind(point: Point3D) -> Point3D {
        return updatePointIfObjectIsBehind(point)
    }
    
    func headingUpdated(heading: CLLocationDirection) {
        //if we are in proper status - try to get accurate heading
        if appStatus == .GettingHeading {
            if abs(calibratedHeading - heading) < 5 {
                //device become stable start timer
                if !isStable {
                    isStable = true
                    startHeadingDataGatheringTimer()
                }
            } else {
                isStable = false
                
                //device is not stable. stop timer
                stopHeadingDataGatheringTimer()
                debugInfo.singleStatus("Don`t shake device!")
            }
            
            calibratedHeading = heading
        }
        
        debugInfo.angleUpdated(CGFloat(heading))
    }
    
    func initLocationReceived() {
        //we received our location
        if appStatus == .GettingLocation {
            retrieveInitialHeading()
        }
    }
    
    func rotationAngleUpdated(angle: Double) {
        for marker in witMarkers {
            marker.updateAngle(angle)
        }
    }
    
    // 3D Scene
    
    func initialize3DSceneWithHeading(calibratedHeading: CLLocationDirection) { // remove
        renderingViewController?.initialize3DSceneWithHeading(calibratedHeading)
        addWits()
    }
    
    // Wits
    
    func addWits() {
        
        demoData.initData()
        
        wit3DModels = [Wit3DModel]()
        
        for wit3DModel in demoData.objects {
            let wit3DModel = Wit3DModel(wit: wit3DModel)
            addNewWitMarkerWithWitModel(wit3DModel)
            sblog.info ("adding wit to scene \(wit3DModel.wObject.witDescription)")  // gary; should only be adding wits that are near  ... and then should refresh scene when location changes by xxxx
            renderingViewController?.geometryNode.addChildNode(wit3DModel.objectGeometry)
            wit3DModels.append(wit3DModel)
        }
    }

    func update3DModels(location: CLLocation) {

        for object in wit3DModels {
            sblog.info ("updating 3dmodels")
            object.updateWitObjectSize(location)
        }
    }
    
    func addNewWitMarkerWithWitModel(witModel: Wit3DModel) {
        // add new witmarker on screen
        sblog.info ("adding witmarker \(witModel.wObject.witDescription)")
        let marker = WitMarker()
        
        marker.registerObject(witModel.wObject)
        marker.delegate = self
        
        marker.wit3DModel = witModel
        
        witMarkers.append(marker)
        markerView?.addSubview(marker.view)
    }

    //MARK: - SceneEventsDelegate
    
    func showObjectDetails(result: SCNHitTestResult) {
        
        for object in wit3DModels {
            if result.node == object.objectGeometry {
                sblog.info("showing scn wit object details \(object.wObject.witDescription)")
                showObjectDetails(object.wObject)
            }
        }
    }
    
    func addNewWitMarker(wObject: WitObject) {   // gary ... never used, obsolete?
        // add new witmarker on screen
        let marker = WitMarker()
        
        marker.registerObject(wObject)
        marker.delegate = self
        
        witMarkers.append(marker)
        markerView?.addSubview(marker.view)
    }
    
    func filterWitMarkers() {
        //check if we have number limitation of witmarkers
        
        let maxNumber = SettingsManager.sharedInstance.getWitMarkerNumberValue()
        
        witMarkers.sortInPlace({ $0.currentDistance < $1.currentDistance })
        
        for i in 0..<witMarkers.count {
            let marker = witMarkers[i]
            
            if i < maxNumber {
                marker.isShowMarker = true
            } else {
                marker.isShowMarker = false
            }
        }
    }
    
    func cameraMoved() {
        
        //if camera moved we neeed to update witmarkers on screen. For that we will need what is object coordinates based on screen coordinates
        
        let screenHeight: Double = Double(UIScreen.mainScreen().bounds.height)
        let  screenWidth: Double = Double(UIScreen.mainScreen().bounds.width)
        
        for marker in witMarkers {
            
            if renderingViewController != nil {
                if renderingViewController!.isNodeOnScreen(marker.wit3DModel.objectGeometry) {
                    marker.showMarker(false)
                } else {
                    marker.showMarker(true)
                }
                
                if marker.wit3DModel != nil {
                    
                    if var point = renderingViewController?.nodePosToScreenCoordinates(marker.wit3DModel.objectGeometry) {
                        point.x -= 30
                        point.y -= 30
                        
                        if  point.x < 0 {
                            point.x = 0
                        }
                        
                        if point.y < 0 {
                            point.y = 0
                        }
                        
                        if point.x > screenWidth - Double(WIT_MARKER_SIZE) {
                            point.x = Double(screenWidth) - Double(WIT_MARKER_SIZE)
                        }
                        
                        if point.y > screenHeight - Double(WIT_MARKER_SIZE) {
                            point.y = screenHeight - Double(WIT_MARKER_SIZE)
                        }
                        
                        //check if element is behind - if yes our point will be inside the screen
                        if (point.z > 1) {
                            point = updatePointIfObjectIsBehind(point)
                            //originalPoint = Point2D(xPos: point.x, yPos: point.y)
                        }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            marker.view.frame = CGRectMake(CGFloat(point.x), CGFloat(point.y), WIT_MARKER_SIZE, WIT_MARKER_SIZE)
                            marker.updatePointerAngle(0)
                        }
                    }
                }
            }
        }
    }
    
    func distanceUpdated(location: CLLocation) {
        for marker in witMarkers {
            dispatch_async(dispatch_get_main_queue()) {
                marker.updateDistance(location)
            }
        }
        
        filterWitMarkers()
    }
    
    // WitMarkerDelegate
    
    func showObjectDetails(wObject: WitObject) {
        dispatch_async(dispatch_get_main_queue()) {
            self.detailsHeader.text = wObject.witName
            
            var claimed: String = "NO"
            
            //            if wObject.isClaimed {
            //                claimed = "YES"
            //            }
            
            self.detailsDescription.text = "\(wObject.witDescription)\n\nBy: \(wObject.author) Claimed: \(claimed)"
        }
        sblog.info("building details dialog")        
        detailsView.hidden = false
    }
    
    //MARK: - InfoLocationDelegate ???
    
    func locationUpdatedInfo(location: String) {
        debugInfo.currentPosition = location
        debugInfo.generateDebugMessage()
    }
    
    func locationDistanceUpdatedInfo(dist: String) {
        debugInfo.distance = "\(dist) m"
        debugInfo.generateDebugMessage()
    }
    
    func altitudeUpdatedInfo(alt: Int) {
        debugInfo.altitude = "\(alt) m"
        debugInfo.generateDebugMessage()
    }
    
    func accuracyUpdatedInfo(acc: Int) {
        debugInfo.accuracyTime = "\(acc) m"
        debugInfo.generateDebugMessage()
    }
    
    func lastTimeLocationUpdateInfo(timeUpdate: Int) {
        debugInfo.updateTime = "\(timeUpdate) sec"
        debugInfo.generateDebugMessage()
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
