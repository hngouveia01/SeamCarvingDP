/*:
 # Encontrando as Costuras (Seams)

 Costuras serão o que chamamos de caminho de pixels que removemos da imagem para reduzir sua largura.

 Nossos critérios para a costura são os seguintes:
 - O caminho que cruza o mínimo de bordas (edges) (conforme determinado pelo filtro Sobel)
 - O caminho pode levar aos três pixels sob o pixel atual.

 Esses três candidatos são mostrados neste diagrama:

 ![Candidate Diagram](/CandidateDiagram.jpg)

 ## Possíveis Algortimos

 Em uma primeira tentativa de encontrar a costura podemos usar um algoritmo guloso.
 Um algoritmo guloso é aquele que sempre escolhe a opção imediatamente mais ótima.
 Nesse caso, ele sempre escolheria o menor dos três candidatos disponíveis para cada linha da imagem.

 Embora isso possa ter bom desempenho, haverá problemas para encontrar o melhor caminho de forma consistente.

 Usar esse algoritmo poderia facilmente travar a costura apenas tendo candidatos com alta borda.

 ![Greedy Algorithm](/GreedyAlgorithm.mp4)

 A armadilha de não saber se o caminho é o caminho mais ideal possível pode ser removida usando um algoritmo que verifica todos os caminhos possíveis através de uma imagem.

 Em seguida, ele escolheria o caminho em que a soma de todos os valores de energia fosse a menor.

 Embora isso sempre nos forneça o melhor caminho possível através de uma imagem, também é extremamente lento.

 ![Recursive Exhaustive Search Algorithm](/RecrusiveExhaustiveSearch.mp4)

 A complexidade de tempo desse método seria da ordem de `colunas * 3^linhas`, portanto, não seria de uso prático em nenhuma imagem de tamanho razoável.

 ## Otimizando por meio de Programação Dinâmica

 A programação dinâmica é uma técnica para otimizar algoritmos, dividindo-os em subpartes que podem ser compartilhadas por outras subpartes. Isso pode reduzir muito a necessidade de trabalho redundante.

 O fato fundamental que nos permitirá otimizar é que a cada pixel, existe um caminho de energia total mínima para a parte inferior da imagem. Como esse sempre será o caminho ideal a partir desse pixel, qualquer costura que inclua esse pixel seguirá esse caminho para o resto da imagem.

 Isso nos permite atribuir a cada pixel um valor de energia total do caminho ideal para o fundo. Usar esse valor para calcular o valor dos pixels acima diminui muito a quantidade de trabalho redundante necessária.

 Para encontrar o valor de cada pixel, a matriz de somas pode ser construída de baixo para cima. Como a soma total de cada candidato seria conhecida, tudo o que seria necessário para encontrar a soma de cada pixel é somar a soma mínima dos candidatos e o valor de si mesmo.

 ![Dynamic Programming Approach Search](/DynamicProgrammingApproachSearch.mp4)

 Isso otimiza muito o algoritmo, removendo o trabalho redundante, reduzindo a complexidade do tempo a um nível muito mais razoável `3 * linhas * colunas`.

 # Implementação

 Primeiro, precisamos de uma função min que seja capaz de encontrar o valor mínimo e o índice desse valor.

 A função para achar o mínimo valor pode ser implementada conforme abaixo:
 */

func minWithIndex(_ val0: UInt32, _ val1: UInt32, _ val2: UInt32) -> (val: UInt32, index: Int8) {
    // tem preferencia pelo centro. Evita out of bound e deixa a imagem com melhor qualidade
    var index: Int8 = 1
    var min = val1

    // verifica o esquerdo
    if val0 < min {
        index = 0
        min = val0
    }

    // verifica o direito
    if val2 < min {
        index = 2
        min = val2
    }

    return (min, index)
}

/*:
 Agora podemos usar essa função dentro de nossa função de soma de energias/bordas (edginess).

 Nossa função receberá o resultado do nosso filtro Sobel como um buffer Accelerate planar de 8 bits.

 Ele retornará a soma e a direção (para o candidato escolhido) em cada pixel como duas matrizes separadas.
 Ambos serão necessários para calcular nossa costura.
 */

import CoreGraphics
import Accelerate.vImage

