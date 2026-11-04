# Licenças (iPhone)

App nativo para iPhone e iPad (SwiftUI, iOS 17; no iPad usa barra lateral) que usa o mesmo servidor do Painel de Licenças (login de RT/administrador).
O app NÃO guarda a senha do Upstash: ele só fala com o seu servidor (Render). O Upstash fica configurado lá.

## Gerar o IPA no GitHub
O endereço do servidor já está em Config.swift (https://licen-as.onrender.com).

1. Crie um repositório e envie o CONTEÚDO desta pasta (project.yml, LicencasApp/, .github/ na raiz).
2. Para mudar o servidor no futuro, edite `serverURL` em `LicencasApp/Config.swift`.
3. Aba Actions > Build IPA > Run workflow. Ao terminar, baixe o artefato `Licencas-ipa` (contém Licencas.ipa).
4. Instale com Sideloadly/AltStore (ID Apple gratuito vale 7 dias).

Ícone: troque `LicencasApp/Assets.xcassets/AppIcon.appiconset/icon-1024.png` (1024x1024).
