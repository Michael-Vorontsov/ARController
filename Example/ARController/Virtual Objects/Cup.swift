/*
See LICENSE folder for this sample’s licensing information.

Abstract:
The virtual cup.
*/

import Foundation
import ARController

class Cup: VirtualObject {
	
    required init() {
		super.init(modelName: "cup", fileExtension: "scn", thumbImageFilename: "cup", title: "Cup")
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
