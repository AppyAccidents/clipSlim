import Foundation
import os.log

final class Logger {
    static let shared = Logger()
    
    private let subsystem = "com.clipslim.app"
    private let clipboardLogger = os.Logger(subsystem: "com.clipslim.app", category: "clipboard")
    private let folderLogger = os.Logger(subsystem: "com.clipslim.app", category: "folder")
    private let optimizerLogger = os.Logger(subsystem: "com.clipslim.app", category: "optimizer")
    private let appLogger = os.Logger(subsystem: "com.clipslim.app", category: "app")
    
    private init() {}
    
    func clipboard(_ message: String, type: OSLogType = .default) {
        clipboardLogger.log(level: type, "\(message)")
    }
    
    func folder(_ message: String, type: OSLogType = .default) {
        folderLogger.log(level: type, "\(message)")
    }
    
    func optimizer(_ message: String, type: OSLogType = .default) {
        optimizerLogger.log(level: type, "\(message)")
    }
    
    func app(_ message: String, type: OSLogType = .default) {
        appLogger.log(level: type, "\(message)")
    }
    
    func error(_ message: String, category: String = "app") {
        let logger: os.Logger
        switch category {
        case "clipboard": logger = clipboardLogger
        case "folder": logger = folderLogger
        case "optimizer": logger = optimizerLogger
        default: logger = appLogger
        }
        logger.log(level: .error, "\(message)")
    }
}
