# ADR-006: Construir o módulo de webhooks com os padrões que o projeto já tem

- **Data do registro:** 2026-11-25
- **Decisores:** Larissa (Tech Lead), Bruno (Pedidos), Diego (Plataforma), Sofia (Segurança), Marcos (PM)
- **Origem:** reunião técnica de webhooks, [09:27] a [09:30], [09:36] e [09:41]; depois da saída de Marcos e Sofia, [09:51]
- **Tags:** backend, padrões de código
- **Relações:** relacionado a [ADR-001](ADR-001-outbox-no-mysql.md), [ADR-002](ADR-002-worker-separado-em-polling.md), [ADR-003](ADR-003-retry-com-backoff-e-dlq.md) e [ADR-004](ADR-004-hmac-sha256-com-secret-por-endpoint.md)

## Status

Aceito.

## Contexto

O OMS já tem convenções claras. Cada domínio tem uma pasta própria em `src/modules/`, com controller, service, repository, routes e schemas ([09:27] Bruno); `src/modules/orders/` e `src/modules/customers/` seguem esse formato. Os erros partem de `AppError` (`src/shared/errors/app-error.ts`), com classes específicas como `InvalidStatusTransitionError` e `InsufficientStockError` em `src/shared/errors/http-errors.ts` e códigos como `INVALID_STATUS_TRANSITION` e `INSUFFICIENT_STOCK` ([09:28] Bruno). O logger é Pino (`src/shared/logger/index.ts`). O `errorMiddleware` em `src/middlewares/error.middleware.ts` já trata `AppError`, erros do Zod e erros conhecidos do Prisma ([09:29] Bruno). O `requireRole` de `src/middlewares/auth.middleware.ts` já controla acesso por role, e todos os ids do `prisma/schema.prisma` são UUID.

A feature precisa de rotas, validação, erros, logs, controle de acesso e uma ligação com o `changeStatus` de `src/modules/orders/order.service.ts`. A pergunta era quanto disso reaproveitar.

## Alternativas Consideradas

1. **Injetar o repository do webhook no `OrderService`.** Bruno levantou essa opção ([09:41] Bruno). Ficou de fora: em vez do repository inteiro, o `changeStatus` chama uma função `publishWebhookEvent(tx, order, fromStatus, toStatus)` que recebe o client da transação ([09:41] Bruno, [09:41] Diego). O papel dessa função na atomicidade está no [ADR-001](ADR-001-outbox-no-mysql.md).
2. **Worker compartilhando a instância do PrismaClient da API.** Diego perguntou ([09:29] Diego). Ficou de fora porque o PrismaClient é por processo: o worker usa o mesmo banco com uma instância própria ([09:30] Bruno).
3. **Montar o módulo com soluções próprias** (outra forma de tratar erros, outro logger, outra estrutura de pastas). Não foi proposta na reunião; está aqui como a alternativa plausível ao reuso. Foi rejeitada pela decisão explícita de "reuso máximo" ([09:30] Larissa) e pelo "não vamos botar nada novo" sobre o logger ([09:29] Bruno).

## Decisão

O módulo de webhooks é um módulo igual aos outros ([09:30] Larissa):

- fica em `src/modules/webhooks/` (a criar), com controller, service, repository, routes e schemas, no formato de `src/modules/orders/` ([09:27] Bruno);
- os erros estendem `AppError` ou as classes de `src/shared/errors/http-errors.ts` e usam códigos com prefixo `WEBHOOK_`, como `WEBHOOK_NOT_FOUND`, `WEBHOOK_INVALID_URL` e `WEBHOOK_SECRET_REQUIRED` ([09:28] Bruno, [09:29] Larissa);
- o `errorMiddleware` não muda; ele já devolve esses erros no formato padrão ([09:29] Bruno);
- os logs usam o logger Pino existente, na API e no worker ([09:29] Bruno);
- a validação usa schemas Zod com o `validate` de `src/middlewares/validate.middleware.ts` ([09:30] Larissa);
- o replay da DLQ usa `requireRole('ADMIN')`, como já acontece em `src/modules/users/user.routes.ts` ([09:36] Larissa);
- as tabelas novas usam ids UUID, como o resto do `prisma/schema.prisma` ([09:51] Larissa).

## Consequências

Positivas:

- Pouco código novo de infraestrutura: erros, logs, validação e autenticação já existem e já estão em uso nos outros módulos.
- Quem conhece o módulo de pedidos entende o de webhooks sem ler nada novo.
- Os erros do módulo saem no mesmo formato JSON que os clientes da API já recebem.

Negativas:

- O módulo herda as limitações do que já existe. A lista de `redact` em `src/shared/logger/index.ts`, por exemplo, não cobre um campo de secret; ela precisa ser estendida, porque já houve cliente que vazou secret em log ([09:22] Diego).
- O `order.service.ts` passa a importar uma função do módulo de webhooks, criando uma dependência entre os dois domínios.
- O padrão de roles atual só tem ADMIN e OPERATOR. O CRUD de webhooks fica aberto a qualquer usuário autenticado por enquanto ([09:37] Sofia); endurecer isso depende de outra decisão.

Trade-off: o time abriu mão de desenhar algo específico para webhooks em troca de consistência com o resto do código e de menos código novo para revisar.

## Referências

- `src/modules/orders/order.service.ts`, `src/shared/errors/app-error.ts`, `src/shared/errors/http-errors.ts`, `src/middlewares/error.middleware.ts`, `src/middlewares/auth.middleware.ts`, `src/middlewares/validate.middleware.ts`, `src/shared/logger/index.ts`, `prisma/schema.prisma`
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature
