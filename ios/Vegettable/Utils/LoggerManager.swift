import Foundation

// MARK: - 應用日誌和分析
class LoggerManager {
    static let shared = LoggerManager()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }()

    private init() {}

    enum LogLevel {
        case debug, info, warning, error

        var prefix: String {
            switch self {
            case .debug: return "[DEBUG]"
            case .info: return "[INFO]"
            case .warning: return "[WARN]"
            case .error: return "[ERROR]"
            }
        }
    }

    func log(_ message: String, level: LogLevel = .info, file: String = #file, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "\(timestamp) \(level.prefix) [\(fileName):\(line)] \(message)"

        #if DEBUG
        print(logMessage)
        #endif

        saveLog(logMessage)
    }

    private func saveLog(_ message: String) {
        let fileManager = FileManager.default
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }

        let logFile = documentsPath.appendingPathComponent("app_logs.txt")
        let timestamp = Date()
        let logEntry = "\(message)\n"

        if fileManager.fileExists(atPath: logFile.path) {
            if let fileHandle = FileHandle(forWritingAtPath: logFile.path) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(logEntry.data(using: .utf8) ?? Data())
                fileHandle.closeFile()
            }
        } else {
            try? logEntry.write(toFile: logFile.path, atomically: true, encoding: .utf8)
        }
    }
}
