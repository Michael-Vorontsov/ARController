//
//  RotationGestureRecognisable.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 19/12/2017.
//

import Foundation
import ARKit
import SceneKit

public protocol NodeRotating: class {
    func didRotate(node: SCNNode?, frame: ARFrame?, gesture: UIRotationGestureRecognizer) -> Bool
}

public protocol RotateGestureRecognisable: SceneControlling {
    var activeRotationProcessor: NodeRotating? { get set }
    @discardableResult
    func processRotationGestureAction(_ sender: UIRotationGestureRecognizer) -> Bool
}

public extension RotateGestureRecognisable {
    
    @discardableResult public
    func processRotationGestureAction(_ sender: UIRotationGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        let frame = (sceneView)?.session.currentFrame
        
        
        switch sender.state  {
        case .began:
            for each in nodes {
                if let controller: NodeRotating = each.enclosedController(), controller.didRotate(node: each, frame: frame, gesture: sender) {
                    activeRotationProcessor = controller
                    gestureProcessed = true
                    break;
                }
            }
        case .ended, .cancelled,.failed:
            defer { activeRotationProcessor = nil }
            fallthrough
        default:
            if !gestureProcessed, let controller = activeRotationProcessor {
                gestureProcessed = controller.didRotate(node: nodes.first, frame: frame, gesture: sender)
            }
        }
        
        return gestureProcessed
    }
    
}