func _edginessSums(buffer: vImage_Buffer) -> (edginessSums: [[UInt32]], directions: [[Int8]]) {
    // cria matrizes em branco do tamanho apropriado para armazenar a saída
    let width = Int(buffer.width)
    let height = Int(buffer.height)

    // os valores do caminho de menor energia
    var edginessSums: [[UInt32]] = zeros(width: width, height: height)
    // a direção para o ponto mínimo de menos energia abaixo (-1: esquerda, 0: centro, 1: direita)
    var directions: [[Int8]] = zeros(width: width, height: height)

    // obtém um ponteiro de buffer do ponteiro vImage
    // permite que seja iterado mais facilmente
    let dataLength = height * buffer.rowBytes
    let dataPtr = buffer.data.bindMemory(to: UInt8.self, capacity: dataLength)
    let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: dataLength)

    // a linha inferior é a mesma (sem intensidades abaixo para adicionar a ela) para que possa ser copiada
    let lastRowStart = (height - 1) * buffer.rowBytes
    for col in 0..<width {
        edginessSums[height-1][col] = UInt32(dataBuffer[lastRowStart + col])
    }

    // adiciona de baixo para cima. Depois, vai na ordem inversa
    // pula a linha de baixo porque já foi copiado
    for row in (0..<height-1).reversed() {
        // o deslocamento no buffer em que a linha atual começa
        let rowStart = row * buffer.rowBytes

        for col in 0..<width {
            // obtém o mínimo dos três valores abaixo do pixel atual
            // se os valores estão fora dos limites, o valor central é usado (é isso que o mínimo e o máximo estão fazendo)
            // nossa função min personalizada os ignora se eles tiverem o mesmo valor do centro
            let (minBelow, minIndex) = minWithIndex(
                edginessSums[row + 1][max(col - 1, 0)],
                edginessSums[row + 1][col],
                edginessSums[row + 1][min(col + 1, width - 1)]
            )

            // soma o limite inferior abaixo e o limite do pixel atual
            let edginessForThisPixel = UInt32(dataBuffer[rowStart + col]) // faz cast acima para não dar overflow
            edginessSums[row][col] = minBelow + edginessForThisPixel

            // adiciona direção ao array
            directions[row][col] = minIndex - 1
        }
    }

    return (edginessSums, directions)
}

/*:
 Vamos obter as somas e direções e, em seguida, visualizá-los como imagens.
 */

import UIKit

// pega a imagem que passou pelo filtro Sobel
let image = ImageFile.get(named: "clock.jpg").argbImage()?.cgImage
let sobeled = sobel(image!)
let buffer = sobeled.planarBuffer

// obter somas e orientações do buffer sobeled
let (sums, dirs) = edginessSums(buffer: buffer)
buffer.free()

// transforma as matrizes retornadas em imagens
let sumsImage = CGImage.scaledGrayscaleFromMatrix(sums)
let dirsColors = directionsToColorMatrix(dirs) // expressa esquerda, centro e direita como RGB, respectivamente
let dirsImage = CGImage.argbFromMatrix(dirsColors)

//: Agora podemos ver os resultados do algoritmo:

sumsImage
dirsImage


/*:
 O padrão triangular que aparece acima das bordas nas somas é significativo porque marca lugares, que se o caminho o tocasse, não haveria como evitar a borda. Isso reflete a taxa máxima que o caminho pode percorrer horizontalmente.

 # Encontrando a costura (seam)

 Agora que temos as direções para cada pixel na imagem e a soma do caminho de energia mínima de cada pixel na linha superior, uma matriz contendo a coluna de cada pixel a ser removida pode ser facilmente criada.

 Esta função faz isso:
 */

func _findSeam(edginessSums: [[UInt32]], directions: [[Int8]]) -> [Int] {
    var seam: [Int] = Array(repeating: 0, count: edginessSums.count)

    // obtém a coluna inicial
    // será o pixel com a soma mínima na linha superior
    let start = edginessSums[0]
        .enumerated()
        .min { $0.element < $1.element }!
        .offset
    seam[0] = start

    // siga as direções para obter o resto da costura
    var col = start
    for row in 1..<directions.count {
        col += Int(directions[row][col])
        seam[row] = col
    }

    return seam
}

//: Vamos encontrar a costura usando a função que fizemos e, em seguida, sobrepô-la na imagem original

let seam = findSeam(edginessSums: sums, directions: dirs)

// obter matriz da imagem original
let imageBuffer = image!.argbBuffer
var imageMatrix = imageBuffer.argb8ToMatrix()
imageBuffer.free()

// sobrepor costura e obter imagem
// desenhe a costura em vermelho
let overlayedMatrix = overlaySeam(seam, on: imageMatrix, color: 0x0000FF00)
let overlayedImage = CGImage.argbFromMatrix(overlayedMatrix)

//: Você pode ver como a linha vermelha desvia de partes importantes da imagem

overlayedImage

//: Agora podemos remover essa costura da imagem

removeSeam(seam, from: &imageMatrix)
let carvedImage = CGImage.argbFromMatrix(imageMatrix)

//: Se você olhar para a barra lateral, você pode ver que a largura da imagem é um pixel menor
carvedImage



/*:
 Embora isso prove que nosso algoritmo é funcional, ainda não o implementamos na escala em que faz uma diferença perceptível na imagem.

  [Next](@next)
 */
