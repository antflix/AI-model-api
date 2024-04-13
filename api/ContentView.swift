////
////  ContentView.swift
////  api
////
////  Created by Anthony on 4/9/24.
////
//import SwiftUI
//
//extension Data {
//  mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
//    if let data = string.data(using: encoding) {
//      append(data)
//    }
//  }
//}
////struct DetectionResponse: Decodable {
////	let class_id: [Int]
////	let bounding_boxes: [[CGFloat]]
////}
//struct Category: Decodable {
//	let id: Int
//	let name: String
//}
//
//struct Score: Decodable {
//	let PredictionScore: Double
//}
//
//struct BoundingBox: Decodable {
//	let BoundingBox: String // "(x, y, x2, y2)"
//	let w: CGFloat
//	let h: CGFloat
//	
//	var rect: CGRect {
//		let numbers = BoundingBox
//			.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
//			.split(separator: ",")
//			.compactMap { CGFloat(Double($0.trimmingCharacters(in: .whitespaces))!) }
//		guard numbers.count == 4 else { return .zero }
//		return CGRect(x: numbers[0], y: numbers[1], width: numbers[2] - numbers[0], height: numbers[3] - numbers[1])
//	}
//}
//
//
//struct ObjectPrediction: Decodable {
//	let bbox: BoundingBox
//	let mask: String?
//	let score: Score
//	let category: Category
//}
//
//struct APIResponseItem: Decodable {
//	let ObjectPrediction: ObjectPrediction
//}
//
//struct DetectionResponse: Decodable {
//	let predictions: [APIResponseItem]
//	
//	var detections: [Detection] {
//		predictions.map {
//			Detection(classId: $0.ObjectPrediction.category.id,
//					  boundingBox: $0.ObjectPrediction.bbox.rect,  score: $0.ObjectPrediction.score.PredictionScore)
//		}
//	}
//}
//
//struct Detection: Identifiable {
//	let id = UUID()  // To conform to Identifiable
//	let classId: Int
//	let boundingBox: CGRect
//	let score: Double? // Optional score property
//}
//class DetectionData: ObservableObject {
//	@Published var detections: [Detection] = []
//}
//
//class BoundingBoxView: UIView {
//	var image: UIImage? // Hold the image reference to calculate scale
//	var detections: [Detection] = []
//	
//	override func draw(_ rect: CGRect) {
//		super.draw(rect)
//		
//		guard let context = UIGraphicsGetCurrentContext(), let image = image else { return }
//		print("boundingboxview")
//		// Calculate the scale factors
//		let scaleX = rect.width / image.size.width
//		let scaleY = rect.height / image.size.height
//		let scale = min(scaleX, scaleY) // To maintain the aspect ratio
//		
//		context.setStrokeColor(UIColor.red.cgColor)
//		context.setLineWidth(2)
//		print("!!!!!!!!!!!!!!!!!!!!!!!boundingBoxView\(detections)")
//		detections.forEach { detection in
//			let scaledRect = CGRect(
//				x: detection.boundingBox.origin.x * scale,
//				y: detection.boundingBox.origin.y * scale,
//				width: detection.boundingBox.width * scale,
//				height: detection.boundingBox.height * scale
//				)
////			).offsetBy(dx: (rect.width - image.size.width * scale) / 2, dy: (rect.height - image.size.height * scale) / 2) // Center the bounding box if the image is centered
//			print("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
//			context.addRect(scaledRect)
//			context.drawPath(using: .stroke)
//		}
//	}
//
//	func update(with image: UIImage?, detections: [Detection]) {
//		self.image = image
//		self.detections = detections
//		self.setNeedsDisplay()
//	}
//
//
//}
//struct BoundingBoxDrawingView: UIViewRepresentable {
//	var image: UIImage?
//	var detections: [Detection]
//	
//	func makeUIView(context: Context) -> BoundingBoxView {
//		let view = BoundingBoxView()
//		view.backgroundColor = UIColor.clear // Make the background transparent
//		return view
//	}
//
//	
//	func updateUIView(_ uiView: BoundingBoxView, context: Context) {
//		// Pass both the image and detections to the UIView for updating
//		uiView.update(with: image, detections: detections)
//	}
//}
////
////struct DetectionResponse: Decodable {
////  let class_id: [Int]
////  let bounding_boxes: [[CGFloat]]  // Assuming format: [[x1, y1, x2, y2], ...]
////
////  var detections: [Detection] {
////    zip(class_id, bounding_boxes).map { classId, box in
////      Detection(
////        classId: classId,
////        boundingBox: CGRect(x: box[0], y: box[1], width: box[2] - box[0], height: box[3] - box[1]))
////    }
////  }
////}
//
//struct ContentView: View {
//	@State private var image: UIImage? = UIImage(named: "123") // Placeholder for your image
//	@State private var detections: [Detection] = []
//	@StateObject private var detectionData = DetectionData() // Holds the detections
//
//	@State private var uploadResult: String? // To store the result or error message
//	
//	var body: some View {
//		GeometryReader { geometry in
//			
//			ZStack(alignment: .topLeading) {
//				// Image as the background
//				if let uiImage = image {
//					Image(uiImage: uiImage)
//						.resizable()
//						.aspectRatio(contentMode: .fit)
//						.frame(width: geometry.size.width)
//						.background(Color.clear) // Ensure background is clear
//				}
//				
//				// Overlay bounding boxes on the image
//				BoundingBoxDrawingView(image: self.image, detections: detections)
//					.frame(width: geometry.size.width, height: geometry.size.height)
//					.background(Color.clear) // Ensure background is clear
//			}
//		}
//
////				// Clip to bounding box's frame to avoid drawing outside
//
////				// Overlay UI controls on top of the image and bounding boxes
////				VStack {
////				
////					
////					// Button to trigger image upload
////					Button("Upload Image") {
////						uploadImageToServer()
////					}
////					.padding() // Adds padding around the button for better tapability and aesthetics
////				}
//			//sIgnoringSafeArea(.all) // Extend to the edges if necessary
//		.onAppear {
////			BoundingBoxDrawingView(detections: detections)
//			uploadImageToServer()
//		
//		}
//		// Display the upload result or error message
////		.alert("Upload Result", isPresented: .constant(uploadResult != nil), presenting: uploadResult) { detail in
////			Button("OK", role: .cancel) {}
////		} message: { detail in
////			Text(detail)
////		}
//	}
////  func loadDetections() {
////    print("loadDetections")
////
////    // Parse the server response and update `detections`
////    // Assuming you've parsed your server's response into `DetectionResponse`
////    let mockResponse = DetectionResponse(
////      class_id: [0], bounding_boxes: [[1436.586, 504.266, 1466.123, 533.599]])
////    detections = mockResponse.detections
////  }
//  func uploadImageToServer() {
//    print("uploadimagetoserver")
//    guard let imageToUpload = image else {
//      print("Image is nil")
//      return
//    }
//
//    uploadImage(image: imageToUpload) { result in
//      DispatchQueue.main.async {
//        switch result {
//			case .success(let detections):
//				print("Upload success")
//				print(detections)
//				print(image!.size)
//				self.detections = detections // Update your detections state with the API response
//				uploadResult = "Success"
//
//        case .failure(let error):
//          print("Upload failed: \(error.localizedDescription)")
//          uploadResult = "Failure: \(error.localizedDescription)"
//        }
//      }
//    }
//  }
//}
//func uploadImage(image: UIImage, completion: @escaping (Result<[Detection], Error>) -> Void) {
//	print("Uploading image...")
//	
//	guard let url = URL(string: "http://10.0.1.29:5003/predict") else {
//		print("Invalid URL")
//		return
//	}
//	
//	guard let imageData = image.jpegData(compressionQuality: 1.0) else {
//		print("Could not convert image to Data")
//		return
//	}
//	
//	let boundary = "Boundary-\(UUID().uuidString)"
//	var request = URLRequest(url: url)
//	request.httpMethod = "POST"
//	request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//	
//	var body = Data()
//	body.append("--\(boundary)\r\n")
//	body.append("Content-Disposition: form-data; name=\"myfile\"; filename=\"image.jpg\"\r\n")
//	body.append("Content-Type: image/jpeg\r\n\r\n")
//	body.append(imageData)
//	body.append("\r\n--\(boundary)--\r\n")
//	
//	request.httpBody = body
//	
//	URLSession.shared.dataTask(with: request) { data, response, error in
//		if let error = error {
//			DispatchQueue.main.async { completion(.failure(error)) }
//			return
//		}
//		
//		guard let data = data else {
//			DispatchQueue.main.async { completion(.failure(URLError(.badServerResponse))) }
//			return
//		}
//		
//		do {
//			// First, decode the string
//			let jsonResponseString = try JSONDecoder().decode(String.self, from: data)
//			// Convert the string back into Data
//			guard let jsonData = jsonResponseString.data(using: .utf8) else {
//
//				DispatchQueue.main.async { completion(.failure(URLError(.cannotDecodeRawData))) }
//				return
//			}
//			// Now, decode your actual structure
//			let detectionResponse = try JSONDecoder().decode(DetectionResponse.self, from: jsonData)
//		
//
//			DispatchQueue.main.async { completion(.success(detectionResponse.detections)) }
//		} catch {
//			print("Decoding error: \(error)")
//			DispatchQueue.main.async { completion(.failure(error)) }
//		}
//	}.resume()
//}
//
//// Helper extension to make appending to Data more convenient
//
//#Preview{
//  ContentView()
//}
