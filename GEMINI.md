# Regras e Diretrizes do Projeto Coral Missão

## Código Limpo e Componentização (MANDATÓRIO)

1. **Modularidade & Desacoplamento**:
   - Sempre prefira criar componentes separados, independentes, reutilizáveis e desacoplados quando for conveniente.
   - Sempre avalie se é conveniente criar utilitários desacoplados ou serviços reutilizáveis nas pastas adequadas (`services`, `utils`, `widgets`, `models`).
   - Evite implementar tudo em um único arquivo desorganizando a estrutura do projeto.

2. **Organização da Interface**:
   - Diálogos, modais, elementos de lista e popups devem residir em componentes próprios na pasta `widgets`.
   - Lógicas de estado e chamadas de serviço devem ser delegadas aos `services` e `viewmodels`.
