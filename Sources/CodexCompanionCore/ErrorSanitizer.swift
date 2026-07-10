import Foundation

public enum ErrorSanitizer {
    public static func displayMessage(_ message: String, maxLength: Int = 240) -> String {
        var result = message
        let patterns = [
            #"(?i)(authorization\s*[:=]\s*bearer\s+)[^\s\"']+"#,
            #"(?i)(token\s*[:=]\s*)[^\s\"']+"#,
            #"(?i)(cookie\s*[:=]\s*)[^\s\"']+"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            result = regex.stringByReplacingMatches(in: result, range: range, withTemplate: "$1[已隐藏]")
        }
        result = result.replacingOccurrences(of: "\n", with: " ")
        return String(result.prefix(maxLength))
    }
}
