import Foundation

public protocol BodyData {
    func contentType() -> String
    func intoData() -> Data
}

public class JsonBody: BodyData {
    public let data: Codable
    
    public init(data: Codable) {
        self.data = data
    }
    
    public func contentType() -> String {
        return "application/json"
    }
    
    public func intoData() -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .withoutEscapingSlashes
        return try! encoder.encode(data)
    }
}

extension [String: String]: BodyData {
    
    public func contentType() -> String {
        return "application/x-www-form-urlencoded"
    }
    
    public func intoData() -> Data {
        self.percentEscaped().data(using: .utf8)!
    }
}

extension Dictionary {
    func percentEscaped() -> String {
        return map { (key, value) in
            let escapedKey = "\(key)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            let escapedValue = "\(value)".addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
            return escapedKey + "=" + escapedValue
            }
            .joined(separator: "&")
    }
}
extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*+,;="
        
        var allowed = CharacterSet.urlQueryAllowed
        allowed.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        return allowed
    }()
}
