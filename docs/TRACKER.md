# Tracker de rastreabilidade

Cada linha liga um item dos documentos à sua origem: uma fala da reunião (`TRANSCRICAO`, com `[hh:mm] Nome`) ou um arquivo do código (`CODIGO`, com o caminho). Quando um item tem mais de uma fala de origem, todas aparecem na coluna Localização, separadas por `;`.

## O que conta como item identificável

| Documento | Itens rastreados |
| --- | --- |
| PRD | contexto, metas, requisitos funcionais, requisitos não funcionais, itens fora de escopo, dependências e riscos |
| RFC | metadado de origem, alternativas, questões em aberto, impactos, riscos técnicos e prazo |
| ADRs | a decisão de cada ADR, cada alternativa considerada e as regras secundárias decididas junto |
| FDD | contratos, códigos de erro, fluxos, tabelas, estratégias de resiliência, itens de observabilidade, pontos de integração com o código, dependências e pendências |

Ficam de fora textos que só resumem outro documento (TL;DR, resumo, critérios de aceitação que repetem requisitos já rastreados) e as referências cruzadas entre documentos.

Itens com Tipo começando por "Proposta" foram definidos nos documentos, e não na reunião, para tornar uma decisão implementável: o path de um endpoint, o nome de uma tabela ou de um código de erro. A reunião decidiu o comportamento (por exemplo, "erro se passar de 64KB"); o documento deu o nome (`WEBHOOK_PAYLOAD_TOO_LARGE`). A Localização aponta para a fala que motivou a proposta.

A contagem e a validação desta tabela estão no fim do arquivo e podem ser refeitas com `bash work/validar-tracker.sh`.

## Tabela

