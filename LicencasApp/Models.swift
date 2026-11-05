import Foundation

struct Janelas: Codable { var LO = 220, OUTORGA = 220, ALVARA = 60, AVCB = 60 }
struct Cfg: Codable {
    var janelas = Janelas()
    var protocoloLO = 120
    var avisoCondicionante = 90
}
struct Usuario: Codable, Identifiable, Hashable {
    var id: String
    var nome: String
    var role: String
    var usuario: String?
    var ativo: Bool?
}
struct Emp: Codable, Identifiable, Hashable {
    var id: String
    var nome: String
    var sigla: String
    var regional: String?
    var ls: String?
    var lr: String?
    var rts: [String]?
    var semPoco: Bool?
}
struct Protocolo: Codable, Hashable {
    var feito = false
    var data = ""
    var numero = ""
}
struct Entrega: Codable, Hashable {
    var data: String
    var ref: String?
}
struct Cond: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var numero: String?
    var descricao: String = ""
    var tipo: String = "prazo"          // prazo | recorrente | acompanhamento
    var obs: String?
    var prazo: String?
    var concluida: Bool?
    var concluidaEm: String?
    var periodicidade: String?          // anual | semestral
    var proxima: String?
    var entregas: [Entrega]?
}
struct Mov: Codable, Identifiable, Hashable {
    var id: String = UUID().uuidString
    var data: String
    var texto: String
    var autor: String?
}
struct Licenca: Codable, Identifiable, Hashable {
    var id: String = ""
    var empId: String = ""
    var tipo: String
    var numero: String?
    var orgao: String?
    var processo: String?
    var emissao: String?
    var validade: String?
    var indeterminada: Bool?
    var obs: String?
    var rev: Int = 0
    var protocolo: Protocolo?
    var condicionantes: [Cond]?
    var movimentacoes: [Mov]?

    var validadeTxt: String { indeterminada == true ? "Indeterminada" : Datas.br(validade) }

    static func vazia(_ tipo: String) -> Licenca {
        Licenca(tipo: tipo, protocolo: tipo == "LO" ? Protocolo() : nil,
                condicionantes: tipo == "LO" ? [] : nil,
                movimentacoes: ["LO", "ALVARA", "AVCB", "OUTORGA"].contains(tipo) ? [] : nil)
    }
}
struct Dados: Decodable {
    var cfg = Cfg()
    var empreendimentos: [Emp] = []
    var licencas: [Licenca] = []
    var usuarios: [Usuario] = []
    static let vazio = Dados()
}

enum Tipos {
    static let todos = ["LO", "ALVARA", "AVCB", "OUTORGA", "IBAMA"]
    static func nome(_ t: String) -> String {
        switch t {
        case "LO": return "Licença de Operação"
        case "ALVARA": return "Alvará"
        case "AVCB": return "AVCB"
        case "OUTORGA": return "Outorga"
        case "IBAMA": return "IBAMA"
        default: return t
        }
    }
    static func curto(_ t: String) -> String { t == "ALVARA" ? "Alvará" : (t == "OUTORGA" ? "Outorga" : t) }
    static func icone(_ t: String) -> String {
        switch t {
        case "LO": return "doc.text"
        case "ALVARA": return "building.2"
        case "AVCB": return "flame"
        case "OUTORGA": return "drop"
        case "IBAMA": return "leaf"
        default: return "square.stack"
        }
    }
}
