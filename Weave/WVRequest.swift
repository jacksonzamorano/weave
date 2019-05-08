import UIKit
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
public class WVRequest {
    public var requestURL:URL
    public var sessionConfiguration:URLSessionConfiguration = URLSessionConfiguration.default
    public var session = URLSession(configuration: .default)
    public init(withRequestURL rurl:URL) {
        self.requestURL = rurl
    }
    
    //#MARK:- Convience Functions
    fileprivate func createURLRequest(methodType:WVRequestType, timeout:TimeInterval = 10) -> URLRequest {
        var request = URLRequest(url: requestURL)
        request.httpMethod = methodType.rawValue
        request.timeoutInterval = timeout
        return request
    }
    fileprivate func paramsToString(params:[String:String]) -> String {
        var string = "{"
        for i in params {
            string += "\"\(i.key)\":\"\(i.value)\","
        }
        string += "}"
        return string
    }
    
    //#MARK:- Parsing
    func parseString(data:Data?, response:URLResponse?) -> WVStringResponse {
        let string = WVStringResponse()
        let res = response as? HTTPURLResponse
        string.statusCode = res?.statusCode
        if let str = data {
            string.string = String(data: str, encoding: .utf8)!
        }
        return string
    }
    func parseJSON(data:Data?, response:URLResponse?) -> WVJSONResponse {
        let r = WVJSONResponse()
        let res = response as? HTTPURLResponse
        let dict = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
        r.statusCode = res?.statusCode
        r.json = dict
        return r
    }
    func parseJSONError(data:Data?, status:Int?) -> WVJSONResponse {
        let res = WVJSONResponse()
        res.statusCode = status
        if let d = data, let str = String(data: d, encoding: .utf8) {
            res.error = str
        }
        return res
    }
    
    //#MARK:- GET Requests
    public func getData(finished comp:@escaping (WVResponse)->Void) {
        let request = createURLRequest(methodType: .get)
        let task = session.dataTask(with: request) { (data, response, error) in
            let res = WVResponse()
            res.data = data
            res.statusCode = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async {
                comp(res)
            }
        }
        task.resume()
    }
    public func getString(finished comp:@escaping (WVStringResponse)->Void) {
        let request = createURLRequest(methodType: .get)
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                comp(self.parseString(data: data, response: response))
            }
        }
        task.resume()
    }
    public func getJSON(decodeIfFaliure:Bool = true, finished comp:@escaping (WVJSONResponse)->Void) {
        let request = createURLRequest(methodType: .get)
        let task = session.dataTask(with: request) { (data, response, error) in
            if (response as? HTTPURLResponse)?.statusCode != 200 {
                if decodeIfFaliure {
                    DispatchQueue.main.async {
                        comp(self.parseJSON(data: data, response: response))
                    }
                } else {
                    DispatchQueue.main.async {
                        comp(self.parseJSONError(data: data, status: (response as? HTTPURLResponse)?.statusCode))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    comp(self.parseJSON(data: data, response: response))
                }
            }
        }
        task.resume()
    }
    //#MARK:- POST Requests
    public func post(parameters:[String:Encodable], finished comp:@escaping (WVResponse)->Void = {_ in}) {
        var request = createURLRequest(methodType: .post)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error) in
            let res = WVResponse()
            res.statusCode = (response as? HTTPURLResponse)?.statusCode
            DispatchQueue.main.async {
                comp(res)
            }
        }
        task.resume()
    }
    public func postString(parameters:[String:Encodable] = [:], finished comp:@escaping (WVStringResponse)->Void) {
        var request = createURLRequest(methodType: .post)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error) in
            DispatchQueue.main.async {
                comp(self.parseString(data: data, response: response))
            }
        }
        task.resume()
    }
    public func postJSON(parameters:[String:Encodable]=[:], decodeIfFaliure:Bool = true, finished comp:@escaping (WVJSONResponse)->Void) {
        var request = createURLRequest(methodType: .post)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = parameters.percentEscaped().data(using: .utf8)
        let task = session.dataTask(with: request) { (data, response, error) in
            if (response as? HTTPURLResponse)?.statusCode != 200 {
                if decodeIfFaliure {
                    DispatchQueue.main.async {
                        comp(self.parseJSON(data: data, response: response))
                    }
                } else {
                    DispatchQueue.main.async {
                        comp(self.parseJSONError(data: data, status: (response as? HTTPURLResponse)?.statusCode))
                    }
                }
            } else {
                DispatchQueue.main.async {
                    comp(self.parseJSON(data: data, response: response))
                }
            }
        }
        task.resume()
    }
    
}

//#MARK:- Response
