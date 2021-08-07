import UIKit
import PlaygroundSupport
/*:
 # Image Seam Carving

 Seam carving é um método de redimensionar imagens com reconhecimento de conteúdo. Isso significa que ele é capaz de alterar a proporção de aspecto de uma imagem sem resultar em uma compressão visualmente desagradável.

 O algoritmo é capaz de fazer isso removendo de forma inteligente os pixels de dentro da imagem que ele determina que não são necessários.

 ![Scaling down](/image05_video.gif)
 ![Result](/image5_result.png)

 [Next](@next)

 */
let image = UIImage.gifFromResourceFolder(name: "girl_resized.gif")!
let imageView = UIImageView(image: image)
PlaygroundPage.current.liveView = imageView

