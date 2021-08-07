import UIKit

public struct ImageFile: Hashable {
    public var name: String
    var url: URL
    
    public init(url: URL) {
        self.name = url.deletingPathExtension().lastPathComponent
        self.url = url
    }
    
    public func argbImage() -> UIImage? {
        return UIImage(contentsOfFile: self.url.path)
    }
    
    private static var imageDir: URL = Bundle.main
        .url(forResource: "markerfile", withExtension: "txt")!
        .resolvingSymlinksInPath()
        .deletingLastPathComponent()
        .appendingPathComponent("Images")
    
    public static func get(named name: String) -> Self {
        let imageUrl = imageDir.appendingPathComponent(name)
        return ImageFile(url: imageUrl)
    }
}
