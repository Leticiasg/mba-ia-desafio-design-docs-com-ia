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
