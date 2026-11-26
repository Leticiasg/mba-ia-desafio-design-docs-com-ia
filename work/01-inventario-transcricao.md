# Inventário da transcrição (E1)

Rascunho de trabalho. Cada item aponta para a fala de origem em `TRANSCRICAO.md` no formato `[hh:mm] Nome`. Quando a decisão foi proposta por uma pessoa e fechada por outra, as duas falas aparecem. Os IDs daqui (DEC, RF, RNF etc.) são internos; o Tracker final usa os IDs de cada documento.

Participantes: Larissa (Tech Lead, conduz), Marcos (PM), Bruno (Eng. Pleno, Pedidos), Diego (Eng. Sênior, Plataforma, entra às 09:05), Sofia (Segurança). Marcos e Sofia saem às 09:50; as decisões DEC-17 e DEC-18 foram tomadas depois disso, só com Larissa, Diego e Bruno.

## 1. Contexto e problema

| ID | Item | Localização |
| --- | --- | --- |
| CTX-01 | Três clientes B2B (Atlas Comercial, MaxDistribuição, Nova Cargo) pediram formalmente notificação quando o status dos pedidos muda | [09:00] Marcos |
| CTX-02 | Hoje os clientes fazem polling no `GET /orders`, o que deixa a integração lenta e cara para eles | [09:00] Marcos |
| CTX-03 | A Atlas sinalizou que pode migrar para o concorrente se a feature não sair até o fim do trimestre | [09:00] Marcos |
| CTX-04 | Para os clientes, "tempo real" é qualquer coisa abaixo de 10 segundos | [09:02] Marcos |
| CTX-05 | Webhook só de saída (outbound): a plataforma envia, os clientes não enviam | [09:02] Marcos, [09:03] Sofia |
| CTX-06 | Os clientes nunca pediram ordenação global; querem saber se cada pedido mudou | [09:14] Marcos |
| CTX-07 | Já houve cliente com indisponibilidade de duas horas em manutenção planejada | [09:16] Diego |
| CTX-08 | Já houve cliente que vazou secret em log da própria aplicação | [09:22] Diego |
| CTX-09 | O time é pequeno (argumento contra subir infra nova) | [09:07] Diego |

## 2. Decisões fechadas

As seis decisões principais do enunciado são DEC-01 a DEC-07 (o retry e a DLQ aparecem separados aqui) e DEC-08.

| ID | Decisão | Localização |
| --- | --- | --- |
| DEC-01 | Padrão outbox no MySQL existente: o evento é gravado numa tabela `webhook_outbox` na mesma transação que atualiza `orders` e `order_status_history`; commit e rollback valem para os dois | [09:06] Diego, [09:08] Larissa |
| DEC-02 | O worker lê a outbox por polling a cada 2 segundos, pegando os pendentes mais antigos; latência de 2s no pior caso foi aceita | [09:09] Diego, [09:10] Marcos, [09:10] Larissa |
| DEC-03 | O worker roda como processo separado da API (se a API reinicia, o worker não cai junto), com entry point `src/worker.ts` e script `npm run worker` | [09:11] Diego, [09:11] Larissa |
| DEC-04 | O worker usa o mesmo banco e a mesma stack, com uma instância própria do PrismaClient (mesma `DATABASE_URL`, outro processo Node) | [09:11] Bruno, [09:11] Diego, [09:30] Bruno |
| DEC-05 | Retry com backoff exponencial, 5 tentativas, intervalos de 1m, 5m, 30m, 2h e 12h (quase 15h entre a primeira falha e a última tentativa) | [09:15] Diego, [09:17] Diego, [09:17] Larissa |
| DEC-06 | Esgotadas as tentativas, o evento vai para uma tabela separada `webhook_dead_letter`, com payload, motivo da falha e timestamp | [09:18] Diego, [09:48] Larissa |
| DEC-07 | Reprocessamento da DLQ é manual, por `POST /admin/webhooks/dead-letter/:id/replay`, que recoloca o evento na outbox como pendente | [09:18] Diego, [09:19] Larissa |
| DEC-08 | HMAC-SHA256 sobre o corpo do request, assinatura no header `X-Signature`; o cliente valida do lado dele | [09:20] Sofia, [09:22] Sofia |
| DEC-09 | Secret única por endpoint de webhook, nunca global ("se vaza uma, vaza tudo") | [09:21] Sofia |
| DEC-10 | Secret rotacionável por endpoint da API; a antiga continua válida por 24h em paralelo e depois expira | [09:21] Sofia, [09:22] Sofia |
| DEC-11 | Garantia at-least-once: o cliente pode receber o mesmo evento mais de uma vez e deduplica pelo `X-Event-Id`, um UUID gerado quando o evento entra na outbox | [09:24] Diego, [09:25] Diego, [09:26] Larissa |
| DEC-12 | Reuso máximo dos padrões do projeto: módulo `src/modules/webhooks` com controller, service, repository, routes e schemas; AppError; Pino; error middleware; schemas Zod; padrão de códigos de erro | [09:27] Bruno, [09:30] Larissa |
| DEC-13 | Códigos de erro do módulo com prefixo `WEBHOOK_` (exemplos citados: `WEBHOOK_NOT_FOUND`, `WEBHOOK_INVALID_URL`, `WEBHOOK_SECRET_REQUIRED`) | [09:28] Bruno, [09:29] Larissa |
| DEC-14 | O replay da DLQ exige role ADMIN, reaproveitando o `requireRole` existente | [09:36] Sofia, [09:36] Larissa |
| DEC-15 | A inserção na outbox fica dentro da transação do `changeStatus`; se a outbox falhar, a transação inteira faz rollback | [09:40] Bruno, [09:41] Diego |
| DEC-16 | O `order.service` chama uma função `publishWebhookEvent(tx, order, fromStatus, toStatus)` que recebe o client da transação, em vez de receber o repository do webhook injetado | [09:41] Bruno, [09:41] Diego |
| DEC-17 | IDs da outbox em UUID, seguindo o padrão do projeto | [09:51] Larissa |
| DEC-18 | O payload é gravado já renderizado na inserção (snapshot do estado no momento da mudança de status) | [09:52] Larissa, [09:52] Diego, [09:52] Bruno |
| DEC-19 | O filtro de status é aplicado na inserção da outbox: se nenhum webhook do customer quer aquele status, nada é inserido | [09:34] Bruno, [09:34] Diego |
| DEC-20 | Ordenação garantida só por `order_id` e só enquanto houver um único worker (processa por `created_at`); registrada como limitação conhecida | [09:12] Diego, [09:13] Larissa |
| DEC-21 | O `customer_id` vai no body ou no path, não vem do JWT (o JWT é de usuário operador; há usuários que representam o cliente) | [09:32] Bruno, [09:32] Marcos, [09:32] Larissa |

