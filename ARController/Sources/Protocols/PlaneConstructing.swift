//
//  PlaneConstructing.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 11/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import ARKit
import Foundation

public protocol PlaneConstruction: class {

    var planes: [ARPlaneAnchor: Plane] { get set }
    
    func addPlane(node: SCNNode, anchor: ARPlaneAnchor, createOcclusion: Bool?)
    func updatePlane(anchor: ARPlaneAnchor)
    func removePlane(anchor: ARPlaneAnchor)
    func restartPlaneDetection()
}

public extension PlaneConstruction where Self: SceneControlling {
    
    /// Add new plane
    ///
    /// - Parameters:
    ///   - node: node to add
    ///   - anchor: anchor
    ///   - createOcclusion: Create occlusion plane or not. Give it nil to use settings preference
    public func addPlane(node: SCNNode, anchor: ARPlaneAnchor, createOcclusion: Bool?) {
        
        let pos = SCNVector3.positionFromTransform(anchor.transform)
        (self as? TextManaging)?.textManager?.showDebugMessage("NEW SURFACE DETECTED AT \(pos.friendlyString())")
        
        let showDebugVisuals: Bool = (self as? DebugVisualizing)?.showDebugVisuals ?? true
        
        let plane = Plane(anchor: anchor,  showDebugVisualization: showDebugVisuals, createOcclusion: createOcclusion)
        
        plane.occlusionVisible = true
        
        planes[anchor] = plane
        node.addChildNode(plane)
        
        (self as? TextManaging)?.textManager?.cancelScheduledMessage(forType: .planeEstimation)
        (self as? TextManaging)?.textManager?.showMessage("SURFACE DETECTED")
    }
    
    public func updatePlane(anchor: ARPlaneAnchor) {
        if let plane = planes[anchor] {
            plane.update(anchor)
        }
    }
    
    public func removePlane(anchor: ARPlaneAnchor) {
        if let plane = planes.removeValue(forKey: anchor) {
            plane.removeFromParentNode()
        }
    }
    
    public func restartPlaneDetection() {
        // configure session
        if let worldSessionConfig = sceneView?.session.configuration as? ARWorldTrackingConfiguration {
            worldSessionConfig.planeDetection = .horizontal
            sceneView?.session.run(worldSessionConfig, options: [.resetTracking, .removeExistingAnchors])
        }
        
        (self as? TextManaging)?.textManager?.scheduleMessage(
            "FIND A SURFACE TO PLACE AN OBJECT",
            inSeconds: 7.5,
            messageType: .planeEstimation
        )
    }
    
}
