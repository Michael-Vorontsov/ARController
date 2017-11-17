//
//  NodeController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 08/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SceneKit

open class NodeController: UIResponder, NodeContorolling  {
    open let sceneView: SCNView
    open var rootNode: SCNNode! {
        didSet {
            reloadRootNode()
        }
    }
    
    public init(view: SCNView, node: VirtualObject) {
        sceneView = view
        rootNode = node
        super.init()
    }
    
    open func reloadRootNode() {}
    
    open override var next: UIResponder? {
        var candidate: SCNNode? = self.rootNode?.parent
        var result: UIResponder? = nil
        repeat {
            result = ((candidate as? NodeControllable)?.controller as? UIResponder)
            candidate = candidate?.parent
        } while (nil != candidate && result == nil)
        
        return result
    }

}

