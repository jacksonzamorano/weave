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
    
    public func start() async -> Result<T.ResponseClass, RequestErrorCode> {
        do {
            let (data, resBasic) = try await self.session.data(for: self.urlRequest)
            let response = resBasic as! HTTPURLResponse
            let parser = T()
            if !parser.canParse(response: response, data: data) {
                throw RequestError(errorType: .parseIneligible, description: "Cannot use requested parser.")
            }
            if response.statusCode < 300 {
                guard let parsed = try? parser.parse(data: data) else {
                    return .failure(.parseError(data))
                }
                return .success(parsed)
            } else {
                return .failure(.fromCode(code: response.statusCode, data: data))
            }
        } catch let error as URLError {
            return .failure(.urlSessionError(error))
        } catch {
            return .failure(.unknownError)
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

public enum RequestErrorCode: Error {
    case unauthorized(Data),
         paymentRequied(Data),
         forbidden(Data),
         notFound(Data),
         methodNotAllowed(Data),
         notAcceptable(Data),
         proxyAuthRequired(Data),
         requestTimeout(Data),
         conflict(Data),
         gone(Data),
         lengthRequired(Data),
         preconditionFailed(Data),
         contentTooLarge(Data),
         uriTooLong(Data),
         unsupportedMediaType(Data),
         urlSessionError(URLError),
         otherCode(Int, Data),
         parseError(Data),
         unknownError
    
    static func fromCode(code: Int, data: Data) -> RequestErrorCode {
        switch code {
        case 401:
            return .unauthorized(data)
        case 402:
            return .paymentRequied(data)
        case 403:
            return .forbidden(data)
        case 404:
            return .notFound(data)
        case 405:
            return .methodNotAllowed(data)
        case 406:
            return .notAcceptable(data)
        case 407:
            return .proxyAuthRequired(data)
        case 408:
            return .requestTimeout(data)
        case 409:
            return .conflict(data)
        case 410:
            return .gone(data)
        case 411:
            return .lengthRequired(data)
        case 412:
            return .preconditionFailed(data)
        case 413:
            return .contentTooLarge(data)
        case 414:
            return .uriTooLong(data)
        case 415:
            return .unsupportedMediaType(data)
        default:
            return .otherCode(code, data)
        }
    }
    
    public func serverMessageData() -> Data? {
        switch self {
        case
                .unauthorized(let data),
                .paymentRequied(let data),
                .forbidden(let data),
                .notFound(let data),
                .methodNotAllowed(let data),
                .notAcceptable(let data),
                .proxyAuthRequired(let data),
                .requestTimeout(let data),
                .conflict(let data),
                .gone(let data),
                .lengthRequired(let data),
                .preconditionFailed(let data),
                .contentTooLarge(let data),
                .uriTooLong(let data),
                .unsupportedMediaType(let data),
                .otherCode(_, let data),
                .parseError(let data):
            return data
        default:
            return nil
        }
    }
    
    public func serverMessageJSON<T: Codable>() -> T? {
        guard let smData = serverMessageData() else {
            return nil
        }
        let jsonParser = JSONDecoder()
        let data = try? jsonParser.decode(T.self, from: smData)
        return data
    }
    
    public func serverMessageString() -> String? {
        guard let smData = serverMessageData() else {
            return nil
        }
        return String(data: smData, encoding: .utf8)
    }
}
