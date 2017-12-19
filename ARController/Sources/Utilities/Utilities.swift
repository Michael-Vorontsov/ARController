/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Utility functions and type extensions used throughout the projects.
*/

import Foundation
import ARKit

// - MARK: UIImage extensions

extension UIImage {
	public func inverted() -> UIImage? {
        guard let ciImage = CIImage(image: self) else {
            return nil
        }
        return UIImage(ciImage: ciImage.applyingFilter("CIColorInvert"))
    }
	
	public static func composeButtonImage(from thumbImage: UIImage, alpha: CGFloat = 1.0) -> UIImage {
		let maskImage = #imageLiteral(resourceName: "buttonring")
		var thumbnailImage = thumbImage
		if let invertedImage = thumbImage.inverted() {
			thumbnailImage = invertedImage
		}
		
		// Compose a button image based on a white background and the inverted thumbnail image.
		UIGraphicsBeginImageContextWithOptions(maskImage.size, false, 0.0)
		let maskDrawRect = CGRect(origin: CGPoint.zero,
		                          size: maskImage.size)
		let thumbDrawRect = CGRect(origin: CGPoint((maskImage.size - thumbImage.size) / 2),
		                           size: thumbImage.size)
		maskImage.draw(in: maskDrawRect, blendMode: .normal, alpha: alpha)
		thumbnailImage.draw(in: thumbDrawRect, blendMode: .normal, alpha: alpha)
		let composedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return composedImage!
	}
}

// MARK: - Collection extensions
extension Array where Iterator.Element == CGFloat {
	public var average: CGFloat? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(CGFloat(0)) { (cur, next) -> CGFloat in
			var cur = cur
			cur += next
			return cur
		}
		let fcount = CGFloat(count)
		ret /= fcount
		return ret
	}
}

extension Array where Iterator.Element == SCNVector3 {
	public var average: SCNVector3? {
		guard !isEmpty else {
			return nil
		}
		
		var ret = self.reduce(SCNVector3Zero) { (cur, next) -> SCNVector3 in
			var cur = cur
			cur.x += next.x
			cur.y += next.y
			cur.z += next.z
			return cur
		}
		let fcount = Float(count)
		ret.x /= fcount
		ret.y /= fcount
		ret.z /= fcount
		
		return ret
	}
}

extension Array {
    
    public func mapUnwrapped<T>(_ transform: (Element) throws -> T?) rethrows -> [T] {
        return try self.map(transform).filter{ $0 != nil }.map{ $0! }
    }
}

extension RangeReplaceableCollection where IndexDistance == Int {
	public mutating func keepLast(_ elementsToKeep: Int) {
		if count > elementsToKeep {
			self.removeFirst(count - elementsToKeep)
		}
	}
}

// MARK: - SCNNode extension

extension SCNNode {
	
	public func setUniformScale(_ scale: Float) {
		self.scale = SCNVector3Make(scale, scale, scale)
	}
	
	public func renderOnTop() {
		self.renderingOrder = 2
		if let geom = self.geometry {
			for material in geom.materials {
				material.readsFromDepthBuffer = false
			}
		}
		for child in self.childNodes {
			child.renderOnTop()
		}
	}
}

// MARK: - SCNVector3 extensions

extension SCNVector3 {
    
	public init(_ vec: vector_float3) {
		self.x = vec.x
		self.y = vec.y
		self.z = vec.z
	}
	
	public func length() -> Float {
		return sqrtf(x * x + y * y + z * z)
	}
	
	public mutating func setLength(_ length: Float) {
		self.normalize()
		self *= length
	}
	
	public mutating func setMaximumLength(_ maxLength: Float) {
		if self.length() <= maxLength {
			return
		} else {
			self.normalize()
			self *= maxLength
		}
	}
	
	public mutating func normalize() {
		self = self.normalized()
	}
	
	public func normalized() -> SCNVector3 {
		if self.length() == 0 {
			return self
		}
		
		return self / self.length()
	}
	
	public static func positionFromTransform(_ transform: matrix_float4x4) -> SCNVector3 {
		return SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
	}
	
