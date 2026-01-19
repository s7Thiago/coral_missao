prótótipo de alta fidelidade seguindo um estilo consistente com Material Design 3, com uma ótima hierarquia visual dos componentes, usando um estilo minimalista e altamente intuitivo para um app de reprodução de músicas para o coral da minha igreja. 

Objetivos do app:
 - Este app deve ser um local onde os coristas possam acessar e reproduzir os kits disponíveis para cada música referente ao seu naipe vocal.
 - Considerando que alguns coristas não tem muita desenvoltura com tecnologia, o app deve ser simples e intuitivo.
 - Ele deve mostrar uma relação dos kits de voz disponíveis para cada música de forma organizada e intuitiva.
 - As músicas disponíveis no app estarão hospedadas em uma release no github.
 - Música do seu naipe vocal que o usuário ainda não ouviu deve ter um ícone de download ao invés de um botão de reprodução.
 - Quando o usuário já fez o download de uma música, ela sempre estará disponível para reprodução offline

Abaixo, estão as aracterísticas gerais de funcionamento e recursos que o app deve ter:

Estrutura dos dados que o app vai consumir:
```json
[
    {
        "id": "agnus_dei_00",
        "titulo": "AGNUS DEI",
        "vozes": [
            {
                "naipe": "SOPRANO",
                "link": "https://.../AGNUS_DEI.SOPRANO.mp3"
            },
            {
                "naipe": "CONTRALTO",
                "link": "https://.../AGNUS_DEI.CONTRALTO.mp3"
            },
            {
                "naipe": "TENOR",
                "link": "https://.../AGNUS_DEI.TENOR.mp3"
            },
            {
                "naipe": "BAIXO",
                "link": "https://.../AGNUS_DEI.BAIXO.mp3"
            }
        ],
        "tamanho": "8.91MB"
    },
]
```

Telas da aplicação:

- tela de listagem de músicas:
    - deve ter um painel de músicas ouvidas recentemente que mostre as músicas que o usuário ouviu recentemente em cima da listagem principal de músicas com kits disponíveis
    - deve conter uma lista de músicas que tem kit disponíveis para algum naipe vocal
    - na listagem de músicas, deve conter um indicador mostrando quais naipes estão disponíveis para cada música
    - ações nessa tela:
      - quando o usuário clicar em um indicador do naipe na lista, deve abrir uma tela de reprodução de música
      - quando o usuário clicar na música na lista, deve abrir uma tela de reprodução

- tela de reprodução de música
  - deve conter controles de pausa/reprodução, avançar/retroceder e velocidade da música
  - o usuário deve conseguir escolher facilmente o naipe que deseja ouvir na tela de reprodução 
  - deve conter um slider minimalista para controlar o momento da música ou acompanhar o progresso da reprodução

Funcionalidades:

- possibilitar pausar/reproduzir, retroceder/avançar na música
- conter um slider minimalista para controlar o momento da música ou acompanhar o progresso da reprodução
- o app deve ter uma organização que facilite reunir músicas por naipe vocal.
- a interface do app deve possibilitar ver apenas os kits de voz disponíveis para cada música, de forma intuitiva e simples