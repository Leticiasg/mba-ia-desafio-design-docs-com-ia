# ADR-001: Registrar os eventos de webhook numa outbox no MySQL

- **Data do registro:** 2026-11-25
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos), Marcos (PM), Sofia (Segurança)
- **Origem:** reunião técnica de webhooks, [09:03] a [09:08] e [09:40] a [09:42]
- **Tags:** backend, pedidos, consistência
- **Relações:** base para [ADR-002](ADR-002-worker-separado-em-polling.md), [ADR-003](ADR-003-retry-com-backoff-e-dlq.md) e [ADR-005](ADR-005-at-least-once-com-x-event-id.md)

## Status

Aceito.

## Contexto

Três clientes B2B querem saber quando o status de um pedido deles muda, com atraso abaixo de 10 segundos ([09:00] e [09:02] Marcos). A mudança de status acontece no método `changeStatus` de `src/modules/orders/order.service.ts`, dentro de uma única transação Prisma que atualiza `orders`, grava em `order_status_history` e mexe no estoque dos produtos do pedido ([09:04] Bruno). Pelo código, o estoque só muda em algumas transições: é debitado em PENDING → PAID e reposto no cancelamento a partir de PAID ou PROCESSING (`src/modules/orders/order.status.ts`).

A pergunta da reunião era onde disparar a notificação. Se o envio HTTP ficar dentro dessa transação, um cliente lento segura a mudança de status de outros pedidos. E se o cliente estiver fora do ar, não há o que fazer com a mudança de status, porque desfazer não é opção ([09:04] Bruno). O time é pequeno e não quer subir infraestrutura nova só para isso ([09:07] Diego).

Fatores que pesaram:

- a notificação não pode existir sem a mudança de status, nem a mudança sem a notificação ([09:06] Diego, [09:40] Bruno);
- o envio não pode travar nem desfazer a transação do pedido ([09:04] Bruno);
- nada de infraestrutura nova ([09:07] Diego).

## Alternativas Consideradas

1. **Envio síncrono dentro do `changeStatus`.** Descartado logo no início: a transação já é pesada e um cliente lento ou fora do ar afetaria todos os pedidos ([09:04] Bruno, [09:06] Diego).
2. **Fila externa, como Redis Streams.** Resolveria o desacoplamento, mas exigiria subir e operar mais infraestrutura. Diego chamou de overengineering para o tamanho do time ([09:07] Larissa, [09:07] Diego).
3. **Outbox numa tabela do MySQL que já existe.** Escolhida.

## Decisão

Cada mudança de status grava um evento numa tabela `webhook_outbox`, no mesmo banco e na mesma transação que atualiza `orders` e `order_status_history` ([09:06] Diego, [09:08] Larissa). Se a transação faz commit, o evento existe; se faz rollback, o evento some junto. Se a inserção na outbox falhar, a transação inteira volta ([09:40] Bruno, [09:41] Diego).

O `changeStatus` não recebe o repository do webhook. Ele chama uma função `publishWebhookEvent(tx, order, fromStatus, toStatus)` que usa o client da transação em andamento ([09:41] Bruno, [09:41] Diego).

Duas regras da inserção ficaram decididas na mesma reunião:

- o evento só entra na outbox se algum webhook do customer quer aquele status ([09:34] Bruno, [09:34] Diego);
- o payload é gravado pronto, como retrato do pedido no momento da mudança, e não é montado de novo na hora do envio ([09:52] Larissa, [09:52] Diego, [09:52] Bruno).

Quem lê a outbox e entrega o evento está no [ADR-002](ADR-002-worker-separado-em-polling.md).

## Consequências

Positivas:

- Não existe caso de status alterado sem evento, nem de evento para uma mudança que foi desfeita ([09:06] Diego).
- O envio HTTP sai da transação do pedido, então um cliente lento não atrasa mais ninguém.
- Nenhum serviço novo para subir ou monitorar: o MySQL e o Prisma já estão no projeto.
- Como o payload é gravado pronto, o evento mostra o pedido como estava na mudança de status, mesmo que ele mude de novo antes do envio ([09:52] Larissa).

Negativas:

- A transação do `changeStatus` fica com mais uma escrita, e o módulo de pedidos passa a depender do módulo de webhooks.
- A tabela cresce com o tempo. Arquivar os eventos entregues (algo como 30 dias) ficou fora do escopo desta feature ([09:08] Diego).
- A entrega deixa de ser imediata: passa a depender de um processo que lê a outbox, com o atraso do [ADR-002](ADR-002-worker-separado-em-polling.md).

Trade-off: o time trocou entrega imediata e um banco mais leve por consistência entre pedido e evento sem infraestrutura nova.

## Referências

- `src/modules/orders/order.service.ts` (`changeStatus`)
- `src/modules/orders/order.status.ts` (transições que mexem no estoque)
- `prisma/schema.prisma` (models `Order` e `OrderStatusHistory`)
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature
