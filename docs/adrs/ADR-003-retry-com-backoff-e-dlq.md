# ADR-003: Retentar com backoff exponencial e mover para uma DLQ em tabela separada

- **Data do registro:** 2026-11-25
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos), Marcos (PM), Sofia (Segurança)
- **Origem:** reunião técnica de webhooks, [09:14] a [09:19], [09:35] a [09:36] e [09:42]
- **Tags:** backend, resiliência
- **Relações:** depende de [ADR-002](ADR-002-worker-separado-em-polling.md); relacionado a [ADR-005](ADR-005-at-least-once-com-x-event-id.md) e [ADR-006](ADR-006-reuso-dos-padroes-do-projeto.md)

## Status

Aceito.

## Contexto

O endpoint do cliente pode estar fora do ar ou lento ([09:14] Larissa). Já houve cliente com duas horas de indisponibilidade numa manutenção planejada ([09:16] Diego). Uma chamada que não responde em 10 segundos também conta como falha ([09:42] Diego).

A política precisava cobrir indisponibilidades de horas sem deixar eventos pendurados para sempre, e definir o que acontece com o evento quando as tentativas acabam.

## Alternativas Consideradas

1. **Retry sem limite, com backoff.** Descartado: se o cliente sumir, o evento fica pendente para sempre ([09:15] Diego).
2. **3 tentativas.** Bruno sugeriu por ser mais agressivo ([09:16] Bruno). Descartado: três tentativas acabariam em cerca de 30 minutos e não cobririam uma manutenção de duas horas ([09:16] Diego).
3. **Marcar o evento como "failed" na própria outbox, em vez de tabela separada.** Larissa colocou as duas opções ([09:17] Larissa). Ficou a tabela separada, que deixa a leitura da outbox mais limpa e guarda o evento como evidência para debug e reprocessamento ([09:18] Diego).

## Decisão

Depois de uma falha, o worker tenta de novo com backoff exponencial nos intervalos de 1 minuto, 5 minutos, 30 minutos, 2 horas e 12 horas: quase 15 horas entre a primeira falha e a última tentativa ([09:17] Diego, [09:17] Larissa). A reunião chama isso de "5 tentativas"; este ADR lê como o envio original mais 5 retentativas, uma por intervalo, porque é a leitura que usa os cinco intervalos e fecha com as 15 horas.

Esgotadas as retentativas, o evento vai para a tabela `webhook_dead_letter`, com o payload, o motivo da falha e o horário ([09:18] Diego).

O reprocessamento é manual, por um endpoint administrativo que recoloca o evento na outbox como pendente ([09:18] Diego, [09:19] Larissa). Só a role ADMIN pode chamá-lo, e cada replay registra quem o fez, para auditoria ([09:36] Sofia, [09:36] Larissa).

## Consequências

Positivas:

- Uma indisponibilidade de horas, como a manutenção de duas horas citada, é coberta sem perder o evento.
- Nenhum evento fica pendente para sempre: depois de cerca de 15 horas ele sai da outbox.
- A DLQ guarda o motivo da falha, o que ajuda o suporte a entender o que houve antes de reprocessar.

Negativas:

- Um cliente que volta depois de uma queda longa pode receber o evento horas depois da mudança de status. Marcos considerou aceitável: um cliente fora do ar por 15 horas já tem um problema sério do lado dele ([09:17] Marcos).
- Nada avisa o cliente de que o webhook está falhando. O aviso por e-mail ficou para uma próxima fase ([09:37] Larissa).
- Tirar algo da DLQ depende de um administrador agir.
- Retentativas e replays podem entregar o mesmo evento mais de uma vez, o que é tratado no [ADR-005](ADR-005-at-least-once-com-x-event-id.md).

Trade-off: o time escolheu uma janela longa e finita de retentativas, aceitando entregas muito atrasadas e reprocessamento manual, em vez de desistir cedo ou insistir sem fim.

## Referências

- `src/middlewares/auth.middleware.ts` (`requireRole`, usado no replay)
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature, com os detalhes de timeout, contadores e contrato do endpoint de replay
