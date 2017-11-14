//
//  Man.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 07/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import UIKit
import ARController

class Man: VirtualObject {
    required init() {
        super.init(
            modelName: "FinalBaseMesh",
            fileExtension: "scn",
            thumbImageFilename: "VitruvianMan",
            title: "Man"
        )
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
