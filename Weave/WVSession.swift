import UIKit
public class WVSession {
    var root:URL
    public init(withRootURL rt:URL) {
        var str = rt.absoluteString
        if str.last != "/" {
            str += "/"
        }
        self.root = URL(string: str)!
    }
    public func requestForEndpoint(endpoint end:String) -> WVRequest {
        var point = end
        if point.first == "/" {
            point.removeFirst()
        }
        return WVRequest(withRequestURL: root.appendingPathComponent(point))
    }
}
