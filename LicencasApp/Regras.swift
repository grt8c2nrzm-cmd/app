import SwiftUI

enum Datas {
    static let cal = Calendar(identifier: .gregorian)
    static let fmt: DateFormatter = {
        let f = DateFormatter()
        f.calendar = cal
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    static var hoje: String { fmt.string(from: Date()) }
    static func date(_ s: String) -> Date? { fmt.date(from: s) }
    static func str(_ d: Date) -> String { fmt.string(from: d) }
    static func dias(ate s: String?) -> Int? {
        guard let s = s, !s.isEmpty, let d = date(s), let h = date(hoje) else { return nil }
        return cal.dateComponents([.day], from: h, to: d).day
    }
    static func somar(_ s: String, dias: Int) -> String {
        guard let d = date(s), let n = cal.date(byAdding: .day, value: dias, to: d) else { return s }
        return str(n)
    }
    static func somarMeses(_ s: String, _ m: Int) -> String {
        guard let d = date(s), let n = cal.date(byAdding: .month, value: m, to: d) else { return s }
        return str(n)
    }
    static func br(_ s: String?) -> String {
        guard let s = s, s.count == 10 else { return "—" }
        return String(s.suffix(2)) + "/" + String(s.dropFirst(5).prefix(2)) + "/" + String(s.prefix(4))
    }
    static func brCurto(_ s: String) -> String { s.count == 10 ? String(s.suffix(2)) + "/" + String(s.dropFirst(5).prefix(2)) : s }
    static func diasTxt(_ d: Int?) -> String {
        guard let d = d else { return "—" }
        if d < 0 { return "há \(-d) d" }
        return d == 0 ? "hoje" : "\(d) d"
    }
}

struct Sit {
    enum Cor { case vermelho, ambar, verde, cinza
        var cor: Color {
            switch self {
            case .vermelho: return .red
            case .ambar: return .orange
            case .verde: return .green
            case .cinza: return .gray
            }
        }
    }
    var cor: Cor
    var texto: String
    var ordem: Int
    var dias: Int?
    var nota: String?
    var atencao: Bool { cor == .vermelho || cor == .ambar }
}

func situacao(_ l: Licenca, _ c: Cfg) -> Sit {
    guard let val = l.validade, !val.isEmpty, let d = Datas.dias(ate: val) else {
        return Sit(cor: .cinza, texto: "Sem validade", ordem: 5, dias: nil, nota: nil)
    }
    switch l.tipo {
    case "LO":
        let lim = Datas.somar(val, dias: -c.protocoloLO)
        if let p = l.protocolo, p.feito {
            if p.data <= lim {
                return Sit(cor: .verde, texto: "Protocolada no prazo", ordem: 4, dias: d, nota: "Válida enquanto o órgão analisa a renovação.")
            }
            return Sit(cor: .vermelho, texto: "Protocolo fora do prazo", ordem: 0, dias: d, nota: "Protocolada em \(Datas.br(p.data)), depois do limite de \(Datas.br(lim)).")
        }
        if Datas.hoje > lim {
            return Sit(cor: .vermelho, texto: d < 0 ? "Vencida" : "Sem protocolo (\(c.protocoloLO)d perdidos)", ordem: 0, dias: d, nota: "O limite para protocolar era \(Datas.br(lim)).")
        }
        if d <= c.janelas.LO {
            return Sit(cor: .ambar, texto: "Renovar · protocolar até \(Datas.brCurto(lim))", ordem: 1, dias: d, nota: "Protocolar até \(Datas.br(lim)) mantém a licença válida.")
        }
        return Sit(cor: .verde, texto: "Vigente", ordem: 4, dias: d, nota: nil)
    case "IBAMA":
        if d < 0 { return Sit(cor: .vermelho, texto: "Vencida · em renovação", ordem: 0, dias: d, nota: nil) }
        return Sit(cor: .verde, texto: "Vigente", ordem: 4, dias: d, nota: nil)
    default:
        let j = l.tipo == "OUTORGA" ? c.janelas.OUTORGA : (l.tipo == "ALVARA" ? c.janelas.ALVARA : c.janelas.AVCB)
        if d < 0 { return Sit(cor: .vermelho, texto: "Vencida", ordem: 0, dias: d, nota: nil) }
        if d <= j { return Sit(cor: .ambar, texto: "Em período de renovação", ordem: 1, dias: d, nota: nil) }
        return Sit(cor: .verde, texto: "Vigente", ordem: 4, dias: d, nota: nil)
    }
}

struct CondPend: Identifiable {
    var lic: Licenca
    var emp: Emp
    var cond: Cond
    var dias: Int
    var id: String { lic.id + cond.id }
}