	public func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)), \(String(format: "%.2f", z)))"
	}
	
	public func dot(_ vec: SCNVector3) -> Float {
		return (self.x * vec.x) + (self.y * vec.y) + (self.z * vec.z)
	}
	
	public func cross(_ vec: SCNVector3) -> SCNVector3 {
		return SCNVector3(self.y * vec.z - self.z * vec.y, self.z * vec.x - self.x * vec.z, self.x * vec.y - self.y * vec.x)
	}
}

public let SCNVector3One: SCNVector3 = SCNVector3(1.0, 1.0, 1.0)

public func SCNVector3Uniform(_ value: Float) -> SCNVector3 {
	return SCNVector3Make(value, value, value)
}

public func SCNVector3Uniform(_ value: CGFloat) -> SCNVector3 {
	return SCNVector3Make(Float(value), Float(value), Float(value))
}

public func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x + right.x, left.y + right.y, left.z + right.z)
}

public func - (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
	return SCNVector3Make(left.x - right.x, left.y - right.y, left.z - right.z)
}

public func += (left: inout SCNVector3, right: SCNVector3) {
	left = left + right
}

public func -= (left: inout SCNVector3, right: SCNVector3) {
	left = left - right
}

public func / (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x / right, left.y / right, left.z / right)
}

public func * (left: SCNVector3, right: Float) -> SCNVector3 {
	return SCNVector3Make(left.x * right, left.y * right, left.z * right)
}

public func /= (left: inout SCNVector3, right: Float) {
	left = left / right
}

public func *= (left: inout SCNVector3, right: Float) {
	left = left * right
}

extension SCNVector3: Equatable {
    public static func ==(lhs: SCNVector3, rhs: SCNVector3) -> Bool {
        return SCNVector3EqualToVector3(lhs, rhs)
    }
}

public func abs(_ vector: SCNVector3) -> SCNVector3 {
    return SCNVector3(x: abs(vector.x), y: abs(vector.y), z: abs(vector.z))
}

// MARK: - SCNVector4 extensions
extension SCNVector4: Equatable {
    public static func ==(lhs: SCNVector4, rhs: SCNVector4) -> Bool {
        return SCNVector4EqualToVector4(lhs, rhs)
    }
}

// MARK: - SCNMatrix4 extensions
extension SCNMatrix4: Equatable, Hashable {
    public static func ==(lhs: SCNMatrix4, rhs: SCNMatrix4) -> Bool {
        return SCNMatrix4EqualToMatrix4(lhs, rhs)
    }
    
    public var hashValue: Int {
        return "\(self)".hashValue
    }
    
    public func transition() -> SCNVector3 {
        let transition = SCNVector3(
            x: self.m41,
            y: self.m42,
            z: self.m43
        )
        return transition
    }
    
    public static func * (lhs: SCNMatrix4, rhs: SCNMatrix4) -> SCNMatrix4 {
        return SCNMatrix4Mult(lhs, rhs)
    }
    
}

// MARK: - CGPoint extensions
extension CGPoint {
    
    public static func * <F: FloatingPoint>(lhs: CGPoint, rhs: F) -> CGPoint {
        let multiplier = CGFloat(rhs as! CGFloat)
        return CGPoint(x: lhs.x * multiplier, y: lhs.y * multiplier)
    }
}

// MARK: - SCNMaterial extensions
extension SCNMaterial {
	
	public static func material(withDiffuse diffuse: Any?, respondsToLighting: Bool = true) -> SCNMaterial {
		let material = SCNMaterial()
		material.diffuse.contents = diffuse
		material.isDoubleSided = true
		if respondsToLighting {
			material.locksAmbientWithDiffuse = true
		} else {
			material.ambient.contents = UIColor.black
			material.lightingModel = .constant
			material.emission.contents = diffuse
		}
		return material
	}
}

// MARK: - CGPoint extensions

extension CGPoint {
	
	public init(_ size: CGSize) {
		self.x = size.width
		self.y = size.height
	}
	
	public init(_ vector: SCNVector3) {
		self.x = CGFloat(vector.x)
		self.y = CGFloat(vector.y)
	}
	
