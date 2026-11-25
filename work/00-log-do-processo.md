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
