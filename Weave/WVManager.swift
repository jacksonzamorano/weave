import Foundation
class WVManager {
    
    var baseParamaters:[String:Encodable] = [:]
    var baseURL:URL
    var session:URLSession = URLSession.shared
    
    init(baseURL base:URL) {
        self.baseURL = base
    }
    func createRequest(forEndpoint end:String, requestType type:WVRequestType = .get, outputType ot:WVOutputType = .string, parameters param:[String:Encodable]) -> WVManagedRequest {
        var point = end
        if point.first == "/" {
            point.removeFirst()
        }
        let request = WVManagedRequest(requestURL: baseURL.appendingPathComponent(point), requestType: type, outputType: ot, manager: self)
        request.parameters = param
        return request
    }
}
