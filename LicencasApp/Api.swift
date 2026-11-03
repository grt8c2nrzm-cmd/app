import Foundation

struct ApiError: LocalizedError {
    var msg: String
    var status: Int = 0
    var sessaoExpirada = false
    var errorDescription: String? { msg }
}

enum Api {
    private struct Resp: Decodable { var mensagem: String?; var sessao: Bool? }
    private struct LoginResp: Decodable { var token: String; var usuario: Usuario }
    private struct MeResp: Decodable { var usuario: Usuario }
    private struct Vazio: Decodable {}

    static func base(_ s: String) -> String {
        var b = s.trimmingCharacters(in: .whitespacesAndNewlines)
        while b.hasSuffix("/") { b.removeLast() }
        return b
    }

    static func chamar<T: Decodable>(_ tipo: T.Type, servidor: String, path: String, method: String = "GET", token: String? = nil, corpo: Data? = nil) async throws -> T {
        guard let url = URL(string: base(servidor) + "/api" + path) else { throw ApiError(msg: "Endereço do servidor inválido.") }
        var req = URLRequest(url: url, timeoutInterval: 70)   // o Render gratuito pode demorar ~30 s para acordar
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let t = token { req.setValue("Bearer " + t, forHTTPHeaderField: "Authorization") }
        req.httpBody = corpo
        let data: Data
        let resp: URLResponse
        do { (data, resp) = try await URLSession.shared.data(for: req) }
        catch { throw ApiError(msg: "Sem conexão com o servidor. Se ele estava dormindo, tente de novo em instantes.") }
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        if code >= 200 && code < 300 {
            do { return try JSONDecoder().decode(T.self, from: data) }
            catch { throw ApiError(msg: "Resposta inesperada do servidor.", status: code) }
        }
        let r = try? JSONDecoder().decode(Resp.self, from: data)
        throw ApiError(msg: r?.mensagem ?? "Erro \(code).", status: code, sessaoExpirada: code == 401 && r?.sessao == false)
    }

    static func login(servidor: String, usuario: String, senha: String, lembrar: Bool) async throws -> (String, Usuario) {
        let corpo = try JSONSerialization.data(withJSONObject: ["usuario": usuario, "senha": senha, "lembrar": lembrar])
        let r = try await chamar(LoginResp.self, servidor: servidor, path: "/login", method: "POST", corpo: corpo)
        return (r.token, r.usuario)
    }
    static func me(servidor: String, token: String) async throws -> Usuario {
        try await chamar(MeResp.self, servidor: servidor, path: "/me", token: token).usuario
    }
    static func dados(servidor: String, token: String) async throws -> Dados {
        try await chamar(Dados.self, servidor: servidor, path: "/dados", token: token)
    }
    static func salvar(servidor: String, token: String, lic: Licenca, novo: Bool) async throws {
        let corpo = try JSONEncoder().encode(lic)
        _ = try await chamar(Vazio.self, servidor: servidor, path: novo ? "/lic" : "/lic/" + lic.id, method: novo ? "POST" : "PUT", token: token, corpo: corpo)
    }
    static func excluir(servidor: String, token: String, id: String) async throws {
        _ = try await chamar(Vazio.self, servidor: servidor, path: "/lic/" + id, method: "DELETE", token: token)
    }
}
