//
//  Chip.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 02/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import SceneKit
import ARController

class Chip: VirtualObject {
    
    var value: Int = 1

    required init() {
        super.init(modelName: "chip", fileExtension: "scn", thumbImageFilename: "suit_chip_red", title: "Chip")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
