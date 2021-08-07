import Foundation
import UIKit

public func carveImage(_ image: CGImage, width: Int) -> CGImage {
    var carvedImage = image
    
    let widthDiff = image.width - width
    for _ in 0..<widthDiff {
        // pega a imagem que passou pelo filtro sobel
        let sobeledImage  = sobel(carvedImage)
        let sobeledBuffer = sobeledImage.planarBuffer
        
        // pega as somas de energia (edginess) do resultado do filtro sobel
        let (sums, dirs) = edginessSums(buffer: sobeledBuffer)
        sobeledBuffer.free()
        
        // encontra a costura (seam)
        let seam = findSeam(edginessSums: sums, directions: dirs)
        
        // pega a matriz da imagem
        let imageBuffer = carvedImage.argbBuffer
        var imageMatrix = imageBuffer.argb8ToMatrix()
        imageBuffer.free()
        
        // remove a costura
        removeSeam(seam, from: &imageMatrix)
        
        // transforma a matriz retornada para uma imagem.
        // assim podemos reaplicar o filtro sobel e descobrir novas áreas importantes da imagem
        carvedImage = CGImage.argbFromMatrix(imageMatrix)
    }
    
    return carvedImage
}
