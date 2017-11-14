//
//  SceneControlling.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 09/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit

/*
 In most cases scene controller is a view controller
 It can have it's own layer of controls, outlets and actions.
 However in simple cases in can be not (if not custom controls needed).
 */

public protocol SceneControlling: class {
    var sceneView: ARSCNView! { set get }
    var enabled: Bool { set get }
    func setupScene()
}

public protocol ErrorReporting: class {
    func restartExperience(_ sender: Any)
    func displayErrorMessage(title: String, message: String)
    func displayErrorMessage(title: String, message: String, allowRestart: Bool)
}

public protocol DebugVisualizing: class {
    var showDebugVisuals: Bool { get }
}

public extension ErrorReporting where Self: TextManaging {
    
    public func displayErrorMessage(title: String, message: String) {
        displayErrorMessage(title: title, message: message, allowRestart: false)
    }
    
    public func displayErrorMessage(title: String, message: String, allowRestart: Bool) {
        // Blur the background.
        textManager?.blurBackground()
        
        if allowRestart {
            // Present an alert informing about the error that has occurred.
            let restartAction = UIAlertAction(title: "Reset", style: .default) { [weak self] _ in
                self?.textManager?.unblurBackground()
                self?.restartExperience(self!)
            }
            
            textManager?.showAlert(title: title, message: message, actions: [restartAction])
        } else {
            textManager?.showAlert(title: title, message: message, actions: [])
        }
    }
}
