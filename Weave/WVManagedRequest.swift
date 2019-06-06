import Foundation
/**
 The main class to make requests with. This can't be created from this class; instead, create a request from a `WVManager`.
 */
public class WVManagedRequest {
    /**
     The HTTP request type.
     */
    public var requestType:WVRequestType = .get
    /**
     The type of response to return.
     */
    public var outputType:WVOutputType = .string
    /**
     HTTP body parameters.
     */
    public var parameters:[String:Encodable] = [:]
    /**
     HTTP headers.
     */
    public var headers:[String:String] = [:]
    /**
     The request URL.
     */
    public var url:URL
    /**
     Number of seconds to try requesting for. Defaults to `10`.
     */
    public var timeoutInterval:TimeInterval = 10
    var manager:WVManager
    init(requestURL req:URL, requestType rt:WVRequestType = .get, outputType ot:WVOutputType, manager mg:WVManager) {
        self.url = req
        self.manager = mg
        self.requestType = rt
        self.outputType = ot
    }
/**
     Starts the HTTP(S) request to the endpoint specified.
     - Parameter finishHandler: After the request finishes, this gets called. Provides a `WVResponse`. You can cast it to the request type you requested in `requestType`.

     - Returns: void
 */
    public func start(finishHandler fin: @escaping (WVResponse)->Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        request.httpMethod = requestType.rawValue
        request.allHTTPHeaderFields = headers
        var combinedParameters = parameters
        for i in manager.baseParameters {
            combinedParameters[i.key] = i.value
        }
        request.httpBody = combinedParameters.percentEscaped().data(using: .utf8)
        manager.session.dataTask(with: request) { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode
            switch self.outputType {
            case .raw:
                let res = WVResponse()
                res.statusCode = status
                res.data = data
                fin(res)
            case .string:
                let res = WVStringResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let str = String(data: d, encoding: .utf8) {
                    res.parseSuccess = true
                    res.parseResult = str
                } else {
                    res.parseSuccess = false
                }
                fin(res)
            case .json:
                let res = WVJSONResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let dict = try? JSONSerialization.jsonObject(with: d, options: .allowFragments) {
                    res.parseSuccess = true
                    res.parseResult = dict
                } else {
                    res.parseSuccess = false
                }
                fin(res)
            }
        }
    }
    
    
}
/**
 The basic request class. Doesn't have any special bells or whistles. Can parse JSON and Strings.
 */
public class WVRequest {
    static var session = URLSession.shared
    
    private var url:URL
    private var requestType:WVRequestType
    private var outputType:WVOutputType
    private var timeoutInterval:TimeInterval
    private var parameters:[String:Encodable]
    private var headers:[String:String]
    
    private init(url:URL, requestType:WVRequestType = .get, outputType:WVOutputType = .string, timeoutInterval:TimeInterval = 10, parameters:[String:Encodable] = [:], headers:[String:String] = [:]) {
        self.url = url
        self.requestType = requestType
        self.outputType = outputType
        self.timeoutInterval = timeoutInterval
        self.parameters = parameters
        self.headers = headers
    }
    /**
     Starts the request.
    - Parameter finishHandler: After the request finishes, this gets called. Provides a `WVResponse`. You can cast it to the request type you requested in `requestType`.
     */
    public func start(finishHandler fin: @escaping (WVResponse)->Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        request.httpMethod = requestType.rawValue
        request.allHTTPHeaderFields = headers
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let req = WVRequest.session.dataTask(with: request) { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode
            switch self.outputType {
            case .raw:
                let res = WVResponse()
                res.statusCode = status
                res.data = data
                fin(res)
            case .string:
                let res = WVStringResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let str = String(data: d, encoding: .utf8) {
                    res.parseSuccess = true
                    res.parseResult = str
                } else {
                    res.parseSuccess = false
                }
                fin(res)
            case .json:
                let res = WVJSONResponse()
                res.statusCode = status
                res.data = data
                if let d = data, let dict = try? JSONSerialization.jsonObject(with: d, options: .allowFragments) {
                    res.parseSuccess = true
                    res.parseResult = dict
                } else {
                    res.parseSuccess = false
                }
                fin(res)
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
    case get = "GET", post = "POST", patch = "PATCH", put = "PUT"
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
     The raw data recieved from the request.
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
