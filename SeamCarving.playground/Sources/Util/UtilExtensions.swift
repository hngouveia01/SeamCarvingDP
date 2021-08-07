import UIKit
import Metal

public extension MTLTexture {
    /// Utility function for building a descriptor that matches this texture
    func matchingDescriptor() -> MTLTextureDescriptor {
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = self.textureType
        // NOTE: We should be more careful to select a renderable pixel format here,
        // especially if operating on a compressed texture.
        descriptor.pixelFormat = self.pixelFormat
        descriptor.width = self.width
        descriptor.height = self.height
        descriptor.depth = self.depth
        descriptor.mipmapLevelCount = self.mipmapLevelCount
        descriptor.arrayLength = self.arrayLength
        // NOTE: We don't set resourceOptions here, since we explicitly set cache and storage modes below.
        descriptor.cpuCacheMode = self.cpuCacheMode
        descriptor.storageMode = self.storageMode
        descriptor.usage = self.usage
        return descriptor
    }
}

public func zeros<T: Numeric>(width: Int, height: Int) -> [[T]] {
    return Array(repeating: Array(repeating: T(exactly: 0)!, count: width), count: height)
}

public extension CGSize {
    var rounded: CGSize {
        return CGSize(width: self.width.rounded(), height: self.height.rounded())
    }
}

public extension CIImage {
    var cgImage: CGImage? {
        let context = CIContext(options: nil)
        return context.createCGImage(self, from: self.extent)
    }
}

public func writeImage(_ image: UIImage, name: String) {
    if name.isEmpty || name.count < 3 {
        print("Name cannot be empty or less than 3 characters.")
        return
    }
    guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
        print("No documents directory found.")
        return
    }
    let imagePath = documentsDirectory.appendingPathComponent("\(name)")
    let imagedata = image.jpegData(compressionQuality: 1.0)
    do {
        try imagedata?.write(to: imagePath)
        print("Image successfully written to path:\n\n \(documentsDirectory) \n\n")
    } catch {
        print("Error writing image: \(error)")
    }
}
