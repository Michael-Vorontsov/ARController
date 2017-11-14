//
//  PlaneSelectionController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 09/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import ARKit
import ARController

class PlaneSelectionController: UIViewController, SceneControlling, TextManaging, ARSCNViewDelegate, ErrorReporting, PlaneConstruction, DebugVisualizing {
    
    var showDebugVisuals = false

    @IBOutlet weak var sceneView: ARSCNView!
    var enabled: Bool = false { didSet {enableDidChange() }}
    var textManager: TextManager?
    var planes = [ARPlaneAnchor: Plane]()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let parentContoller = navigationController?.parent as? ViewController, parentContoller.sceneController !== self {
            parentContoller.sceneController = self
        }
        enableDidChange()
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let center = view.center
        // If user looking on plane - hide all planes except this one
//
//        if let plane:Plane = sceneView.nodesAt(point: center).first, let material = plane.occlusionNode?.geometry?.firstMaterial {
//
//            material.diffuse.contents = UIColor.green.withAlphaComponent(0.5)
//
//            var allPlanes = Array(planes.values)
//            allPlanes.remove(at: allPlanes.index(of: plane)!)
//            allPlanes.forEach{ $0.occlusionVisible = false }
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textManager?.scheduleMessage("Please look at Table", inSeconds: 1.0, messageType: .contentPlacement)
    }
    
    func  enableDidChange() {
        if enabled {
            // Prevent the screen from being dimmed after a while.
            UIApplication.shared.isIdleTimerDisabled = true
            // Start the ARSession.
            let worldSessionConfig = self.sceneView?.session.configuration ?? ARWorldTrackingConfiguration()
            if let worldSessionConfig = worldSessionConfig as? ARWorldTrackingConfiguration {
                worldSessionConfig.planeDetection = .horizontal
            }
            session.run(worldSessionConfig, options: [])
        }
        else {
            session.pause()
        }
    }
    
    // MARK: - ARKit / ARSCNView
    var session:ARSession! = ARSession()
    var sessionConfig: ARConfiguration! = ARWorldTrackingConfiguration()

    func setupScene() {
        // set up sceneView
        sceneView.delegate = self
        
        session = sceneView.session
        
        sceneView.antialiasingMode = .multisampling4X
        sceneView.automaticallyUpdatesLighting = false
        
        sessionConfig.worldAlignment = .gravityAndHeading
        (sessionConfig as? ARWorldTrackingConfiguration)?.planeDetection = .horizontal
        
        sceneView.preferredFramesPerSecond = 60
        sceneView.contentScaleFactor = 1.3
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        textManager?.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable:
            textManager?.escalateFeedback(for: camera.trackingState, inSeconds: 5.0)
        case .limited:
            textManager?.escalateFeedback(for: camera.trackingState, inSeconds: 10.0)
        case .normal:
            textManager?.cancelScheduledMessage(forType: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard let arError = error as? ARError else { return }
        
        let nsError = error as NSError
        var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
        if let recoveryOptions = nsError.localizedRecoveryOptions {
            for option in recoveryOptions {
                sessionErrorMsg.append("\(option).")
            }
        }
        
        let isRecoverable = (arError.code == .worldTrackingFailed)
        if isRecoverable {
            sessionErrorMsg += "\nYou can try resetting the session or quit the application."
        } else {
            sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
        }
        
        displayErrorMessage(title: "We're sorry!", message: sessionErrorMsg, allowRestart: isRecoverable)
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        textManager?.blurBackground()
        textManager?.showAlert(title: "Session Interrupted", message: "The session will be reset after the interruption has ended.")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        textManager?.unblurBackground()
        sceneView.session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        restartExperience(self)
        textManager?.showMessage("RESETTING SESSION")
    }
  

    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            // If light estimation is enabled, update the intensity of the model's lights and the environment map
            let intensity: CGFloat
            if let lightEstimate = self.session.currentFrame?.lightEstimate {
                 intensity = lightEstimate.ambientIntensity / 40.0
            } else {
                intensity = 25.0
            }
            self.sceneView?.scene.lightingEnvironment.intensity = intensity
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.addPlane(node: node, anchor: planeAnchor, createOcclusion: true)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.updatePlane(anchor: planeAnchor)
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                self.removePlane(anchor: planeAnchor)
            }
        }
    }
    
    @IBAction func debug(_ sender: UIButton) {
        self.sceneView?.delegate = nil
        self.sceneView = nil
        self.sessionConfig = nil
        self.session = nil
    }
    
    @IBAction func restartExperience(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.textManager?.cancelAllScheduledMessages()
            self.textManager?.dismissPresentedAlert()
            self.textManager?.showMessage("STARTING A NEW SESSION")
            
            self.restartPlaneDetection()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Disable plane detaction (to Illustrate how second phase can work without PlaneDetection)
        if let sceneController = segue.destination as? SceneController {
            sceneController.planeDetectionEnabled = false
        }
        
        super.prepare(for: segue, sender: sender)
    }
}
