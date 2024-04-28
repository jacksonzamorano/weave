import Foundation

class WVInsecureRequestDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if let st = challenge.protectionSpace.serverTrust {
            return (URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: st))
        } else {
            return (URLSession.AuthChallengeDisposition.useCredential, nil)
        }
    }
}

/**
 The basic request class. Doesn't have any special bells or whistles. Can parse JSON and Strings.
 */
public class WVRequest {
    var session: URLSession
    var delegate: URLSessionDelegate?
    
    private var url:URL
    private var requestType:WVRequestType
    private var outputType:WVOutputType
    private var timeoutInterval:TimeInterval
    private var parameters:[String:Encodable]
    private var headers:[String:String]
    
    public init(url:URL, requestType:WVRequestType = .get, outputType:WVOutputType = .string, timeoutInterval:TimeInterval = 10, parameters:[String:Encodable] = [:], headers:[String:String] = [:], username: String? = nil, password: String? = nil, allowInsecure: Bool = false) {
        self.url = url
        self.requestType = requestType
        self.outputType = outputType
        self.timeoutInterval = timeoutInterval
        self.parameters = parameters
        self.headers = headers
        if allowInsecure {
            self.delegate = WVInsecureRequestDelegate()
        }
        self.session = URLSession(configuration: URLSessionConfiguration.ephemeral, delegate: self.delegate, delegateQueue: nil)
        if let u = username, let p = password {
            let auth = "\(u):\(p)"
            let authData = auth.data(using: .utf8)
            let authBase64 = authData!.base64EncodedString()
            self.headers["Authorization"] = "Basic \(authBase64)"
        }
    }
    /**
     Starts the request.
    - Parameter finishHandler: After the request finishes, this gets called. Provides a `WVResponse`. You can cast it to the request type you requested in `requestType` (i.e, let json = response as! WVJSONRequest).
     */
    public func start(finishHandler fin: @escaping (WVResponse)->Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        request.httpMethod = requestType.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let req = self.session.dataTask(with: request) { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode
            switch self.outputType {
            case .raw:
                let res = WVResponse()
                res.statusCode = status
                res.data = data
                DispatchQueue.main.async {
                    fin(res)
                }
            case .string:
                let res = WVStringResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let str = String(data: d, encoding: .utf8) {
                    res.parseSuccess = true
                    res.parseResult = str
                    res.string = str
                } else {
                    res.parseSuccess = false
                }
                DispatchQueue.main.async {
                    fin(res)
                }
            case .json:
                let res = WVJSONResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let dict = try? JSONSerialization.jsonObject(with: d, options: .allowFragments) {
                    res.parseSuccess = true
                    res.parseResult = dict
                    res.json = dict
                } else {
                    res.parseSuccess = false
                }
                DispatchQueue.main.async {
                    fin(res)
                }
            }
        }
        req.resume()
    }
    
    /**
     Creates a HTTP(S) request to the endpoint specified.
     - Parameter url: After the request finishes, this gets called.
     - Parameter requestType: The request type to make. Defaults to GET
     - Parameter outputType: The request output type. Defaults to string.
     - Parameter timeoutInterval: How long the request tries for. Defaults to 10 seconds.
     - Parameter parameters: Any HTTP body to send. Defaults to blank.
     - Parameter headers: Any HTTP headers to send. Defaults to blank.
     - Returns: `WVRequest`
     */
    public static func request(url:URL, requestType:WVRequestType = .get, outputType:WVOutputType = .string, timeoutInterval:TimeInterval = 10, parameters:[String:Encodable] = [:], headers:[String:String] = [:]) -> WVRequest {
        return WVRequest(url: url, requestType: requestType, outputType: outputType, timeoutInterval: timeoutInterval, parameters: parameters, headers: headers)
    }
}


public class WVCustomRequest {
    var session: URLSession
    
    private var outputType:WVOutputType
    private var request: URLRequest
    
