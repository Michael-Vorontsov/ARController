//
//  StackNodeController.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 08/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import SceneKit
import ARController
import ARKit

class StackNodeController: NodeController {
    var closeLook: SCNNode?  = nil
    var textCell: SCNText?
    var tempStack: SCNNode?
    
    var lastMaterial: Any?
    
    override func reloadRootNode() {
        let textNode = self.rootNode.childNode(withName: "textNode", recursively: true)
        textCell = textNode?.geometry as? SCNText
    }
    
}
extension StackNodeController: DragOverProtocol {
    
    func startDraggingOver(_ draggable: SCNNode, over destination: SCNNode?) {
        guard let rootNode = (self.rootNode as? ChipsStack), let copy = draggable.copy() as? VirtualObject else { return }
        copy.loadModel()
        textCell?.string = "\(String(describing: rootNode.count)) +"
        rootNode.addChildNode(copy)
        copy.opacity = 0.2
        copy.transform = rootNode.newChipTransform() * SCNMatrix4MakeTranslation(0.0, 0.01, 0.0)
        tempStack = copy
    }
    
    func endDraggingOver(_ draggable: SCNNode, over destination: SCNNode?) {
        tempStack?.removeFromParentNode()
        tempStack = nil
        guard let rootNode = (self.rootNode as? ChipsStack) else { return }
        textCell?.string = "\(rootNode.count)"
    }
}

extension StackNodeController: DragSourceProtocol {
    func endDrag(node draggable: VirtualObject, resolution: Bool) {
        guard !resolution, let rootStack = rootNode as? ChipsStack else { return }

        if let chip = draggable as? Chip{
            
            rootStack.count += 1
            let transform = chip.worldTransform
            rootStack.addChildNode(chip)
            chip.setWorldTransform(transform)
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            chip.transform = rootStack.newChipTransform()
            SCNTransaction.commit()
        }
        
        if let stack = draggable as? ChipsStack {
            for chip in stack.childNodes {
                let transform = chip.worldTransform
                rootStack.addChildNode(chip)
                chip.setWorldTransform(transform)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.1
                chip.transform = rootStack.newChipTransform()
                SCNTransaction.commit()
            }
            rootStack.count += stack.count
        }
        
    }

    func canBeginDrag(node: VirtualObject) -> Bool {
        return true
    }

    func startDrag(node: VirtualObject) -> VirtualObject? {
        let stack = rootNode as? ChipsStack
        stack?.count -= 1

        // Start draggin topmost chip
        return stack?.childNodes.filter{ nil != $0 as? VirtualObject }.last as? VirtualObject
    }
    
    func allowDrag(node: VirtualObject, to destination: VirtualObject?) -> Bool {
        return nil != destination
    }
}

extension StackNodeController: DropDestinationProtocol {
    
    
    func allowDropNode(_ draggable: SCNNode, to destination: SCNNode) -> Bool {
        guard let rootStack = destination as? ChipsStack else {
            return false
        }
        if let chip = draggable as? Chip {
            return chip.value == rootStack.value
        }
        if let stack = draggable as? ChipsStack {
            return stack.value == rootStack.value
        }
        return false
    }
    
    func dropNode(_ draggable: SCNNode, to destination: SCNNode) {
        guard let rootStack = destination as? ChipsStack else {
            return
        }
        if let chip = draggable as? Chip{
            
            rootStack.count += 1
            let transform = chip.worldTransform
            rootStack.addChildNode(chip)
            chip.setWorldTransform(transform)
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 1.0
            chip.transform = rootStack.newChipTransform()
            SCNTransaction.commit()
        }
        
        if let stack = draggable as? ChipsStack {
            for chip in stack.childNodes {
                let transform = chip.worldTransform
                rootStack.addChildNode(chip)
                chip.setWorldTransform(transform)
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 1.1
                chip.transform = rootStack.newChipTransform()
                SCNTransaction.commit()
            }
            rootStack.count += stack.count
        }
    }
    
}


extension StackNodeController: NodeFocusing {
    func startFocus(at node: SCNNode, distance: Float, frame: ARFrame?) {
        lastMaterial = node.geometry?.firstMaterial?.diffuse.contents
        node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
    }
    
    func updateFocus(node: SCNNode, distance: Float, frame: ARFrame?) {
        if distance < 0.2 && closeLook != node {
            closeLook?.removeAllActions()
            node.runAction( SCNAction.repeatForever( SCNAction.rotateBy(x: 0, y: CGFloat.pi, z: 0, duration: 4.0)))
            closeLook = node
        }
        else if distance > 0.2  {
            closeLook?.removeAllActions()
            closeLook = nil
        }
    }
    
    func endFocus(at node: SCNNode, frame: ARFrame?) {
        node.geometry?.firstMaterial?.diffuse.contents = lastMaterial
        lastMaterial = nil
    }

}
