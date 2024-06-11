import Foundation

public protocol Response {
    associatedtype ResponseClass = Any
    
    init()
    
    func canParse(response: HTTPURLResponse, data: Data) -> Bool
    func parse(response: HTTPURLResponse, data: Data) -> ResponseClass?
}

public class RawResponse: Response {
    public typealias ResponseClass = Data
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return true
    }
    public func parse(response: HTTPURLResponse, data: Data) -> Data? {
        return data
    }
}

public class JsonAnyResponse<ValueType>: Response {
    public typealias ResponseClass = ValueType
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return response.statusCode < 400
    }
    
    public func parse(response: HTTPURLResponse, data: Data) -> JsonAnyResponse<ValueType>.ResponseClass? {
        return try? JSONSerialization.jsonObject(with: data) as? JsonAnyResponse<ValueType>.ResponseClass
    }
    
}

public class JsonCodableResponse<ValueType: Codable>: Response {
    public typealias ResponseClass = ValueType
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return true
    }
    
    public func parse(response: HTTPURLResponse, data: Data) -> ValueType? {
        return try? JSONDecoder().decode(ValueType.self, from: data)
    }
}
