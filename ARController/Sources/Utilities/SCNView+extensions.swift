//
//  SCNView+extensions.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 09/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import CoreGraphics
import SceneKit
import ARKit

extension SCNView {
    
    /// Sepcilized function to fetch VirtualObjects behind point on screen, arranged in z-order
    ///
    /// - Parameters:
    ///   - point: Point on screen coordinate
    ///   - objectsToExculde: List of objects to exclude from
    /// - Returns: List of objects behind point on screen
    public func objectsAt(point: CGPoint, exclude objectsToExculde: [VirtualObject]? = nil) -> [VirtualObject] {
        return nodesAt(point: point, exclude: objectsToExculde)
      
    }
    
    /// Generic function to fetch specific types of node behind point on screen
    ///
    /// Useful to fetch specific kind of nodes behind the point. Specialized objectsAt are fetching VirtualObject
    ///
    /// - Parameters:
    ///   - point: Point on screen coordinate
    ///   - objectsToExculde: List of objects to exclude from
    /// - Returns: List of objects behind point on screen
    public func nodesAt<T: SCNNode>(_ type: T.Type? = nil, point: CGPoint, exclude objectsToExculde: [T]? = nil) -> [T] {

        let results: [T] = self
            .hitTest(point, options: [:])
            .mapUnwrapped { arg -> (T?) in  SCNNode.nodeByPart(arg.node) }

        if let objectsToExculde = objectsToExculde {
            return results.filter{ false == objectsToExculde.contains($0) }
        }
        return  results
    }

}

extension SCNNode {
    
    public static func nodeByPart<T: SCNNode>(_ node: SCNNode) -> T? {
        if let parent = node.parent {
            let convertedNode = (node as? T)
            return convertedNode ?? nodeByPart(parent)
        }
        return node as? T
    }
    
    public func enclosedController<T>(_ type: T.Type? = nil) -> T?{
        var parent: SCNNode? = self
        
        repeat {
            parent = parent?.parent
            if let controller = (parent as? NodeControllable)?.controller as? T {
                return controller
            }
        }while (parent != nil)
        
        return nil
    }
}

public extension ARCamera {
    public var position: SCNVector3 { return SCNVector3( transform.columns.3.x, transform.columns.3.y, transform.columns.3.z) }
    
    public func distanceTo(position worldPoistion: SCNVector3) -> Float {
        let offset =  worldPoistion - position
        return offset.length()
    }
}
