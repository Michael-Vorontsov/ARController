//
//  SceneControlling+Session.swift
//  ARControllers
//
//  Created by Mykhailo Vorontsov on 12/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit

extension ARSCNViewDelegate where Self: ErrorReporting & SceneControlling & TextManaging   {
    
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
        guard let sessionConfig = sceneView.session.configuration else { return }
        session.run(sessionConfig, options: [.resetTracking, .removeExistingAnchors])
        restartExperience(self)
        textManager?.showMessage("RESETTING SESSION")
    }

}
