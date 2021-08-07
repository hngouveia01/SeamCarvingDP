/*:
 # Aplicação

 Agora que descobrimos como remover uma costura da imagem, podemos repetir esse processo para remover várias.

 ## Implementação

 O método mais simples de fazer isso seria apenas fazer um loop com todos os passos.
 Isso seria implementado como:
 */

import UIKit
import SwiftUI


func _carveImage(_ image: CGImage, width: Int) -> CGImage {
    var carvedImage = image

    let widthDiff = image.width - width
    for _ in 0..<widthDiff {
        // pega a imagem que passou pelo filtro Sobel
        let sobeledImage  = sobel(carvedImage)
        let sobeledBuffer = sobeledImage.planarBuffer

        // pega as somas do sobel
        let (sums, dirs) = edginessSums(buffer: sobeledBuffer)
        sobeledBuffer.free()

        // encontra a costura (seam)
        let seam = findSeam(edginessSums: sums, directions: dirs)

        // pega a matriz da imagem
        let imageBuffer = carvedImage.argbBuffer
        var imageMatrix = imageBuffer.argb8ToMatrix()
        imageBuffer.free()

        // aplica a costura
        removeSeam(seam, from: &imageMatrix)

        // transformar a matriz em imagem para que o filtro Sobel possa ser reaplicado
        carvedImage = CGImage.argbFromMatrix(imageMatrix)
    }

    return carvedImage
}

//:  Agora vamos usar isso para diminuir nossa imagem em uma quantidade perceptível

let image = ImageFile.get(named: "clock.jpg").argbImage()?.cgImage

// altere o valor subtraído para retirar mais pixels da imagem
let carved = carveImage(image!, width: image!.width - 200)

//: Vamos comparar nossa imagem esculpida com a original

image
carved
/*:
 Original:
![Original Image](/image_final.jpg)

 Reduzida:
 ![Carved Image](/carved_final.jpg)
 */
