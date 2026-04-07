import Foundation

struct RenameContext {
    let originalName: String       // filename without extension
    let outputExtension: String    // e.g. "webp"
    let date: Date
    let sequenceNumber: Int
    let width: Int
    let height: Int
    let formatName: String         // e.g. "webp"
    let presetName: String         // e.g. "Web quality"
    let savingsPercent: Int        // e.g. 42

    /// Date formatted as YYYY-MM-DD
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    /// Time formatted as HH-mm-ss
    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH-mm-ss"
        return formatter.string(from: date)
    }

    /// Zero-padded sequence number (3 digits)
    var paddedNumber: String {
        String(format: "%03d", sequenceNumber)
    }
}
