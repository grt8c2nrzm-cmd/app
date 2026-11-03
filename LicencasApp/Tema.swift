import SwiftUI

enum Tema: String, CaseIterable, Identifiable {
    case sistema, claro, escuro
    var id: String { rawValue }
    var titulo: String {
        switch self {
        case .sistema: return "Automático"
        case .claro: return "Claro"
        case .escuro: return "Escuro"
        }
    }
    var esquema: ColorScheme? {
        switch self {
        case .sistema: return nil
        case .claro: return .light
        case .escuro: return .dark
        }
    }
}

let laranja = Color(red: 0.96, green: 0.51, blue: 0.16)

struct Fundo: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
            RadialGradient(colors: [laranja.opacity(0.22), .clear], center: .topLeading, startRadius: 0, endRadius: 420)
            RadialGradient(colors: [Color.blue.opacity(0.10), .clear], center: .topTrailing, startRadius: 0, endRadius: 360)
        }
        .ignoresSafeArea()
    }
}

struct PillCampo: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .padding(.horizontal, 18)
            .frame(minHeight: 48)
            .background(Capsule().fill(Color(.secondarySystemBackground)))
            .overlay(Capsule().strokeBorder(Color.primary.opacity(0.10), lineWidth: 1))
    }
}
extension View { func pill() -> some View { modifier(PillCampo()) } }

struct Chip: View {
    var sit: Sit
    var body: some View {
        Text(sit.texto)
            .font(.caption.weight(.bold))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .foregroundStyle(sit.cor.cor)
            .background(Capsule().fill(sit.cor.cor.opacity(0.16)))
            .lineLimit(1)
    }
}

struct Etiqueta: View {
    var texto: String
    var body: some View {
        Text(texto).font(.caption2.weight(.bold))
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(Color.secondary.opacity(0.18)))
            .foregroundStyle(.secondary)
    }
}

struct DataCampo: View {
    var titulo: String
    @Binding var valor: String
    var body: some View {
        HStack {
            Text(titulo)
            Spacer()
            if valor.isEmpty {
                Button("Definir") { valor = Datas.hoje }.buttonStyle(.borderless)
            } else {
                DatePicker("", selection: Binding(get: { Datas.date(valor) ?? Date() }, set: { valor = Datas.str($0) }), displayedComponents: .date)
                    .labelsHidden()
                Button { valor = "" } label: { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.borderless).foregroundStyle(.secondary)
            }
        }
    }
}
