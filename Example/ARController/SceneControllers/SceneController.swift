//
//  SceneController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 07/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SceneKit
import Photos
import ARKit
import ARController

class SceneController: UIViewController, SceneControlling, SettingsConfugurable, SceneObjectTracking, PlaneConstruction, DebugVisualizing, PanGestureRecognisable {
    

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var addObjectButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var screenshotButton: UIButton!

    var dragOnInfinitePlanesEnabled: Bool = false

    var planeDetectionEnabled: Bool = true
    var textManager: TextManager?
    
    private var use3DOFTrackingFallback = false
    private var screenCenter: CGPoint?
    private var restartExperienceButtonIsEnabled = true
    private var notificationSubscriptionTokens = [Any]()
    private var trackingFallbackTimer: Timer?
    
    weak var hoverOverController: DragOverProtocol?
    weak var draggedObjectSourceController: DragSourceProtocol?
    private var panGR: UIPanGestureRecognizer!
    
    // Selected vitualObject
    weak var trackedObject: VirtualObject?
    
    // Selected
    private var objects = [VirtualObject]()
    
    var enabled: Bool = false {
        didSet {
            guard  isViewLoaded, enabled != oldValue else { return }
            enableDidChange()
        }
    }
    
    var use3DOFTracking = false {
        didSet {
            guard var sessionConfig = sceneView.session.configuration else { return }
            if use3DOFTracking {
                sessionConfig = AROrientationTrackingConfiguration()
            }
            sessionConfig.isLightEstimationEnabled = UserDefaults.standard.bool(for: .ambientLightEstimation)
            sceneView.session.run(sessionConfig)
        }
    }

    // Use average of recent virtual object distances to avoid rapid changes in object scale.
    var recentVirtualObjectDistances = [CGFloat]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        panGR = UIPanGestureRecognizer()
        self.view.addGestureRecognizer(panGR)
        panGR.addTarget(self, action: #selector(didPanGesture(_:)))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if let parentContoller = navigationController?.parent as? ViewController {
            parentContoller.sceneController = self
        }
        enableDidChange()
        updateSettings()

