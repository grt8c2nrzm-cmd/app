import Foundation

enum Config {
    /// Endereço do SEU servidor (o do Render), sem barra no final. Ex.: "https://meu-painel.onrender.com"
    /// Se deixar o texto padrão, o app pede o endereço na tela de entrada.
    static let serverURL = "COLOQUE-AQUI-O-ENDERECO-DO-SERVIDOR"
    static var configurado: Bool { serverURL.hasPrefix("http") }
}