## 3. Requisitos funcionais

| ID | Requisito | Localização |
| --- | --- | --- |
| RF-01 | Notificar o endpoint do cliente quando o status de um pedido dele muda | [09:00] Marcos |
| RF-02 | Cadastrar webhook via POST, com url e lista de status a receber; a secret é gerada pela plataforma e devolvida na criação | [09:31] Marcos |
| RF-03 | Editar webhook (PATCH) | [09:33] Bruno |
| RF-04 | Remover webhook (DELETE) | [09:33] Bruno |
| RF-05 | Listar os webhooks de um customer (GET) | [09:33] Bruno |
| RF-06 | Filtrar por endpoint quais status disparam notificação (ex.: só SHIPPED e DELIVERED) | [09:33] Marcos |
| RF-07 | Consultar o histórico de entregas de um webhook (`GET /webhooks/:id/deliveries`): últimas 100, sucesso/falha, payload, response e tempo de resposta | [09:34] Marcos |
| RF-08 | Rotacionar a secret de um webhook pela API | [09:21] Sofia |
| RF-09 | Reprocessar manualmente um evento da DLQ (`POST /admin/webhooks/dead-letter/:id/replay`) | [09:18] Diego, [09:35] Diego |
| RF-10 | Registrar quem fez o replay, para auditoria | [09:36] Sofia |
| RF-11 | Recusar com erro de validação URL que não seja https | [09:23] Sofia |
| RF-12 | Recusar (erro, sem truncar) evento acima de 64KB | [09:23] Sofia, [09:24] Diego, [09:24] Larissa |
| RF-13 | Enviar os headers `X-Event-Id`, `X-Signature`, `X-Timestamp`, `X-Webhook-Id` e `Content-Type: application/json` | [09:44] Diego, [09:44] Sofia, [09:45] Diego |
| RF-14 | Payload JSON com `event_id`, `event_type` (ex.: `order.status_changed`), timestamp ISO 8601, `order_id`, `order_number`, `from_status`, `to_status`, `customer_id` e campos básicos do pedido como `total_cents`; sem items | [09:43] Diego, [09:44] Bruno |

## 4. Requisitos não funcionais e restrições

