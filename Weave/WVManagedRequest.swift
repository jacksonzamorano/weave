import Foundation
public class WVManagedRequest {
    public var type:WVRequestType = .get
    public var output:WVOutputType = .string
    public var parameters:[String:Encodable] = [:]
    public var url:URL
    var timeoutInterval:TimeInterval = 10
    var manager:WVManager
    init(requestURL req:URL, requestType rt:WVRequestType = .get, outputType ot:WVOutputType, manager mg:WVManager) {
        self.url = req
        self.manager = mg
        self.type = rt
        self.output = ot
    }
    
    public func start(finishHandler fin: @escaping (WVResponse)->Void) {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeoutInterval)
        request.httpMethod = type.rawValue
        if type == .post {
            var combinedParameters = parameters
            for i in manager.baseParamaters {
                combinedParameters[i.key] = i.value
            }
            request.httpBody = combinedParameters.percentEscaped().data(using: .utf8)
        }
        manager.session.dataTask(with: request) { (data, response, error) in
            let status = (response as? HTTPURLResponse)?.statusCode
            switch self.output {
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
                if let d = data, let dict = try? JSONSerialization.jsonObject(with: d, options: .allowFragments) as? NSDictionary {
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
public enum WVRequestType:String {
    case get = "GET", post = "POST"
}
public enum WVOutputType {
    case string,json,raw
}
public class WVResponse {
    public var statusCode:Int?
    public var data:Data?
    public var success:Bool {
        get {
            return statusCode == 200
        }
    }
}
public class WVParsedResponse:WVResponse {
    var parseSuccess = false
    var parseResult:Any?
}
public class WVStringResponse:WVParsedResponse {
    public var string:String = ""
}
public class WVJSONResponse:WVParsedResponse {
    public var json:NSDictionary = [:]
    public var error:String?
}
