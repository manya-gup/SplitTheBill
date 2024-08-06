import TesseractOCR
import Combine

class ImageReader: ObservableObject {
    func extractText(image: UIImage, lang: String = "eng", completion: @escaping ([String]) -> Void) {
        let tesseract = G8Tesseract(language: lang)
        tesseract?.engineMode = .tesseractOnly
        tesseract?.pageSegmentationMode = .auto

        var texts: [String] = []

        let preprocessedImages: [UIImage?] = [
            image,
            ImageProcessor.preprocessImageGrayscaleThreshold(image: image),
            ImageProcessor.preprocessImageSharpen(image: image),
            ImageProcessor.preprocessImageBrighten(image: image)
        ]

        let group = DispatchGroup()

        for preprocessedImage in preprocessedImages {
            guard let image = preprocessedImage else { continue }
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                tesseract?.image = image
                tesseract?.recognize()
                if let text = tesseract?.recognizedText {
                    texts.append(text)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion(texts)
        }
    }

    func parseReceipt(text: String) -> Bill? {
        let lines = text.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        var restaurantName: String?
        var items: [FoodItem] = []
        var subtotal: Float?
        var gratuity: Float?
        var tax: Float?
        var total: Float?
        var date: Date?

        let itemPattern = try! NSRegularExpression(pattern: "(\\d+)?\\s*(.*?)\\s*\\$?(\\d+\\.\\d{2})")
        let subtotalPattern = try! NSRegularExpression(pattern: "Subtotal\\s*\\$?(\\d+\\.\\d{2})")
        let taxPattern = try! NSRegularExpression(pattern: "Tax\\s*\\$?(\\d+\\.\\d{2})")
        let gratuityPattern = try! NSRegularExpression(pattern: "Gratuity\\s*\\(\\s*(\\d+\\.\\d{2})%?\\s*\\)")
        let totalPattern = try! NSRegularExpression(pattern: "Total\\s*\\$?(\\d+\\.\\d{2})")
        let datePattern = try! NSRegularExpression(pattern: "Ordered:\\s*(\\d{1,2}/\\d{1,2}/\\d{2,4}\\s\\d{1,2}:\\d{2}\\s(?:AM|PM))")
        let dateFallbackPattern = try! NSRegularExpression(pattern: "(\\d{1,2}/\\d{1,2}/\\d{2,4}\\s\\d{1,2}:\\d{2}:\\d{2}\\s(?:AM|PM))")

        for line in lines {
            if restaurantName == nil, !line.isEmpty, !line.contains("Order Number") {
                restaurantName = line
                continue
            }

            if let match = itemPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let quantity = (line as NSString).substring(with: match.range(at: 1)).isEmpty ? 1 : Int((line as NSString).substring(with: match.range(at: 1)))!
                let name = (line as NSString).substring(with: match.range(at: 2))
                let price = Float((line as NSString).substring(with: match.range(at: 3)))!
                items.append(FoodItem(text1: name, text2: "", selectedNumber: quantity, addedPersons: []))
                continue
            }

            if let match = subtotalPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                subtotal = Float((line as NSString).substring(with: match.range(at: 1)))
            }

            if let match = gratuityPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                gratuity = Float((line as NSString).substring(with: match.range(at: 1)))
            }

            if let match = taxPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                tax = Float((line as NSString).substring(with: match.range(at: 1)))
            }

            if let match = totalPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                total = Float((line as NSString).substring(with: match.range(at: 1)))
            }

            if let match = datePattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let dateString = (line as NSString).substring(with: match.range(at: 1))
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yy hh:mm a"
                date = formatter.date(from: dateString)
            } else if let match = dateFallbackPattern.firstMatch(in: line, options: [], range: NSRange(location: 0, length: line.count)) {
                let dateString = (line as NSString).substring(with: match.range(at: 1))
                let formatter = DateFormatter()
                formatter.dateFormat = "MM/dd/yyyy hh:mm:ss a"
                date = formatter.date(from: dateString)
            }
        }

        guard let restaurantNameUnwrapped = restaurantName else { return nil }

        return Bill(tip: gratuity?.description ?? "", tax: tax?.description ?? "", pickedContacts: [], inputInfos: items, isPersonSelected: [], title: restaurantNameUnwrapped)
    }
}
