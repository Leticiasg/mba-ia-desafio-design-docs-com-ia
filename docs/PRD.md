# PRD — Webhooks de notificação de pedidos

| Campo | Valor |
| --- | --- |
| Autor | Leticiasg |
| Status | Rascunho para revisão |
| Data | 2026-11-25 |
| Responsável de produto | Marcos (Product Manager) |
| Documentos ligados | [RFC](RFC.md) · [FDD](FDD.md) · [ADRs](adrs/) · [Tracker](TRACKER.md) |

## Resumo e contexto

O OMS vai avisar os clientes B2B, em menos de 10 segundos, sempre que o status de um pedido deles mudar. O aviso é uma chamada HTTP (webhook) para um endereço que o próprio cliente cadastra pela API, assinada para que ele saiba que veio do OMS.

A feature nasceu de um pedido formal de três clientes B2B, Atlas Comercial, MaxDistribuição e Nova Cargo ([09:00] Marcos), e foi desenhada numa reunião técnica com tech lead, produto, engenharia e segurança. Hoje o OMS não manda nenhum tipo de notificação para fora.

## Problema e motivação

Para saber se um pedido mudou, os clientes consultam a lista de pedidos de tempos em tempos. Marcos contou que isso deixa a integração deles lenta e cara ([09:00] Marcos). Quanto mais espaçadas as consultas, mais o cliente demora a saber; quanto mais frequentes, mais caro fica para ele.

Há também um risco comercial: a Atlas sugeriu que pode ir para um concorrente se a feature não sair até o fim do trimestre ([09:00] Marcos), e pediu a entrega para o fim de novembro ([09:45] Marcos).

## Público-alvo e cenários de uso

**Quem usa:**

- **Clientes B2B com integração própria**, como os três que pediram a feature ([09:00] Marcos). Eles recebem as notificações e configuram os webhooks pela API, autenticados com usuários do OMS que os representam ([09:32] Marcos).
- **Administradores do OMS**, que reprocessam notificações que falharam de vez ([09:36] Sofia).
- **Suporte e produto**, que consultam o histórico de entregas quando um cliente diz que não recebeu algo ([09:34] Marcos).

**Cenários:**

1. *Acompanhar a entrega.* Um cliente quer saber só quando o pedido sai para entrega e quando chega. Ele cadastra um webhook que escuta apenas SHIPPED e DELIVERED e para de consultar a lista de pedidos ([09:33] Marcos).
2. *Cliente em manutenção.* O sistema do cliente fica duas horas fora do ar numa manutenção planejada, como já aconteceu com um cliente ([09:16] Diego). As notificações desse período chegam depois, quando ele volta.
3. *Notificação repetida.* O cliente recebe a mesma notificação duas vezes e descarta a segunda pelo identificador do evento ([09:24] Diego, [09:25] Diego).
4. *Secret vazada.* Um cliente expõe sua secret num log, como já aconteceu ([09:22] Diego). Ele pede uma secret nova e tem 24 horas para trocar nos sistemas dele ([09:21] Sofia).
5. *"Não recebi."* O cliente diz que não recebeu um aviso. Ele mesmo, ou o suporte, olha as últimas 100 entregas daquele webhook e vê se houve falha, o que o sistema dele respondeu e quanto tempo levou ([09:34] Marcos).
6. *Falha definitiva.* Depois de quase 15 horas de tentativas, uma notificação vai para a fila de falhas. Quando o cliente resolve o problema, um administrador reenvia ([09:17] Diego, [09:18] Diego).

**Fluxo de integração do cliente:**

1. Cadastra o webhook com o endereço https e os status que quer receber; recebe a secret uma única vez.
2. Implementa no seu sistema a validação da assinatura e o descarte de repetidos, seguindo o portal de desenvolvedor ([09:26] Marcos, [09:40] Marcos).
3. Passa a receber as notificações; quando precisa de detalhes do pedido, como os itens, consulta o pedido pela API ([09:43] Diego).
4. Usa o histórico de entregas para investigar problemas e a rotação para trocar a secret.

## Objetivos e métricas de sucesso