	public func distanceTo(_ point: CGPoint) -> CGFloat {
		return (self - point).length()
	}
	
	public func length() -> CGFloat {
		return sqrt(self.x * self.x + self.y * self.y)
	}
	
	public func midpoint(_ point: CGPoint) -> CGPoint {
		return (self + point) / 2
	}
	
	public func friendlyString() -> String {
		return "(\(String(format: "%.2f", x)), \(String(format: "%.2f", y)))"
	}
}

public func + (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x + right.x, y: left.y + right.y)
}

public func - (left: CGPoint, right: CGPoint) -> CGPoint {
	return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

public func += (left: inout CGPoint, right: CGPoint) {
	left = left + right
}

public func -= (left: inout CGPoint, right: CGPoint) {
	left = left - right
}

public func / (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x / right, y: left.y / right)
}

public func * (left: CGPoint, right: CGFloat) -> CGPoint {
	return CGPoint(x: left.x * right, y: left.y * right)
}

public func /= (left: inout CGPoint, right: CGFloat) {
	left = left / right
}

public func *= (left: inout CGPoint, right: CGFloat) {
	left = left * right
}

// MARK: - CGSize extensions

extension CGSize {
	
	public init(_ point: CGPoint) {
		self.width = point.x
		self.height = point.y
	}
	
	public func friendlyString() -> String {
		return "(\(String(format: "%.2f", width)), \(String(format: "%.2f", height)))"
	}
}

public func + (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width + right.width, height: left.height + right.height)
}

public func - (left: CGSize, right: CGSize) -> CGSize {
	return CGSize(width: left.width - right.width, height: left.height - right.height)
}

public func += (left: inout CGSize, right: CGSize) {
	left = left + right
}

public func -= (left: inout CGSize, right: CGSize) {
	left = left - right
}

public func / (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width / right, height: left.height / right)
}

public func * (left: CGSize, right: CGFloat) -> CGSize {
	return CGSize(width: left.width * right, height: left.height * right)
}

public func /= (left: inout CGSize, right: CGFloat) {
	left = left / right
}

public func *= (left: inout CGSize, right: CGFloat) {
	left = left * right
}

// MARK: - CGRect extensions

extension CGRect {
	
	public var mid: CGPoint {
		return CGPoint(x: midX, y: midY)
	}
}

public func rayIntersectionWithHorizontalPlane(rayOrigin: SCNVector3, direction: SCNVector3, planeY: Float) -> SCNVector3? {
	
	let direction = direction.normalized()
	
	// Special case handling: Check if the ray is horizontal as well.
	if direction.y == 0 {
		if rayOrigin.y == planeY {
			// The ray is horizontal and on the plane, thus all points on the ray intersect with the plane.
			// Therefore we simply return the ray origin.
			return rayOrigin
		} else {
			// The ray is parallel to the plane and never intersects.
			return nil
		}
	}
	
	// The distance from the ray's origin to the intersection point on the plane is:
	//   (pointOnPlane - rayOrigin) dot planeNormal
	//  --------------------------------------------
	//          direction dot planeNormal
	
	// Since we know that horizontal planes have normal (0, 1, 0), we can simplify this to:
	let dist = (planeY - rayOrigin.y) / direction.y

	// Do not return intersections behind the ray's origin.
	if dist < 0 {
		return nil
	}
	
	// Return the intersection point.
	return rayOrigin + (direction * dist)
}

extension ARSCNView {
	
	public struct HitTestRay {
		let origin: SCNVector3
		let direction: SCNVector3
	}
	
	public func hitTestRayFromScreenPos(_ point: CGPoint) -> HitTestRay? {
		
		guard let frame = self.session.currentFrame else {
			return nil
		}

		let cameraPos = SCNVector3.positionFromTransform(frame.camera.transform)

		// Note: z: 1.0 will unproject() the screen position to the far clipping plane.
		let positionVec = SCNVector3(x: Float(point.x), y: Float(point.y), z: 1.0)
		let screenPosOnFarClippingPlane = self.unprojectPoint(positionVec)
		
		var rayDirection = screenPosOnFarClippingPlane - cameraPos
		rayDirection.normalize()
		
		return HitTestRay(origin: cameraPos, direction: rayDirection)
	}
	
