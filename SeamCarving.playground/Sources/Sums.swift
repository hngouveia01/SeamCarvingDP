import Accelerate.vImage

public func edginessSums(buffer: vImage_Buffer) -> (edginessSums: [[UInt32]], directions: [[Int8]]) {
    // cria matrizes em branco do tamanho apropriado para armazenar a saída
    let width = Int(buffer.width)
    let height = Int(buffer.height)
    
    // os valores do caminho de menor energia
    // a resolução vertical máxima é 2 ^ 32/2 ^ 8 = 16.777.216
    // porque essa seria a quantidade de pixels que levaria para transbordar se cada pixel da detecção de borda estivesse no limite
    var edginessSums: [[UInt32]] = zeros(width: width, height: height)
    // a direção para o ponto mínimo de menos energia abaixo (-1: esquerda, 0: centro, 1: direita)
    var directions: [[Int8]] = zeros(width: width, height: height)
    
    // utilitário para ser capaz de iterar no buffer vImage
    let dataLength = height * buffer.rowBytes
    let dataPtr = buffer.data.bindMemory(to: UInt8.self, capacity: dataLength)
    let dataBuffer = UnsafeBufferPointer(start: dataPtr, count: dataLength)
    
    // a linha inferior é a mesma (sem intensidades abaixo para adicionar a ela) para que possa ser copiada
    let lastRowStart = (height - 1) * buffer.rowBytes
    for col in 0..<width {
        edginessSums[height-1][col] = UInt32(dataBuffer[lastRowStart + col])
    }
    
    // adiciona de baixo para cima, por isso vai na ordem inversa
    // pula a linha inferior porque ela já foi copiada
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
            
            // some o limite mais baixo abaixo e o limite do pixel atual
            let edginessForThisPixel = UInt32(dataBuffer[rowStart + col]) // elenco para evitar o estouro ao adicionar
            edginessSums[row][col] = minBelow + edginessForThisPixel
            
            // adicione direção ao array
            directions[row][col] = minIndex - 1
        }
    }
    
    return (edginessSums, directions)
}

public func edginessSums(intensities: [[UInt8]]) -> (edginessSums: [[UInt32]], directions: [[Int8]]) {
    // faça matrizes em branco do tamanho apropriado para armazenar a saída
    let width = intensities[0].count
    let height = intensities.count
    
    // os valores do caminho de menor energia
    // a resolução vertical máxima é 2 ^ 32/2 ^ 8 = 16.777.216
    // porque essa seria a quantidade de pixels que levaria para transbordar se cada pixel da detecção de borda estivesse no limite
    var edginessSums: [[UInt32]] = zeros(width: width, height: height)
    // a direção para o ponto mínimo de menos energia abaixo (-1: esquerda, 0: centro, 1: direita)
    var directions: [[Int8]] = zeros(width: width, height: height)
    
    // a linha inferior é a mesma (sem intensidades abaixo para adicionar a ela) para que possa ser copiada
    for col in 0..<width {
        edginessSums[height-1][col] = UInt32(intensities[height - 1][col])
    }
    
    // adiciona de baixo para cima, então vai na ordem inversa // pula a linha de baixo porque já foi copiado
    for row in (0..<height-1).reversed() {
        for col in 0..<width {
            // obtém o mínimo dos três valores abaixo do pixel atual
            // se os valores estão fora dos limites, o valor central é usado (é isso que o mínimo e o máximo estão fazendo)
            // nossa função min personalizada os ignora se eles tiverem o mesmo valor do centro
            let (minBelow, minIndex) = minWithIndex(
                edginessSums[row + 1][max(col - 1, 0)],
                edginessSums[row + 1][col],
                edginessSums[row + 1][min(col + 1, width - 1)]
            )
            
            // some o limite mais baixo abaixo e o limite do pixel atual
            let edginessForThisPixel = UInt32(intensities[row][col]) // faz cast acima para prevenir overflow na adição
            edginessSums[row][col] = minBelow + edginessForThisPixel
            
            // adicione direção ao array
            directions[row][col] = minIndex - 1
        }
    }
    
    return (edginessSums, directions)
}

// prefere a coluna do meio se eles forem iguais
// é uma técnica usada para evitar Out of Index
func minWithIndex(_ val0: UInt32, _ val1: UInt32, _ val2: UInt32) -> (val: UInt32, index: Int8) {
    var index: Int8 = 1
    var min = val1
    if val0 < min {
        index = 0
        min = val0
    }
    if val2 < min {
        index = 2
        min = val2
    }
    return (min, index)
}

// isso pode ser implementado como um shader
// mas é executado apenas uma vez para que não tenha um grande impacto na experiência do playground
public func directionsToColorMatrix(_ directions: [[Int8]]) -> [[UInt32]] {
    var matrix: [[UInt32]] = zeros(width: directions[0].count, height: directions.count)
    
    for row in 0..<directions.count {
        for col in 0..<directions[0].count {
            let direction = directions[row][col]
            if direction == -1 {
                matrix[row][col] = 0x0000FF00 // big endian red
            } else if direction == 0 {
                matrix[row][col] = 0x00FF0000 // big endian green
            } else if direction == 1 {
                matrix[row][col] = 0xFF000000 // big endian blue
            }
        }
    }
    
    return matrix
}
