---
name: cost-report
description: |
  Gera relatório de tokens consumidos na sessão atual do Claude Code,
  separando agente principal e subagentes. Lê o transcript jsonl em
  `~/.claude/projects/<encoded-cwd>/` e roda
  `python .claude/scripts/cost-report.py`. Reporta volumes de input
  (incluindo cache hit/miss), output, e quebra por modelo + subagente.

  Triggers automáticos (rodar SEM o user pedir):
    - No fim de uma tarefa de setup/implementação iniciada a partir de
      leitura do README.md ("lê o README e implementa", "segue o setup
      do README", "faz o que o README pede"). Ao fechar essa tarefa, a
      skill roda automaticamente como feedback do consumo.

  Triggers manuais:
    - "relatório de tokens", "quanto gastei de token?", "cost report",
      "quanto custou essa task?", "/cost-report", "mostra o gasto".

  NÃO usa pra: medir custo em $ (skill foca em tokens — pricing varia
  por modelo/plano); previsão futura (skill é retrospectiva); medir
  consumo de uma chamada específica (skill agrega sessão inteira).
---

# cost-report

Lê o transcript jsonl da sessão atual e reporta tokens consumidos.
Funciona como feedback retrospectivo — útil pra calibrar quão pesada
foi uma task e onde os tokens foram (principal vs cada subagente).

## Quando rodar

**Automaticamente** (sem user pedir):

- No fechamento de tarefa de setup/implementação que começou com user
  pedindo pra ler README.md. Padrões típicos da abertura:
  - "lê o README e começa o setup"
  - "segue o que o README pede"
  - "implementa conforme README"
  - "faz o setup descrito no README.md"
- Ao terminar TODO o trabalho (mapeamento + setup + ajustes), rode a
  skill e apresente o relatório como última coisa antes do summary do turno.

**Manualmente**:

- User fala: "relatório de tokens", "cost report", "/cost-report",
  "quanto gastei?", "mostra o consumo da sessão", etc.

**Pula quando**:
- A tarefa foi trivial (edit de 1-3 linhas, pergunta isolada).
- User não veio do fluxo "README → setup" e não pediu manualmente.
- Já rodou neste turno (não rode duas vezes na mesma resposta).

## Workflow

### 1. Verifique se Python existe

```bash
python --version
```

Se falhar, tenta `python3`. Se nenhum dos dois → reporta ao user
"Python não encontrado, relatório indisponível" e pula. Não inventa
estimativa.

### 2. Rode o script

```bash
python .claude/scripts/cost-report.py
```

Sem argumentos = sessão mais recente (a atual).

Opções úteis se precisar:
- `--session <id>` pra sessão específica (não a mais recente)
- `--markdown` pra output em formato markdown
- `--project <path>` pra forçar project dir

### 3. Apresente ao user

Pegue o output do script e passe direto ao user num bloco code, com
1-2 linhas de contexto antes:

```text
Relatório de tokens da task (gerado por .claude/scripts/cost-report.py):

<output do script>
```

Se rodou automaticamente (não por pedido explícito), prefacie com:

```text
> Setup/mapeamento concluído. Snapshot do consumo:
<output do script>
```

### 4. Não interprete os números

Skill não diz "foi caro" ou "foi barato" — só apresenta. User
interpreta. Comparar com outras tasks é trabalho do user, não da skill.

## Regras duras

1. **Skill é retrospectiva.** Lê transcript que JÁ existe. Não estima,
   não projeta, não calcula em tempo real.
2. **Tokens são autoritativos.** O jsonl é a fonte do servidor
   Anthropic — refletem cobrança real. Skill não inventa nada além
   do que tá lá.
3. **Não traduz pra USD.** Pricing varia por modelo/plano/região e
   muda com o tempo. Token é a métrica honesta.
4. **Subagente conta separado.** Cada `.jsonl` em
   `<sessionId>/subagents/` é um subagente distinto. Skill agrega cada
   um e mostra subtotal.
5. **Apresenta, não comenta.** "Foi caro/barato" é juízo do user.

## Output esperado

Skill devolve o output literal do script Python. Não duplica, não
parafraseia. Formato:

```text
Relatório de tokens — sessão <id>
=================================
Project: <path>
Arquivo: <jsonl>

--- Agente principal ---
  Turnos: N
  input (não-cache):     ...
  input cache (criação): ...
  input cache (leitura): ...
  output:                ...
  TOTAL in:              ...
  TOTAL out:             ...
  Modelo: ...

--- Subagentes ---
  - [<tipo>] <id> — <descrição>
    Turnos: N
    ...
  SUBTOTAL (N subagentes): ...

--- Resumo ---
  Principal:  ... in / ... out
  Subagentes: ... in / ... out (N agente(s))
  TOTAL:      ... in / ... out
```

## Quando o relatório é especialmente útil

- Após uma sessão "README → setup" pra ver onde foi o token na
  primeira inicialização do projeto
- Comparar custo entre profile fibonacci vs lean ao executar a
  mesma task em sessões diferentes (eyeball: anota o relatório de
  cada uma)
- Antes de fechar sessão longa, pra ter ideia do consumo total
