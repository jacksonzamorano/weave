import Foundation
/**
 A class for creating and managing `WVRequest`s.
 */
public class WVManager {
    /**
     All of these parameters will be copied to *every* request created from this manager.
     */
    public var baseParameters:[String:Encodable] = [:]
    /**
     A base URL. This URL could be used for an API start. (i.e. "https://api.github.com")
     */
    public var baseURL:URL
    /**
     A URL session used by underlying NSURLSession framework. Defaults to `URLSession.shared`. Can be changed to a background session to download large files in the background.
     */
    public var session:URLSession = URLSession.shared
    /**
     Creates a new manager.
     - Parameter baseURL: The base URL to be used. See declaration.
     */
    public init(baseURL base:URL) {
        self.baseURL = base
    }
    /**
     Creates a new manager with base parameters.
     - Parameter baseURL: The base URL to be used. See declaration.
     - Parameter baseParameters: The base parameters to be used. See declaration.
     */
    public init(baseURL base:URL, baseParameters pm:[String:Encodable]) {
        self.baseURL = base
        self.baseParameters = pm
    }
    /**
     Creates a new `WVRequest`.
     - Parameter forEndpoint: The endpoint to extend off of `baseURL`.
     - Parameter requestType: The HTTP request type to use.
     - Parameter outputType: The output type/parser to use.
     - Parameter parameters: Extra parmeters to provide on top of `baseParameters`.
     */
    public func createRequest(forEndpoint end:String, requestType type:WVRequestType = .get, outputType ot:WVOutputType = .string, parameters param:[String:Encodable]) -> WVManagedRequest {
        var point = end
        if point.first == "/" {
            point.removeFirst()
        }
        let request = WVManagedRequest(requestURL: baseURL.appendingPathComponent(point), requestType: type, outputType: ot, manager: self)
        request.parameters = param
        return request
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
