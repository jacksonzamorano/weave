import Foundation

public protocol ResponseType {
    associatedtype ResponseClass = Any
    
    init()
    
    func canParse(response: HTTPURLResponse, data: Data) -> Bool
    func parse(response: HTTPURLResponse, data: Data) throws -> ResponseClass
}

public class RawResponse: ResponseType {
    public typealias ResponseClass = Data
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return true
    }
    public func parse(response: HTTPURLResponse, data: Data) throws -> Data {
        return data
    }
}

public class JsonAnyResponse<ValueType>: ResponseType {
    public typealias ResponseClass = ValueType
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return response.statusCode < 400
    }
    
    public func parse(response: HTTPURLResponse, data: Data) throws -> JsonAnyResponse<ValueType>.ResponseClass {
        return try JSONSerialization.jsonObject(with: data) as! JsonAnyResponse<ValueType>.ResponseClass
    }
    
}

public class JsonCodableResponse<ValueType: Codable>: ResponseType {
    public typealias ResponseClass = ValueType
    
    required public init() {
        
    }
    
    public func canParse(response: HTTPURLResponse, data: Data) -> Bool {
        return true
    }
    
    public func parse(response: HTTPURLResponse, data: Data) throws -> ValueType {
        return try JSONDecoder().decode(ValueType.self, from: data)
    }
}
