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
    
    public func timeout(_ timeout: TimeInterval) -> Self {
        self.urlRequest.timeoutInterval = timeout
        return self
    }
    
    public func start() async throws(RequestError) -> T.ResponseClass {
        do {
            let (data, resBasic) = try await self.session.data(for: self.urlRequest)
            let response = resBasic as! HTTPURLResponse
            let parser = T()
            if !parser.canParse(response: response, data: data) {
                throw RequestErrorPayload(errorType: .parseIneligible, description: "Cannot use requested parser.")
            }
            if response.statusCode < 300 {
                guard let parsed = try? parser.parse(data: data) else {
                    throw RequestError.parseError(data)
                }
                return parsed
            } else {
                throw RequestError
                    .fromCode(code: response.statusCode, data: data)
            }
        } catch let error as URLError {
            throw RequestError.urlSessionError(error)
        } catch let error as RequestError {
            throw error
        } catch {
            throw RequestError.unknownError(error)
        }
    }
}

public struct Response<T> {
    public var data: T?
    public var status_code: Int
    public var raw: Data
}

public struct RequestErrorPayload: Error {
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

public enum RequestError: LocalizedError {
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
         unknownError(Error)

    public var errorDescription: String? {
        guard let data = serverMessageData(), !data.isEmpty else {
            return summary
        }

        let body = String(decoding: data, as: UTF8.self)
        let preview = body.prefix(1_000)
        let suffix = preview.endIndex < body.endIndex ? "…" : ""
        return "\(summary)\nResponse body: \(preview)\(suffix)"
    }

    private var summary: String {
        switch self {
        case .unauthorized:
            return "Authentication is required to complete this request (HTTP 401)."
        case .paymentRequied:
            return "Payment is required to complete this request (HTTP 402)."
        case .forbidden:
            return "You do not have permission to access this resource (HTTP 403)."
        case .notFound:
            return "The requested resource could not be found (HTTP 404)."
        case .methodNotAllowed:
            return "The server does not allow this request method for the resource (HTTP 405)."
        case .notAcceptable:
            return "The server cannot provide a response in an acceptable format (HTTP 406)."
        case .proxyAuthRequired:
            return "The proxy requires authentication (HTTP 407)."
        case .requestTimeout:
            return "The server timed out waiting for the request (HTTP 408)."
        case .conflict:
            return "The request conflicts with the current state of the resource (HTTP 409)."
        case .gone:
            return "The requested resource is no longer available (HTTP 410)."
        case .lengthRequired:
            return "The server requires a content length for this request (HTTP 411)."
        case .preconditionFailed:
            return "A precondition for the request was not met (HTTP 412)."
        case .contentTooLarge:
            return "The request body is too large for the server (HTTP 413)."
        case .uriTooLong:
            return "The request URL is too long for the server (HTTP 414)."
        case .unsupportedMediaType:
            return "The server does not support the request's content type (HTTP 415)."
        case .urlSessionError(let error):
            return "The network request failed: \(error.localizedDescription)"
        case .otherCode(let code, _):
            return "The server returned HTTP \(code): \(HTTPURLResponse.localizedString(forStatusCode: code))."
        case .parseError:
            return "The server response could not be parsed into the expected format."
        case .unknownError(let error):
            return "The request failed: \(error.localizedDescription)"
        }
    }
    
    static func fromCode(code: Int, data: Data) -> RequestError {
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
