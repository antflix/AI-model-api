import SwiftUI

import SwiftUI
struct ContentView: View {
	@State private var image: UIImage? = UIImage(named: "walls.png")
	@State private var predictions: [PredictionDetails] = []
	@State private var displayImage: UIImage?
	@State private var predictionsByCategory: [String: [PredictionDetails]] = [:]
	
	var body: some View {
		GeometryReader { geometry in
			
			VStack {
				Button("Upload Image") {
					uploadImage()
					displayImage = image
				}
				.padding()
				.background(Color.blue)
				.foregroundColor(Color.white)
				.clipShape(RoundedRectangle(cornerRadius: 8))
				
				Button("Draw Bounding Boxes") {
					if let uiImage = image {
						self.displayImage = drawBoundingBoxes(on: uiImage, predictions: predictions)
					}
				}
				.padding()
				.background(Color.green)
				.foregroundColor(Color.white)
				.clipShape(RoundedRectangle(cornerRadius: 8))
				if let displayImage = displayImage {
					Image(uiImage: displayImage)
						.resizable()
						.scaledToFit()
						.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
				}
				Spacer()
				
				
			}
		}
		.onAppear {
//			xuploadImage()
		}
	}

	
	func handleAPIResponse(data: Data) {
		print("handleAPIResponse(data: Data)")
		do {
			let decodedResponse = try JSONDecoder().decode([ObjectPredictionContainer].self, from: data)
			DispatchQueue.main.async {
				for prediction in decodedResponse.map({ $0.ObjectPrediction }) {
					let categoryName = prediction.category.Category.name
					if self.predictionsByCategory[categoryName] == nil {
						self.predictionsByCategory[categoryName] = []
					}
					self.predictionsByCategory[categoryName]?.append(prediction)
				}
			}
			print("Predictions by category: \(predictionsByCategory)")
		} catch {
			print("Failed to decode response: \(error)")
		}
	}
	func getColor(forCategory category: String) -> Color {
		print("getColor(forCategory category: String) -> Color")
		switch category {
			case "Data Box":
				return .red
			case "Dedicated Outlet":
				return .green
			case "Duplex Outlet":
				return .red
			case "Floor Box":
				return .yellow
			case "Furniture Feed":
				return .blue
			case "Quad Outlet":
				return .orange
			case "TV Box":
				return .purple
			default:
				return .blue
		}
	}
//	{0: 'Data Box', 1: 'Dedicated Outlet', 2: 'Duplex Outlet', 3: 'Floor Box', 4: 'Furniture Feed', 5: 'Quad Outlet', 6: 'TV Box'}
	func drawBoundingBoxes(on image: UIImage, predictions: [PredictionDetails]) -> UIImage? {
		// Begin a graphics context
		
		print("drawBoundingBoxes(on image: UIImage, predictions: [PredictionDetails]) -> UIImage? ")
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
		image.draw(at: .zero) // Draw the base image
		
		// Set the properties for the bounding box
		context.setStrokeColor(UIColor.red.cgColor)
		context.setLineWidth(2)
		
		// Draw each bounding box
		for prediction in predictions {
			let bbox = parseBoundingBox(prediction.bbox.BoundingBox)
			let rect = CGRect(x: bbox.x, y: bbox.y, width: bbox.width, height: bbox.height)
			context.addRect(rect)
			context.strokePath()
		}
		
		// Retrieve the edited image
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return newImage
	}
	
	func overlayView(uiImage: UIImage, geometry: GeometryProxy) -> some View {
		print("overlayView(uiImage: UIImage, geometry: GeometryProxy) -> some View ")
		let imageScale = min(geometry.size.width / uiImage.size.width, geometry.size.height / uiImage.size.height)
		let offsetX = (geometry.size.width - (uiImage.size.width * imageScale)) / 2
		let offsetY = (geometry.size.height - (uiImage.size.height * imageScale)) / 2
		
		return ForEach(predictionsByCategory.keys.sorted(), id: \.self) { category in
			ForEach(predictionsByCategory[category]!, id: \.self) { prediction in
				let bbox = parseBoundingBox(prediction.bbox.BoundingBox)
				if bbox.width > 0 && bbox.height > 0 {
					Rectangle()
						.stroke(getColor(forCategory: category), lineWidth: 2)
						.frame(width: bbox.width * imageScale, height: bbox.height * imageScale)
						.offset(x: (bbox.x * imageScale) + offsetX, y: (bbox.y * imageScale) + offsetY)
				}
			}
		}
	}
	
	func parseBoundingBox(_ boundingBox: String) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {
		print("parseBoundingBox(_ boundingBox: String) -> (x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat)")
		let components = boundingBox.trimmingCharacters(in: CharacterSet(charactersIn: " ()"))
			.split(separator: ",")
			.map { substring -> CGFloat in
				let number = Double(substring.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
				return CGFloat(number)
			}
		if components.count == 4 {
			let x = components[0]
			let y = components[1]
			let x2 = components[2]
			let y2 = components[3]
//			print("Before: x: \(x) y: \(y) y2: \(x2) x2: \(y2)")
//			print("Width before: \(max(x2 - x, 0)) Height before: \(max(y2 - y, 0))")
			return (x: x, y: y, width: max(x2 - x, 0), height: max(y2 - y, 0))
		} else {
			// Return zeros if the components aren't as expected to avoid crashing
			return (x: 0, y: 0, width: 0, height: 0)
		}
	}
	
	
	func uploadImage() {
		print("uploadImage()")
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
	
	static func == (lhs: PredictionDetails, rhs: PredictionDetails) -> Bool {
		return lhs.category.Category.name == rhs.category.Category.name
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(category.Category.name)
	}
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

