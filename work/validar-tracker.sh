#!/usr/bin/env bash
# Valida docs/TRACKER.md contra os critérios do desafio.
# Uso (na raiz do repositório): bash work/validar-tracker.sh
set -u

TRACKER="docs/TRACKER.md"
TRANSCRICAO="TRANSCRICAO.md"
erros=0

# Linhas da tabela: começam com "| " e um ID em maiúsculas (ignora cabeçalho e separador).
linhas=$(grep -E '^\| [A-Z]+-[A-Z0-9-]+ \|' "$TRACKER" | grep -v '^| ID |')
total=$(printf '%s\n' "$linhas" | grep -c .)

# 1. Seis colunas em cada linha
fora_formato=$(printf '%s\n' "$linhas" | awk -F'|' 'NF != 8' | wc -l | tr -d ' ')
[ "$fora_formato" -ne 0 ] && { echo "ERRO: $fora_formato linha(s) sem 6 colunas"; erros=1; }

# 2. IDs únicos
dup=$(printf '%s\n' "$linhas" | awk -F'|' '{gsub(/ /,"",$2); print $2}' | sort | uniq -d)
[ -n "$dup" ] && { echo "ERRO: IDs repetidos: $dup"; erros=1; }

# 3. Documento existe
while IFS= read -r doc; do
  [ -e "$doc" ] || { echo "ERRO: documento inexistente: $doc"; erros=1; }
done < <(printf '%s\n' "$linhas" | awk -F'|' '{print $3}' | tr -d '` ' | sort -u)

# 4. Fonte e localização
n_trans=0; n_cod=0
while IFS= read -r linha; do
  id=$(printf '%s' "$linha" | awk -F'|' '{gsub(/ /,"",$2); print $2}')
  fonte=$(printf '%s' "$linha" | awk -F'|' '{gsub(/ /,"",$6); print $6}')
  loc=$(printf '%s' "$linha" | awk -F'|' '{print $7}')
  case "$fonte" in
    TRANSCRICAO)
      n_trans=$((n_trans + 1))
      refs=$(printf '%s' "$loc" | grep -oE '\[[0-9]{2}:[0-9]{2}\] [A-Z][a-z]+')
      [ -z "$refs" ] && { echo "ERRO: $id sem [hh:mm] Nome"; erros=1; }
      while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        grep -qF -- "$ref:" "$TRANSCRICAO" || { echo "ERRO: $id cita fala inexistente: $ref"; erros=1; }
      done <<< "$refs"
      ;;
    CODIGO)
      n_cod=$((n_cod + 1))
      caminho=$(printf '%s' "$loc" | tr -d '` ')
      [ -e "$caminho" ] || { echo "ERRO: $id cita caminho inexistente: $caminho"; erros=1; }
      ;;
    *) echo "ERRO: $id com fonte inválida: $fonte"; erros=1 ;;
  esac
done <<< "$linhas"

pct_trans=$(awk -v a="$n_trans" -v t="$total" 'BEGIN { printf "%.1f", 100 * a / t }')

# 5. Cobertura: itens identificáveis contados direto nos documentos
conta_doc() { grep -cE "$2" "$1"; }
conta_trk() { printf '%s\n' "$linhas" | grep -cE "^\| $1"; }

itens=0; cobertos=0
cobertura() { # rótulo, qtd no documento, qtd no tracker
  local c=$3; [ "$c" -gt "$2" ] && c=$2
  itens=$((itens + $2)); cobertos=$((cobertos + c))
  printf '| %s | %s | %s |\n' "$1" "$2" "$3"
}

