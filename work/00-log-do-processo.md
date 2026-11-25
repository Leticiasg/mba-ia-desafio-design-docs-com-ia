# Log do processo

Anotações para o README: ferramenta, prompts e o que precisou de correção em cada etapa.

Ferramenta: Claude Code (app desktop), com acesso ao repositório clonado.

## E0 — Setup

Fork público e clone feitos pelo `gh`. Combinados da sessão: nada em `src/`, `prisma/`, `tests/` e configurações; todo fato vem da transcrição ou do código; o que faltar é perguntado; commits e push ficam comigo.

## E1 — Inventário da transcrição

Prompt (pedido inicial da sessão, trecho):

```text
Todo fato nos documentos precisa vir da transcrição ou do código. Se faltar
alguma informação, me pergunte em vez de inventar.
```

Critérios aplicados na extração:

```text
Leia TRANSCRICAO.md inteira e monte um inventário por categoria: contexto,
decisões fechadas, requisitos funcionais, requisitos não funcionais e restrições,
ganchos com o código, descartados (com o motivo), adiados, em aberto e prazo.
Cada item precisa de [hh:mm] Nome da fala de origem; item sem fala não entra.
Quando uma pessoa propõe e outra fecha a decisão, cite as duas.
Adiado = decidido que fica para depois. Em aberto = ninguém decidiu.
No fim, liste as ambiguidades da transcrição em vez de escolher um lado.
```

Verificação: um script conferiu as 86 referências `[hh:mm] Nome` do inventário contra a transcrição; nenhuma inválida. Resultado: 21 decisões, 14 RFs, 9 RNFs, 14 ganchos com o código, 14 descartados, 5 adiados, 5 em aberto.

Ambiguidades encontradas e o que decidi:

- "5 tentativas" com 5 intervalos de backoff: são 5 ou 6 envios? Decidi por envio inicial + 5 retentativas (6 envios), porque é a única leitura que usa os 5 intervalos e fecha com as "quase 15 horas".
- Prazo citado como "fim do trimestre" ([09:00] Marcos) e "fim de novembro" ([09:45] Marcos). Decidi citar as duas: a primeira é o prazo da ameaça de migração da Atlas, a segunda é a data pedida.
- "Latência mínima de 2 segundos no pior caso" ([09:10] Larissa). Decidi registrar como "o polling acrescenta até 2s", dentro da meta de menos de 10s.

A IA listou as ambiguidades e não escolheu nenhum lado; a escolha foi minha.

## E2 — Mapa do código

Pedido: ler o código e listar os arquivos onde a feature encosta, conferindo cada gancho que a reunião cita (COD-01 a COD-14 do inventário) contra o arquivo real, com número de linha.

Verificação: um script rodou `ls` em todos os caminhos citados no mapa. Só `src/worker.ts` não existe, o que é esperado, porque é arquivo a criar.

Ajuste: a primeira versão do mapa dizia que o módulo `users` não tinha schemas em uso. Conferi e estava errado (`user.schemas.ts` é usado pelo `user.service.ts`). Corrigi antes de fechar.

Achados que vão para os documentos: rotas sob `/api/v1`; payload do webhook em snake_case enquanto a API responde em camelCase; nenhum vínculo entre `User` e `Customer`; nenhuma métrica ou tracing no código hoje; campo `secret` fora do `redact` do logger.

Lacunas de observabilidade: a IA apontou que nem a reunião nem o código têm métricas ou tracing, e o enunciado exige os dois no FDD. Decidi usar só métricas com fonte na transcrição, tracing por correlação de `X-Request-Id` e `event_id` nos logs (sem escolher ferramenta) e propor o `secret` no `redact` do logger.

## E3 — ADRs

Formato: MADR adaptado do material do curso (aulas 02 a 05 e 11 do módulo de ADR), em português, sem blocos de código e no nível de decisão. Seções fixas: Status, Contexto, Decisão, Alternativas Consideradas, Consequências (positivas, negativas e uma linha de trade-off) e Referências, com metadados de data, decisores, origem na transcrição e relações (depende de / relacionado a).

