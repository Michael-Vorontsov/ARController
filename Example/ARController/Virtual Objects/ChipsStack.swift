//
//  ChipsStack.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 02/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SceneKit
import ARController

extension SCNNode {
    var  volume: SCNVector3 {
        let box = self.boundingBox
        return box.max - box.min
    }
}

extension FloatingPoint {
    static func rand(range: Range<Self> = (0..<1)) -> Self {
        let randXNorm = Self(arc4random()) / Self(UInt32.max)
        return randXNorm * (range.upperBound - range.lowerBound) + range.lowerBound
    }
}

extension SCNMatrix4 {
    static func * (a: SCNMatrix4, b: SCNMatrix4) -> SCNMatrix4 {
        return SCNMatrix4Mult(a, b)
    }
}

extension CGPoint {
    static func randomPoint(xRange: Range<CGFloat> = (-1.0..<1.0), yRange: Range<CGFloat> = (-1.0..<1.0)) -> CGPoint {
        return CGPoint(x: CGFloat.rand(range: xRange), y: CGFloat.rand(range: yRange))
        
    }
}

class ChipsStack: VirtualObject {
    
    func newChipTransform() -> SCNMatrix4 {
         let chip = childNodes.filter{ nil != ($0 as? Chip) }.last
        return SCNMatrix4MakeTranslation(Float.rand(range: -0.01..<0.01), (chip?.volume.y ?? 0) * Float(count), Float.rand(range: -0.01..<0.01))
    }
    
    var textNode: SCNNode?
    
    func refreshCount() {
        let oldValue = childNodes.filter{ nil != ($0 as? Chip) }.count
        if (count > oldValue) {
            var index = 0
            for _ in oldValue..<count {
                let newChip = Chip()
                newChip.loadModel()
                self.addChildNode(newChip)
                newChip.transform = SCNMatrix4Translate(
                    newChip.transform,
                    Float.rand(range: -0.01..<0.01),
                    Float(index) * newChip.volume.y,
                    Float.rand(range: -0.01..<0.01)
                )
                index += 1
            }
        }
        if (count < oldValue) {
            for _ in count..<oldValue {
                if (self.childNodes.count > 0) {
                    self.childNodes.last?.removeFromParentNode()
                }
                else {
                    self.removeFromParentNode()
                }
            }
        }
    }

    var count: Int = 1 {
        didSet {
            (textNode?.geometry as? SCNText)?.string = "\(self.count)"
        }
    }
    
    var value: Int = 1
    
    override func loadModel() {
        super.loadModel()
        if let textNode = childNode(withName: "textNode", recursively: true) {
            
            (textNode.geometry as? SCNText)?.string = "\(count)"
            self.textNode = textNode
            
            // Workaround bug with scale and BillboardConstraint
            let node = SCNNode()
            self.addChildNode(node)
            node.addChildNode(textNode)
            let constraint = SCNBillboardConstraint()
            constraint.freeAxes = [.Y]
            node.constraints = [constraint]
        }
        self.childNodes.forEach{ ($0 as? VirtualObject)?.loadModel()}
    }

    required init() {
        super.init(modelName: "chipsStack", fileExtension: "scn", thumbImageFilename: "suit_chip_red", title: "Chips stack")
        self.title = "Chips"
        let firstChip = Chip()
        self.addChildNode(firstChip)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
 
}