	public func hitTestWithInfiniteHorizontalPlane(_ point: CGPoint, _ pointOnPlane: SCNVector3) -> SCNVector3? {
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return nil
		}
		
		// Do not intersect with planes above the camera or if the ray is almost parallel to the plane.
		if ray.direction.y > -0.03 {
			return nil
		}
		
		// Return the intersection of a ray from the camera through the screen position with a horizontal plane
		// at height (Y axis).
		return rayIntersectionWithHorizontalPlane(rayOrigin: ray.origin, direction: ray.direction, planeY: pointOnPlane.y)
	}
	
	public struct FeatureHitTestResult {
		public let position: SCNVector3
		public let distanceToRayOrigin: Float
		public let featureHit: SCNVector3
		public let featureDistanceToHitResult: Float
	}
	
	public func hitTestWithFeatures(_ point: CGPoint, coneOpeningAngleInDegrees: Float,
	                         minDistance: Float = 0,
	                         maxDistance: Float = Float.greatestFiniteMagnitude,
	                         maxResults: Int = 1) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return results
		}
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		let maxAngleInDeg = min(coneOpeningAngleInDegrees, 360) / 2
		let maxAngle = ((maxAngleInDeg / 180) * Float.pi)
		
		let points = features.points
		
        for i in 0..<features.points.count {
			
            let feature = points[i];
			let featurePos = SCNVector3(feature)
			
			let originToFeature = featurePos - ray.origin
			
			let crossProduct = originToFeature.cross(ray.direction)
			let featureDistanceFromResult = crossProduct.length()
			
			let hitTestResult = ray.origin + (ray.direction * ray.direction.dot(originToFeature))
			let hitTestResultDistance = (hitTestResult - ray.origin).length()
			
			if hitTestResultDistance < minDistance || hitTestResultDistance > maxDistance {
				// Skip this feature - it is too close or too far away.
				continue
			}
			
			let originToFeatureNormalized = originToFeature.normalized()
			let angleBetweenRayAndFeature = acos(ray.direction.dot(originToFeatureNormalized))
			
			if angleBetweenRayAndFeature > maxAngle {
				// Skip this feature - is is outside of the hit test cone.
				continue
			}

			// All tests passed: Add the hit against this feature to the results.
			results.append(FeatureHitTestResult(position: hitTestResult,
			                                    distanceToRayOrigin: hitTestResultDistance,
			                                    featureHit: featurePos,
			                                    featureDistanceToHitResult: featureDistanceFromResult))
		}
		
		// Sort the results by feature distance to the ray.
		results = results.sorted(by: { (first, second) -> Bool in
			return first.distanceToRayOrigin < second.distanceToRayOrigin
		})
		
		// Cap the list to maxResults.
		var cappedResults = [FeatureHitTestResult]()
		var i = 0
		while i < maxResults && i < results.count {
			cappedResults.append(results[i])
			i += 1
		}
		
		return cappedResults
	}
	
	public func hitTestWithFeatures(_ point: CGPoint) -> [FeatureHitTestResult] {
		
		var results = [FeatureHitTestResult]()
		
		guard let ray = hitTestRayFromScreenPos(point) else {
			return results
		}
		
		if let result = self.hitTestFromOrigin(origin: ray.origin, direction: ray.direction) {
			results.append(result)
		}
		
		return results
	}
	
	public func hitTestFromOrigin(origin: SCNVector3, direction: SCNVector3) -> FeatureHitTestResult? {
		
		guard let features = self.session.currentFrame?.rawFeaturePoints else {
			return nil
		}
		
		let points = features.points
		
		// Determine the point from the whole point cloud which is closest to the hit test ray.
		var closestFeaturePoint = origin
		var minDistance = Float.greatestFiniteMagnitude
		
		for i in 0..<features.points.count {
			let feature = points[i]
			let featurePos = SCNVector3(feature)
			
			let originVector = origin - featurePos
			let crossProduct = originVector.cross(direction)
			let featureDistanceFromResult = crossProduct.length()

			if featureDistanceFromResult < minDistance {
				closestFeaturePoint = featurePos
				minDistance = featureDistanceFromResult
			}
		}
		
		// Compute the point along the ray that is closest to the selected feature.
		let originToFeature = closestFeaturePoint - origin
		let hitTestResult = origin + (direction * direction.dot(originToFeature))
		let hitTestResultDistance = (hitTestResult - origin).length()
		
		return FeatureHitTestResult(position: hitTestResult,
		                            distanceToRayOrigin: hitTestResultDistance,
		                            featureHit: closestFeaturePoint,
		                            featureDistanceToHitResult: minDistance)
	}
}

