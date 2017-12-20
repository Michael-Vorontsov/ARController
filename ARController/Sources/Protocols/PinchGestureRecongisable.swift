//
//  PinchGestureRecongisable.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 20/12/2017.
//

import Foundation
import ARKit

public protocol NodePinching: class {
    func didPinch(node: SCNNode?, frame: ARFrame?, gesture: UIPinchGestureRecognizer) -> Bool
}

public protocol NodePinchable: class {
    var activePinchProcessor: NodePinching? {get set}
    
}

public protocol PinchGestureRecongnisable: SceneControlling {
    @discardableResult
    func processPinchGestureAction(_ sender: UIPinchGestureRecognizer) -> Bool
}


public extension PinchGestureRecongnisable where Self: NodePinchable {
    @discardableResult public
    func processPinchGestureAction(_ sender: UIPinchGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        let frame = (sceneView)?.session.currentFrame
        
        
        switch sender.state  {
        case .began:
            for each in nodes {
                if let controller: NodePinching = each.enclosedController(), controller.didPinch(node: each, frame: frame, gesture: sender) {
                    activePinchProcessor = controller
                    gestureProcessed = true
                    break;
                }
            }
        case .ended, .cancelled,.failed:
            defer { activePinchProcessor = nil }
            fallthrough
        default:
            if !gestureProcessed, let controller = activePinchProcessor {
                gestureProcessed = controller.didPinch(node: nodes.first, frame: frame, gesture: sender)
            }
        }
        
        return gestureProcessed
    }
    
}




public extension PinchGestureRecongnisable where Self: NodePinchable {
    @discardableResult public
    func processHoldGestureAction(_ sender: UIPinchGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        let frame = (sceneView)?.session.currentFrame
        
        
        switch sender.state  {
        case .began:
            for each in nodes {
                if let controller: NodePinching = each.enclosedController(), controller.didPinch(node: each, frame: frame, gesture: sender) {
                    activePinchProcessor = controller
                    gestureProcessed = true
                    break;
                }
            }
        case .ended, .cancelled,.failed:
            defer { activePinchProcessor = nil }
            fallthrough
        default:
            if !gestureProcessed, let controller = activePinchProcessor {
                gestureProcessed = controller.didPinch(node: nodes.first, frame: frame, gesture: sender)
            }
        }
        
        return gestureProcessed
    }
    
}
