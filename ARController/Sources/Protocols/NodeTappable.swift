//
//  NodeTappable.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 18/11/2017.
//

import Foundation
import ARKit

public protocol NodeTappable: NodeContorolling {
    func didTapped(point: CGPoint, node: SCNNode, frame: ARFrame?)
}

public protocol TapGestureRecognisable: class {
    @discardableResult
    func processTapGestureAction(_ sender: UITapGestureRecognizer) -> Bool
}

public extension SceneControlling  where Self: TapGestureRecognisable  {
    
    @discardableResult
    public func processTapGestureAction(_ sender: UITapGestureRecognizer) -> Bool {
        guard sender.state == .ended else { return false }
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        for each in nodes {
            if let controller: NodeTappable = each.enclosedController() {
                controller.didTapped(point: touchLocation, node: each, frame: sceneView.session.currentFrame)
                gestureProcessed = true
                // Break cycle as soon as some controller able to process the touch
                break;
            }
        }
        return gestureProcessed
    }
}



