/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The virtual chair.
*/

import Foundation
import ARController

class Chair: VirtualObject {
	
    required init() {
		super.init(modelName: "chair", fileExtension: "scn", thumbImageFilename: "chair", title: "Chair")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
