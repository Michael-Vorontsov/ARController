/*
See LICENSE folder for this sample’s licensing information.

Abstract:
SceneKit node wrapper for plane geometry detected in AR.
*/

import Foundation
import ARKit

public class Plane: SCNNode {
    
    static let useOcclusionPlaneSettingsKey = "useOcclusionPlanes"
	
    public var occlusionVisible = false {
        didSet {
            guard oldValue != occlusionVisible else { return }
            if occlusionVisible {
                occlusionNode?.geometry?.firstMaterial?.colorBufferWriteMask = .all
            }
            else {
                occlusionNode?.geometry?.firstMaterial?.colorBufferWriteMask = []
            }
        }
    }
        
	public var anchor: ARPlaneAnchor
	public var occlusionNode: SCNNode?
	public let occlusionPlaneVerticalOffset: Float = -0.001  // The occlusion plane should be placed 1 mm below the actual
													// plane to avoid z-fighting etc.
	
	var debugVisualization: PlaneDebugVisualization?
	
	public var focusSquare: FocusSquare?
	
    public init(anchor: ARPlaneAnchor, showDebugVisualization: Bool = false, createOcclusion: Bool? = nil) {
		self.anchor = anchor
		
		super.init()
		
		self.showDebugVisualization(showDebugVisualization)
		
        let createOcclusion = createOcclusion ?? UserDefaults.standard.bool(forKey: Plane.useOcclusionPlaneSettingsKey )
        if createOcclusion {
            createOcclusionNode()
        }
    }
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	public func update(_ anchor: ARPlaneAnchor) {
		self.anchor = anchor
		debugVisualization?.update(anchor)
        if UserDefaults.standard.bool(forKey: Plane.useOcclusionPlaneSettingsKey) {
            updateOcclusionNode()
        }
	}
	
	public func showDebugVisualization(_ show: Bool) {
		if show {
			if debugVisualization == nil {
				DispatchQueue.global().async {
					self.debugVisualization = PlaneDebugVisualization(anchor: self.anchor)
					DispatchQueue.main.async {
						self.addChildNode(self.debugVisualization!)
					}
				}
			}
		} else {
			debugVisualization?.removeFromParentNode()
			debugVisualization = nil
		}
	}
	
	public func updateOcclusionSetting() {
        if UserDefaults.standard.bool(forKey: Plane.useOcclusionPlaneSettingsKey) {
			if occlusionNode == nil {
				createOcclusionNode()
			}
		} else {
			occlusionNode?.removeFromParentNode()
			occlusionNode = nil
		}
	}
	
	// MARK: Private
	
	private func createOcclusionNode() {
		// Make the occlusion geometry slightly smaller than the plane.
		let occlusionPlane = SCNPlane(width: CGFloat(anchor.extent.x - 0.05), height: CGFloat(anchor.extent.z - 0.05))
       
        let material = SCNMaterial()
        material.colorBufferWriteMask = occlusionVisible ? .all : []
        material.isDoubleSided = true
        occlusionPlane.materials = [material]
        occlusionPlane.firstMaterial?.diffuse.contents = UIColor.yellow.withAlphaComponent(0.3)

		occlusionNode = SCNNode()
		occlusionNode?.geometry = occlusionPlane
		occlusionNode?.transform = SCNMatrix4MakeRotation(-Float.pi / 2.0, 1, 0, 0)
		occlusionNode?.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
		
		self.addChildNode(occlusionNode!)
	}
	
	private func updateOcclusionNode() {
		guard let occlusionNode = occlusionNode, let occlusionPlane = occlusionNode.geometry as? SCNPlane else {
			return
		}
        occlusionPlane.width = CGFloat(anchor.extent.x - 0.05)
        occlusionPlane.height = CGFloat(anchor.extent.z - 0.05)

		occlusionNode.position = SCNVector3Make(anchor.center.x, occlusionPlaneVerticalOffset, anchor.center.z)
	}
}

