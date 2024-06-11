import Foundation

/**
 Automatically handles the fetching and caching of images from the network.
 */
public class WVImage {
    private static var inProgress = [String]()
    private static var listeners = [String:[(Data?)->Void]]()
    
    /// Change `WVImage.filePath` to change where `WVImage` will save and search for images.
    public static var filePath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("wv-imagecache")
    
    /**
     Get an image. If it cannot be found locally, it will be downloaded from the URL specified.
     - Parameter id: Any persistent identifier to store the image under. This will be the filename of the url downloaded.
     - Parameter fallbackURL: The URL to download from if the image cannot be found locally.
     - Parameter completion: The `UIImage` will be returned here, always. It is recommended to set a placeholder image (i.e. a generic profile icon) before calling `get` to set the image so that a user is not left with a blank view.
     */
    static public func get(id: String, fallbackURL url: String, completion:@escaping(Data?)->Void) {
        if !FileManager.default.fileExists(atPath: filePath.path) {
            try! FileManager.default.createDirectory(at: filePath, withIntermediateDirectories: false, attributes: nil)
        }
        if inProgress.contains(url) {
            if listeners[url] != nil {
                listeners[url]?.append(completion)
            } else {
                listeners[url] = [completion]
            }
        } else {
            if let av = cachedImage(id: id) {
                completion(av)
            } else {
                Request<RawResponse>(URL(string: url)!)
                    .startTask({ res in
                        switch res {
                        case .success(let d):
                            if let ls = listeners[id] {
                                for i in ls { i(d) }
                            }
                            completion(d)
                            try! d.write(to: filePath.appendingPathComponent("\(id).png"))
                            break
                        case .failure(_):
                            completion(nil)
                            break
                        }
                    })
            }
        }
    }
    
    /**
     Delete an image with `id` from Weave's local cache.
    - Parameter id: Any persistent identifier to attempt to delete.
    */
    static public func purge(id: String) {
        let path = filePath.appendingPathComponent("\(id).png").path
        if FileManager.default.fileExists(atPath: path) {
            try! FileManager.default.removeItem(atPath: path)
        }
    }
    
    /**
     Clears all stored images.
     */
    static public func clearCache() {
        if FileManager.default.fileExists(atPath: filePath.path) {
            try! FileManager.default.removeItem(at: filePath)
        }
    }
    
    static private func cachedImage(id:String) -> Data? {
        let contents = try! FileManager.default.contentsOfDirectory(atPath: filePath.path)
        if contents.contains("\(id).png") {
            return try! Data(contentsOf: filePath.appendingPathComponent("\(id).png"))
        } else {
            return nil
        }
    }
}
