# Webhooks de Notificação de Pedidos: da reunião aos design docs

Entrega do desafio "Da Reunião ao Documento: Design Docs Gerados por IA". O enunciado original está no [README do repositório base](https://github.com/devfullcycle/mba-ia-desafio-design-docs-com-ia/blob/main/README.md).

## Sobre o desafio

O ponto de partida era a transcrição de uma reunião de 55 minutos (`TRANSCRICAO.md`) em que a tech lead, o PM, dois engenheiros e a engenheira de segurança decidem como um Order Management System (OMS) em produção vai avisar clientes B2B quando o status de um pedido muda. Minha tarefa foi transformar a conversa e o código do OMS num pacote de documentação que um time conseguisse usar para começar a implementar PRD, RFC, FDD, seis ADRs e um tracker que liga cada item à fala ou ao arquivo de onde veio.

A parte difícil foi filtrar o que poderia ser considerado. A reunião descarta ideias (envio síncrono, Redis, secret global), adia outras (aviso por e-mail, painel visual) e deixa coisas sem decisão (rate limiting, escala com vários workers). Em alguns pontos a fala e o código nem concordam entre si. Usei a IA para ler tudo e montar os documentos, e passei a maior parte do tempo decidindo o que entrava, conferindo fontes e corrigindo o que ela escreveu com mais certeza do que a reunião tinha.

## Ferramentas de IA utilizadas

- **Claude Code (app desktop), com o modelo Claude Opus 5.5.** Foi a ferramenta principal. Rodou com acesso ao repositório clonado: leu a transcrição e o código em `src/`, `prisma/` e `tests/` e escreveu os documentos. Também rodou os comandos de conferência (existência de arquivos, timestamps, `git diff` para garantir que o código não mudou).
- **Script de validação escrito com a IA** (`work/validar-tracker.sh`). Não é uma ferramenta de IA, mas foi gerado por ela a meu pedido: confere o formato do tracker, se cada `[hh:mm] Nome` existe na transcrição, se cada caminho de código existe e quanto de cada documento está coberto.

O fork e o clone foram feitos com o `gh` (GitHub CLI), sem IA.

## Workflow adotado

Segui a ordem sugerida no enunciado, com duas etapas de preparação antes dos documentos.

1. **Regras da sessão.** Antes de qualquer documento instruí a IA para não tocar em `src/`, `prisma/`, `tests/` e configurações, que todo fato deveria vir da transcrição ou do código, que se faltar informação ela pergunta em vez de inventar e os commits são minha responsabilidade para que cada etapa seja verificada. Também pedi um checklist com os critérios de aceite de cada documento, que usei até a revisão final.
2. **Inventário da transcrição** (`work/01-inventario-transcricao.md`). Extração por categoria (decisões, requisitos, descartados, adiados, em aberto, prazo), cada item com `[hh:mm] Nome`. Um script conferiu as 86 referências contra a transcrição.
3. **Mapa do código** (`work/02-mapa-do-codigo.md`). Os arquivos onde a feature cobre, com número de linha, e a conferência de cada coisa que a reunião diz sobre o código.
4. **ADRs → RFC → FDD → PRD → Tracker → README**, um por vez, cada um com o esqueleto de seções definido no enunciado. Depois de cada documento, a IA conferia timestamps, caminhos e seções por script e revisava o texto. Nos ADRs, no FDD e no tracker eu pedi uma segunda rodada, lendo cada afirmação ao lado da fala citada. Após minha validação manual, então eu commitava.
5. **Log do processo** (`work/00-log-do-processo.md`). A cada etapa a IA registrava o que foi feito, o prompt e o que eu corrigi. Foi daqui que saiu este README.

Em vários momentos a IA parou e me perguntou em vez de seguir. Quase sempre eram pontos em que a transcrição era ambígua ou não fechava com o código. Na maioria deles escolhi registrar a dúvida como pendência nos documentos em vez de decidir por conta própria, porque decidir seria inventar uma decisão que o time não tomou.

## Prompts customizados

Os prompts abaixo são os que geraram os documentos, copiados sem alteração do log do processo ([`work/00-log-do-processo.md`](work/00-log-do-processo.md)), onde cada um aparece na etapa em que foi usado.

Regra do pedido inicial da sessão, que valeu para todas as etapas:

```text
Todo fato nos documentos precisa vir da transcrição ou do código. Se faltar
alguma informação, me pergunte em vez de inventar.
```

ADRs:

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

PRD:

```text
Escreva o PRD consolidando ADRs, RFC e FDD no nível de produto. Use só fatos com
[hh:mm] Nome. Métricas: só números ditos na reunião. Fora de escopo: itens
descartados ou adiados, cada um com a fala. Riscos com probabilidade, impacto e
mitigação; como a reunião não dá probabilidade, escreva a justificativa de cada
nota a partir de uma fala e diga que a nota é avaliação do documento. Não decida
nenhuma pendência do FDD.
```

Tracker:

```text
Monte docs/TRACKER.md com a tabela exata do enunciado (ID | Documento | Tipo |
Conteúdo (resumo) | Fonte | Localização). Uma linha por item identificável de cada
documento, seguindo o critério que você vai declarar no topo do arquivo. Fonte só
TRANSCRICAO ou CODIGO. Item que o documento propôs sem a reunião decidir recebe Tipo
"Proposta" e aponta para a fala que o motivou. Depois escreva um script que valide
formato, falas, caminhos e cobertura, rode e cole o resultado no fim do tracker.
```

## Iterações e ajustes

Contei quatro iterações principais, em que uma revisão mudou o conteúdo de verdade, além de ajustes menores em cada etapa. Os momentos em que a IA errou, foi rasa ou escreveu com mais certeza do que a fonte permitia:

1. **Ambiguidades da transcrição.** A reunião fala em "5 tentativas" e lista cinco intervalos de espera "entre primeira falha e última tentativa", o que dá seis envios. Também cita o prazo como "fim do trimestre" e "fim de novembro", e diz "latência mínima de 2 segundos no pior caso". A IA listou as três dúvidas sem escolher lado e eu decidi: envio original mais 5 retentativas, as duas datas citadas cada uma no seu papel, e "o polling acrescenta até 2 segundos".
2. **Fala atribuída errado (ADRs, segunda rodada).** O ADR-001 dizia que o Bruno explicou que o estoque só muda em PENDING → PAID e no cancelamento, mas ele disse só que a transação "decrementa stock_quantity", enquanto quem mostra a regra é `src/modules/orders/order.status.ts`. Na mesma rodada, uma consequência positiva estava listada como negativa e os fatores de decisão estavam sem fonte.
3. **Pontos que a reunião não deixa claro (FDD).** Antes de escrever o FDD, a IA achou quatro conflitos. O mais claro: a Sofia diz que a regra de https fica "no schema Zod", o Bruno cita o código `WEBHOOK_INVALID_URL`, e no código atual todo erro de Zod vira `VALIDATION_ERROR`, então as duas coisas não acontecem juntas. Decidi não escolher lado em nenhum deles. O FDD terminou com onze pendências (P-01 a P-11) para a revisão do time. Na segunda rodada, a IA tinha colocado `requestId` num log dentro de uma função que, pela assinatura decidida na reunião, não recebe esse valor.
4. **Afirmações sem fonte (RFC e PRD).** O RFC dizia que "testes de integração cobrem o caminho" e o PRD dizia que as três sprints "cabem no prazo" de novembro. Ninguém na reunião disse nenhuma das duas coisas. Troquei pelo que foi dito: testes ponta a ponta no plano da Larissa e "a Atlas vai gostar", do Marcos.

O detalhe de cada rodada, com antes e depois, está em `work/00-log-do-processo.md`.

## Como navegar a entrega

| Arquivo | O que tem |
| --- | --- |
| [`docs/PRD.md`](docs/PRD.md) | Problema, público, metas, escopo, requisitos e riscos, no nível de produto |
| [`docs/RFC.md`](docs/RFC.md) | Proposta técnica para revisão: abordagem, alternativas descartadas e questões em aberto |
| [`docs/adrs/`](docs/adrs/) | Seis ADRs, um por decisão (outbox, worker, retry e DLQ, HMAC, at-least-once, reuso de padrões) |
| [`docs/FDD.md`](docs/FDD.md) | Como construir: modelo de dados, fluxos, contratos, erros, observabilidade, integração com o código e pendências |
| [`docs/TRACKER.md`](docs/TRACKER.md) | Origem de cada item, com a contagem de cobertura no fim |
| [`work/`](work/) | Rascunhos do processo: log, inventário da transcrição, mapa do código e o script que valida o tracker |
| [`TRANSCRICAO.md`](TRANSCRICAO.md) | A reunião original, sem alteração |

Ordem de leitura sugerida: PRD para entender o porquê, RFC para a visão da solução, os ADRs para o motivo de cada decisão, o FDD para o detalhe de implementação e o tracker para conferir a origem de qualquer item. Para revalidar o tracker depois de alguma mudança:

```bash
bash work/validar-tracker.sh
```

O código da aplicação (`src/`, `prisma/`, `tests/` e configurações) não foi alterado.
