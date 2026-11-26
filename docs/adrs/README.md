# Architectural Decision Records

Este diretório armazena os ADRs (Architectural Decision Records) do projeto.
Cada decisão arquitetural relevante deve ser registrada aqui em arquivos individuais,
nomeados sequencialmente no formato `ADR-NNN-titulo-em-kebab-case.md` (por exemplo `ADR-001-outbox-no-mysql.md`).

## Índice

| ADR | Decisão | Status |
| --- | --- | --- |
| [ADR-001](ADR-001-outbox-no-mysql.md) | Registrar os eventos de webhook numa outbox no MySQL | Aceito |
| [ADR-002](ADR-002-worker-separado-em-polling.md) | Entregar os eventos com um worker separado que lê a outbox por polling | Aceito |
| [ADR-003](ADR-003-retry-com-backoff-e-dlq.md) | Retentar com backoff exponencial e mover para uma DLQ em tabela separada | Aceito |
| [ADR-004](ADR-004-hmac-sha256-com-secret-por-endpoint.md) | Assinar os webhooks com HMAC-SHA256 e uma secret por endpoint | Aceito |
| [ADR-005](ADR-005-at-least-once-com-x-event-id.md) | Garantir entrega at-least-once, com deduplicação pelo X-Event-Id | Aceito |
| [ADR-006](ADR-006-reuso-dos-padroes-do-projeto.md) | Construir o módulo de webhooks com os padrões que o projeto já tem | Aceito |
