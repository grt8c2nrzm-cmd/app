import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var restaurando = true
    @Published var token: String?
    @Published var me: Usuario?
    @Published var dados = Dados.vazio
    @Published var carregando = false
    @Published var servidor: String = UserDefaults.standard.string(forKey: "servidor") ?? (Config.configurado ? Config.serverURL : "")

    var logado: Bool { token != nil && me != nil }
    var admin: Bool { me?.role == "admin" }
    var precisaServidor: Bool { !Config.configurado }

    func emp(_ id: String) -> Emp? { dados.empreendimentos.first { $0.id == id } }

    func restaurarSessao() async {
        defer { restaurando = false }
        guard !servidor.isEmpty, let t = Keychain.get("token") else { return }
        do {
            me = try await Api.me(servidor: servidor, token: t)
            token = t
            await carregar()
        } catch let e as ApiError where e.status == 401 {
            Keychain.remove("token")
        } catch {
            // sem internet: mantém o token para a próxima tentativa
        }
    }

    func entrar(servidor s: String, usuario: String, senha: String, lembrar: Bool) async throws {
        let srv = Api.base(s)
        guard srv.hasPrefix("http") else { throw ApiError(msg: "Informe o endereço do servidor começando com https://") }
        let (t, u) = try await Api.login(servidor: srv, usuario: usuario, senha: senha, lembrar: lembrar)
        servidor = srv
        UserDefaults.standard.set(srv, forKey: "servidor")
        if lembrar { Keychain.set(t, for: "token") } else { Keychain.remove("token") }
        token = t
        me = u
        await carregar()
    }

    func sair() {
        Keychain.remove("token")
        token = nil
        me = nil
        dados = .vazio
    }

    func carregar() async {
        guard let t = token else { return }
        carregando = true
        defer { carregando = false }
        do { dados = try await Api.dados(servidor: servidor, token: t) }
        catch let e as ApiError where e.sessaoExpirada { sair() }
        catch {}
    }

    func salvar(_ l: Licenca, novo: Bool) async throws {
        guard let t = token else { return }
        do { try await Api.salvar(servidor: servidor, token: t, lic: l, novo: novo) }
        catch let e as ApiError {
            if e.status == 409 { await carregar() }
            if e.sessaoExpirada { sair() }
            throw e
        }
        await carregar()
    }

    func excluir(_ id: String) async throws {
        guard let t = token else { return }
        try await Api.excluir(servidor: servidor, token: t, id: id)
        await carregar()
    }

    // ── regras derivadas ──
    func condicionantesPendentes(rt: String?) -> [CondPend] {
        var out: [CondPend] = []
        let aviso = dados.cfg.avisoCondicionante
        for l in dados.licencas where l.tipo == "LO" {
            guard let e = emp(l.empId) else { continue }
            if let rt = rt, !(e.rts ?? []).contains(rt) { continue }
            for c in l.condicionantes ?? [] {
                if c.tipo == "prazo", c.concluida != true, let p = c.prazo, let d = Datas.dias(ate: p), d <= aviso {
                    out.append(CondPend(lic: l, emp: e, cond: c, dias: d))
                } else if c.tipo == "recorrente", let p = c.proxima, let d = Datas.dias(ate: p), d <= aviso {
                    out.append(CondPend(lic: l, emp: e, cond: c, dias: d))
                }
            }
        }
        return out.sorted { $0.dias < $1.dias }
    }

    func concluir(_ p: CondPend) async throws {
        var l = p.lic
        guard var conds = l.condicionantes, let i = conds.firstIndex(where: { $0.id == p.cond.id }) else { return }
        if conds[i].tipo == "prazo" {
            conds[i].concluida = true
            conds[i].concluidaEm = Datas.hoje
        } else {
            var ent = conds[i].entregas ?? []
            ent.append(Entrega(data: Datas.hoje, ref: conds[i].proxima))
            conds[i].entregas = ent
            conds[i].proxima = Datas.somarMeses(conds[i].proxima ?? Datas.hoje, conds[i].periodicidade == "semestral" ? 6 : 12)
        }
        l.condicionantes = conds
        try await salvar(l, novo: false)
    }
}
