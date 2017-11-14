/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The virtual lamp.
*/

import Foundation
import ARKit
import ARController

class Lamp: VirtualObject {
	
    required init() {
		super.init(modelName: "FinalBaseMesh", fileExtension: "scn", thumbImageFilename: "lamp", title: "Lamp")
//        super.init(modelName: "FinalBaseMesh", fileExtension: "scn", thumbImageFilename: "lamp", title: "Lamp")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
