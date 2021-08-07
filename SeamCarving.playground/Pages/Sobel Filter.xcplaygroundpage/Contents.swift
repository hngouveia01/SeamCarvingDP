
/*:
 # Filtro Sobel

 Para remover os pixels desnecessários, primeiro devemos descobrir quais pixels são necessários.

 Nesse caso, necessário significa pixels de onde seria visualmente perceptível para eles serem removidos.

 A detecção de bordas é capaz de fazer isso, pois é capaz de detectar mudanças importantes na cor. Vamos implementar essa detecção de borda usando uma convolução de imagem.

 ## O que é uma convolução de imagem?

 Uma convolução é um efeito de filtro para uma imagem que determina o valor de cada pixel de uma nova imagem a partir do valor do pixel original e de seus vizinhos.

 O efeito de uma convolução é determinado por uma matriz de tamanho arbitrário que é transmitida, chamada de kernel.

 ![Convolution Intro](/ConvolutionIntroduction.mp4)

 Quando a convolução é aplicada, o centro do kernel é alinhado com cada pixel da imagem de origem. Os valores de cor de cada canal são então independentemente multiplicados pelo valor do kernel em sua posição e, em seguida, somados. Essas somas tornam-se os novos valores de cor do pixel posicionado no centro do kernel na imagem de saída.

 Dependendo do kernel usado, as convoluções são capazes de fazer uma ampla variedade de operações nas imagens, desde borrar e aumentar a nitidez até aproximar a derivada.

 Um exemplo de kernel é o kernel de diferenciação, que, como seu nome sugere, se aproxima do valor da derivada da cor em um pixel selecionado:

 ```
 Dx = [+1 0 -1]
 Dy = [
    +1
    0
    -1
 ]
 ```

 Ele é capaz de aproximar a derivada naquele ponto porque está tomando a diferença entre os pixels vizinhos como (+1) (esquerda) + (-1) (direita) = esquerda - direita. Quando os resultados dos kernel x e y são tratados como componentes vetoriais de um único campo vetorial, ele é capaz de atuar como um operador gradiente bruto.

 Outro seria um kernel de média, que obtém uma média ponderada do pixel atual e seus vizinhos verticais. O kernel para isso é o seguinte:

 ```
 Ay = [
    1
    2
    1
 ]
 Ay = [1 2 1]
 ```

 ## O Filtro Sobel

 Agora que cobrimos o básico de como funcionam as convoluções da imagem, vamos aprimorar a convolução específica que usaremos para a detecção de bordas: o filtro Sobel.

 Kernel Sobel:
 ```
 Sx = [
    +1 0 -1
    +2 0 -2
    +1 0 -1
 ]
 Sy = [
    +1 +2 +1
     0  0  0
    -1 -2 -1
 ]
 ```

 O kernel para o filtro Sobel é o resultado da multiplicação da matriz da derivada e da média dos kernels
   (com o arranjo que resulta em uma saída 3x3).

 Isso ocorre porque o filtro Sobel é um método aprimorado para aproximar a derivada em cada pixel. Como leva em consideração os pixels vizinhos, ele será mais suave do que apenas o kernel derivado - agindo como uma melhor aproximação do operador gradiente.

 ## Implementação

 Vamos usar o Metal para fazer a operação porque as convoluções são operações altamente regulares aplicadas a uma imagem inteira, portanto, executá-la em uma GPU forneceria uma vantagem significativa de tempo e eficiência.

 Aqui está a função Metal que será chamada para aplicar o filtro Sobel. Está escrito na linguagem Metal Shader. O arquivo real está em `/Resources/sobel.metal`.

 ```
 kernel void sobel(
    texture2d<half, access::read> inTexture [[ texture (0) ]],
    texture2d<half, access::write> outTexture [[ texture (1) ]],
    uint2 gid [[ thread_position_in_grid ]]
 ) {
    // define os kernels
    constexpr int kernel_size = 3;
    constexpr int radius = kernel_size / 2;
    half3x3 horizontal_kernel = half3x3(
        -1, 0, 1,
        -2, 0, 2,
        -1, 0, 1
    );
    half3x3 vertical_kernel = half3x3(
        -1, -2, -1,
        0, 0, 0,
        1, 2, 1
    );

    // passa iterando por toda imagem
    // multiplique cada pixel pelo seu peso e, em seguida, adicione-o à soma do pixel atual
    half3 result_horizontal(0, 0, 0);
    half3 result_vertical(0, 0, 0);
    for (int j = 0; j<= kernel_size - 1; j++) {
        for (int i = 0; i <= kernel_size - 1; i++) {
            uint2 texture_index(gid.x + (i - radius), gid.y + (j + radius));
            result_horizontal += horizontal_kernel[i][j] * inTexture.read(texture_index).rgb;
            result_vertical += vertical_kernel[i][j] * inTexture.read(texture_index).rgb;
        }
    }

    // pegue os resultados rgb individuais e combine-os em um único canal em tons de cinza
    // usa o padrão bt601 para os pesos dos componentes
    half3 bt601 = half3(0.299, 0.587, 0.114);
    half gray_horizontal = dot(result_horizontal.rgb, bt601);
    half gray_vertical = dot(result_vertical.rgb, bt601);

    // encontra a magnitude do vetor
    half magnitude = length(half2(gray_horizontal, gray_vertical));

    // escreve no arquivo de saída
    outTexture.write(magnitude, gid);
 }
 ```

 Vamos chamar essa função passando uma image:

 */
// pega a imagem
let image = ImageFile.get(named: "clock.jpg").argbImage()?.cgImage

// abstraindo a chamada da função metal pois ela requer várias configurações, a implementação está em Sources/Sobel.swift
let sobeled = sobel(image!)

sobeled

/*:
 Agora que encontramos as bordas da imagem, podemos utilizá-las para encontrar o que remover.

 [Next](@next)
 */
