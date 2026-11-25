# ADR-005: Garantir entrega at-least-once, com deduplicação pelo X-Event-Id

- **Data do registro:** 2026-11-25
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Sofia (Segurança), Marcos (PM), Bruno (Pedidos)
- **Origem:** reunião técnica de webhooks, [09:24] a [09:26] e [09:44] a [09:45]
- **Tags:** contrato externo, confiabilidade
- **Relações:** depende de [ADR-001](ADR-001-outbox-no-mysql.md) e [ADR-003](ADR-003-retry-com-backoff-e-dlq.md); relacionado a [ADR-004](ADR-004-hmac-sha256-com-secret-por-endpoint.md)

## Status

Aceito.

## Contexto

Com retentativas ([ADR-003](ADR-003-retry-com-backoff-e-dlq.md)) e replay manual da DLQ, o mesmo evento pode chegar ao cliente mais de uma vez ([09:24] Diego). Um exemplo é o cliente que processa a chamada mas demora mais que o timeout de 10 segundos para responder ([09:42] Diego): para a plataforma isso é falha, e o evento volta para a fila. A reunião precisava dizer o que a plataforma promete e como o cliente lida com a repetição ([09:25] Bruno).

## Alternativas Consideradas

1. **Exactly-once (cada evento chega uma única vez).** Descartada: exigiria coordenação entre os dois lados e ficaria muito mais complexa ([09:25] Diego).
2. **At-least-once com um identificador único por evento.** Escolhida. Diego citou Stripe e GitHub como exemplos de quem faz assim ([09:25] Diego).

## Decisão

A plataforma promete que cada evento é entregue pelo menos uma vez e pode ser entregue mais de uma ([09:24] Diego, [09:26] Larissa).

Cada evento recebe um UUID quando entra na outbox. Esse id vai no header `X-Event-Id` e também no corpo, como `event_id`. O cliente usa esse id para descartar o que já processou ([09:25] Diego, [09:43] Diego). Cada envio também leva o `X-Webhook-Id`, com o id do endpoint cadastrado, para o cliente que tem mais de um cadastro saber qual deles recebeu o evento ([09:44] Sofia, [09:45] Diego).

Marcos vai explicar a deduplicação, em destaque, no portal de desenvolvedor ([09:26] Marcos).

## Consequências

Positivas:

- O lado da plataforma fica simples: retentar é sempre seguro, porque o cliente sabe lidar com a repetição.
- É o modelo que integradores já conhecem de outros provedores ([09:25] Diego).

Negativas:

- A responsabilidade de deduplicar passa para o cliente, como Sofia apontou ([09:25] Sofia). Um cliente que ignore o `X-Event-Id` vai processar o mesmo evento duas vezes.
- A deduplicação só funciona se o id se mantiver em todos os reenvios. A reunião não disse se o replay da DLQ, que "recoloca na outbox como pendente" ([09:18] Diego), mantém o `event_id` original ou cria um novo. Isso precisa ser fechado no FDD.

Trade-off: o time aceitou passar a deduplicação para o cliente em troca de um mecanismo de entrega simples e de retentativas sem risco para a plataforma.

## Referências

- [ADR-003](ADR-003-retry-com-backoff-e-dlq.md) (retentativas e replay que geram reentrega)
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature
