# Mapa do código (E2)

Rascunho de trabalho. Lista os arquivos reais que os documentos podem citar, com a linha que interessa. Todos os caminhos foram conferidos com `ls` no clone. Nenhum arquivo de código foi alterado.

Arquivos que ainda não existem e só podem aparecer nos documentos como "a criar": `src/worker.ts`, `src/modules/webhooks/` e tudo dentro dele. O Tracker nunca usa esses caminhos com fonte `CODIGO`.

Stack (de `package.json`): Node >= 20, TypeScript 5.6, Express 4.21, Prisma 5.22 com MySQL 8.0 (`docker-compose.yml`), Zod 3.23, Pino 9.5, jsonwebtoken 9, uuid 11, Vitest 2.1 com Supertest. Scripts atuais: `dev`, `build`, `start`, `db:*`, `test`, `lint`, `format`. Não existe script `worker`.

## 1. Pontos de integração da feature

| Arquivo | O que tem hoje | Onde o webhook encosta |
| --- | --- | --- |
| `src/modules/orders/order.service.ts` | `changeStatus` (l. 126–179) abre `this.prisma.$transaction` (l. 131), busca o pedido com items, valida a transição, debita ou repõe estoque, faz `tx.order.update` (l. 158) e `tx.orderStatusHistory.create` (l. 159–167). O tipo `TxClient = Prisma.TransactionClient` está na l. 24 | Chamada a `publishWebhookEvent(tx, order, from, to)` depois do insert no histórico, dentro do mesmo `$transaction`. O `order` lido na l. 132 já tem `id`, `orderNumber`, `customerId`, `status` e `totalCents` |
| `src/modules/orders/order.status.ts` | Máquina de estados: `transitions` (l. 3–10), `canTransition`, `allowedTransitions`, `isTerminal`, `shouldDebitStock`, `shouldReplenishStock` | Fonte dos valores válidos para o filtro de status do webhook; nenhuma mudança na máquina |
| `prisma/schema.prisma` | Enum `OrderStatus` (l. 16–23): PENDING, PAID, PROCESSING, SHIPPED, DELIVERED, CANCELLED. Enum `UserRole` (l. 11–14): ADMIN, OPERATOR. Ids `String @id @default(uuid()) @db.Char(36)`. Tabelas com `@@map` em snake_case e índices com `@@index` | Novos models para configuração de webhook, outbox, dead letter e histórico de entregas, seguindo o mesmo padrão de id e mapeamento |
| `prisma/migrations/20260519182739_init/migration.sql` | Migration inicial | Uma migration nova para as tabelas do webhook |
| `src/server.ts` | Entry point da API: `buildApp({ prisma })`, `app.listen`, shutdown em SIGINT/SIGTERM com `prisma.$disconnect()` | Modelo para o novo `src/worker.ts` |
| `src/config/database.ts` | `createPrismaClient()` e o `prisma` exportado | O worker cria a própria instância com `createPrismaClient()` |
| `src/config/env.ts` | Schema Zod das variáveis de ambiente (`DATABASE_URL`, `JWT_SECRET`, `LOG_LEVEL` etc.) | Mesmo carregamento de env no worker |
| `src/app.ts` | `buildControllers` monta repository → service → controller de cada módulo (l. 26–53); `buildApp` registra `express.json`, `requestLogger`, `/api/v1`, 404 e `errorMiddleware` | Registrar o controller do módulo de webhooks |
| `src/routes/index.ts` | `Controllers` e `buildApiRouter`, um `router.use` por módulo (l. 24–28) | `router.use('/webhooks', ...)` e a rota admin |
| `src/shared/errors/app-error.ts` | `AppError(message, statusCode, errorCode, details)` | Base dos erros `WEBHOOK_*` |
| `src/shared/errors/http-errors.ts` | `BadRequestError`, `ValidationError`, `UnauthorizedError`, `ForbiddenError`, `NotFoundError`, `ConflictError`, `UnprocessableEntityError`; específicas `InvalidStatusTransitionError` (l. 45, código `INVALID_STATUS_TRANSITION`) e `InsufficientStockError` (l. 55, código `INSUFFICIENT_STOCK`) | Classes específicas do webhook estendendo as genéricas, como as duas de pedidos |
| `src/shared/errors/index.ts` | Barrel que reexporta os erros | Exportar os erros novos |
| `src/middlewares/error.middleware.ts` | Trata `AppError` → `{ error: { code, message, details } }`; `ZodError` → 400 `VALIDATION_ERROR`; Prisma P2002 → 409, P2025 → 404; resto → 500 com log | Pega os erros do webhook sem mudança |
| `src/middlewares/auth.middleware.ts` | `authenticate` (JWT Bearer → `req.user` com `id`, `email`, `role`) e `requireRole(...roles)` → 403 `FORBIDDEN` | `requireRole('ADMIN')` no replay da DLQ |
| `src/middlewares/validate.middleware.ts` | `validate({ body, query, params })` com Zod, devolve `ValidationError` | Validação das rotas de webhook (incluindo URL https) |
| `src/middlewares/request-logger.middleware.ts` | Gera ou reaproveita `X-Request-Id`, loga `http_request` com `requestId`, `durationMs`, `userId` | Correlação de logs da API |
| `src/shared/logger/index.ts` | Pino com `redact` (authorization, cookie, password, passwordHash, token, accessToken), `base.service = 'order-management-api'`, timestamp ISO | Logger do worker e da API |
| `src/shared/http/response.ts` | `paginated()` → `{ data, pagination }` | Formato de resposta das listagens (webhooks e deliveries) |
| `src/modules/users/user.routes.ts` | Único uso atual de `requireRole('ADMIN')` (l. 15) | Exemplo para a rota admin |
| `src/modules/orders/order.routes.ts` | `router.use(authenticate)` + `validate(...)` por rota; `PATCH /:id/status` chama `changeStatus` | Padrão de rotas do módulo novo |
| `src/modules/orders/order.schemas.ts` | Schemas Zod, `z.string().uuid()` nos params, `z.nativeEnum(OrderStatus)` | Padrão dos schemas do webhook |
| `src/modules/customers/` | Módulo com controller, service, repository, routes, schemas | Padrão de CRUD a seguir; webhook pertence a um customer |
| `tests/orders.test.ts` | Testes de integração com Supertest em `/api/v1/orders`, incluindo transições e estoque | Modelo de teste para a integração no `changeStatus` |
| `tests/setup.ts` | Limpa as tabelas em `beforeEach` | Testes futuros precisariam limpar as tabelas novas (anotar no FDD; não mexer agora) |
| `tests/helpers/factories.ts` | `getTestApp`, `bootstrapAuthenticatedUser`, `createTestCustomer`, `createTestProduct` | Reuso nos testes do webhook |
| `vitest.config.ts` | Testes em série (`singleFork`, `fileParallelism: false`) | Estratégia de teste |

