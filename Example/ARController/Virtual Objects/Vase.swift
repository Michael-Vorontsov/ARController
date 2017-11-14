/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The virtual vase.
*/

import Foundation
import ARController

class Vase: VirtualObject {
	
    required init() {
		super.init(modelName: "vase", fileExtension: "scn", thumbImageFilename: "vase", title: "Vase")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