tabela_cob=$(
  cobertura "PRD: requisitos funcionais" "$(conta_doc docs/PRD.md '^\| RF-[0-9]+')" "$(conta_trk 'PRD-FR-')"
  cobertura "PRD: requisitos não funcionais" "$(conta_doc docs/PRD.md '^\| RNF-[0-9]+')" "$(conta_trk 'PRD-NFR-')"
  cobertura "PRD: metas" "$(awk '/^## Objetivos/,/^## Escopo/' docs/PRD.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'PRD-OBJ-')"
  cobertura "PRD: fora de escopo" "$(awk '/Fora de escopo/,/^## Requisitos funcionais/' docs/PRD.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'PRD-FORA-')"
  cobertura "PRD: dependências" "$(awk '/^## Dependências/,/^## Riscos/' docs/PRD.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'PRD-DEP-')"
  cobertura "PRD: riscos" "$(awk '/^## Riscos/,/^## Critérios/' docs/PRD.md | grep -cE '\| (Baixa|Média|Alta) \|')" "$(conta_trk 'PRD-RISCO-')"
  cobertura "RFC: alternativas" "$(awk '/^## Alternativas/,/^## Questões/' docs/RFC.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'RFC-ALT-')"
  cobertura "RFC: questões em aberto" "$(awk '/^## Questões/,/^## Impacto/' docs/RFC.md | grep -cE '^[0-9]+\. ')" "$(conta_trk 'RFC-ABE-')"
  cobertura "RFC: riscos técnicos" "$(awk '/Riscos técnicos/,/Prazo/' docs/RFC.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'RFC-RISCO-')"
  cobertura "ADRs: decisões" "$(ls docs/adrs/ADR-*.md | wc -l | tr -d ' ')" "$(conta_trk 'ADR-[0-9]{3} ')"
  cobertura "ADRs: alternativas não escolhidas" "$(for f in docs/adrs/ADR-*.md; do awk '/^## Alternativas/,/^## Decisão/' "$f" | grep -E '^[0-9]+\. \*\*' | grep -vc 'Escolhida'; done | awk '{s+=$1} END {print s}')" "$(conta_trk 'ADR-[0-9]{3}-ALT-')"
  cobertura "FDD: contratos" "$(awk '/^## Contratos públicos/,/^## Matriz/' docs/FDD.md | grep -cE '^### [0-9]+\.')" "$(conta_trk 'FDD-CONTRATO-0[1-8]')"
  cobertura "FDD: códigos WEBHOOK_" "$(grep -oE 'WEBHOOK_[A-Z_]+' docs/FDD.md | sort -u | wc -l | tr -d ' ')" "$(conta_trk 'FDD-ERRO-0[1-8]')"
  cobertura "FDD: fluxos" "$(awk '/^## Fluxos detalhados/,/^## Contratos/' docs/FDD.md | grep -cE '^### [0-9]+\.')" "$(conta_trk 'FDD-FLUXO-')"
  cobertura "FDD: métricas" "$(awk '/^\*\*Métricas/,/^\*\*Tracing/' docs/FDD.md | grep -cE '^\| [A-Z]' | awk '{print $1-1}')" "$(conta_trk 'FDD-OBS-0[1-5]')"
  cobertura "FDD: integração com o código" "$(awk '/^## Integração com o sistema existente/,/^Arquivos novos/' docs/FDD.md | grep -cE '^\| `')" "$(conta_trk 'FDD-INT-')"
  cobertura "FDD: pendências" "$(grep -cE '^\| P-[0-9]+ ' docs/FDD.md)" "$(conta_trk 'FDD-PEND-')"
)
# Recalcula os totais fora do subshell
itens=0; cobertos=0
while IFS='|' read -r _ _ qd qt _; do
  qd=$(echo "$qd" | tr -d ' '); qt=$(echo "$qt" | tr -d ' ')
  c=$qt; [ "$c" -gt "$qd" ] && c=$qd
  itens=$((itens + qd)); cobertos=$((cobertos + c))
done <<< "$tabela_cob"
pct_cob=$(awk -v a="$cobertos" -v t="$itens" 'BEGIN { printf "%.1f", 100 * a / t }')

echo "Linhas no tracker: $total"
echo "Fonte TRANSCRICAO: $n_trans ($pct_trans%) | exigido: >= 70%"
echo "Fonte CODIGO: $n_cod | exigido: >= 5"
echo "Cobertura das categorias contadas: $cobertos de $itens ($pct_cob%) | exigido: >= 80%"
echo
echo "| Categoria | Itens no documento | Linhas no tracker |"
echo "| --- | --- | --- |"
printf '%s\n' "$tabela_cob"
echo
[ "$erros" -eq 0 ] && echo "Nenhum erro de formato, fonte ou caminho." || { echo "Há erros acima."; exit 1; }
