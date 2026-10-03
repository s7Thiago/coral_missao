# Diretrizes de Código Limpo e Componentização

## Princípios Obrigatórios

1. **Modularidade e Componentização**:
   - Sempre prefira criar componentes separados, independentes, reutilizáveis e desacoplados quando for conveniente.
   - Evite implementar tudo em um arquivo só, desorganizando o projeto.
   - Modais, diálogos e widgets complexos devem ser extraídos para arquivos separados na pasta `widgets`.

2. **Reutilização e Utilitários**:
   - Sempre avalie se é conveniente criar utilitários, serviços ou repositórios desacoplados.
   - Mantenha o código limpo, organizado e legível, respeitando as responsabilidades de cada camada (`models`, `services`, `utils`, `viewmodels`, `widgets`, `views`).
