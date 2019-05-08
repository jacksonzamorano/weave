import Foundation
public class WVManager {
    
    public var baseParamaters:[String:Encodable] = [:]
    public var baseURL:URL
    public var session:URLSession = URLSession.shared
    
    public init(baseURL base:URL) {
        self.baseURL = base
    }
    public init(baseURL base:URL, baseParameters pm:[String:Encodable]) {
        self.baseURL = base
        self.baseParamaters = pm
    }
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