## 2. Conferência dos ganchos da reunião (COD-xx do inventário)

| ID | O que a reunião diz | No código | Situação |
| --- | --- | --- | --- |
| COD-01 | Transação atualiza `orders`, insere em `order_status_history`, decrementa `stock_quantity` | `order.service.ts` l. 151–167. A coluna real é `stockQuantity` (`migration.sql` l. 38); o estoque é debitado só em PENDING → PAID e reposto em cancelamento a partir de PAID ou PROCESSING (`order.status.ts` l. 24–37) | Confere, com nuance: não é toda mudança de status que mexe em estoque |
| COD-02 | Método `changeStatus` do service de orders | `order.service.ts` l. 126 | Confere |
| COD-03 | Existe `src/server.ts` | Existe | Confere |
| COD-04 | Módulos em `src/modules` com controller, service, repository, routes e schemas | orders, customers, products e users têm os cinco arquivos; `auth` não tem repository (usa o `UserRepository`) | Confere para os módulos de domínio |
| COD-05 | `AppError`, `InsufficientStockError`, `InvalidStatusTransitionError`, códigos `INSUFFICIENT_STOCK`, `INVALID_STATUS_TRANSITION` | `app-error.ts`, `http-errors.ts` l. 45–63 | Confere |
| COD-06 | Pino no projeto inteiro | `src/shared/logger/index.ts`, usado em `server.ts` e nos middlewares | Confere |
| COD-07 | Error middleware trata AppError, Zod e Prisma | `error.middleware.ts` l. 15–54 | Confere |
| COD-08 | `requireRole` com ADMIN | `auth.middleware.ts` l. 49; roles `ADMIN` e `OPERATOR` | Confere |
| COD-09 | JWT é de usuário operador, não de customer | `AuthUser` tem `id`, `email`, `role`; o model `User` não tem `customerId` | Confere |
| COD-10 | Status PAID, PROCESSING, SHIPPED, DELIVERED | Enum também tem PENDING e CANCELLED | Confere |
| COD-11 | `GET /orders` e `GET /orders/:id` | Existem, mas com prefixo: `/api/v1/orders` e `/api/v1/orders/:id` (`app.ts` l. 67) | Confere, com prefixo `/api/v1` |
| COD-12 | Ids em UUID no projeto todo | Todos os models (exceto `OrderNumberSequence`, id int fixo 1) | Confere |
| COD-13 | Pedido tem `order_number` e `total_cents` | Campos `orderNumber` (formato `ORD-000001`) e `totalCents` em camelCase | Confere; o payload da reunião usa snake_case |
| COD-14 | Lógica do worker em `webhook.worker.ts` ou `webhook.processor.ts` | Ainda não existe (é proposta) | Arquivo a criar |