// MARK: - Simple geometries

public func createAxesNode(quiverLength: CGFloat, quiverThickness: CGFloat) -> SCNNode {
	let quiverThickness = (quiverLength / 50.0) * quiverThickness
	let chamferRadius = quiverThickness / 2.0
	
	let xQuiverBox = SCNBox(width: quiverLength, height: quiverThickness, length: quiverThickness, chamferRadius: chamferRadius)
	xQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.red, respondsToLighting: false)]
	let xQuiverNode = SCNNode(geometry: xQuiverBox)
	xQuiverNode.position = SCNVector3Make(Float(quiverLength / 2.0), 0.0, 0.0)
	
	let yQuiverBox = SCNBox(width: quiverThickness, height: quiverLength, length: quiverThickness, chamferRadius: chamferRadius)
	yQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.green, respondsToLighting: false)]
	let yQuiverNode = SCNNode(geometry: yQuiverBox)
	yQuiverNode.position = SCNVector3Make(0.0, Float(quiverLength / 2.0), 0.0)
	
	let zQuiverBox = SCNBox(width: quiverThickness, height: quiverThickness, length: quiverLength, chamferRadius: chamferRadius)
	zQuiverBox.materials = [SCNMaterial.material(withDiffuse: UIColor.blue, respondsToLighting: false)]
	let zQuiverNode = SCNNode(geometry: zQuiverBox)
	zQuiverNode.position = SCNVector3Make(0.0, 0.0, Float(quiverLength / 2.0))
	
	let quiverNode = SCNNode()
	quiverNode.addChildNode(xQuiverNode)
	quiverNode.addChildNode(yQuiverNode)
	quiverNode.addChildNode(zQuiverNode)
	quiverNode.name = "Axes"
	return quiverNode
}

public func createCrossNode(size: CGFloat = 0.01, color: UIColor = UIColor.green, horizontal: Bool = true, opacity: CGFloat = 1.0) -> SCNNode {
	
	// Create a size x size m plane and put a grid texture onto it.
	let planeDimension = size
	
	var fileName = ""
	switch color {
	case UIColor.blue:
		fileName = "crosshair_blue"
	case UIColor.yellow:
		fallthrough
	default:
		fileName = "crosshair_yellow"
	}
	
    
    
	let path = Bundle.main.path(forResource: fileName, ofType: "png", inDirectory: "Models.scnassets")!
	let image = UIImage(contentsOfFile: path)
	
	let planeNode = SCNNode(geometry: createSquarePlane(size: planeDimension, contents: image))
	if let material = planeNode.geometry?.firstMaterial {
		material.ambient.contents = UIColor.black
		material.lightingModel = .constant
	}
	
	if horizontal {
		planeNode.eulerAngles = SCNVector3Make(Float.pi / 2.0, 0, Float.pi) // Horizontal.
	} else {
		planeNode.constraints = [SCNBillboardConstraint()] // Facing the screen.
	}
	
	let cross = SCNNode()
	cross.addChildNode(planeNode)
	cross.opacity = opacity
	return cross
}

public func createSquarePlane(size: CGFloat, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size, height: size)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}

public func createPlane(size: CGSize, contents: AnyObject?) -> SCNPlane {
	let plane = SCNPlane(width: size.width, height: size.height)
	plane.materials = [SCNMaterial.material(withDiffuse: contents)]
	return plane
}


