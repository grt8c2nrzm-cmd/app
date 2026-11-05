import SwiftUI

struct LicencaDetalhe: View {
    @EnvironmentObject var app: AppState
    @Environment(\.dismiss) private var dismiss
    @State var l: Licenca
    var novo: Bool
    @State private var salvando = false
    @State private var msg: String?
    @State private var movData = Datas.hoje
    @State private var movTexto = ""
    @State private var confirmaExcluir = false

    private var sit: Sit { app.sit(l) }
    private var emp: Emp? { app.emp(l.empId) }
    private var proto: Binding<Protocolo> { Binding(get: { l.protocolo ?? Protocolo() }, set: { l.protocolo = $0 }) }
    private var conds: Binding<[Cond]> { Binding(get: { l.condicionantes ?? [] }, set: { l.condicionantes = $0 }) }
    private var movs: [Mov] { (l.movimentacoes ?? []).sorted { $0.data > $1.data } }
    private func txt(_ k: WritableKeyPath<Licenca, String?>) -> Binding<String> {
        Binding(get: { l[keyPath: k] ?? "" }, set: { l[keyPath: k] = $0 })
    }

    var body: some View {
        Form {
            if !novo || !l.empId.isEmpty, (l.validade?.isEmpty == false || l.indeterminada == true) {
                Section {
                    HStack { Chip(sit: sit); Spacer(); Text(Datas.diasTxt(sit.dias)).foregroundStyle(.secondary) }
                    if let n = sit.nota { Text(n).font(.footnote).foregroundStyle(.secondary) }
                }
            }
            Section("Dados") {
                if novo {
                    Picker("Tipo", selection: Binding(get: { l.tipo }, set: { novoTipo($0) })) {
                        ForEach(Tipos.todos, id: \.self) { Text(Tipos.nome($0)).tag($0) }
                    }
                    Picker("Empreendimento", selection: $l.empId) {
                        Text("Selecione…").tag("")
                        ForEach(app.dados.empreendimentos.sorted { $0.sigla < $1.sigla }) { e in Text("\(e.sigla) — \(e.nome)").tag(e.id) }
                    }
                } else if let e = emp {
                    LabeledContent("Unidade", value: "\(e.sigla) — \(e.nome)")
                    LabeledContent("Regional / LS / LR", value: [e.regional, e.ls, e.lr].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
                }
                TextField("Número", text: txt(\.numero))
                TextField("Órgão", text: txt(\.orgao))
                TextField("Processo", text: txt(\.processo))
                DataCampo(titulo: "Emissão", valor: txt(\.emissao))
                Toggle("Vencimento indeterminado", isOn: Binding(get: { l.indeterminada ?? false }, set: { l.indeterminada = $0; if $0 { l.validade = "" } }))
                if l.indeterminada != true { DataCampo(titulo: "Validade", valor: txt(\.validade)) }
            }
            if l.tipo == "LO" {
                Section(header: Text("Protocolo de renovação"), footer: Text("Protocolar até \(app.dados.cfg.protocoloLO) dias antes do vencimento mantém a LO válida.")) {
                    Toggle("Renovação protocolada", isOn: proto.feito)
                    if proto.wrappedValue.feito {
                        DataCampo(titulo: "Data do protocolo", valor: proto.data)
                        TextField("Nº do protocolo", text: proto.numero)
                    }
                }
                Section("Condicionantes") {
                    ForEach(conds) { $c in CondEditor(c: $c) }
                        .onDelete { conds.wrappedValue.remove(atOffsets: $0) }
                    Button { conds.wrappedValue.append(Cond()) } label: { Label("Adicionar condicionante", systemImage: "plus") }
                }
            }
            if ["LO", "ALVARA", "AVCB", "OUTORGA"].contains(l.tipo) {
                Section("Movimentações do processo") {
                    DataCampo(titulo: "Data", valor: $movData)
                    TextField("O que aconteceu", text: $movTexto, axis: .vertical).lineLimit(2...6)
                    Button {
                        let t = movTexto.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty, !movData.isEmpty else { return }
                        var m = l.movimentacoes ?? []
                        m.append(Mov(data: movData, texto: t, autor: app.me?.nome))
                        l.movimentacoes = m
                        movTexto = ""
                    } label: { Label("Adicionar movimentação", systemImage: "plus") }
                    ForEach(movs) { m in
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(Datas.br(m.data))\(m.autor.map { " · " + $0 } ?? "")").font(.caption).foregroundStyle(.secondary)
                            Text(m.texto)
                        }
                        .contextMenu {
                            Button("Remover", role: .destructive) { l.movimentacoes?.removeAll { $0.id == m.id } }
                        }
                    }
                    if !movs.isEmpty { Text("Segure uma movimentação para remover.").font(.caption2).foregroundStyle(.tertiary) }
                }
            }
            Section("Observações") { TextField("Observações", text: txt(\.obs), axis: .vertical).lineLimit(2...8) }
            if !novo {
                Section { Button("Excluir licença", role: .destructive) { confirmaExcluir = true } }
            }
        }
        .navigationTitle(novo ? "Nova licença" : Tipos.curto(l.tipo))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if novo { ToolbarItem(placement: .topBarLeading) { Button("Cancelar") { dismiss() } } }
            ToolbarItem(placement: .topBarTrailing) {
                Button { Task { await salvar() } } label: { if salvando { ProgressView() } else { Text("Salvar").bold() } }
                    .disabled(salvando || l.empId.isEmpty)
            }
        }
        .alert(msg ?? "", isPresented: Binding(get: { msg != nil }, set: { if !$0 { msg = nil } })) { Button("OK", role: .cancel) {} }
        .confirmationDialog("Excluir esta licença? Não dá para desfazer.", isPresented: $confirmaExcluir, titleVisibility: .visible) {
            Button("Excluir", role: .destructive) {
                Task {
                    do { try await app.excluir(l.id); dismiss() } catch { msg = error.localizedDescription }
                }
            }
        }
    }

    private func novoTipo(_ t: String) {
        let v = Licenca.vazia(t)
        l.tipo = t
        l.protocolo = v.protocolo
        l.condicionantes = v.condicionantes
        l.movimentacoes = v.movimentacoes
    }

    private func salvar() async {
        salvando = true
        defer { salvando = false }
        do {
            try await app.salvar(l, novo: novo)
            if novo { dismiss() } else if let n = app.dados.licencas.first(where: { $0.id == l.id }) { l = n; msg = "Salvo." }
        } catch {
            msg = error.localizedDescription
            if let n = app.dados.licencas.first(where: { $0.id == l.id }), (error as? ApiError)?.status == 409 { l = n }
        }
    }
}

