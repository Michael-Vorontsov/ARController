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

extension SCNView {
    
    /// Sepcilized function to fetch VirtualObjects behind point on screen, arranged in z-order
    ///
    /// - Parameters:
    ///   - point: Point on screen coordinate
    ///   - objectsToExculde: List of objects to exclude from
    /// - Returns: List of objects behind point on screen
    public func objectsAt(point: CGPoint, exclude objectsToExculde: [VirtualObject]? = nil) -> [VirtualObject] {
        
        let results: [VirtualObject] = self
            .hitTest(point, options: [:])
            .filter{VirtualObject.isNodePartOfVirtualObject($0.node)}
            .sorted{ $0.faceIndex > $1.faceIndex }
            .map{ (VirtualObject.objectByNode($0.node))! }
        
        if let objectsToExculde = objectsToExculde {
            return results.filter{ false == objectsToExculde.contains($0) }
        }
        return  results
    }
    
    /// Generic function to fetch specific types of node behind point on screen
    ///
    /// Useful to fetch specific kind of nodes behind the point. Specialized objectsAt are fetching VirtualObject
    ///
    /// - Parameters:
    ///   - point: Point on screen coordinate
    ///   - objectsToExculde: List of objects to exclude from
    /// - Returns: List of objects behind point on screen
    public func nodesAt<T: SCNNode>(point: CGPoint, exclude objectsToExculde: [T]? = nil) -> [T] {

        let results: [T] = self
            .hitTest(point, options: [:])
            .sorted{ $0.faceIndex > $1.faceIndex }
            .mapUnwrapped { arg -> (T?) in  SCNNode.nodeByPart(arg.node) }

        if let objectsToExculde = objectsToExculde {
            return results.filter{ false == objectsToExculde.contains($0) }
        }
        return  results
    }

    
}