| ID | Documento | Tipo | Conteúdo (resumo) | Fonte | Localização |
| --- | --- | --- | --- | --- | --- |
| PRD-CTX-01 | `docs/PRD.md` | Contexto | Três clientes B2B consultam a lista de pedidos periodicamente, o que deixa a integração lenta e cara | TRANSCRICAO | [09:00] Marcos |
| PRD-CTX-02 | `docs/PRD.md` | Contexto | A Atlas pode migrar para um concorrente se a feature não sair até o fim do trimestre | TRANSCRICAO | [09:00] Marcos |
| PRD-OBJ-01 | `docs/PRD.md` | Métrica | Notificação chega em menos de 10 segundos após a mudança de status | TRANSCRICAO | [09:02] Marcos |
| PRD-OBJ-02 | `docs/PRD.md` | Métrica | 3 clientes (Atlas, MaxDistribuição, Nova Cargo) recebendo notificações | TRANSCRICAO | [09:00] Marcos |
| PRD-OBJ-03 | `docs/PRD.md` | Métrica | Entrada em produção até o fim de novembro; estimativa de três sprints | TRANSCRICAO | [09:45] Marcos; [09:47] Larissa |
| PRD-OBJ-04 | `docs/PRD.md` | Métrica | Quase 15 horas de tentativas antes da fila de falhas | TRANSCRICAO | [09:17] Diego; [09:17] Marcos |
| PRD-FR-01 | `docs/PRD.md` | Requisito Funcional | Notificar o endpoint do cliente quando o pedido muda para um status escutado | TRANSCRICAO | [09:00] Marcos; [09:33] Marcos |
| PRD-FR-02 | `docs/PRD.md` | Requisito Funcional | Cadastrar webhook com endereço e status; secret gerada e devolvida na criação | TRANSCRICAO | [09:31] Marcos |
| PRD-FR-03 | `docs/PRD.md` | Requisito Funcional | Editar webhook | TRANSCRICAO | [09:33] Bruno |
| PRD-FR-04 | `docs/PRD.md` | Requisito Funcional | Remover webhook | TRANSCRICAO | [09:33] Bruno |
| PRD-FR-05 | `docs/PRD.md` | Requisito Funcional | Listar webhooks do cliente | TRANSCRICAO | [09:33] Bruno |
| PRD-FR-06 | `docs/PRD.md` | Requisito Funcional | Filtro de status por webhook, aplicado na inserção | TRANSCRICAO | [09:33] Marcos; [09:34] Bruno |
| PRD-FR-07 | `docs/PRD.md` | Requisito Funcional | Histórico das últimas 100 entregas com resultado, conteúdo, resposta e tempo | TRANSCRICAO | [09:34] Marcos |
| PRD-FR-08 | `docs/PRD.md` | Requisito Funcional | Rotação de secret com a anterior aceita por 24 horas | TRANSCRICAO | [09:21] Sofia |
| PRD-FR-09 | `docs/PRD.md` | Requisito Funcional | Assinatura de cada notificação com a secret do webhook | TRANSCRICAO | [09:19] Sofia; [09:20] Sofia |
| PRD-FR-10 | `docs/PRD.md` | Requisito Funcional | Identificador único do evento e do webhook em cada notificação | TRANSCRICAO | [09:25] Diego; [09:44] Sofia |
| PRD-FR-11 | `docs/PRD.md` | Requisito Funcional | Conteúdo da notificação: pedido, status anterior e novo, cliente, total e momento, sem itens | TRANSCRICAO | [09:43] Diego |
| PRD-FR-12 | `docs/PRD.md` | Requisito Funcional | Novas tentativas em intervalos crescentes e depois fila de falhas | TRANSCRICAO | [09:15] Diego; [09:17] Larissa |
| PRD-FR-13 | `docs/PRD.md` | Requisito Funcional | Reenvio manual por administrador, com registro de quem fez | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| PRD-FR-14 | `docs/PRD.md` | Requisito Funcional | Recusar endereço que não seja https | TRANSCRICAO | [09:23] Sofia |
| PRD-NFR-01 | `docs/PRD.md` | Requisito Não Funcional | Atraso abaixo de 10 segundos | TRANSCRICAO | [09:02] Marcos |
| PRD-NFR-02 | `docs/PRD.md` | Requisito Não Funcional | Notificação não bloqueia mudança de status de outros pedidos | TRANSCRICAO | [09:04] Bruno |
| PRD-NFR-03 | `docs/PRD.md` | Requisito Não Funcional | Notificação registrada se e somente se a mudança de status for confirmada | TRANSCRICAO | [09:06] Diego; [09:40] Bruno |
| PRD-NFR-04 | `docs/PRD.md` | Requisito Não Funcional | Entrega pelo menos uma vez, com repetição possível | TRANSCRICAO | [09:24] Diego |
| PRD-NFR-05 | `docs/PRD.md` | Requisito Não Funcional | Ordem garantida só dentro de cada pedido | TRANSCRICAO | [09:13] Larissa |
| PRD-NFR-06 | `docs/PRD.md` | Requisito Não Funcional | Sem resposta em 10 segundos conta como falha | TRANSCRICAO | [09:42] Diego |
| PRD-NFR-07 | `docs/PRD.md` | Requisito Não Funcional | Só https; uma secret por webhook | TRANSCRICAO | [09:21] Sofia; [09:23] Sofia |
| PRD-NFR-08 | `docs/PRD.md` | Requisito Não Funcional | Notificação acima de 64KB não é enviada e gera erro | TRANSCRICAO | [09:24] Diego; [09:24] Larissa |
| PRD-NFR-09 | `docs/PRD.md` | Restrição | Sem infraestrutura nova | TRANSCRICAO | [09:07] Diego; [09:11] Diego |
| PRD-NFR-10 | `docs/PRD.md` | Restrição | Revisão de segurança de pelo menos dois dias úteis antes do deploy | TRANSCRICAO | [09:46] Sofia |
| PRD-FORA-01 | `docs/PRD.md` | Escopo excluído (adiado) | Aviso por e-mail quando o webhook falha | TRANSCRICAO | [09:37] Larissa; [09:38] Marcos |
| PRD-FORA-02 | `docs/PRD.md` | Escopo excluído (fora desta fase, projeto separado) | Painel visual para o cliente | TRANSCRICAO | [09:40] Larissa |
| PRD-FORA-03 | `docs/PRD.md` | Escopo excluído (em aberto) | Rate limiting de envio por cliente | TRANSCRICAO | [09:39] Diego; [09:39] Larissa |
| PRD-FORA-04 | `docs/PRD.md` | Escopo excluído (descartado) | Webhooks de entrada | TRANSCRICAO | [09:02] Marcos |
| PRD-FORA-05 | `docs/PRD.md` | Escopo excluído (descartado) | Ordem global entre pedidos | TRANSCRICAO | [09:13] Larissa; [09:14] Marcos |
| PRD-FORA-06 | `docs/PRD.md` | Escopo excluído (descartado) | Itens do pedido na notificação | TRANSCRICAO | [09:43] Diego; [09:44] Bruno |
| PRD-FORA-07 | `docs/PRD.md` | Escopo excluído (fora da feature) | Arquivamento de notificações antigas | TRANSCRICAO | [09:08] Diego |
| PRD-FORA-08 | `docs/PRD.md` | Escopo excluído (adiado) | Permissões por tipo de usuário na configuração | TRANSCRICAO | [09:37] Sofia |
| PRD-DEP-01 | `docs/PRD.md` | Dependência | Sistemas dos clientes expostos em https | TRANSCRICAO | [09:23] Sofia |
| PRD-DEP-02 | `docs/PRD.md` | Dependência | Usuários do OMS que representam os clientes | TRANSCRICAO | [09:32] Marcos |
| PRD-DEP-03 | `docs/PRD.md` | Dependência | Portal de desenvolvedor atualizado | TRANSCRICAO | [09:26] Marcos; [09:40] Marcos |
| PRD-DEP-04 | `docs/PRD.md` | Dependência | Revisão de segurança da Sofia antes do deploy | TRANSCRICAO | [09:46] Sofia; [09:49] Sofia |
| PRD-DEP-05 | `docs/PRD.md` | Dependência | Fluxo de mudança de status dos pedidos | TRANSCRICAO | [09:40] Bruno |
| PRD-DEP-06 | `docs/PRD.md` | Dependência | Confirmação do prazo com a Atlas | TRANSCRICAO | [09:47] Marcos |
| PRD-RISCO-01 | `docs/PRD.md` | Risco | Atlas migrar para concorrente (baixa / alto) | TRANSCRICAO | [09:00] Marcos; [09:47] Marcos |
| PRD-RISCO-02 | `docs/PRD.md` | Risco | Cliente processar a mesma notificação duas vezes (média / médio) | TRANSCRICAO | [09:24] Diego; [09:25] Sofia |
| PRD-RISCO-03 | `docs/PRD.md` | Risco | Vazamento de secret (média / alto) | TRANSCRICAO | [09:22] Diego; [09:19] Sofia |
| PRD-RISCO-04 | `docs/PRD.md` | Risco | Muitas chamadas de uma vez para o cliente (baixa / médio) | TRANSCRICAO | [09:38] Diego; [09:39] Diego |
| PRD-RISCO-05 | `docs/PRD.md` | Risco | Notificação na fila de falhas sem o cliente saber (baixa / médio) | TRANSCRICAO | [09:17] Marcos; [09:37] Larissa |
| RFC-META-01 | `docs/RFC.md` | Contexto | O RFC é o documento de design que Larissa abriria para revisão com Bruno e Diego | TRANSCRICAO | [09:50] Larissa |
| RFC-ALT-01 | `docs/RFC.md` | Alternativa descartada | Envio síncrono no `changeStatus` | TRANSCRICAO | [09:04] Bruno; [09:06] Diego |
| RFC-ALT-02 | `docs/RFC.md` | Alternativa descartada | Fila externa (Redis Streams ou Cluster) | TRANSCRICAO | [09:07] Larissa; [09:07] Diego |
| RFC-ALT-03 | `docs/RFC.md` | Alternativa descartada | Trigger no MySQL para acordar o worker | TRANSCRICAO | [09:09] Bruno; [09:09] Diego |
| RFC-ALT-04 | `docs/RFC.md` | Alternativa descartada | Retry sem limite ou só 3 tentativas | TRANSCRICAO | [09:15] Diego; [09:16] Bruno; [09:16] Diego |
| RFC-ALT-05 | `docs/RFC.md` | Alternativa descartada | Secret global da plataforma | TRANSCRICAO | [09:21] Sofia |
| RFC-ALT-06 | `docs/RFC.md` | Alternativa descartada | Entrega exactly-once | TRANSCRICAO | [09:25] Diego |
| RFC-ABE-01 | `docs/RFC.md` | Questão em aberto | Rate limiting de envio por cliente | TRANSCRICAO | [09:38] Diego; [09:39] Larissa |
| RFC-ABE-02 | `docs/RFC.md` | Questão em aberto | Escala além de um worker: particionar por pedido ou lock pessimista | TRANSCRICAO | [09:13] Diego |
| RFC-ABE-03 | `docs/RFC.md` | Questão em aberto | `customer_id` no body ou no path | TRANSCRICAO | [09:32] Larissa |
| RFC-ABE-04 | `docs/RFC.md` | Questão em aberto | Proteção contra replay attack sem janela definida | TRANSCRICAO | [09:44] Diego |
| RFC-ABE-05 | `docs/RFC.md` | Questão adiada | Aviso por e-mail para a próxima fase | TRANSCRICAO | [09:37] Larissa |
| RFC-ABE-06 | `docs/RFC.md` | Questão adiada | Restringir o CRUD por role | TRANSCRICAO | [09:37] Sofia |
| RFC-ABE-07 | `docs/RFC.md` | Lacuna | Secret usada na assinatura durante as 24 horas de rotação | TRANSCRICAO | [09:21] Sofia |
| RFC-ABE-08 | `docs/RFC.md` | Lacuna | Replay da DLQ mantém ou não o `event_id` | TRANSCRICAO | [09:18] Diego; [09:25] Diego |
| RFC-IMP-01 | `docs/RFC.md` | Impacto | Tabela de outbox cresce sem limpeza nesta fase | TRANSCRICAO | [09:08] Diego |
| RFC-IMP-02 | `docs/RFC.md` | Impacto | Clientes precisam deduplicar e validar a assinatura, com apoio do portal | TRANSCRICAO | [09:26] Marcos; [09:40] Marcos |
| RFC-RISCO-01 | `docs/RFC.md` | Risco | Falha na outbox derruba a mudança de status (comportamento escolhido) | TRANSCRICAO | [09:40] Bruno; [09:46] Larissa |
| RFC-RISCO-02 | `docs/RFC.md` | Risco | Ordem trocada com um segundo worker | TRANSCRICAO | [09:12] Diego; [09:13] Diego |
| RFC-RISCO-03 | `docs/RFC.md` | Risco | Tabelas da feature crescem sem limpeza nesta fase | TRANSCRICAO | [09:08] Diego |
| RFC-PRAZO-01 | `docs/RFC.md` | Estimativa | Três sprints, com a revisão de segurança no fim | TRANSCRICAO | [09:46] Larissa; [09:47] Larissa |
| ADR-001 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Decisão | Outbox no MySQL, gravada na mesma transação do `changeStatus` | TRANSCRICAO | [09:06] Diego; [09:08] Larissa |
| ADR-001-DEC-02 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Decisão | Falha na inserção da outbox desfaz a transação inteira | TRANSCRICAO | [09:40] Bruno; [09:41] Diego |
| ADR-001-DEC-03 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Decisão | Filtro de status aplicado na inserção da outbox | TRANSCRICAO | [09:34] Bruno; [09:34] Diego |
| ADR-001-DEC-04 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Decisão | Payload gravado pronto, como retrato do pedido | TRANSCRICAO | [09:52] Larissa; [09:52] Diego; [09:52] Bruno |
| ADR-001-ALT-01 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Alternativa descartada | Envio síncrono dentro do `changeStatus` | TRANSCRICAO | [09:04] Bruno; [09:06] Diego |
| ADR-001-ALT-02 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Alternativa descartada | Redis Streams | TRANSCRICAO | [09:07] Larissa; [09:07] Diego |
| ADR-001-COD-01 | `docs/adrs/ADR-001-outbox-no-mysql.md` | Restrição | Estoque só muda em PENDING → PAID e no cancelamento a partir de PAID ou PROCESSING | CODIGO | `src/modules/orders/order.status.ts` |
| ADR-002 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Decisão | Worker em processo separado, polling a cada 2 segundos | TRANSCRICAO | [09:09] Diego; [09:10] Larissa; [09:11] Diego |
| ADR-002-DEC-02 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Decisão | Instância própria do PrismaClient no mesmo banco | TRANSCRICAO | [09:11] Bruno; [09:30] Bruno |
| ADR-002-DEC-03 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Limitação aceita | Um único worker; ordem só por pedido | TRANSCRICAO | [09:12] Diego; [09:13] Larissa |
| ADR-002-ALT-01 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Alternativa descartada | Trigger no banco | TRANSCRICAO | [09:09] Bruno; [09:09] Diego |
| ADR-002-ALT-02 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Alternativa descartada | Worker dentro do processo da API | TRANSCRICAO | [09:11] Diego |
| ADR-002-ALT-03 | `docs/adrs/ADR-002-worker-separado-em-polling.md` | Alternativa adiada | Vários workers em paralelo | TRANSCRICAO | [09:12] Diego; [09:13] Diego |
| ADR-003 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Decisão | Backoff 1m/5m/30m/2h/12h e DLQ em tabela separada | TRANSCRICAO | [09:17] Diego; [09:17] Larissa; [09:18] Diego |
| ADR-003-DEC-02 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Interpretação | "5 tentativas" lidas como envio original mais 5 retentativas | TRANSCRICAO | [09:17] Diego; [09:48] Larissa |
| ADR-003-DEC-03 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Decisão | Replay manual por endpoint admin, com role ADMIN e registro de quem fez | TRANSCRICAO | [09:18] Diego; [09:36] Sofia; [09:36] Larissa |
| ADR-003-ALT-01 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Alternativa descartada | Retry sem limite | TRANSCRICAO | [09:15] Diego |
| ADR-003-ALT-02 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Alternativa descartada | 3 tentativas | TRANSCRICAO | [09:16] Bruno; [09:16] Diego |
| ADR-003-ALT-03 | `docs/adrs/ADR-003-retry-com-backoff-e-dlq.md` | Alternativa descartada | Marcar "failed" na própria outbox | TRANSCRICAO | [09:17] Larissa; [09:18] Diego |
| ADR-004 | `docs/adrs/ADR-004-hmac-sha256-com-secret-por-endpoint.md` | Decisão | HMAC-SHA256 sobre o corpo, no header `X-Signature` | TRANSCRICAO | [09:20] Sofia; [09:22] Sofia |
| ADR-004-DEC-02 | `docs/adrs/ADR-004-hmac-sha256-com-secret-por-endpoint.md` | Decisão | Secret por endpoint, gerada pela plataforma, rotacionável com 24 horas de convivência | TRANSCRICAO | [09:21] Sofia; [09:31] Marcos |
| ADR-004-ALT-01 | `docs/adrs/ADR-004-hmac-sha256-com-secret-por-endpoint.md` | Alternativa descartada | Secret global | TRANSCRICAO | [09:21] Sofia |
| ADR-005 | `docs/adrs/ADR-005-at-least-once-com-x-event-id.md` | Decisão | At-least-once com UUID no `X-Event-Id` para deduplicação pelo cliente | TRANSCRICAO | [09:24] Diego; [09:25] Diego; [09:26] Larissa |
| ADR-005-DEC-02 | `docs/adrs/ADR-005-at-least-once-com-x-event-id.md` | Decisão | Header `X-Webhook-Id` com o id do endpoint | TRANSCRICAO | [09:44] Sofia; [09:45] Diego |
| ADR-005-ALT-01 | `docs/adrs/ADR-005-at-least-once-com-x-event-id.md` | Alternativa descartada | Exactly-once | TRANSCRICAO | [09:25] Diego |
| ADR-006 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Decisão | Módulo de webhooks com os padrões do projeto e códigos `WEBHOOK_` | TRANSCRICAO | [09:27] Bruno; [09:29] Larissa; [09:30] Larissa |
| ADR-006-ALT-01 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Alternativa descartada | Injetar o repository do webhook no `OrderService` | TRANSCRICAO | [09:41] Bruno; [09:41] Diego |
| ADR-006-ALT-02 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Alternativa descartada | Worker compartilhando o PrismaClient da API | TRANSCRICAO | [09:29] Diego; [09:30] Bruno |
| ADR-006-ALT-03 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Alternativa plausível | Módulo com soluções próprias de erro, log e estrutura | TRANSCRICAO | [09:29] Bruno; [09:30] Larissa |
| ADR-006-COD-01 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Padrão existente | Classes de erro e códigos como `INVALID_STATUS_TRANSITION` e `INSUFFICIENT_STOCK` | CODIGO | `src/shared/errors/http-errors.ts` |
| ADR-006-COD-02 | `docs/adrs/ADR-006-reuso-dos-padroes-do-projeto.md` | Padrão existente | `requireRole('ADMIN')` já usado numa rota | CODIGO | `src/modules/users/user.routes.ts` |
| FDD-FLUXO-01 | `docs/FDD.md` | Fluxo | Criação do evento na outbox via `publishWebhookEvent(tx, ...)` | TRANSCRICAO | [09:40] Bruno; [09:41] Bruno |
| FDD-FLUXO-02 | `docs/FDD.md` | Fluxo | Worker lê pendentes mais antigos em lote pequeno a cada 2 segundos | TRANSCRICAO | [09:08] Diego; [09:09] Diego |
| FDD-FLUXO-03 | `docs/FDD.md` | Fluxo | Retry com intervalos e tempo acumulado de 14h36 | TRANSCRICAO | [09:17] Diego |
| FDD-FLUXO-04 | `docs/FDD.md` | Fluxo | Ida para a DLQ e replay recolocando o evento como pendente | TRANSCRICAO | [09:18] Diego |
| FDD-FLUXO-05 | `docs/FDD.md` | Fluxo | Rotação de secret com a anterior válida por 24 horas | TRANSCRICAO | [09:21] Sofia |
| FDD-DADOS-01 | `docs/FDD.md` | Proposta | Tabela `webhook_endpoints` com url, secret, customer, status e ativo | TRANSCRICAO | [09:21] Bruno; [09:21] Sofia; [09:31] Marcos |
| FDD-DADOS-02 | `docs/FDD.md` | Decisão | Tabela `webhook_outbox` com status pendente, processando, falhou, entregue e índices em status e `created_at` | TRANSCRICAO | [09:06] Diego; [09:08] Diego |
| FDD-DADOS-03 | `docs/FDD.md` | Decisão | Tabela `webhook_dead_letter` com payload, motivo e horário | TRANSCRICAO | [09:18] Diego |
| FDD-DADOS-04 | `docs/FDD.md` | Proposta | Tabela `webhook_deliveries` para o histórico de entregas | TRANSCRICAO | [09:34] Marcos |
| FDD-DADOS-05 | `docs/FDD.md` | Proposta | Uma linha da outbox por endpoint, cada uma com seu `event_id` | TRANSCRICAO | [09:25] Diego |
| FDD-DADOS-06 | `docs/FDD.md` | Decisão | Ids em UUID | TRANSCRICAO | [09:51] Larissa |
| FDD-CONTRATO-01 | `docs/FDD.md` | Contrato | `POST /api/v1/webhooks` cadastra e devolve a secret uma vez | TRANSCRICAO | [09:31] Marcos |
| FDD-CONTRATO-02 | `docs/FDD.md` | Contrato | `GET /api/v1/webhooks?customerId=` lista os webhooks; query segue o padrão de orders, com body ou path em aberto (RFC-ABE-03) | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-03 | `docs/FDD.md` | Contrato | `PATCH /api/v1/webhooks/:id` edita url, status e ativo | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-04 | `docs/FDD.md` | Contrato | `DELETE /api/v1/webhooks/:id` remove | TRANSCRICAO | [09:33] Bruno |
| FDD-CONTRATO-05 | `docs/FDD.md` | Proposta | `POST /api/v1/webhooks/:id/rotate-secret` (path proposto) | TRANSCRICAO | [09:21] Sofia |
| FDD-CONTRATO-06 | `docs/FDD.md` | Contrato | `GET /api/v1/webhooks/:id/deliveries` com as últimas 100 entregas | TRANSCRICAO | [09:34] Marcos |
| FDD-CONTRATO-07 | `docs/FDD.md` | Contrato | `POST /api/v1/admin/webhooks/dead-letter/:id/replay` com role ADMIN | TRANSCRICAO | [09:18] Diego; [09:36] Sofia |
| FDD-CONTRATO-08 | `docs/FDD.md` | Contrato | Chamada de saída com headers `X-Event-Id`, `X-Webhook-Id`, `X-Timestamp`, `X-Signature` e payload em snake_case | TRANSCRICAO | [09:43] Diego; [09:44] Diego; [09:44] Sofia |
| FDD-CONTRATO-09 | `docs/FDD.md` | Padrão existente | Todas as rotas da API montadas sob `/api/v1` | CODIGO | `src/app.ts` |
| FDD-ERRO-01 | `docs/FDD.md` | Erro | `WEBHOOK_NOT_FOUND` (404) | TRANSCRICAO | [09:28] Bruno |
| FDD-ERRO-02 | `docs/FDD.md` | Proposta (código de erro) | `WEBHOOK_DEAD_LETTER_NOT_FOUND` (404) no replay | TRANSCRICAO | [09:18] Diego |
| FDD-ERRO-03 | `docs/FDD.md` | Erro | `WEBHOOK_INVALID_URL` (400), mecanismo pendente | TRANSCRICAO | [09:23] Sofia; [09:28] Bruno |
| FDD-ERRO-04 | `docs/FDD.md` | Proposta (código de erro) | `WEBHOOK_PAYLOAD_TOO_LARGE` para evento acima de 64KB | TRANSCRICAO | [09:24] Diego; [09:24] Larissa |
| FDD-ERRO-05 | `docs/FDD.md` | Erro | `WEBHOOK_SECRET_REQUIRED`, sem cenário definido | TRANSCRICAO | [09:28] Bruno |
| FDD-ERRO-06 | `docs/FDD.md` | Proposta (código de erro) | `WEBHOOK_DELIVERY_TIMEOUT` quando passa de 10 segundos | TRANSCRICAO | [09:42] Diego |
| FDD-ERRO-07 | `docs/FDD.md` | Proposta (código de erro) | `WEBHOOK_DELIVERY_FAILED` em erro de rede ou resposta de falha | TRANSCRICAO | [09:15] Diego |
| FDD-ERRO-08 | `docs/FDD.md` | Proposta (código de erro) | `WEBHOOK_MAX_ATTEMPTS_EXCEEDED` ao ir para a DLQ | TRANSCRICAO | [09:15] Diego; [09:18] Diego |
| FDD-ERRO-09 | `docs/FDD.md` | Padrão existente | Erros reaproveitados: `VALIDATION_ERROR`, `UNAUTHORIZED`, `FORBIDDEN`, `NOT_FOUND` | CODIGO | `src/shared/errors/http-errors.ts` |
| FDD-RES-01 | `docs/FDD.md` | Resiliência | Timeout de 10 segundos por chamada | TRANSCRICAO | [09:42] Diego |
| FDD-RES-02 | `docs/FDD.md` | Resiliência | Isolamento de processo entre API e worker | TRANSCRICAO | [09:11] Diego |
| FDD-RES-03 | `docs/FDD.md` | Resiliência | Fallback para a DLQ com replay manual; sem fallback automático por e-mail | TRANSCRICAO | [09:18] Diego; [09:37] Larissa |
| FDD-RES-04 | `docs/FDD.md` | Proposta | Retry, ida para a DLQ e replay em transações curtas | TRANSCRICAO | [09:18] Diego |
| FDD-OBS-01 | `docs/FDD.md` | Métrica | Entregas com sucesso e com falha | TRANSCRICAO | [09:34] Marcos |
| FDD-OBS-02 | `docs/FDD.md` | Métrica | Tempo de resposta do cliente | TRANSCRICAO | [09:34] Marcos; [09:42] Diego |
| FDD-OBS-03 | `docs/FDD.md` | Métrica | Número de retentativas | TRANSCRICAO | [09:15] Diego |
| FDD-OBS-04 | `docs/FDD.md` | Métrica | Tamanho da DLQ | TRANSCRICAO | [09:18] Diego |
| FDD-OBS-05 | `docs/FDD.md` | Métrica | Idade do evento pendente mais antigo comparada à meta de 10 segundos | TRANSCRICAO | [09:02] Marcos |
| FDD-OBS-06 | `docs/FDD.md` | Log | Log de auditoria do replay com o `userId` | TRANSCRICAO | [09:36] Sofia |
| FDD-OBS-07 | `docs/FDD.md` | Proposta (log) | `secret` e `previousSecret` na lista `redact` do logger | TRANSCRICAO | [09:22] Diego |
| FDD-OBS-08 | `docs/FDD.md` | Tracing | Correlação por `requestId`, `orderId` e `eventId` nos logs | CODIGO | `src/middlewares/request-logger.middleware.ts` |
| FDD-INT-01 | `docs/FDD.md` | Integração | `changeStatus` chama `publishWebhookEvent(tx, ...)` dentro do `$transaction` | CODIGO | `src/modules/orders/order.service.ts` |
| FDD-INT-02 | `docs/FDD.md` | Integração | Enum `OrderStatus` e transições definem os status válidos | CODIGO | `src/modules/orders/order.status.ts` |
| FDD-INT-03 | `docs/FDD.md` | Integração | Quatro models novos com ids UUID `@db.Char(36)` | CODIGO | `prisma/schema.prisma` |
| FDD-INT-04 | `docs/FDD.md` | Integração | Classes `WEBHOOK_*` no molde de `InvalidStatusTransitionError` | CODIGO | `src/shared/errors/http-errors.ts` |
| FDD-INT-05 | `docs/FDD.md` | Integração | `errorMiddleware` sem mudança | CODIGO | `src/middlewares/error.middleware.ts` |
| FDD-INT-06 | `docs/FDD.md` | Integração | `authenticate` e `requireRole('ADMIN')` nas rotas novas | CODIGO | `src/middlewares/auth.middleware.ts` |
| FDD-INT-07 | `docs/FDD.md` | Integração | `validate` com os schemas do módulo | CODIGO | `src/middlewares/validate.middleware.ts` |
| FDD-INT-08 | `docs/FDD.md` | Integração | `buildControllers` monta o controller do webhook | CODIGO | `src/app.ts` |
| FDD-INT-09 | `docs/FDD.md` | Integração | `buildApiRouter` registra `/webhooks` e `/admin/webhooks` | CODIGO | `src/routes/index.ts` |
| FDD-INT-10 | `docs/FDD.md` | Integração | Logger Pino na API e no worker, com `redact` estendido | CODIGO | `src/shared/logger/index.ts` |
| FDD-INT-11 | `docs/FDD.md` | Integração | `paginated()` na listagem de webhooks | CODIGO | `src/shared/http/response.ts` |
| FDD-INT-12 | `docs/FDD.md` | Integração | Worker cria o próprio PrismaClient com `createPrismaClient()` | CODIGO | `src/config/database.ts` |
| FDD-INT-13 | `docs/FDD.md` | Integração | Worker carrega o mesmo env | CODIGO | `src/config/env.ts` |
| FDD-INT-14 | `docs/FDD.md` | Integração | `src/server.ts` como modelo de bootstrap e shutdown do worker | CODIGO | `src/server.ts` |
| FDD-INT-15 | `docs/FDD.md` | Integração | Script `worker` no molde de `dev` e `start` | CODIGO | `package.json` |
| FDD-INT-16 | `docs/FDD.md` | Integração | Testes de integração no padrão Supertest em `/api/v1` | CODIGO | `tests/orders.test.ts` |
| FDD-INT-17 | `docs/FDD.md` | Integração | `beforeEach` precisa limpar as tabelas novas | CODIGO | `tests/setup.ts` |
| FDD-DEP-01 | `docs/FDD.md` | Dependência | Node.js >= 20, sem biblioteca nova | CODIGO | `package.json` |
| FDD-DEP-02 | `docs/FDD.md` | Dependência | MySQL 8.0 | CODIGO | `docker-compose.yml` |
| FDD-PEND-01 | `docs/FDD.md` | Pendência | P-01: secret usada na assinatura durante a rotação | TRANSCRICAO | [09:21] Sofia |
| FDD-PEND-02 | `docs/FDD.md` | Pendência | P-02: replay mantém ou não o `event_id` | TRANSCRICAO | [09:18] Diego; [09:25] Diego |
| FDD-PEND-03 | `docs/FDD.md` | Pendência | P-03: https no Zod (`VALIDATION_ERROR`) ou no service (`WEBHOOK_INVALID_URL`) | TRANSCRICAO | [09:23] Sofia; [09:28] Bruno |
| FDD-PEND-04 | `docs/FDD.md` | Pendência | P-04: quando ocorre `WEBHOOK_SECRET_REQUIRED` | TRANSCRICAO | [09:28] Bruno; [09:31] Marcos |
| FDD-PEND-05 | `docs/FDD.md` | Pendência | P-05: onde o limite de 64KB é checado | TRANSCRICAO | [09:23] Sofia; [09:24] Larissa |
| FDD-PEND-06 | `docs/FDD.md` | Pendência | P-06: que resposta do cliente conta como sucesso | TRANSCRICAO | [09:42] Diego |
| FDD-PEND-07 | `docs/FDD.md` | Pendência | P-07: ordem por pedido quando há retentativa | TRANSCRICAO | [09:12] Diego; [09:13] Larissa |
| FDD-PEND-08 | `docs/FDD.md` | Pendência | P-08: codificação da assinatura e formato do `X-Timestamp` | TRANSCRICAO | [09:20] Sofia; [09:44] Diego |
| FDD-PEND-09 | `docs/FDD.md` | Pendência | P-09: eventos presos em `PROCESSING` | TRANSCRICAO | [09:08] Diego |
| FDD-PEND-10 | `docs/FDD.md` | Pendência | P-10: eventos pendentes de webhook removido; erro `P2003` não tratado | TRANSCRICAO | [09:33] Bruno |
| FDD-PEND-11 | `docs/FDD.md` | Pendência | P-11: tamanho do lote do worker | TRANSCRICAO | [09:08] Diego |

