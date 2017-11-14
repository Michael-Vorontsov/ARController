//
//  FocusingProtocol.swift
//  ARControllers
//
//  Created by Mykhailo Vorontsov on 12/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation

public protocol Focusing: class {
    var focusSquare: FocusSquare? { get set }
    var focusPoing: CGPoint? {get set}
    func setupFocusSquare()
    func updateFocusSquare()
}

public extension Focusing where Self: SceneControlling & SceneObjectTracking {
    
    public func setupFocusSquare() {
        guard nil == focusSquare else { return }
        focusSquare = FocusSquare()
        self.sceneView?.scene.rootNode.addChildNode(focusSquare!)
        
        (self as? TextManaging)?.textManager?.scheduleMessage("TRY MOVING LEFT OR RIGHT", inSeconds: 5.0, messageType: .focusSquare)
    }
    
    public func updateFocusSquare() {
        guard
            let screenCenter = focusPoing,
            let frameCamera = self.sceneView?.session.currentFrame?.camera
        else { return }
        
        if trackedObject != nil && (true == self.sceneView?.isNode(trackedObject!, insideFrustumOf: sceneView.pointOfView!)) {
            focusSquare?.hide()
        } else {
            focusSquare?.unhide()
        }
        let (worldPos, planeAnchor, _) = worldPositionFromScreenPosition(screenCenter, objectPos: focusSquare?.position, infinitePlane: false)
        if let worldPos = worldPos {
            focusSquare?.update(for: worldPos, planeAnchor: planeAnchor, camera: frameCamera)
            (self as? TextManaging)?.textManager?.cancelScheduledMessage(forType: .focusSquare)
        }
    }
}