## 3. Divergências e lacunas para levar aos documentos

1. **Prefixo `/api/v1`.** Todas as rotas da API ficam sob `/api/v1` (`src/app.ts` l. 67). Os endpoints citados na reunião (`/webhooks/:id/deliveries`, `/admin/webhooks/dead-letter/:id/replay`) devem aparecer no FDD com esse prefixo.
2. **snake_case × camelCase.** A API devolve JSON em camelCase (`orderNumber`, `totalCents`), e a reunião definiu o payload do webhook em snake_case (`order_number`, `total_cents`, [09:43] Diego). São contratos diferentes (resposta da API × corpo do webhook), então não há contradição, mas o FDD deve deixar explícito.
3. **Usuário que representa o cliente.** Marcos diz que "a gente tem usuários que representam o cliente" ([09:32]), mas o model `User` não tem vínculo com `Customer`. Isso confirma a decisão de passar o `customer_id` no body ou no path ([09:32] Larissa).
4. **Nada de métricas nem tracing no código.** Hoje existem só logs Pino e o `X-Request-Id` do `request-logger.middleware.ts`. Não há OpenTelemetry, Prometheus ou similar no `package.json`, e a reunião não discute métricas nem tracing. O FDD exige as duas coisas.
5. **Secret fora do `redact` do logger.** A lista de `redact` em `src/shared/logger/index.ts` não cobre um campo `secret`. A reunião lembra que um cliente já vazou secret em log ([09:22] Diego).
6. **`express.json({ limit: '1mb' })`** em `src/app.ts` l. 59. Vale para requests que chegam à API, não para o payload de saída de 64KB. Sem conflito.
7. **Seed.** `prisma/seed.ts` tem um customer da Atlas Comercial (`contato@atlascomercial.com.br`), mas não tem MaxDistribuição nem Nova Cargo. Não afeta os documentos.

## 4. Decisões sobre as lacunas

- **Métricas (lacuna 4):** o FDD lista só métricas com fonte: entregas com sucesso e com falha e tempo de resposta ([09:34] Marcos), número de retentativas ([09:15] Diego), tamanho da DLQ ([09:18] Diego) e idade do evento pendente mais antigo comparada com a meta de menos de 10s ([09:02] Marcos). Nenhuma métrica sem origem.
- **Redact do secret (lacuna 5):** o FDD propõe incluir o campo `secret` no `redact` de `src/shared/logger/index.ts`, com fonte no arquivo e em [09:22] Diego.
- **Tracing:** só correlação por ids nos logs Pino: `X-Request-Id` (`src/middlewares/request-logger.middleware.ts`) do lado da API e `event_id` ([09:25] Diego) da outbox até o envio. Sem ferramenta de tracing e sem questão em aberto sobre isso, porque a reunião não tocou no assunto.