Prompt usado:

```text
Escreva os 6 ADRs (outbox no MySQL, worker separado em polling, retry com backoff e
DLQ, HMAC-SHA256 com secret por endpoint, at-least-once com X-Event-Id, reuso dos
padrões do projeto) usando só o inventário (work/01) e o mapa do código (work/02).
Cada afirmação leva [hh:mm] Nome ou um caminho real. Alternativas: só as discutidas
na reunião; se precisar de uma plausível, marque como plausível. Consequências
negativas são obrigatórias. Arquivo que ainda não existe aparece como "(a criar)".
Quando a reunião não decidir algo que a decisão precisa, escreva que não foi
decidido em vez de completar.
```

Verificação por script: 6 arquivos no padrão `ADR-NNN-titulo-em-kebab-case.md`; as cinco seções obrigatórias em todos; todos os timestamps existem na transcrição; links entre ADRs funcionam; caminhos de código existem, exceto `src/worker.ts` e `src/modules/webhooks/`, marcados como "(a criar)".

Ajustes feitos na revisão:

- O ADR-006 dizia que erros, logs e validação "já têm testes". Não há teste específico para eles (`tests/` só tem auth e orders), então troquei por "já estão em uso nos outros módulos".
- O ADR-006 citava `src/modules/<domínio>`, que não é um caminho real. Reescrevi para não parecer arquivo inexistente.

Lacunas que os ADRs deixaram registradas como "não decidido": com qual secret a plataforma assina durante as 24h de rotação (ADR-004) e se o replay da DLQ mantém o `event_id` original (ADR-005).

Revisão dos ADRs, segunda rodada (pedi uma releitura de cada ADR contra as falas citadas):

- O ADR-001 atribuía a Bruno ([09:04]) a regra de que o estoque só muda em PENDING → PAID e no cancelamento. Bruno disse apenas que a transação "decrementa stock_quantity"; a regra das transições vem de `src/modules/orders/order.status.ts`. Separei a fala da reunião do que o código mostra.
- Os fatores de decisão do ADR-001 estavam sem fonte. Coloquei o timestamp em cada um.
- O payload gravado pronto estava como consequência negativa no ADR-001, mas Larissa o escolheu justamente por isso ([09:52]). Passou para as positivas.
- O ADR-002 listava quatro decisores e os outros, cinco. Sofia estava na call nesse trecho; incluí.
- A função `publishWebhookEvent` aparecia com o mesmo peso no ADR-001 e no ADR-006. Deixei o ADR-006 apontando para o ADR-001 em vez de repetir o raciocínio.

## E4 — RFC

O material do curso não traz um template de RFC, só a diferença entre RFC (discussão antes da decisão) e ADR (registro depois). Usei as seções do enunciado. Como as decisões já estavam fechadas na reunião, o RFC ficou com status "Em revisão" e se apresenta como o documento de design que Larissa disse que ia abrir para Bruno e Diego revisarem ([09:50] Larissa).

Regra para não invadir o FDD: o RFC não tem payload, códigos de erro, status HTTP, modelagem de tabela nem métricas; cada bloco da proposta resume a decisão em duas ou três frases e aponta para o ADR.

Questões em aberto separadas em três grupos: não decididas na reunião (4), adiadas (2) e lacunas que apareceram ao escrever os ADRs (2), marcadas como não vindas da reunião.

Ajuste: a primeira versão dizia, na tabela de riscos, que "testes de integração no `changeStatus` cobrem o caminho", sem fonte. Troquei pelos testes ponta a ponta que Larissa colocou no plano ([09:46] Larissa).

Verificação por script: as 8 seções do enunciado; todos os timestamps existem; links para os 6 ADRs, PRD, FDD e Tracker funcionam; único caminho inexistente é `src/modules/webhooks/`, marcado como "(a criar)". Tamanho: cerca de 1.700 palavras, dentro de 2 a 4 páginas.

