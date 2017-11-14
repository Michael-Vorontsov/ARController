//
//  File.swift
//  ARKitExample
//
//  Created by Mykhailo Vorontsov on 11/11/2017.
//  Copyright © 2017 Apple. All rights reserved.
//

import Foundation
import ARController

extension VirtualObject {
    //TODO: Remove from here
    static let availableObjects: [VirtualObject] = [
        Chip(),
        ChipsStack(),
        Candle(),
        Cup(),
        Vase(),
        Lamp(),
        Chair(),
        Man()
    ]
}

