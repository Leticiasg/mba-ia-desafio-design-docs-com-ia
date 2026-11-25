# ADR-004: Assinar os webhooks com HMAC-SHA256 e uma secret por endpoint

- **Data do registro:** 2026-11-25
- **Decisores:** Sofia (Segurança), Larissa (Tech Lead), Diego (Plataforma), Bruno (Pedidos), Marcos (PM)
- **Origem:** reunião técnica de webhooks, [09:19] a [09:23], [09:31] e [09:44] a [09:46]
- **Tags:** segurança, contrato externo
- **Relações:** relacionado a [ADR-005](ADR-005-at-least-once-com-x-event-id.md) e [ADR-006](ADR-006-reuso-dos-padroes-do-projeto.md)

## Status

Aceito.

## Contexto

Os webhooks levam dados de pedidos para endpoints fora da infraestrutura da empresa. O cliente precisa conseguir confirmar que a requisição veio mesmo da plataforma e que o corpo não foi alterado no caminho ([09:19] Sofia). Diego lembrou que um cliente já vazou uma secret no log da própria aplicação ([09:22] Diego), então a decisão também precisava limitar o estrago de um vazamento.

## Alternativas Consideradas

1. **Uma secret global da plataforma para todos os clientes.** Descartada: se ela vaza, todos os clientes ficam expostos ([09:21] Sofia).
2. **Uma secret por endpoint de webhook.** Escolhida.

## Decisão

Cada requisição de webhook leva uma assinatura HMAC-SHA256 calculada sobre o corpo do request, enviada no header `X-Signature`. O cliente recalcula do lado dele e compara ([09:20] Sofia, [09:22] Sofia). Sofia escolheu o SHA-256 por ser o padrão de mercado, com biblioteca disponível em qualquer stack ([09:20] Sofia).

Cada endpoint cadastrado tem a sua secret. A plataforma gera a secret e a devolve na criação do webhook ([09:31] Marcos). A configuração guarda url, secret, customer e se o endpoint está ativo ([09:21] Bruno, [09:21] Sofia).

O cliente pode pedir uma secret nova pela API. Depois da rotação, a secret antiga continua válida por 24 horas, para dar tempo de o cliente atualizar os sistemas dele, e então deixa de valer ([09:21] Sofia, [09:22] Sofia).

Duas medidas complementam a assinatura sem fazer parte desta decisão: a URL do webhook tem de ser https, validada no schema Zod ([09:23] Sofia), e cada envio leva um `X-Timestamp` para que o cliente possa detectar replay se quiser ([09:44] Diego).

## Consequências

Positivas:

- Um vazamento atinge só o endpoint daquela secret, e a rotação permite trocá-la sem derrubar a integração.
- O cliente consegue validar origem e integridade com bibliotecas comuns.

Negativas:

- A plataforma precisa guardar cada secret de um jeito que permita assinar com ela, porque o HMAC usa a secret em si. Ela não pode ser guardada só como hash, como acontece com senha.
- A rotação exige manter duas secrets por endpoint durante 24 horas. A reunião não definiu com qual delas a plataforma assina nesse período; isso precisa ser fechado no FDD ou na revisão.
- A proteção contra replay fica a critério do cliente: a reunião não definiu janela de validade para o `X-Timestamp`.
- O código de HMAC e de geração de secret passa por revisão de segurança de pelo menos dois dias úteis antes do deploy ([09:46] Sofia).

Trade-off: o time aceitou guardar e rotacionar uma secret por endpoint, com mais estado e mais código sensível, para que um vazamento fique restrito a um cliente.

## Referências

- `src/middlewares/validate.middleware.ts` (validação Zod onde entra a regra de https)
- `src/shared/logger/index.ts` (lista de `redact`, que hoje não cobre um campo de secret)
- [RFC](../RFC.md) e [FDD](../FDD.md) da feature