struct CondEditor: View {
    @Binding var c: Cond
    private func txt(_ k: WritableKeyPath<Cond, String?>) -> Binding<String> {
        Binding(get: { c[keyPath: k] ?? "" }, set: { c[keyPath: k] = $0 })
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Nº (opcional)", text: txt(\.numero)).font(.caption)
            TextField("Descrição", text: $c.descricao, axis: .vertical).lineLimit(1...5)
            Picker("Tipo", selection: $c.tipo) {
                Text("Com prazo").tag("prazo")
                Text("Recorrente").tag("recorrente")
                Text("Acompanhamento").tag("acompanhamento")
            }
            if c.tipo == "prazo" {
                DataCampo(titulo: "Prazo", valor: txt(\.prazo))
                Toggle("Concluída", isOn: Binding(get: { c.concluida ?? false }, set: {
                    c.concluida = $0
                    c.concluidaEm = $0 ? Datas.hoje : ""
                }))
            } else if c.tipo == "recorrente" {
                Picker("Periodicidade", selection: Binding(get: { c.periodicidade ?? "anual" }, set: { c.periodicidade = $0 })) {
                    Text("Anual").tag("anual")
                    Text("Semestral").tag("semestral")
                }
                DataCampo(titulo: "Próxima entrega", valor: txt(\.proxima))
                if let e = c.entregas, !e.isEmpty {
                    Text("Entregas: " + e.map { Datas.br($0.data) }.joined(separator: ", ")).font(.caption).foregroundStyle(.secondary)
                }
            } else {
                Text("Somente acompanhamento — nada a entregar. Não aparece no Painel.").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
