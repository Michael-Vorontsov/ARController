//
//  NoodLooking.swift
//  ARController
//
//  Created by Mykhailo Vorontsov on 18/11/2017.
//

import UIKit
import ARKit
import SceneKit

public protocol NodeFocusing: NodeContorolling {
    func startFocus(at node: SCNNode, distance: Float, frame: ARFrame?)
    func updateFocus(node: SCNNode, distance: Float, frame: ARFrame?)
    func endFocus(at node: SCNNode, frame: ARFrame?)
}

public protocol FocusGestureRecognsing: SceneControlling {
    
    var focusController: NodeFocusing? { get set }
    var nodeInFocus: SCNNode? { get set }
    
    var screenCenter: CGPoint { get }
    func processFocusGestureAction(_ arFrame: ARFrame)
    
}

public extension FocusGestureRecognsing {
    
    public func processFocusGestureAction(_ arFrame: ARFrame) {
        
        let hitTest = sceneView.hitTest(screenCenter, options: [:]).first
        let node = hitTest?.node
        
        let controller: NodeFocusing? = node?.enclosedController()
        if  controller !== focusController {
            if let nodeInFocus = self.nodeInFocus {
                focusController?.endFocus(at: nodeInFocus, frame: arFrame)
            }
            if let node = node, let controller = controller, let hitTestPos = hitTest?.worldCoordinates {
                self.nodeInFocus = node
                controller.startFocus(
                    at: node,
                    distance: arFrame.camera.distanceTo(position: hitTestPos),
                    frame: arFrame
                )
            }
            self.focusController = controller
        }
        else if controller === focusController, let controller = controller, let node = node, let hitTestPos = hitTest?.worldCoordinates  {
            controller.updateFocus(
                node: node,
                distance: arFrame.camera.distanceTo(position: hitTestPos),
                frame: arFrame
            )
        }
        
    }
}