## E5 — FDD

Formato: as 10 seções da aula de FDD do curso (06-feature-design-doc.md), mais as exigidas pelo enunciado (matriz de erros, resiliência, "Integração com o sistema existente") e duas seções minhas: modelo de dados e pendências para a revisão. Segui a dica da aula 08: usar o esqueleto como contrato de completude e preencher com o inventário, o mapa do código, os ADRs e o RFC.

Antes de escrever, a IA apontou quatro pontos em que a transcrição e o código não fecham. Decidi deixar todos como pendência, sem escolher lado:

- https "no schema Zod" ([09:23] Sofia) × código `WEBHOOK_INVALID_URL` ([09:28] Bruno): o `validate.middleware.ts` transforma todo erro de Zod em `VALIDATION_ERROR`, então as duas coisas não acontecem juntas;
- `WEBHOOK_SECRET_REQUIRED` foi citado, mas a secret é gerada pela plataforma, então não há quando ocorrer;
- limite de 64KB: a reunião não disse onde o erro acontece, e na inserção ele desfaria a mudança de status;
- o que conta como falha de entrega além do timeout.

Ao escrever os fluxos apareceram mais cinco lacunas, também registradas como pendência (P-07 a P-11): ordem por pedido quando há retentativa, codificação da assinatura e formato do `X-Timestamp`, eventos presos em `PROCESSING`, eventos de webhook removido e tamanho do lote.

Onde a reunião não fixou um nome (tabelas além de `webhook_outbox` e `webhook_dead_letter`, colunas, path de rotação de secret), o FDD propõe e marca como proposta. O `customerId` no body da criação e na query da listagem segue o padrão de `src/modules/orders/order.schemas.ts`, com a ressalva de que a reunião deixou body ou path em aberto.

Ajustes na revisão:

- A primeira versão colocava `requestId` no log `webhook_event_enqueued`, mas a função `publishWebhookEvent(tx, order, fromStatus, toStatus)` decidida na reunião não recebe esse valor. Reescrevi o tracing: a ligação com a requisição é feita pelo `orderId`, que aparece no path logado pelo `request-logger.middleware.ts`.
- A linha de "atomicidade" na tabela de resiliência citava [09:18] Diego como se ele tivesse dito aquilo. Marquei como proposta do FDD derivada da DLQ em tabela separada.

Verificação por script: as 12 seções obrigatórias; 8 contratos com request em bloco `http` (7 da API + a chamada de saída), 6 com response JSON e o DELETE com `204` sem corpo; 8 códigos `WEBHOOK_*`; todos os timestamps existem; 22 caminhos reais na seção de integração; só `src/worker.ts` e `src/modules/webhooks/` não existem, ambos marcados como "a criar".

Revisão do FDD, segunda rodada:

- O modelo dizia que cada endpoint gera sua própria linha na outbox, citando Marcos e Sofia como se tivessem decidido isso. A reunião só diz que o UUID nasce na entrada da outbox e é único por evento ([09:25] Diego). Marquei como proposta do FDD.
- O endpoint 6 devolvia o payload de cada entrega, mas a tabela `webhook_deliveries` não tinha esse campo. Expliquei que o payload vem da outbox pelo `eventId`.
- O endpoint 1 dizia que url fora de https dá `VALIDATION_ERROR`, o que já escolhia um lado da pendência P-03. Agora cita os dois códigos possíveis; o endpoint 3 (PATCH) passou a mencionar a mesma regra.
- "Fetch nativo, sem dependência nova" estava escrito como fato. Marquei como proposta, apoiada no "não vamos botar nada novo" ([09:29] Bruno).
- Achado novo na P-10: se a FK da outbox bloquear o DELETE do webhook, o Prisma lança `P2003`, que o `errorMiddleware` não trata (só `P2002` e `P2025`) e viraria erro 500.
