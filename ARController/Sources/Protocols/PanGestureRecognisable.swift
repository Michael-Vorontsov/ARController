//
//  PanGestureRecognisable.swift
//  ARControllers
//
//  Created by Mykhailo Vorontsov on 12/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

public protocol NodeDragging {
    
    //    didTapped(point: CGPoint, node: SCNNode, frame: ARFrame?)
    func didDrag(node: SCNNode?, frame: ARFrame?, panGesture: UIPanGestureRecognizer) -> Bool
}

public protocol NodeDraggable: class {
    var currentDragController: NodeDragging? { get set }
}

public protocol PanGestureRecognisable: SceneControlling {
    var hoverOverController: DragOverProtocol? {get set}
    var draggedObjectSourceController: DragSourceProtocol? {get set}
    
    @discardableResult
    func processPanGestureAction(_ sender: UIPanGestureRecognizer) -> Bool
}

public extension PanGestureRecognisable where Self: SceneObjectTracking {
    
    private func hover(object: VirtualObject?, over destinationObject: VirtualObject?) {
        guard
            let virtualObject = object
            else {
                return
        }
        
        let nodeController = virtualObject.controller
        let destinationController = destinationObject?.controller
        
        if nodeController !== destinationController || nil == destinationController {
            if let controller = destinationController as? DragOverProtocol {
                if  hoverOverController !== controller  {
                    hoverOverController?.endDraggingOver(virtualObject, over: hoverOverController?.rootNode)
                    hoverOverController = controller
                    controller.startDraggingOver(virtualObject, over: controller.rootNode)
                }
            } else {
                hoverOverController?.endDraggingOver(virtualObject, over: hoverOverController?.rootNode)
                hoverOverController = nil
            }
        }
    }
    
    private func cancelDrag(_ dragged: VirtualObject) {
        draggedObjectSourceController?.endDrag(node: dragged, resolution: false)
        draggedObjectSourceController = nil
    }
    
    private func finishDrag(_ dragged: VirtualObject, to destination: VirtualObject?, atPoint: CGPoint) {
        hoverOverController?.endDraggingOver(dragged, over: hoverOverController?.rootNode)
        hoverOverController = nil
        
        var dragAllowed = true
        if let controller = draggedObjectSourceController {
            dragAllowed = controller.allowDrag(node: dragged, to: destination)
        }
        
        if dragAllowed, let destination = destination, let controller = destination.controller as? DropDestinationProtocol  {
            dragAllowed = controller.allowDropNode(dragged, to: destination)
            if dragAllowed {
                defer {
                    controller.dropNode(dragged, to: destination)
                }
            }
        }
        draggedObjectSourceController?.endDrag(node: dragged, resolution: dragAllowed)
        draggedObjectSourceController = nil
    }
    
    private func dragObject(_ dragged: VirtualObject, to destination: VirtualObject?, point: CGPoint) {
        self.translateBasedOnScreen(object: dragged, pos: point, instantly: true, infinitePlane: false)
        self.hover(object: dragged, over: destination)
    }
    
    private func startDraggingObject(_ objectToDrag: VirtualObject) {
        // Move object to root node with retaining worl trnasform
        let transformation = objectToDrag.worldTransform
        objectToDrag.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(objectToDrag)
        objectToDrag.setWorldTransform(transformation)
    }
    
    @discardableResult
    public func processPanGestureAction(_ sender: UIPanGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        
        let touchedObject = self.sceneView.objectsAt(point: touchLocation, exclude: nil == trackedObject ? nil : [trackedObject!]).first
        var gestureProcessed = false

        switch sender.state {
        case .began:
            if let touchedObject = touchedObject, let controller = (touchedObject.controller as? DragSourceProtocol) {
                draggedObjectSourceController = controller
                if controller.canBeginDrag(node: touchedObject) {
                    let objectToDrag = controller.startDrag(node: touchedObject) ?? touchedObject
                    startDraggingObject(objectToDrag)
                    trackedObject = objectToDrag
                }
            } else {
                self.trackedObject = touchedObject
            }
            gestureProcessed = true
            displayVirtualObjectTransform()
            
        case .possible:
            break;
            
        case .changed:
            guard let draggedObject = trackedObject else { return false}
            dragObject(draggedObject, to: touchedObject, point: touchLocation)
            gestureProcessed = true
        case .ended:
            guard let draggedObject = trackedObject else { return  false }
            self.finishDrag(draggedObject, to: touchedObject, atPoint: touchLocation)
            gestureProcessed = true
            self.trackedObject = nil
            
        case .cancelled, .failed:
            guard let draggedObject = trackedObject else { return false}
            self.finishDrag(draggedObject, to: touchedObject, atPoint: touchLocation)
            gestureProcessed = true
            self.trackedObject = nil
        }
        return gestureProcessed
    }
    
}


