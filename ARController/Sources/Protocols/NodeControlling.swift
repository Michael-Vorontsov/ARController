//
//  NodeControlling.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 11/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import SceneKit

public protocol NodeContorolling: NSObjectProtocol {
    var sceneView: SCNView { get }
    var rootNode: VirtualObject! { get }
}

public protocol DragSourceProtocol: class, NodeContorolling {
    func canBeginDrag(node: VirtualObject) -> Bool
    func startDrag(node: VirtualObject) -> VirtualObject?
    func allowDrag(node: VirtualObject, to: VirtualObject?) -> Bool
    func endDrag(node: VirtualObject, resolution: Bool)
}

public protocol DropDestinationProtocol: class, NodeContorolling {
    func allowDropNode(_ draggable: SCNNode, to destination: SCNNode) -> Bool
    func dropNode(_ draggable: SCNNode, to destination: SCNNode)
}

public protocol DragOverProtocol: class, NodeContorolling {
    func startDraggingOver(_ draggable: SCNNode, over destination: SCNNode?)
    func endDraggingOver(_ draggable: SCNNode, over destination: SCNNode?)
}

public protocol NodeControllable {
    var controller: NodeContorolling? { get }
}
