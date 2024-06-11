import Foundation

public class Request<T: Response> {
    var session: URLSession
    
    var urlRequest: URLRequest
    var timeout: TimeInterval = 30
    
    var delegate: (any URLSessionDelegate)?
    
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
    
    public func start() async throws -> T.ResponseClass {
        do {
            let (data, response) = try await self.session.data(for: self.urlRequest)
            let parser = T()
            if !parser.canParse(response: response as! HTTPURLResponse, data: data) {
                throw RequestError(errorType: .parseIneligible, description: "Cannot use requested parser.")
            }
            guard let parsed = parser.parse(response: response as! HTTPURLResponse, data: data) else {
                throw RequestError(errorType: .parseFailed, description: "Parser produced error.")
            }
            return parsed
        } catch {
            throw RequestError(errorType: .networkFailed, description: error.localizedDescription)
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
                guard let parsed = parser.parse(response: response as! HTTPURLResponse, data: data!) else {
                    ch(.failure(.init(errorType: .parseFailed, description: "Parser produced error.")))
                    return
                }
                ch(.success(parsed))
                return
            }
        }
    }
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