| Objetivo | Métrica | Meta | Fonte |
| --- | --- | --- | --- |
| Avisar o cliente rápido o bastante para ele parar de consultar | Tempo entre a mudança de status e a chegada da notificação, com o sistema do cliente respondendo normalmente | Menos de 10 segundos | [09:02] Marcos |
| Atender os clientes que pediram a feature | Clientes com webhook cadastrado e recebendo notificações | 3 clientes: Atlas Comercial, MaxDistribuição e Nova Cargo | [09:00] Marcos |
| Entregar a tempo de reter a Atlas | Data de entrada em produção | Até o fim de novembro, data pedida pela Atlas; a estimativa do time é de três sprints | [09:45] Marcos, [09:47] Larissa |
| Não perder notificação quando o cliente fica fora do ar | Janela coberta por novas tentativas antes de a notificação ir para a fila de falhas | Quase 15 horas (1m, 5m, 30m, 2h, 12h) | [09:17] Diego, [09:17] Marcos |

Larissa também condicionou a próxima fase (aviso por e-mail) a medir o impacto desta ([09:37] Larissa). As métricas de entrega descritas no [FDD](FDD.md#observabilidade) (sucesso, falha, tempo de resposta, tamanho da fila de falhas) são a base dessa medição.

## Escopo

**Incluso:**

- notificação de mudança de status de pedido para endpoints cadastrados pelos clientes;
- cadastro, listagem, edição e remoção de webhooks pela API, com escolha dos status de interesse;
- assinatura de cada notificação, com secret por webhook e rotação;
- novas tentativas automáticas e fila de falhas com reenvio manual por administrador;
- histórico das últimas entregas de cada webhook.

**Fora de escopo:**

| Item | Situação | Fonte |
| --- | --- | --- |
| Aviso por e-mail ao cliente quando o webhook dele falha repetidamente | Adiado para a próxima fase, depois de medir o impacto desta | [09:37] Larissa, [09:38] Marcos |
| Painel visual para o cliente ver os webhooks | Descartado nesta fase; é projeto separado do time de frontend. Nesta fase só há API | [09:40] Larissa |
| Limite de envio por cliente (rate limiting) | Não entra; o time vai observar e decidir se virar problema | [09:39] Diego, [09:39] Larissa |
| Webhooks de entrada (cliente enviando dados para o OMS) | Descartado; os clientes só querem receber | [09:02] Marcos |
| Garantia de ordem global entre pedidos | Não entra; a ordem vale só dentro de cada pedido, e os clientes não pediram mais que isso | [09:13] Larissa, [09:14] Marcos |
| Itens do pedido na notificação | Descartado para manter a mensagem enxuta; o cliente consulta o pedido se precisar | [09:43] Diego, [09:44] Bruno |
| Arquivamento de notificações antigas | Fora do escopo desta feature | [09:08] Diego |
| Permissões diferentes por tipo de usuário na configuração | Adiado; por enquanto qualquer usuário autenticado configura | [09:37] Sofia |

## Requisitos funcionais

| Id | Requisito | Fonte |
| --- | --- | --- |
| RF-01 | O OMS notifica o endpoint cadastrado pelo cliente sempre que o status de um pedido daquele cliente muda para um status que o webhook escuta | [09:00] Marcos, [09:33] Marcos |
| RF-02 | O cliente cadastra um webhook pela API informando o endereço e os status de interesse; o OMS gera a secret e a devolve na criação | [09:31] Marcos |
| RF-03 | O cliente edita um webhook existente | [09:33] Bruno |
| RF-04 | O cliente remove um webhook | [09:33] Bruno |
| RF-05 | O cliente lista os webhooks cadastrados para ele | [09:33] Bruno |
| RF-06 | Cada webhook tem seu próprio filtro de status; um status fora do filtro não gera notificação | [09:33] Marcos, [09:34] Bruno |
| RF-07 | O cliente consulta o histórico das últimas 100 entregas de um webhook, com sucesso ou falha, conteúdo enviado, resposta e tempo de resposta | [09:34] Marcos |
| RF-08 | O cliente pede uma secret nova; a anterior continua aceita por 24 horas | [09:21] Sofia |
| RF-09 | Cada notificação é assinada com a secret do webhook, para o cliente confirmar origem e integridade | [09:19] Sofia, [09:20] Sofia |
| RF-10 | Cada notificação traz um identificador único do evento, para o cliente descartar repetições, e o identificador do webhook que a recebeu | [09:25] Diego, [09:44] Sofia |
| RF-11 | A notificação traz o pedido (id e número), o status anterior e o novo, o cliente, o valor total e o momento da mudança, sem os itens | [09:43] Diego |
| RF-12 | Notificações que falham são reenviadas automaticamente em intervalos crescentes; depois da última tentativa vão para uma fila de falhas | [09:15] Diego, [09:17] Larissa |
| RF-13 | Um administrador reenvia manualmente uma notificação da fila de falhas, e o OMS registra quem fez o reenvio | [09:18] Diego, [09:36] Sofia |
| RF-14 | O cadastro e a edição recusam endereços que não sejam https | [09:23] Sofia |

## Requisitos não funcionais

| Id | Requisito | Fonte |
| --- | --- | --- |
| RNF-01 | Atraso abaixo de 10 segundos entre a mudança de status e a notificação | [09:02] Marcos |
| RNF-02 | A notificação nunca atrasa nem bloqueia a mudança de status de outros pedidos | [09:04] Bruno |
| RNF-03 | Se o status muda, a notificação é registrada; se a mudança é desfeita, a notificação também é | [09:06] Diego, [09:40] Bruno |
| RNF-04 | Entrega pelo menos uma vez: o cliente pode receber a mesma notificação mais de uma vez | [09:24] Diego |
| RNF-05 | Ordem garantida apenas dentro de cada pedido | [09:13] Larissa |
| RNF-06 | Sistema do cliente que não responde em 10 segundos conta como falha | [09:42] Diego |
| RNF-07 | Apenas https; uma secret por webhook, nunca compartilhada | [09:21] Sofia, [09:23] Sofia |
| RNF-08 | Notificação acima de 64KB não é enviada e gera erro | [09:24] Diego, [09:24] Larissa |
| RNF-09 | Sem infraestrutura nova: a feature usa o banco e a stack que já existem | [09:07] Diego, [09:11] Diego |
| RNF-10 | O código de segurança (assinatura e geração de secret) passa por revisão de pelo menos dois dias úteis antes do deploy | [09:46] Sofia |

## Decisões e trade-offs principais

| Decisão | O que o produto ganha | O que aceita em troca | Registro |
| --- | --- | --- | --- |
| Registrar a notificação junto com a mudança de status e enviar depois | Nenhuma mudança fica sem aviso, e cliente lento não atrapalha a operação | Atraso de até 2 segundos | [ADR-001](adrs/ADR-001-outbox-no-mysql.md), [ADR-002](adrs/ADR-002-worker-separado-em-polling.md) |
| Tentar de novo por quase 15 horas e depois parar | Cobre quedas longas do cliente | Notificação muito atrasada em quedas longas; reenvio depois disso é manual | [ADR-003](adrs/ADR-003-retry-com-backoff-e-dlq.md) |
| Assinatura com secret própria de cada webhook | Um vazamento afeta um só cliente | Mais configuração para guardar e rotacionar | [ADR-004](adrs/ADR-004-hmac-sha256-com-secret-por-endpoint.md) |
| Entrega pelo menos uma vez | Ninguém perde notificação por falha momentânea | O cliente precisa descartar repetidas | [ADR-005](adrs/ADR-005-at-least-once-com-x-event-id.md) |
| Seguir os padrões que o código já tem | Entrega mais rápida e previsível | Herda as limitações do que já existe | [ADR-006](adrs/ADR-006-reuso-dos-padroes-do-projeto.md) |

A discussão técnica e as alternativas descartadas estão no [RFC](RFC.md).

## Dependências

| Dependência | Por que importa | Fonte |
| --- | --- | --- |
| Sistemas dos clientes expostos em https | Sem isso não há para onde enviar | [09:23] Sofia |
| Usuários do OMS que representam os clientes | É com eles que os clientes configuram os webhooks pela API | [09:32] Marcos |
| Portal de desenvolvedor atualizado por Marcos | Os clientes precisam saber validar a assinatura e descartar repetidas | [09:26] Marcos, [09:40] Marcos |
| Revisão de segurança da Sofia | Condição para o deploy | [09:46] Sofia, [09:49] Sofia |
| Fluxo de mudança de status dos pedidos | É onde a notificação nasce | [09:40] Bruno, `src/modules/orders/order.service.ts` |
| Confirmação do prazo com a Atlas | Marcos ficou de confirmar a data com o cliente | [09:47] Marcos |

## Riscos e mitigação

A reunião não atribuiu probabilidade nem impacto aos riscos. As notas abaixo são a avaliação deste documento, e a coluna "Motivo da nota" mostra de que fala cada uma saiu.

| Risco | Probabilidade | Impacto | Motivo da nota | Mitigação |
| --- | --- | --- | --- | --- |
| Atlas migrar para um concorrente | Baixa | Alto | Probabilidade baixa porque Marcos achou que a Atlas vai gostar da estimativa de três sprints ([09:47] Marcos). Impacto alto porque é a perda de um dos três clientes que pediram a feature, e a ameaça foi explícita ([09:00] Marcos) | Plano de três sprints com a revisão de segurança já incluída ([09:47] Larissa); Marcos confirma o prazo e atualiza os clientes ([09:47] Marcos, [09:49] Marcos) |
| Cliente processar a mesma notificação duas vezes | Média | Médio | Probabilidade média porque a repetição faz parte da garantia escolhida ([09:24] Diego) e depende de cada cliente implementar o descarte, como Sofia apontou ([09:25] Sofia). Impacto médio porque o efeito fica no sistema do cliente; os pedidos no OMS não mudam | Identificador único em toda notificação e explicação destacada no portal ([09:26] Marcos) |
| Vazamento de secret | Média | Alto | Probabilidade média porque já aconteceu com um cliente ([09:22] Diego). Impacto alto porque a secret é o que prova que a notificação veio do OMS; com ela, alguém consegue enviar notificações falsas que parecem legítimas ([09:19] Sofia) | Secret por webhook, rotação com 24 horas de convivência e revisão de segurança antes do deploy ([09:21] Sofia, [09:46] Sofia) |
| Cliente receber muitas chamadas de uma vez | Baixa | Médio | Probabilidade baixa porque Diego levantou como hipótese e o time decidiu só observar ([09:38] Diego, [09:39] Diego). Impacto médio porque sobrecarrega o sistema do cliente, sem afetar os pedidos no OMS ([09:38] Diego) | Observar depois do lançamento e decidir um limite se virar problema ([09:39] Larissa) |
| Notificação parar na fila de falhas sem o cliente saber | Baixa | Médio | Probabilidade baixa porque só acontece depois de quase 15 horas de falhas seguidas, e Marcos disse que um cliente fora do ar por tanto tempo já tem um problema sério do lado dele ([09:17] Diego, [09:17] Marcos). Impacto médio porque o cliente fica sem a notificação até um administrador reenviar, e o aviso por e-mail ficou para depois ([09:37] Larissa) | Histórico de entregas para o cliente consultar e reenvio manual pelo administrador ([09:18] Diego, [09:34] Marcos) |

## Critérios de aceitação

1. Um cliente cadastra um webhook com endereço https e status escolhidos e recebe a secret uma única vez.
2. Um endereço que não é https é recusado no cadastro.
3. Quando um pedido do cliente muda para um status escolhido, a notificação chega em menos de 10 segundos.
4. Quando o pedido muda para um status que o webhook não escuta, nada é enviado.
5. A assinatura de cada notificação confere com a secret do webhook.
6. Toda notificação tem identificador do evento e do webhook, e as novas tentativas automáticas de um mesmo evento repetem o mesmo identificador.
7. Com o sistema do cliente fora do ar, a notificação é tentada de novo nos intervalos definidos e, se continuar falhando, vai para a fila de falhas.
8. Só um administrador consegue reenviar uma notificação da fila de falhas, e o reenvio fica registrado com quem o fez.
9. O cliente vê as últimas 100 entregas de cada webhook, com resultado, resposta e tempo.
10. Depois de pedir uma secret nova, a antiga ainda é aceita por 24 horas.
11. A mudança de status de um pedido continua funcionando normalmente mesmo com o sistema do cliente lento ou fora do ar.
12. A revisão de segurança da Sofia foi feita antes do deploy.

## Estratégia de testes e validação

- **Testes automatizados.** Testes de integração no padrão que o projeto já usa (Vitest e Supertest, como em `tests/orders.test.ts`) para os endpoints de configuração, o histórico e o reenvio, e testes ponta a ponta da integração com a mudança de status, que já estão no plano ([09:46] Larissa). Os critérios técnicos detalhados estão no [FDD](FDD.md#critérios-de-aceite-técnicos).
- **Cenários de falha.** Simular sistema do cliente lento (mais de 10 segundos), fora do ar e voltando, e notificação repetida, cobrindo os cenários 2, 3 e 6 deste documento.
- **Revisão de segurança.** Pelo menos dois dias úteis reservados para a Sofia revisar assinatura e geração de secret antes do deploy ([09:46] Sofia).
- **Revisão do desenho.** Sessão com Bruno e Diego sobre o documento de design antes de começar a codar ([09:50] Larissa).
- **Depois do lançamento.** Acompanhar atraso, falhas e fila de falhas para medir o impacto, que é a condição para decidir o aviso por e-mail e o limite de envio ([09:37] Larissa, [09:39] Larissa).