        super.viewDidAppear(animated)
        if !self.planeDetectionEnabled {
            textManager?.scheduleMessage("Please place objects", inSeconds: 5.0, messageType: .contentPlacement)
        }
    }
    
    @objc
    func didPanGesture(_ sender: UIPanGestureRecognizer) {
        processPanGestureAction(sender)
    }
    
    func  enableDidChange() {
        if enabled {
            // Prevent the screen from being dimmed after a while.
            UIApplication.shared.isIdleTimerDisabled = true
            // Start the ARSession.
            if let runningConfiguration = sceneView.session.configuration {
                self.sceneView?.session.run(runningConfiguration, options: [])
            }
            
            notificationSubscriptionTokens.append( subsctibeForSettingsUpdate() )
            
        }
        else {
            notificationSubscriptionTokens.removeAll()
            sceneView.session.pause()
        }
    }
    
    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
    
        let sessionConfig = sceneView.session.configuration as? ARWorldTrackingConfiguration ?? ARWorldTrackingConfiguration()
        sessionConfig.planeDetection = planeDetectionEnabled ? .horizontal : []
        self.sceneView.session.run(sessionConfig, options: [])
        setupFocusSquare()
        DispatchQueue.main.async {
            self.screenCenter = self.sceneView.bounds.mid
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        textManager?.showTrackingQualityInfo(for: camera.trackingState, autoHide: !self.showDebugVisuals)
        
        switch camera.trackingState {
        case .notAvailable:
            textManager?.escalateFeedback(for: camera.trackingState, inSeconds: 5.0)
        case .limited:
            if use3DOFTrackingFallback {
                // After 10 seconds of limited quality, fall back to 3DOF mode.
                trackingFallbackTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { _ in
                    self.use3DOFTracking = true
                    self.trackingFallbackTimer?.invalidate()
                    self.trackingFallbackTimer = nil
                })
            } else {
                textManager?.escalateFeedback(for: camera.trackingState, inSeconds: 10.0)
            }
        case .normal:
            textManager?.cancelScheduledMessage(forType: .trackingStateEscalation)
            if use3DOFTrackingFallback && trackingFallbackTimer != nil {
                trackingFallbackTimer!.invalidate()
                trackingFallbackTimer = nil
            }
        }
    }
    
    
    // MARK: - Ambient Light Estimation
    
    func toggleAmbientLightEstimation(_ enabled: Bool) {
        
        guard var sessionConfig = sceneView.session.configuration else { return }

        if enabled {
            if !sessionConfig.isLightEstimationEnabled {
                // turn on light estimation
                sessionConfig.isLightEstimationEnabled = true
                sceneView.session.run(sessionConfig)
            }
        } else {
            if sessionConfig.isLightEstimationEnabled {
                // turn off light estimation
                sessionConfig.isLightEstimationEnabled = false
                sceneView.session.run(sessionConfig)
            }
        }
    }
    
    func resetVirtualObject() {
        for each in objects {
            each.unloadModel()
            each.removeFromParentNode()
        }
        objects.removeAll()
        
        if isViewLoaded {
            addObjectButton.setImage(#imageLiteral(resourceName: "add"), for: [])
            addObjectButton.setImage(#imageLiteral(resourceName: "addPressed"), for: [.highlighted])
        }
    }
    
    var isLoadingObject: Bool = false {
        didSet {
            DispatchQueue.main.async {
                self.settingsButton.isEnabled = !self.isLoadingObject
                self.addObjectButton.isEnabled = !self.isLoadingObject
                self.screenshotButton.isEnabled = !self.isLoadingObject
            }
        }
    }
    
    func addVirtualObject(at index: Int) {
        
        // Show progress indicator
        let spinner = UIActivityIndicatorView()
        spinner.center = addObjectButton.center
        spinner.bounds.size = CGSize(
            width: addObjectButton.bounds.width - 5,
            height: addObjectButton.bounds.height - 5
        )
        
        addObjectButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
        sceneView.addSubview(spinner)
        spinner.startAnimating()
        self.isLoadingObject = true
        
        guard
            let object = VirtualObject.availableObjects[index].copy() as? VirtualObject,
            let screenCenter = screenCenter else {
                return
        }
        
        if let stack = object as? ChipsStack {
            stack.count = Int(arc4random_uniform(20) + 1)
            stack.controller = StackNodeController(view: self.sceneView, node: stack)
            stack.refreshCount()
        }

        self.addObject(object, screenPosition: screenCenter) { [weak self] _ in
            self?.isLoadingObject = false
            spinner.removeFromSuperview()
        }
        self.objects.append(object)

        let stacks = self.objects.filter{ obj in return nil != obj as? ChipsStack }
        if stacks.count > 2 {
            self.performSegue(withIdentifier: "dragMode", sender: self)
        }
    }
    
    @IBAction func chooseObject(_ button: UIButton) {
        // Abort if we are about to load another object to avoid concurrent modifications of the scene.
        if isLoadingObject { return }
        
        textManager?.cancelScheduledMessage(forType: .contentPlacement)
        
        let rowHeight = 45
        let popoverSize = CGSize(width: 250, height: rowHeight * VirtualObject.availableObjects.count)
        
        let objectViewController = VirtualObjectSelectionViewController(size: popoverSize)
        objectViewController.markLastSelection = false
        objectViewController.delegate = self
        objectViewController.modalPresentationStyle = .popover
        objectViewController.popoverPresentationController?.delegate = self
        self.present(objectViewController, animated: true, completion: nil)
        
        objectViewController.popoverPresentationController?.sourceView = button
        objectViewController.popoverPresentationController?.sourceRect = button.bounds
    }
    
    // MARK: - VirtualObjectSelectionViewControllerDelegate
    
    func virtualObjectSelectionViewController(_: VirtualObjectSelectionViewController, didSelectObjectAt index: Int) {
        addVirtualObject(at: index)
        //        loadVirtualObject(at: index)
    }
    
    func virtualObjectSelectionViewControllerDidDeselectObject(_: VirtualObjectSelectionViewController) {
    }
    
    // MARK: - Planes
    
    var planes = [ARPlaneAnchor: Plane]()
    
    // MARK: - Focus Square
    var focusSquare: FocusSquare?
    
    func setupFocusSquare() {
        guard nil == focusSquare else { return }
        focusSquare = FocusSquare()
        sceneView.scene.rootNode.addChildNode(focusSquare!)
        
        textManager?.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    
    func updateFocusSquare() {
        guard let screenCenter = screenCenter else { return }
        
        if trackedObject != nil && sceneView.isNode(trackedObject!, insideFrustumOf: sceneView.pointOfView!) {
            focusSquare?.hide()
        } else {
            focusSquare?.unhide()
        }
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: self.sceneView.session.currentFrame?.camera)
            textManager?.cancelScheduledMessage(forType: .focusSquare)
        }
    }
    
    // MARK: - Hit Test Visualization
    
    var hitTestVisualization: HitTestVisualization?
    
    var showHitTestAPIVisualization = UserDefaults.standard.bool(for: .showHitTestAPI) {
        didSet {
            if  oldValue != showHitTestAPIVisualization {
                UserDefaults.standard.set(showHitTestAPIVisualization, for: .showHitTestAPI)
            }
            if showHitTestAPIVisualization {
                hitTestVisualization = HitTestVisualization(sceneView: sceneView)
            } else {
                hitTestVisualization = nil
            }
        }
    }
    
    // MARK: - Debug Visualizations
    
    func refreshFeaturePoints() {
        guard showDebugVisuals else {
            return
        }
        
        // retrieve cloud
        guard let cloud = sceneView.session.currentFrame?.rawFeaturePoints else {
            return
        }
        
    }

    
    var showDebugVisuals: Bool = UserDefaults.standard.bool(for: .debugMode) {
        didSet {
            guard isViewLoaded else { return }
            planes.values.forEach { $0.showDebugVisualization(showDebugVisuals) }
            
            if showDebugVisuals {
                sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
            } else {
                sceneView.debugOptions = []
            }
            
            // save pref
            if oldValue != showDebugVisuals {
                UserDefaults.standard.set(showDebugVisuals, for: .debugMode)
            }
        }
    }
    // MARK: - Error handling
    
    
    func updateSettings() {
        guard  isViewLoaded else { return }
        let defaults = UserDefaults.standard
        
        showDebugVisuals = defaults.bool(for: .debugMode)
        toggleAmbientLightEstimation(defaults.bool(for: .ambientLightEstimation))
        dragOnInfinitePlanesEnabled = defaults.bool(for: .dragOnInfinitePlanes)
        showHitTestAPIVisualization = defaults.bool(for: .showHitTestAPI)
        use3DOFTracking    = defaults.bool(for: .use3DOFTracking)
        use3DOFTrackingFallback = defaults.bool(for: .use3DOFFallback)
        for (_, plane) in planes {
            plane.updateOcclusionSetting()
        }
    }

    
}