    public init(request:URLRequest, outputType:WVOutputType = .string) {
        self.request = request
        self.outputType = outputType
        self.session = URLSession.shared
    }
    /**
     Starts the request.
    - Parameter finishHandler: After the request finishes, this gets called. Provides a `WVResponse`. You can cast it to the request type you requested in `requestType` (i.e, let json = response as! WVJSONRequest).
     */
    public func start(finishHandler fin: @escaping (WVResponse)->Void) {
        let req = self.session.dataTask(with: request) { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode
            switch self.outputType {
            case .raw:
                let res = WVResponse()
                res.statusCode = status
                res.data = data
                DispatchQueue.main.async {
                    fin(res)
                }
            case .string:
                let res = WVStringResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let str = String(data: d, encoding: .utf8) {
                    res.parseSuccess = true
                    res.parseResult = str
                    res.string = str
                } else {
                    res.parseSuccess = false
                }
                DispatchQueue.main.async {
                    fin(res)
                }
            case .json:
                let res = WVJSONResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let dict = try? JSONSerialization.jsonObject(with: d, options: .allowFragments) {
                    res.parseSuccess = true
                    res.parseResult = dict
                    res.json = dict
                } else {
                    res.parseSuccess = false
                }
                DispatchQueue.main.async {
                    fin(res)
                }
            }
        }
        req.resume()
    }
    
    /**
     Creates a HTTP(S) request to the endpoint specified.
     - Parameter url: After the request finishes, this gets called.
     - Parameter requestType: The request type to make. Defaults to GET
     - Parameter outputType: The request output type. Defaults to string.
     - Parameter timeoutInterval: How long the request tries for. Defaults to 10 seconds.
     - Parameter parameters: Any HTTP body to send. Defaults to blank.
     - Parameter headers: Any HTTP headers to send. Defaults to blank.
     - Returns: `WVRequest`
     */
    public static func request(url:URL, requestType:WVRequestType = .get, outputType:WVOutputType = .string, timeoutInterval:TimeInterval = 10, parameters:[String:Encodable] = [:], headers:[String:String] = [:]) -> WVRequest {
        return WVRequest(url: url, requestType: requestType, outputType: outputType, timeoutInterval: timeoutInterval, parameters: parameters, headers: headers)
    }
}

/**
 Describes the type of request to be made.
 */
public enum WVRequestType:String {
    /**
     A HTTP request type.
     */
    case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE"
}
/**
 Describes the type of output to be made.
 - `.raw` returns a `WVResponse`
 - `.string` returns a `WVStringResponse`
 - `.json` returns a `WVJSONResponse`
 */
public enum WVOutputType {
    /**
     Indicates a `WVStringResponse`.
     */
    case string
    /**
     Indicates a `WVJSONResponse`.
     */
    case json
    /**
     Indicates a `WVResponse`.
     */
    case raw
}
/**
 A class that is a response from a request. This is a base class for many other response subclasses.
 */
public class WVResponse {
    /**
     The status code, if the request succeeded.
     */
    public var statusCode:Int?
    /**
     The raw data received request.
     */
    public var data:Data?
    /**
     A shorthand of `statusCode == 200`.
     */
    public var success:Bool {
        get {
            return statusCode == 200
        }
    }
}
/**
 A subclass of WVResponse designed to handle responses that need to be parsed or formatted.
 */
public class WVParsedResponse:WVResponse {
    /**
     Is true if the parse succeeded.
     */
    public var parseSuccess = false
    /**
     Subclasses of this class can provide anything here. See documentation for the individual parser.
     */
    public var parseResult:Any?
}
/**
 A WVParsedResponse for parsing responses into strings.
 */
public class WVStringResponse:WVParsedResponse {
    /**
     The string value after parsing.
     */
    public var string:String = ""
}
/**
 A WVParsedResponse for parsing responses into JSON objects.
 */
public class WVJSONResponse:WVParsedResponse {
    /**
     The JSON object after parsing. Depending on the API, you will need to cast this into an array or dictionary.
     */
    public var json:Any? = nil
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
