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

Formato: MADR adaptado, em português, sem blocos de código e no nível de decisão. Seções fixas: Status, Contexto, Decisão, Alternativas Consideradas, Consequências (positivas, negativas e uma linha de trade-off) e Referências, com metadados de data, decisores, origem na transcrição e relações (depende de / relacionado a).

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

Usei as seções do enunciado. O RFC é a discussão antes da decisão; o ADR é o registro depois. Como as decisões já estavam fechadas na reunião, o RFC ficou com status "Em revisão" e se apresenta como o documento de design que Larissa disse que ia abrir para Bruno e Diego revisarem ([09:50] Larissa).

Regra para não invadir o FDD: o RFC não tem payload, códigos de erro, status HTTP, modelagem de tabela nem métricas; cada bloco da proposta resume a decisão em duas ou três frases e aponta para o ADR.

Questões em aberto separadas em três grupos: não decididas na reunião (4), adiadas (2) e lacunas que apareceram ao escrever os ADRs (2), marcadas como não vindas da reunião.

Ajuste: a primeira versão dizia, na tabela de riscos, que "testes de integração no `changeStatus` cobrem o caminho", sem fonte. Troquei pelos testes ponta a ponta que Larissa colocou no plano ([09:46] Larissa).

Verificação por script: as 8 seções do enunciado; todos os timestamps existem; links para os 6 ADRs, PRD, FDD e Tracker funcionam; único caminho inexistente é `src/modules/webhooks/`, marcado como "(a criar)". Tamanho: cerca de 1.700 palavras, dentro de 2 a 4 páginas.

## E5 — FDD

Formato: as seções exigidas pelo enunciado e duas seções minhas, modelo de dados e pendências para a revisão. O esqueleto do documento funcionou como contrato de completude, preenchido com o inventário, o mapa do código, os ADRs e o RFC.

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

## E6 — PRD

Formato: as 12 seções do enunciado, mais um "fluxo de integração do cliente" dentro de público-alvo e cenários. Nível de produto: sem nomes de tabela, rotas ou códigos de erro; para o "como", o PRD aponta para o RFC, os ADRs e o FDD.

Prompt usado:

```text
Escreva o PRD consolidando ADRs, RFC e FDD no nível de produto. Use só fatos com
[hh:mm] Nome. Métricas: só números ditos na reunião. Fora de escopo: itens
descartados ou adiados, cada um com a fala. Riscos com probabilidade, impacto e
mitigação; como a reunião não dá probabilidade, escreva a justificativa de cada
nota a partir de uma fala e diga que a nota é avaliação do documento. Não decida
nenhuma pendência do FDD.
```

Metas numéricas, todas da reunião: menos de 10 segundos ([09:02] Marcos), 3 clientes ([09:00] Marcos), fim de novembro ([09:45] Marcos) e quase 15 horas de tentativas ([09:17] Diego).

Ajustes na revisão:

- A meta de prazo dizia "até o fim de novembro, dentro das três sprints estimadas", e o risco da Atlas dizia que "a estimativa cabe no prazo". Ninguém na reunião comparou as três sprints com a data. Reescrevi: a data é a pedida pela Atlas, a estimativa é de três sprints, e o que Marcos disse foi que a Atlas "vai gostar" ([09:47]).
- O critério de aceitação 6 dizia que "duas entregas do mesmo evento têm o mesmo identificador", o que já decidia a pendência P-02 (replay mantém ou não o `event_id`). Restringi às novas tentativas automáticas.

Verificação por script: 12 seções; 14 RFs; 10 RNFs; 8 itens fora de escopo; 5 riscos com probabilidade e impacto; todos os timestamps existem; links funcionam.

## E7 — Tracker

Montei o tracker no fim, varrendo os documentos prontos, com IDs no padrão do enunciado (`PRD-FR-01`, `RFC-ALT-02`, `FDD-CONTRATO-03`, `ADR-002`). O critério de "item identificável" ficou escrito no próprio tracker, por categoria de cada documento. Itens que os documentos propõem sem a reunião ter decidido (path de rotação, nomes de tabela, um código de erro) ficaram com Tipo "Proposta" e apontam para a fala que os motivou.

Para não contar à mão, escrevi `work/validar-tracker.sh`. Ele confere formato, IDs, existência de cada fala na transcrição e de cada caminho no repositório, e compara a quantidade de itens de cada categoria nos documentos com as linhas do tracker.

Prompt usado:

```text
Monte docs/TRACKER.md com a tabela exata do enunciado (ID | Documento | Tipo |
Conteúdo (resumo) | Fonte | Localização). Uma linha por item identificável de cada
documento, seguindo o critério que você vai declarar no topo do arquivo. Fonte só
TRANSCRICAO ou CODIGO. Item que o documento propôs sem a reunião decidir recebe Tipo
"Proposta" e aponta para a fala que o motivou. Depois escreva um script que valide
formato, falas, caminhos e cobertura, rode e cole o resultado no fim do tracker.
```