extension SceneController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        refreshFeaturePoints()
        
        DispatchQueue.main.async {
            self.updateFocusSquare()
            self.hitTestVisualization?.render()
            
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            if let lightEstimate = self.sceneView.session.currentFrame?.lightEstimate {
                self.sceneView.scene.lightingEnvironment.intensity = lightEstimate.ambientIntensity / 40.0
            } else {
                self.sceneView.scene.lightingEnvironment.intensity = 25.0
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard planeDetectionEnabled else { return }
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor, createOcclusion: nil)
                for each in self.objects {
                    self.checkIfObjectShouldMoveOntoPlane(object: each,anchor: planeAnchor)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard planeDetectionEnabled else { return }
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
                for each in self.objects {
                    self.checkIfObjectShouldMoveOntoPlane(object: each,anchor: planeAnchor)
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard planeDetectionEnabled else { return }
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    
    @IBAction func restartExperience(_ sender: Any) {
        guard restartExperienceButtonIsEnabled else {
            return
        }
        self.navigationController?.popViewController(animated: true)

    }
    
    @IBAction func takeScreenshot() {
        guard screenshotButton.isEnabled else {
            return
        }
        
        let takeScreenshotBlock = {
            UIImageWriteToSavedPhotosAlbum(self.sceneView.snapshot(), nil, nil, nil)
            DispatchQueue.main.async {
                // Briefly flash the screen.
                let flashOverlay = UIView(frame: self.sceneView.frame)
                flashOverlay.backgroundColor = UIColor.white
                self.sceneView.addSubview(flashOverlay)
                UIView.animate(withDuration: 0.25, animations: {
                    flashOverlay.alpha = 0.0
                }, completion: { _ in
                    flashOverlay.removeFromSuperview()
                })
            }
        }
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            takeScreenshotBlock()
        case .restricted, .denied:
            let title = "Photos access denied"
            let message = "Please enable Photos access for this application in Settings > Privacy to allow saving screenshots."
            textManager?.showAlert(title: title, message: message)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization({ (authorizationStatus) in
                if authorizationStatus == .authorized {
                    takeScreenshotBlock()
                }
            })
        }
    }
    
}

extension SceneController: VirtualObjectSelectionViewControllerDelegate {}

extension SceneController: UIPopoverPresentationControllerDelegate {
    // MARK: - UIPopoverPresentationControllerDelegate
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
    }
}

extension SceneController: ErrorReporting, TextManaging { }
