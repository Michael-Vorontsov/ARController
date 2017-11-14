//
//  NodeController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 08/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SceneKit
import ARController

class NodeController: UIResponder, NodeContorolling  {
    let sceneView: SCNView
    var rootNode: VirtualObject! {
        didSet {
            reloadRootNode()
        }
    }
    
    init(view: SCNView, node: VirtualObject) {
        sceneView = view
        rootNode = node
        super.init()
    }
    
    func reloadRootNode() {}
    
    override var next: UIResponder? {
        var candidate: SCNNode? = self.rootNode?.parent
        var result: UIResponder? = nil
        repeat {
            result = ((candidate as? NodeControllable)?.controller as? UIResponder)
            candidate = candidate?.parent
        } while (nil != candidate && result == nil)
        
        return result
    }

}