Ajustes na primeira rodada da validação:

- O script contava as alternativas dos ADRs junto com a opção escolhida (que alguns ADRs também listam em "Alternativas Consideradas") e somava as linhas de decisão às de alternativa. Corrigi para comparar só alternativas não escolhidas com as linhas `ADR-NNN-ALT-`.
- A linha `FDD-ERRO-09` apontava os erros reaproveitados para `validate.middleware.ts`, mas `UNAUTHORIZED`, `FORBIDDEN` e `NOT_FOUND` são definidos em `src/shared/errors/http-errors.ts`. Troquei o caminho.
- A linha `FDD-CONTRATO-09` misturava o prefixo `/api/v1` (de `src/app.ts`) com o formato de erro (de `error.middleware.ts`). Deixei só o que está no arquivo citado.

Resultado final: 174 linhas, 85,6% com fonte TRANSCRICAO, 25 com CODIGO, 139 de 139 itens das categorias contadas cobertos, nenhum erro.

Revisão do Tracker, segunda rodada: o script só confere se a fala existe, então listei cada linha ao lado do texto das falas citadas e li uma por uma.

- Três itens de "fora de escopo" estavam com o tipo errado. Rate limiting estava como "adiado", mas a reunião decidiu "observar e decidir depois", que é questão em aberto. O painel visual estava como "descartado", mas Larissa disse que é projeto do time de frontend. O arquivamento estava como "adiado", mas Diego disse "fora do escopo dessa feature".
- Cinco códigos de erro (`WEBHOOK_DEAD_LETTER_NOT_FOUND`, `WEBHOOK_PAYLOAD_TOO_LARGE`, `WEBHOOK_DELIVERY_TIMEOUT`, `WEBHOOK_DELIVERY_FAILED`, `WEBHOOK_MAX_ATTEMPTS_EXCEEDED`) estavam com tipo "Erro", como se a reunião tivesse dado esses nomes. A reunião só citou `WEBHOOK_NOT_FOUND`, `WEBHOOK_INVALID_URL` e `WEBHOOK_SECRET_REQUIRED`. Os outros cinco viraram "Proposta (código de erro)". O mesmo valeu para o `redact` do secret no logger.
- A listagem de webhooks com `customerId` na query não dizia que isso é escolha do FDD com a questão do body ou path ainda aberta. Acrescentei a referência à questão do RFC.
- Duas linhas ganharam a fala que faltava: a confirmação de Sofia sobre os campos da configuração ([09:21]) e a fala de Diego que levantou o risco de rajada ([09:38]).

## E8 — README

Substituí o enunciado pelo README do processo, nas seis seções pedidas, com link para o enunciado original no repositório base. Fonte de tudo: este log e as regras da sessão.

Prompts no README: o trecho do pedido de abertura e os prompts das etapas de ADRs, PRD e Tracker, copiados sem alteração deste log, porque foram eles que geraram os documentos.

Atualizei `docs/adrs/README.md`: o exemplo de nome passou para o formato `ADR-NNN-titulo-em-kebab-case.md`, que é o dos arquivos, e o arquivo ganhou um índice dos seis ADRs.

Revisão final: quatro menções a `src/worker.ts` e `src/modules/webhooks/` (no ADR-002 e no FDD) estavam sem a marca "(a criar)". Como o enunciado não aceita arquivo de código inexistente citado nos documentos, marquei todas.

Revisão de altura entre os documentos, depois da revisão final: os scripts contavam seções e fontes, mas não pegavam conteúdo repetido. Comparando os documentos, achei quatro problemas e corrigi:

- Riscos repetidos em PRD, RFC e FDD. Cada documento ficou com os da sua altura: PRD com os de produto e cliente, RFC com os de arquitetura (outbox bloqueando a mudança de status, ordem com um segundo worker, tabelas crescendo sem limpeza) e FDD com os de implementação. RFC e FDD apontam para os outros dois.
- Detalhe de código no PRD: a estratégia de testes citava as ferramentas e um arquivo de teste, e uma dependência citava um arquivo de `src/`. Ficou só o que será validado, com link para o FDD.
- As exclusões do FDD repetiam o fora de escopo do PRD. O FDD ficou só com as exclusões técnicas e um link para o PRD.
- O contexto do RFC recontava o problema de produto. Ficou uma frase com link para o PRD, e a proposta passou a citar o retry como "intervalos crescentes por cerca de 15 horas", deixando os números no ADR-003 e no FDD.

No tracker, saíram as três linhas de risco do RFC que deixaram de existir e entrou a de crescimento das tabelas. Resultado: 172 linhas, 85,5% com TRANSCRICAO, 25 com CODIGO, 137 de 137 itens cobertos.
