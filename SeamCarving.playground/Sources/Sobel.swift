import Metal
import MetalKit
import Foundation

let device = MTLCreateSystemDefaultDevice()!

var sobelPipeline: MTLComputePipelineState = {
    // carrega a biblioteca padrão
    let library = device.makeDefaultLibrary()!
    // nela existe o shader pré compilado sobel
    let function = library.makeFunction(name: "sobel")!
    let pipeline = try! device.makeComputePipelineState(function: function)
    return pipeline
}()

// MARK: - Sobel
public func sobel(_ image: CGImage) -> CGImage {
    let queue  = device.makeCommandQueue()!

    // pega a textura de entrada
    let textureLoader = MTKTextureLoader(device: device)
    let inputTexture = try! textureLoader.newTexture(cgImage: image)

    // cria a textura de saída
    let textureDescriptor = inputTexture.matchingDescriptor()
    textureDescriptor.pixelFormat = .r32Float
    textureDescriptor.usage = [.shaderRead, .shaderWrite]
    let outputTexture = device.makeTexture(descriptor: textureDescriptor)!

    // cria o kernel
    let buffer = queue.makeCommandBuffer()!

    // codifica o kernel
    let encoder = buffer.makeComputeCommandEncoder()!
    encoder.setComputePipelineState(sobelPipeline)
    encoder.setTexture(inputTexture, index: 0)
    encoder.setTexture(outputTexture, index: 1)

    // configura os threadgroups #
    let threadsPerThreadGroup = MTLSize(width: 16, height: 16, depth: 1)
    let threadgroupsPerGrid = MTLSize(width: inputTexture.width/16 + 1, height: inputTexture.height/16 + 1, depth: 1)
    encoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadGroup)
    encoder.endEncoding()

    // roda
    buffer.commit()
    buffer.waitUntilCompleted()

    // pega os resultados
    let ciImg = CIImage(mtlTexture: outputTexture, options: [.colorSpace: CGColorSpaceCreateDeviceGray()])!.oriented(.downMirrored)
    return ciImg.cgImage!
}
