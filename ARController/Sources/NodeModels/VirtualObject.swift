/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Wrapper SceneKit node for virtual objects placed into the AR scene.
*/

import Foundation
import SceneKit
import ARKit

open class VirtualObject: SCNNode, NodeControllable {
	
    public var controller: NodeContorolling? {
        get {
            if (nil != _controller) {
                return _controller
            }
            var parent: SCNNode? = self
            repeat {
                parent = parent?.parent
                if let controller = (parent as? NodeControllable)?.controller {
                    return controller
                }
            }while (parent != nil)
            return nil
        }
        set {
            _controller = newValue
        }
    }
    
    private var _controller: NodeContorolling?
    
	public var modelName: String = ""
	public var fileExtension: String = ""
	public var thumbImage: UIImage?
	public var title: String = ""
	
    fileprivate(set) var modelLoaded: Bool = false
	
    class func niceObject() -> Self {
        return self.init()
    }
    
	public required override init() {
		super.init()
	}
	
    public init(modelName: String, fileExtension: String, thumbImageFilename: String, title: String) {
        super.init()
		self.modelName = modelName
		self.fileExtension = fileExtension
		self.thumbImage = UIImage(named: thumbImageFilename)
		self.title = title
	}
	
	public required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	open func loadModel() {
		guard !modelLoaded, let virtualObjectScene = SCNScene(named: "\(modelName).\(fileExtension)", inDirectory: "Models.scnassets/\(modelName)") else {
			return
		}
		
		let wrapperNode = SCNNode()
		
		for child in virtualObjectScene.rootNode.childNodes {
			child.geometry?.firstMaterial?.lightingModel = .physicallyBased
			child.movabilityHint = .movable
			wrapperNode.addChildNode(child)
		}
		self.addChildNode(wrapperNode)
		
		modelLoaded = true
	}
	
	open func unloadModel() {
		for child in self.childNodes {
			child.removeFromParentNode()
		}
		
		modelLoaded = false
	}
	
}

extension VirtualObject {
	
	public static func isNodePartOfVirtualObject(_ node: SCNNode) -> Bool {
		if nil !=  (node as? VirtualObject) {
			return true
		}
		
		if node.parent != nil {
			return isNodePartOfVirtualObject(node.parent!)
		}
		
		return false
	}
    
    public static func objectByNode(_ node: SCNNode) -> VirtualObject? {
        if let parent = node.parent {
            return (node as? VirtualObject) ?? objectByNode(parent)
        }
        return node as? VirtualObject
    }
 
}

// MARK: - Protocols for Virtual Objects

public protocol ReactsToScale {
    func reactToScale()
}

extension SCNNode {
	
	public func reactsToScale() -> ReactsToScale? {
		if let canReact = self as? ReactsToScale {
			return canReact
		}
		
		if parent != nil {
			return parent!.reactsToScale()
		}
		
		return nil
	}
}
