import SwiftUI

struct LoginView: View {
    @EnvironmentObject var app: AppState
    @State private var usuario = ""
    @State private var senha = ""
    @State private var lembrar = true
    @State private var servidor = ""
    @State private var erro = ""
    @State private var entrando = false

    var body: some View {
        ZStack {
            Fundo()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18).fill(laranja.gradient).frame(width: 60, height: 60)
                        Image(systemName: "checkmark.seal.fill").font(.system(size: 28)).foregroundStyle(.white)
                    }
                    .padding(.top, 60)
                    Text("Bem-vindo").font(.largeTitle.bold())
                    Text("Entre para acompanhar as licenças dos seus empreendimentos.").foregroundStyle(.secondary)
                    if app.precisaServidor {
                        TextField("Endereço do servidor (https://…)", text: $servidor)
                            .textInputAutocapitalization(.never).autocorrectionDisabled().keyboardType(.URL).pill()
                    }
                    TextField("Usuário", text: $usuario)
                        .textInputAutocapitalization(.never).autocorrectionDisabled().textContentType(.username).pill()
                    SecureField("Senha", text: $senha).textContentType(.password).pill()
                    Toggle("Manter conectado neste iPhone", isOn: $lembrar).font(.subheadline)
                    if !erro.isEmpty { Text(erro).font(.footnote).foregroundStyle(.red) }
                    Button {
                        Task { await entrar() }
                    } label: {
                        HStack {
                            if entrando { ProgressView().tint(.white) }
                            Text("Entrar").bold()
                        }
                        .frame(maxWidth: .infinity, minHeight: 50)
                        .background(Capsule().fill(laranja))
                        .foregroundStyle(.white)
                    }
                    .disabled(entrando || usuario.isEmpty || senha.isEmpty)
                    .opacity(usuario.isEmpty || senha.isEmpty ? 0.5 : 1)
                    Text("O primeiro acesso (criar o administrador) é feito pelo site.")
                        .font(.footnote).foregroundStyle(.secondary).padding(.top, 6)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear { servidor = app.servidor }
    }

    func entrar() async {
        erro = ""
        entrando = true
        defer { entrando = false }
        do {
            let srv = app.precisaServidor ? servidor : app.servidor
            try await app.entrar(servidor: srv, usuario: usuario.trimmingCharacters(in: .whitespaces).lowercased(), senha: senha, lembrar: lembrar)
        } catch {
            erro = error.localizedDescription
        }
    }
}