| ID | Item | Localização |
| --- | --- | --- |
| RNF-01 | Latência abaixo de 10s entre a mudança de status e a notificação | [09:02] Marcos, [09:09] Diego |
| RNF-02 | Envio síncrono proibido: um cliente lento não pode travar a mudança de status de outros pedidos | [09:04] Bruno, [09:06] Diego |
| RNF-03 | Timeout de 10s no HTTP call do worker; sem resposta, conta como falha e vai para retry | [09:42] Diego |
| RNF-04 | TLS obrigatório (URL https), validado no schema Zod | [09:23] Sofia |
| RNF-05 | Limite de 64KB de payload (tratado como requisito não funcional, não como decisão arquitetural) | [09:24] Larissa |
| RNF-06 | Índices da outbox em `status` (pendente, processando, falhou, entregue) e em `created_at`; worker lê em batch pequeno | [09:08] Diego |
| RNF-07 | Nada de infra nova (sem Redis/broker) | [09:07] Diego |
| RNF-08 | CRUD de configuração aceita qualquer role autenticada, por enquanto | [09:36] Marcos, [09:37] Sofia |
| RNF-09 | Revisão de segurança de pelo menos dois dias úteis antes do deploy, com foco em HMAC e geração de secret | [09:46] Sofia, [09:49] Sofia |

## 5. Ganchos com o código (conferir no E2)

| ID | O que a reunião diz do código | Localização |
| --- | --- | --- |
| COD-01 | A transação de mudança de status atualiza `orders`, insere em `order_status_history` e decrementa `stock_quantity` | [09:04] Bruno, [09:40] Bruno |
| COD-02 | O método a estender é o `changeStatus` do service de orders | [09:40] Bruno |
| COD-03 | Existe `src/server.ts` como entry point da API | [09:11] Larissa |
| COD-04 | Cada domínio é um módulo em `src/modules` com controller, service, repository, routes e schemas | [09:27] Bruno |
| COD-05 | Existem `AppError`, `InsufficientStockError`, `InvalidStatusTransitionError` e códigos como `INSUFFICIENT_STOCK`, `INVALID_STATUS_TRANSITION` | [09:28] Bruno |
| COD-06 | Logger Pino usado no projeto todo | [09:29] Bruno |
| COD-07 | Middleware de erro centralizado trata AppError, Zod e Prisma | [09:29] Bruno |
| COD-08 | Middleware `requireRole` com role ADMIN no JWT | [09:35] Larissa, [09:36] Larissa |
| COD-09 | JWT é de usuário operador, não de customer | [09:32] Bruno |
| COD-10 | Status de pedido citados: PAID, PROCESSING, SHIPPED, DELIVERED | [09:12] Larissa, [09:33] Marcos |
| COD-11 | Endpoints `GET /orders` e `GET /orders/:id` | [09:00] Marcos, [09:43] Diego |
| COD-12 | IDs em UUID no projeto todo | [09:51] Larissa |
| COD-13 | Pedido tem `order_number` e `total_cents` | [09:43] Diego |
| COD-14 | Lógica do worker num arquivo do módulo (`src/modules/webhooks/webhook.worker.ts` ou `webhook.processor.ts`) | [09:28] Bruno |

## 6. Descartados (alternativas rejeitadas)

| ID | O que foi descartado | Motivo | Localização |
| --- | --- | --- | --- |
| DESC-01 | Disparo síncrono dentro do service de orders | Transação já pesada; cliente lento trava outros pedidos; cliente fora do ar obrigaria rollback da mudança de status | [09:04] Bruno, [09:06] Diego |
| DESC-02 | Redis Streams / Redis Cluster | Exige subir infra nova; overengineering para time pequeno | [09:07] Larissa, [09:07] Diego |
| DESC-03 | Trigger do banco para acordar o worker | MySQL não tem LISTEN/NOTIFY; trigger só executa SQL e não avisa processo externo | [09:09] Bruno, [09:09] Diego |
| DESC-04 | Retry indefinido com backoff | Evento fica pendurado para sempre se o cliente sumiu | [09:15] Diego |
| DESC-05 | 3 tentativas | Mataria o evento em cerca de 30 minutos; não cobre indisponibilidade de horas | [09:16] Bruno, [09:16] Diego |
| DESC-06 | DLQ como status "failed" na própria outbox | Tabela separada deixa a leitura da outbox mais limpa e guarda evidência para debug e reprocessamento | [09:17] Larissa, [09:18] Diego |
| DESC-07 | Secret global da plataforma | Se vaza uma, vaza tudo | [09:21] Sofia |
| DESC-08 | Exactly-once | Exige coordenação dos dois lados, muito mais complexo | [09:25] Diego |
| DESC-09 | Truncar payload grande | Evento desse tamanho indica erro; preferiram recusar | [09:23] Sofia, [09:24] Larissa |
| DESC-10 | `customer_id` extraído do JWT | O JWT é do usuário operador | [09:32] Bruno, [09:32] Larissa |
| DESC-11 | Mandar os items do pedido no payload | Infla o payload; o cliente consulta `GET /orders/:id` se precisar | [09:43] Diego |
| DESC-12 | Renderizar o payload na hora do envio | O evento deixaria de refletir o estado do momento da mudança | [09:52] Larissa |
| DESC-13 | ID auto incremental na outbox | Projeto usa UUID em tudo | [09:51] Larissa |
| DESC-14 | Webhooks de entrada (clientes enviando para a plataforma) | Clientes só querem receber | [09:02] Marcos |

