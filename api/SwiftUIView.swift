import SwiftUI

import SwiftUI
struct ContentView: View {
	@State private var image: UIImage? = UIImage(named: "123.png")
	@State private var predictions: [PredictionDetails] = []
	@State private var scaledHeight: CGFloat
	@State private var scaledWidth: CGFloat
	
	var body: some View {
		GeometryReader { geometry in
			ZStack {
				if let uiImage = image {
					Image(uiImage: uiImage)
						.resizable()
						.scaledToFit()
						.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
						.overlay(overlayView(uiImage: uiImage, geometry: geometry))
				}
			}
			VStack {
				Spacer()
				Button("Upload Image") {
					uploadImage()
				}
				.padding()
				.background(Color.blue)
				.foregroundColor(Color.white)
				.clipShape(RoundedRectangle(cornerRadius: 8))
			}
		}
		.onAppear {
			uploadImage()
		}
	}
	
	func overlayView(uiImage: UIImage, geometry: GeometryProxy) -> some View {
		let imageScale = min(geometry.size.width / uiImage.size.width, geometry.size.height / uiImage.size.height)
		let offsetX = (geometry.size.width - (uiImage.size.width * imageScale)) / 2
		let offsetY = (geometry.size.height - (uiImage.size.height * imageScale)) / 2

		print("offsetX: \(offsetX)")
		print("offsetY: \(offsetY)")


		return ForEach(predictions, id: \.self) { prediction in
			let bbox = parseBoundingBox(prediction.bbox.BoundingBox)
			if bbox.width > 0 && bbox.height > 0 {
				scaledWidth = bbox.width * imageScale
				scaledHeight = bbox.height * imageScale

				Rectangle()
				
					.stroke(Color.red, lineWidth: 2)
					.frame(width: scaledWidth, height: scaledHeight)
					.offset(x: (bbox.x * imageScale) + offsetX, y: (bbox.y * imageScale) + offsetY)
			}
			
		}
		
	}


	func parseBoundingBox(_ boundingBox: String) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
		// Remove parentheses and whitespaces then split by comma
		let trimmedString = boundingBox.trimmingCharacters(in: CharacterSet(charactersIn: " ()"))
		let components = trimmedString.split(separator: ",").map { Double($0.trimmingCharacters(in: .whitespaces)) ?? 0 }
		let x = CGFloat(components[0])
		let y = CGFloat(components[1])
		let x2 = CGFloat(components[2])
		let y2 = CGFloat(components[3])
		print("Before: x: \(x) y: \(y) y2: \(x2) x2: \(y2)")
		print("Width before: \(max(x2 - x, 0)) Height before: \(max(y2 - y, 0))")
		return (x: x, y: y, width: max(x2 - x, 0), height: max(y2 - y, 0))
	}
//	
//	func translateX(_ boundingBox: String, geometry: GeometryProxy) -> CGFloat {
//		let bbox = parseBoundingBox(boundingBox)
//		let x = bbox.x
//		return CGFloat(x / Double(image!.size.width) * geometry.size.width)
//	}
//	
//	func translateY(_ boundingBox: String, geometry: GeometryProxy) -> CGFloat {
//		let bbox = parseBoundingBox(boundingBox)
//		let y = bbox.y
//		return CGFloat(y / Double(image!.size.height) * geometry.size.height)
//	}
	
//	func scaleWidth(_ boundingBox: String, geometry: GeometryProxy) -> CGFloat {
//		let bbox = parseBoundingBox(boundingBox)
//		let width = bbox.width
//		return CGFloat(width / Double(image!.size.width) * geometry.size.width)
//	}
//	
//	func scaleHeight(_ boundingBox: String, geometry: GeometryProxy) -> CGFloat {
//		let bbox = parseBoundingBox(boundingBox)
//		let height = bbox.height
//		return CGFloat(height / Double(image!.size.height) * geometry.size.height)
//	}

	
	func uploadImage() {
		guard let url = URL(string: "http://10.0.1.29:5000/predict") else {
			showAlert(message: "Invalid server URL")
			return
		}
		guard let imageToUpload = image else {
			showAlert(message: "Image not found")
			return
		}
		guard let imageData = imageToUpload.jpegData(compressionQuality: 0.9) else {
			showAlert(message: "Failed to process image")
			return
		}
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		
		let boundary = "Boundary-\(UUID().uuidString)"
		request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
		
		var body = Data()
		body.append("--\(boundary)\r\n".data(using: .utf8)!)
		body.append("Content-Disposition: form-data; name=\"image\"; filename=\"img2.jpg\"\r\n".data(using: .utf8)!)
		body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
		body.append(imageData)
		body.append("\r\n".data(using: .utf8)!)
		body.append("--\(boundary)--\r\n".data(using: .utf8)!)
		
		let task = URLSession.shared.uploadTask(with: request, from: body) { data, response, error in
			guard let data = data else {
				print("No data in response: \(error?.localizedDescription ?? "Unknown error")")
				return
			}
			
			do {
				// First, decode the data into a string
				let jsonResponseString = try JSONDecoder().decode(String.self, from: data)
				// Convert the string back into Data
				guard let jsonData = jsonResponseString.data(using: .utf8) else {
					DispatchQueue.main.async {
						print("Failed to convert JSON string back to Data")
					}
					return
				}
				// Now, decode your actual structure
				let decodedResponse = try JSONDecoder().decode([ObjectPredictionContainer].self, from: jsonData)
				DispatchQueue.main.async {
					// Update UI or state with the decoded response
					self.predictions = decodedResponse.map { $0.ObjectPrediction }
				}
				print("Decoded response: \(decodedResponse)")
			} catch {
				print("Failed to decode response: \(error)")
			}
		}
		task.resume()
	}

	
}
func showAlert(message: String) {
	// Method to show an alert or handle the error visually in your app
	print(message)
}
// Encapsulate each prediction
struct ObjectPredictionContainer: Codable, Hashable {
	let ObjectPrediction: PredictionDetails
}

// Details of each prediction
struct PredictionDetails: Codable, Hashable {
	let bbox: BoundingBox
	let mask: String?
	let score: PredictionScore
	let category: CategoryDetails
}

// Bounding box information
struct BoundingBox: Codable, Hashable {
	let BoundingBox: String
	let w: Double
	let h: Double
}

// Score of the prediction
struct PredictionScore: Codable, Hashable {
	let PredictionScore: Double
}

// Category information nested within another "Category" key
struct CategoryDetails: Codable, Hashable {
	let Category: Category
}

// Actual category data
struct Category: Codable, Hashable {
	let id: Int
	let name: String
}
// Update the decoding part if needed


//@main
//struct YourAppName: App {
//	var body: some Scene {
//		WindowGroup {
//			ContentView()
//		}
//	}
//}