## Contagem e validação

Resultado de `bash work/validar-tracker.sh` sobre esta versão. O script confere que cada linha tem seis colunas e ID único, que cada documento citado existe, que toda fala `[hh:mm] Nome` existe na transcrição e que todo caminho `CODIGO` existe no repositório. Depois conta, direto nos documentos, os itens de cada categoria e compara com as linhas desta tabela.

| Indicador | Resultado | Exigido |
| --- | --- | --- |
| Linhas | 172 | — |
| Fonte `TRANSCRICAO` com `[hh:mm] Nome` válido | 147 (85,5%) | ≥ 70% |
| Fonte `CODIGO` com caminho real | 25 | ≥ 5 |
| Itens identificáveis com linha no tracker | 137 de 137 (100%) | ≥ 80% |

| Categoria | Itens no documento | Linhas no tracker |
| --- | --- | --- |
| PRD: requisitos funcionais | 14 | 14 |
| PRD: requisitos não funcionais | 10 | 10 |
| PRD: metas | 4 | 4 |
| PRD: fora de escopo | 8 | 8 |
| PRD: dependências | 6 | 6 |
| PRD: riscos | 5 | 5 |
| RFC: alternativas | 6 | 6 |
| RFC: questões em aberto | 8 | 8 |
| RFC: riscos de arquitetura | 3 | 3 |
| ADRs: decisões | 6 | 6 |
| ADRs: alternativas não escolhidas | 13 | 13 |
| FDD: contratos | 8 | 8 |
| FDD: códigos `WEBHOOK_` | 8 | 8 |
| FDD: fluxos | 5 | 5 |
| FDD: métricas | 5 | 5 |
| FDD: integração com o código | 17 | 17 |
| FDD: pendências | 11 | 11 |

Além dessas categorias, o tracker tem linhas para contexto, impactos, decisões secundárias dos ADRs, tabelas do modelo de dados, resiliência, logs, tracing e dependências técnicas.
