import Foundation

@available(macOS 12.0, *)
public class Request<T: ResponseType> {
    var session: URLSession
    
    var urlRequest: URLRequest
    var timeout: TimeInterval = 30
    
    var delegate: (any URLSessionDelegate)?
    
    public var url: URL {
        get {
            return urlRequest.url!
        }
    }
    
    public convenience init(_ url: URL) {
        var req = URLRequest(url: url)
        req.httpMethod = RequestMethod.get.rawValue
        self.init(urlRequest: URLRequest(url: url))
    }
    
    public init(urlRequest req: URLRequest) {
        self.urlRequest = req
        self.session = URLSession.shared
    }
    
    public func body(_ body: any BodyData) -> Self {
        self.urlRequest.httpBody = body.intoData()
        self.urlRequest.setValue(body.contentType(), forHTTPHeaderField: "Content-Type")
        return self
    }
    
    public func header(key: String, value: String) -> Self {
        self.urlRequest.setValue(value, forHTTPHeaderField: key)
        return self
    }
    
    public func allowInsecure() -> Self {
        self.delegate = AllowInsecureRequestDelegate()
        return self
    }
    
    public func bearer(_ token: String) -> Self {
        self.urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return self
    }
    
    public func method(_ method: RequestMethod) -> Self {
        self.urlRequest.httpMethod = method.rawValue
        return self
    }
    
    public func start() async throws -> Response<T.ResponseClass> {
        do {
            let (data, resBasic) = try await self.session.data(for: self.urlRequest)
            let response = resBasic as! HTTPURLResponse
            let parser = T()
            if !parser.canParse(response: response, data: data) {
                throw RequestError(errorType: .parseIneligible, description: "Cannot use requested parser.")
            }
            var res = Response<T.ResponseClass>(status_code: response.statusCode, raw: data)
            do {
                let parsed = try parser.parse(response: response as! HTTPURLResponse, data: data)
                res.data = parsed
            } catch {
                print(error)
            }
            return res
        } catch {
            print(error)
            throw error
        }
    }
    
    public func startTask(_ ch: @escaping (Result<T.ResponseClass, RequestError>) -> Void) {
        self.session.dataTask(with: self.urlRequest) { data, response, error in
            if let e = error {
                ch(.failure(.init(errorType: .networkFailed, description: e.localizedDescription)))
                return
            } else {
                let parser = T()
                if !parser.canParse(response: response as! HTTPURLResponse, data: data!) {
                    ch(.failure(.init(errorType: .parseIneligible, description: "Cannot use requested parser.")))
                    return
                }
                guard let parsed = try? parser.parse(response: response as! HTTPURLResponse, data: data!) else {
                    ch(.failure(.init(errorType: .parseFailed, description: "Parser produced error.")))
                    return
                }
                ch(.success(parsed))
                return
            }
        }
    }
}

public struct Response<T> {
    public var data: T?
    public var status_code: Int
    public var raw: Data
}

public struct RequestError: Error {
    var errorType: RequestErrorType
    var description: String
}

public enum RequestErrorType {
    case networkFailed
    case parseIneligible
    case parseFailed
}

public enum RequestMethod: String {
    case get = "GET", post = "POST", patch = "PATCH", put = "PUT", delete = "DELETE"
}
