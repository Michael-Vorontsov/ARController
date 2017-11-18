//
//  NodeTappable.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 18/11/2017.
//

import Foundation
import ARKit

protocol NodeTappable: NodeContorolling {
    func didTapped(point: CGPoint, node: SCNNode, frame: ARFrame?)
}

protocol TapGestureRecognisable: class {
    func processTapGestureAction(_ sender: UITapGestureRecognizer)
}

extension SceneControlling  where Self: TapGestureRecognisable  {
    
    func processTapGestureAction(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        let touchLocation = sender.location(in: sceneView)
        
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        for each in nodes {
            if let controller: NodeTappable = each.enclosedController() {
                controller.didTapped(point: touchLocation, node: each, frame: sceneView.session.currentFrame)
            }
        }
    }
}