## 7. Adiados (decidido que fica para depois)

| ID | Item | Localização |
| --- | --- | --- |
| ADI-01 | E-mail avisando o cliente quando o webhook dele falha: fora desta fase, talvez na próxima, depois de medir impacto | [09:37] Larissa, [09:38] Marcos, [09:48] Larissa |
| ADI-02 | Dashboard visual para o cliente: fora desta fase; projeto separado do time de frontend; nesta fase só endpoints | [09:40] Larissa, [09:48] Larissa |
| ADI-03 | Arquivar linhas entregues da outbox depois de uns 30 dias: fora do escopo da feature | [09:08] Diego |
| ADI-04 | Restringir por role o CRUD de configuração: "mais pra frente a gente pode endurecer" | [09:37] Sofia |
| ADI-05 | Escalar para vários workers em paralelo: "problema do futuro" | [09:13] Diego |

## 8. Em aberto (não decidido)

| ID | Questão | Localização |
| --- | --- | --- |
| ABE-01 | Rate limiting de envio por cliente (ex.: 50 pedidos mudando em um minuto): observar e decidir depois | [09:38] Diego, [09:39] Diego, [09:39] Larissa, [09:48] Larissa |
| ABE-02 | Como escalar além de um worker sem perder ordenação: particionar por `order_id` ou lock pessimista | [09:13] Diego |
| ABE-03 | `customer_id` no body ou no path das rotas de configuração | [09:32] Larissa |
| ABE-04 | Nome do arquivo de processamento: `webhook.worker.ts` ou `webhook.processor.ts` | [09:28] Bruno |
| ABE-05 | Proteção contra replay attack: a reunião só manda o `X-Timestamp` para o cliente detectar "se quiser"; nenhuma janela de validade foi definida | [09:44] Diego |

## 9. Prazo e plano

| ID | Item | Localização |
| --- | --- | --- |
| PRZ-01 | A Atlas quer a feature para o fim de novembro | [09:45] Marcos |
| PRZ-02 | Estimativa: outbox e DLQ (1 sprint), worker e retry (1), CRUD e deliveries (meia), integração no `order.service` e testes ponta a ponta (meia), HMAC, schemas e validações (um pouco mais) | [09:46] Larissa |
| PRZ-03 | Total de três sprints, com a revisão de segurança da Sofia no fim | [09:46] Larissa, [09:47] Larissa |
| PRZ-04 | Marcos documenta o at-least-once e a integração no portal de desenvolvedor | [09:26] Marcos, [09:40] Marcos |
| PRZ-05 | Larissa abre o doc de design e marca revisão com Bruno e Diego antes de começar a codar | [09:50] Larissa |

## 10. Ambiguidades e como foram resolvidas

1. **Número de tentativas.** A reunião fala em "5 tentativas" e lista 5 intervalos (1m, 5m, 30m, 2h, 12h), com "quase 15 horas entre primeira falha e última tentativa" ([09:15] Diego, [09:17] Diego, [09:48] Larissa). Se a primeira falha conta como tentativa 1, cinco intervalos levam a 6 envios no total.
   **Resolução:** envio inicial + 5 retentativas, uma por intervalo (6 envios). É a leitura que usa os 5 intervalos citados e fecha com as "quase 15 horas". Nos documentos, marcar como interpretação da lista de intervalos e citar [09:17] Diego.
2. **Prazo.** Às [09:00] Marcos fala em "fim do trimestre" e às [09:45] em "fim de novembro".
   **Resolução:** citar as duas falas, cada uma no seu papel: "fim do trimestre" é o prazo da ameaça de migração da Atlas ([09:00] Marcos) e "fim de novembro" é a data que a Atlas pediu ([09:45] Marcos).
3. **"Latência mínima de 2 segundos no pior caso"** ([09:10] Larissa). A frase mistura mínimo e pior caso.
   **Resolução:** registrar que o polling acrescenta até 2s de atraso, dentro da meta de menos de 10s, citando [09:10] Larissa e [09:09] Diego.
