//
//  LongPressGestureRecongnisable.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 20/12/2017.
//

import Foundation
import ARKit

public protocol NodePressing: class {
    func didPress(node: SCNNode?, frame: ARFrame?, gesture: UILongPressGestureRecognizer) -> Bool
}

public protocol NodePressable: class {
    var activePressProcessor: NodePressing? {get set}
    
}

public protocol LongPressGestureRecongnisable: SceneControlling {
    @discardableResult
    func processPressGestureAction(_ sender: UILongPressGestureRecognizer) -> Bool
}

extension LongPressGestureRecongnisable where Self: NodePressable {
    @discardableResult public
    func processPressGestureAction(_ sender: UILongPressGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        let frame = (sceneView)?.session.currentFrame
        
        
        switch sender.state  {
        case .began:
            for each in nodes {
                if let controller: NodePressing = each.enclosedController(), controller.didPress(node: each, frame: frame, gesture: sender) {
                    activePressProcessor = controller
                    gestureProcessed = true
                    break;
                }
            }
        case .ended, .cancelled,.failed:
            defer { activePressProcessor = nil }
            fallthrough
        default:
            if !gestureProcessed, let controller = activePressProcessor {
                gestureProcessed = controller.didPress(node: nodes.first, frame: frame, gesture: sender)
            }
        }
        
        return gestureProcessed
    }
}
