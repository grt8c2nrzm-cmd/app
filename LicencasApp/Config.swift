import Foundation

enum Config {
    /// Endereço do SEU servidor (o do Render), sem barra no final. Ex.: "https://meu-painel.onrender.com"
    /// Se trocar por um texto que não comece com http, o app pede o endereço na tela de entrada.
    static let serverURL = "https://licen-as.onrender.com"
    static var configurado: Bool { serverURL.hasPrefix("http") }
}
