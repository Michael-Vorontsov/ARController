//
//  SceneObjectTracking.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 11/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARKit

public protocol SimpleObjectTracking: class {
    var trackedObject: VirtualObject? { get set }
}

public protocol SceneObjectTracking: SimpleObjectTracking {
    
    var dragOnInfinitePlanesEnabled: Bool { get }
    var recentVirtualObjectDistances: [CGFloat] { get set }
    
    func addObject(_ object: VirtualObject, screenPosition: CGPoint, completion: @escaping (VirtualObject)->())
    func translateBasedOnScreen(object: VirtualObject, pos: CGPoint, instantly: Bool, infinitePlane: Bool)

    func moveVirtualObjectToPosition(virtualObject: VirtualObject, pos: SCNVector3?, instantly: Bool, filterPosition: Bool)
    func setNewVirtualObjectPosition(object: VirtualObject, pos: SCNVector3)
    func updateVirtualObjectPosition(object: VirtualObject, pos: SCNVector3, filterPosition: Bool)
    
    func displayVirtualObjectTransform()
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool)
    func checkIfObjectShouldMoveOntoPlane(object: VirtualObject, anchor: ARPlaneAnchor)
    
}

public extension SceneObjectTracking where Self: SceneControlling & TextManaging {
    
    public func displayVirtualObjectTransform() {
        
        guard let object = trackedObject, let cameraTransform = sceneView?.session.currentFrame?.camera.transform else {
            return
        }
        
        // Output the current translation, rotation & scale of the virtual object as text.
        
        let cameraPos = SCNVector3.positionFromTransform(cameraTransform)
        let vectorToCamera = cameraPos - object.position
        
        let distanceToUser = vectorToCamera.length()
        
        var angleDegrees = Int(((object.eulerAngles.y) * 180) / Float.pi) % 360
        if angleDegrees < 0 {
            angleDegrees += 360
        }
        
        let distance = String(format: "%.2f", distanceToUser)
        let scale = String(format: "%.2f", object.scale.x)
        textManager?.showDebugMessage("Distance: \(distance) m\nRotation: \(angleDegrees)°\nScale: \(scale)x")
    }
    
    public func translateBasedOnScreen(object: VirtualObject, pos: CGPoint, instantly: Bool, infinitePlane: Bool) {
        let worldPosition = worldPositionFromScreenPosition(pos, objectPos: object.position, infinitePlane: infinitePlane)
        moveVirtualObjectToPosition(
            virtualObject: object,
            pos:  worldPosition.position,
            instantly:  instantly,
            filterPosition: !worldPosition.hitAPlane
        )
    }
    
    public func moveVirtualObjectToPosition(virtualObject: VirtualObject, pos: SCNVector3?, instantly: Bool, filterPosition: Bool) {
        
        guard let newPosition = pos else {
            textManager?.showMessage("CANNOT PLACE OBJECT\nTry moving left or right.")
            return
        }
        
        if instantly {
            setNewVirtualObjectPosition(object: virtualObject, pos: newPosition)
        } else {
            updateVirtualObjectPosition(object: virtualObject, pos: newPosition, filterPosition: filterPosition)
        }
    }
    
    public func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 0.2, maxDistance: 2.0)
        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
    
    
    public func setNewVirtualObjectPosition(object: VirtualObject, pos: SCNVector3) {
        
        guard let cameraTransform = sceneView?.session.currentFrame?.camera.transform else {
            return
        }
        
        recentVirtualObjectDistances.removeAll()
        
        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        cameraToPosition.setMaximumLength(10)
        
        object.position = cameraWorldPos + cameraToPosition
        
        if object.parent == nil {
            sceneView.scene.rootNode.addChildNode(object)
        }
    }
    
    public func updateVirtualObjectPosition(object: VirtualObject, pos: SCNVector3, filterPosition: Bool) {
        guard let cameraTransform = sceneView?.session.currentFrame?.camera.transform else {
            return
        }
        
        let cameraWorldPos = SCNVector3.positionFromTransform(cameraTransform)
        var cameraToPosition = pos - cameraWorldPos
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        cameraToPosition.setMaximumLength(10)
        
        // Compute the average distance of the object from the camera over the last ten
        // updates. If filterPosition is true, compute a new position for the object
        // with this average. Notice that the distance is applied to the vector from
        // the camera to the content, so it only affects the percieved distance of the
        // object - the averaging does _not_ make the content "lag".
        let hitTestResultDistance = CGFloat(cameraToPosition.length())
        
        recentVirtualObjectDistances.append(hitTestResultDistance)
        recentVirtualObjectDistances.keepLast(10)
        
        if filterPosition {
            let averageDistance = recentVirtualObjectDistances.average!
            
            cameraToPosition.setLength(Float(averageDistance))
            let averagedDistancePos = cameraWorldPos + cameraToPosition
            
            object.position = averagedDistancePos
        } else {
            object.position = cameraWorldPos + cameraToPosition
        }
    }
    
    public func checkIfObjectShouldMoveOntoPlane(object: VirtualObject, anchor: ARPlaneAnchor) {
        guard let planeAnchorNode = sceneView.node(for: anchor) else {
            return
        }
        
        // Get the object's position in the plane's coordinate system.
        let objectPos = planeAnchorNode.convertPosition(object.position, from: object.parent)
        
        if objectPos.y == 0 {
            return; // The object is already on the plane - nothing to do here.
        }
        
        // Add 10% tolerance to the corners of the plane.
        let tolerance: Float = 0.1
        
        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        if objectPos.x < minX || objectPos.x > maxX || objectPos.z < minZ || objectPos.z > maxZ {
            return
        }
        
        // Drop the object onto the plane if it is near it.
        let verticalAllowance: Float = 0.03
        if objectPos.y > -verticalAllowance && objectPos.y < verticalAllowance {
            textManager?.showDebugMessage("OBJECT MOVED\nSurface detected nearby")
            
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            object.position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
        }
    }

    public func addObject(_ object: VirtualObject, screenPosition: CGPoint, completion: @escaping (VirtualObject)->()) {
        
        let currentQueue = OperationQueue.current ?? OperationQueue.main
        // Load the content asynchronously.
        DispatchQueue.global().async {
            object.loadModel()
            currentQueue.addOperation{
                completion(object)
            }
        }
        
        // Immediately place the object in 3D space.
        guard let newObjectPosition = self.worldPositionFromScreenPosition(screenPosition, objectPos: nil).position else { return }
        
        self.setNewVirtualObjectPosition(object: object, pos: newObjectPosition)
    }
    
}