public extension PanGestureRecognisable where Self: SimpleObjectTracking {
    
    func hover(object: VirtualObject?, over destinationObject: VirtualObject?) {
        guard
            let virtualObject = object
            else {
                return
        }
        
        let nodeController = virtualObject.controller
        let destinationController = destinationObject?.controller
        
        
        if nodeController !== destinationController || nil == destinationController {
            if let controller = destinationController as? DragOverProtocol {
                if  hoverOverController !== controller  {
                    hoverOverController?.endDraggingOver(virtualObject, over: hoverOverController?.rootNode)
                    hoverOverController = controller
                    controller.startDraggingOver(virtualObject, over: controller.rootNode)
                }
            } else {
                hoverOverController?.endDraggingOver(virtualObject, over: hoverOverController?.rootNode)
                hoverOverController = nil
            }
        }
    }
    
    func cancelDrag(_ dragged: VirtualObject) {
        draggedObjectSourceController?.endDrag(node: dragged, resolution: false)
        draggedObjectSourceController = nil
    }
    
    func finishDrag(_ dragged: VirtualObject, to destination: VirtualObject?, atPoint: CGPoint) {
        hoverOverController?.endDraggingOver(dragged, over: hoverOverController?.rootNode)
        hoverOverController = nil
        
        dragged.opacity = 1.0

        var dragAllowed = true
        if let controller = draggedObjectSourceController {
            dragAllowed = controller.allowDrag(node: dragged, to: destination)
        }
        
        if dragAllowed, let destination = destination, let controller = destination.controller as? DropDestinationProtocol  {
            dragAllowed = controller.allowDropNode(dragged, to: destination)
            if dragAllowed {
                defer {
                    controller.dropNode(dragged, to: destination)
                }
            }
        }
        draggedObjectSourceController?.endDrag(node: dragged, resolution: dragAllowed)
        draggedObjectSourceController = nil
    }
    
    func dragObject(_ dragged: VirtualObject, to destination: VirtualObject?, point: CGPoint) {
        self.hover(object: dragged, over: destination)
    }
    
    func startDraggingObject(_ objectToDrag: VirtualObject) {
        // Just remove object from parent
        objectToDrag.opacity = 0.1
    }
    
    @discardableResult
    public func processPanGestureAction(_ sender: UIPanGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        
        let touchedObject = self.sceneView.objectsAt(point: touchLocation, exclude: nil == trackedObject ? nil : [trackedObject!]).first
        
        switch sender.state {
        case .began:
            if let touchedObject = touchedObject, let controller = (touchedObject.controller as? DragSourceProtocol) {
                draggedObjectSourceController = controller
                if controller.canBeginDrag(node: touchedObject) {
                    let objectToDrag = controller.startDrag(node: touchedObject) ?? touchedObject
                    startDraggingObject(objectToDrag)
                    trackedObject = objectToDrag
                }
            } else {
                self.trackedObject = touchedObject
            }
            
        case .possible:
            break;
            
        case .changed:
            guard let draggedObject = trackedObject else { return true}
            dragObject(draggedObject, to: touchedObject, point: touchLocation)
        case .ended:
            guard let draggedObject = trackedObject else { return true}
            self.finishDrag(draggedObject, to: touchedObject, atPoint: touchLocation)
            self.trackedObject = nil
            
        case .cancelled, .failed:
            guard let draggedObject = trackedObject else { return true}
            self.finishDrag(draggedObject, to: touchedObject, atPoint: touchLocation)
            self.trackedObject = nil
        }
        return true
    }
}

extension PanGestureRecognisable where Self: NodeDraggable {
    
    @discardableResult
    public func processPanGestureAction(_ sender: UIPanGestureRecognizer) -> Bool {
        let touchLocation = sender.location(in: sceneView)
        let nodes = self.sceneView.nodesAt(point: touchLocation)
        
        var gestureProcessed = false
        let frame = (sceneView)?.session.currentFrame

        if !gestureProcessed, sender.state != .began, let controller = currentDragController {
            gestureProcessed = controller.didDrag(node: nodes.first, frame: frame, panGesture: sender)
        }
        
        guard !gestureProcessed else { return gestureProcessed }
        
        for each in nodes {
            if let controller: NodeDragging = each.enclosedController(), controller.didDrag(node: each, frame: frame, panGesture: sender) {
                currentDragController = controller
                gestureProcessed = true
                break;
            }
        }
        
        return gestureProcessed
        
    }
}


