# ADR-002: Entregar os eventos com um worker separado que lê a outbox por polling

- **Data do registro:** 2026-11-25
- **Decisores:** Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos), Marcos (PM), Sofia (Segurança)
- **Origem:** reunião técnica de webhooks, [09:08] a [09:14] e [09:28] a [09:30]
- **Tags:** backend, processamento assíncrono
- **Relações:** depende de [ADR-001](ADR-001-outbox-no-mysql.md); relacionado a [ADR-003](ADR-003-retry-com-backoff-e-dlq.md)

## Status

Aceito.

## Contexto

Com a outbox do [ADR-001](ADR-001-outbox-no-mysql.md), alguém precisa ler os eventos pendentes e fazer as chamadas HTTP. O requisito de latência é "abaixo de 10 segundos" ([09:02] Marcos).

O MySQL não tem um mecanismo como o LISTEN/NOTIFY do Postgres. Trigger existe, mas só executa SQL e não avisa um processo de fora ([09:09] Diego). Se a leitura rodasse dentro do processo da API, cada reinício da API derrubaria a entrega junto ([09:11] Diego).

Fatores que pesaram:

- atraso bem abaixo de 10 segundos;
- entrega que não depende do ciclo de vida da API;
- mesma stack e mesmo banco, sem infraestrutura nova.

## Alternativas Consideradas

1. **Trigger no banco para acordar o worker.** Bruno sugeriu para ganhar reatividade ([09:09] Bruno). Descartada: a trigger não notifica processo externo, e qualquer improviso (escrever em arquivo, chamar um endpoint) ficaria esquisito ([09:09] Diego).
2. **Worker dentro do processo da API.** Descartado: um reinício da API pararia a entrega ([09:11] Diego).
3. **Vários workers em paralelo desde já.** Adiado. Com mais de um worker a ordem dos eventos se perde, e as saídas citadas (particionar por `order_id` ou lock pessimista) ficaram para quando houver necessidade ([09:12] e [09:13] Diego).

## Decisão

A entrega roda num processo Node separado da API, com entry point próprio `src/worker.ts` (a criar) e um script `npm run worker`, no mesmo molde de `src/server.ts` ([09:11] Diego, [09:11] Larissa). O processo usa o mesmo banco e a mesma `DATABASE_URL`, mas com uma instância própria do PrismaClient, porque o client é por processo ([09:11] Bruno, [09:30] Bruno).

O worker faz polling a cada 2 segundos: busca em lote pequeno os eventos pendentes mais antigos, processa e marca o resultado ([09:08] e [09:09] Diego). A reunião aceitou que o polling acrescente até 2 segundos de atraso, dentro da meta de 10 ([09:10] Marcos, [09:10] Larissa).

Nesta fase roda um worker só, processando pela ordem de `created_at` da outbox ([09:12] Diego).

## Consequências

Positivas:

- O atraso causado pelo polling fica em até 2 segundos, com folga para a meta de 10 ([09:09] Diego).
- Reinícios e deploys da API não interrompem a entrega, e um cliente lento não ocupa o processo que atende as requisições.
- A implementação é simples: um loop, uma consulta indexada por status e `created_at` ([09:08] Diego), sem broker.

Negativas:

- A ordem só é garantida por pedido (`order_id`) e enquanto houver um único worker. Não há ordem global. A reunião registrou isso como limitação conhecida ([09:13] Larissa), e os clientes não pediram mais que isso ([09:14] Marcos).
- Escalar além de um worker exige uma decisão nova sobre particionamento ou lock ([09:13] Diego).
- O banco recebe uma consulta a cada 2 segundos mesmo quando não há eventos.
- Passa a existir mais um processo para subir, monitorar e reiniciar.

Trade-off: o time aceitou até 2 segundos de atraso e um único worker em troca de não depender de infraestrutura nova nem de truques no banco.

## Referências

- `src/server.ts` (entry point atual, modelo para `src/worker.ts`, a criar)
- `src/config/database.ts` (`createPrismaClient`)
- [ADR-003](ADR-003-retry-com-backoff-e-dlq.md) para o que acontece quando a entrega falha
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature
