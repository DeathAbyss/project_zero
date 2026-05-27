# Design — agent-teams-upgrade

## Modelo mental: subagents vs teammates

```
SUBAGENT (atual)                TEAMMATE (novo onde cabe)
════════════════                ════════════════════════════
Lead                            Lead (team lead)
 └─ Agent(prompt)                ├─ spawn teammate A
     └─ trabalha                 ├─ spawn teammate B
     └─ retorna resultado        └─ spawn teammate C
          ↓ sequencial                ↓↓↓ simultâneo
     próximo Agent(...)          A, B, C trabalham em paralelo
                                 cada um envia SendMessage ao lead
                                 lead sintetiza

Quando usar subagent: tarefa focada, resultado importa,
                      sem necessidade de comunicação entre workers.
Quando usar teammate: paralelismo real importa; workers precisam
                      coordenar ou comunicar descobertas.
Custo: teammates = N × context window. Mais caro. Usar onde o ganho
       de tempo/qualidade justifica.
```

## 1. sdd-apply (nova skill)

Preenche a lacuna entre propose e archive:

```
sdd-propose → [sdd-apply] → [gate] → sdd-archive
```

Responsabilidade: lê `tasks.md`, executa cada task usando o agente
certo (dev para código, escriba para doc), marca `- [x]` ao concluir.
Não gerencia o gate (isso é sdd-archive). Não re-propõe (isso é
sdd-propose).

Dúvida de design resolvida: sdd-apply despacha agentes como **subagents**
(não teammates) porque tasks.md tem dependências entre si e são
sequenciais por natureza. Paralelismo aqui causaria conflitos de arquivo.
Exceção: tasks explicitamente marcadas como `[parallel]` podem usar
teammates — deixar isso como opt-in futuro.

## 2. Harness gate paralelo

```
sdd-archive (hoje)              sdd-archive (novo)
══════════════════              ══════════════════
1. despacha seguranca           1. spawn teammate "seguranca"   ┐
   └─ espera veredito           2. spawn teammate "testes"      ├─ paralelo
2. despacha testes              3. spawn teammate "protecao"    ┘
   └─ espera veredito           4. aguarda 3 TeamateIdle
3. despacha protecao            5. check-harness-gate.sh já lê
   └─ espera veredito              harness/ — sem mudança aqui
4. roda code-review skill       6. roda code-review skill
5. check gate                   7. check gate
```

Cada agente do harness grava em arquivo diferente:
- `harness/security.md` ← seguranca
- `harness/tests.md`    ← testes
- `harness/data-protection.md` ← protecao-dados

Zero conflito de arquivo. Lógica de gate (check-harness-gate.sh) não muda.

Custo: 3x context window vs 1 por vez. Justificado: gate é o gargalo
do SDD flow; redução de ~3x no wall-clock time.

## 3. operador como orquestrador

Mudança semântica: o `operador` antes era "planner que devolve ao
principal e sai". Agora tem dois modos:

```
MODO PLANNER (mantido, default)
  Principal → operador(demanda)
            ← plano estruturado
            → principal despacha baseado no plano

MODO ORQUESTRADOR (novo, quando principal o spawna como teammate)
  Principal spawna operador como teammate
  operador recebe demanda
  operador usa SendMessage + task list pra coordenar outros teammates
  operador reporta síntese ao lead quando concluir
```

O body do agente explica os dois modos. A restrição antiga ("não
despacha sub-agentes") virou: "em modo subagent, devolve plano ao
principal; em modo teammate, pode coordenar via SendMessage".

## 4. Padrão SendMessage nos agentes

Todos os agentes ganham seção curta no body:

```markdown
## Quando usado como teammate

SendMessage disponível automaticamente (mesmo com tools restrito).
Reportar ao lead quando concluir ou se precisar de input:
  - Conclusão: reportar via SendMessage, não só gravar arquivo
  - Bloqueio: SendMessage ao lead descrevendo o impasse
  - Descoberta crítica: SendMessage imediato, não espera o fim
```

Harness agents (seguranca, testes, protecao-dados) ganham instrução
extra: ao gravar o veredito, enviar SendMessage ao lead com 1 linha de
sumário do status (PASS/N/A/BLOCKED + motivo em frase).

## 5. sdd-explore com teammates paralelos

```
sdd-explore (hoje)              sdd-explore (novo)
══════════════════              ══════════════════
1. despacha analista            1. spawn teammate "analista"   ┐
   └─ espera relatório             (explora codebase)          ├─ paralelo
2. despacha architect           2. spawn teammate "architect"  ┘
   └─ espera proposta              (avalia arquitetura)
3. compila dossiê               3. aguarda ambos
                                4. recebe SendMessage de cada um
                                5. compila dossiê com inputs paralelos
```

Custo: 2 context windows paralelos. Justificado para sdd-explore porque
a fase de exploração é exatamente o caso de uso "pesquisa com múltiplas
perspectivas simultâneas" que a docs recomendam para Agent Teams.

## 6. Hooks Agent Teams

Três hooks novos:

| Hook | Quando | Uso no project_zero |
|---|---|---|
| `TeammateIdle` | Harness agent vai encerrar | Valida que gravou harness/*.md antes de idle |
| `TaskCompleted` | Task vai ser marcada completa | Valida formato do resultado |
| `TaskCreated` | Task nova sendo criada | (N/A por agora — não bloqueia criação) |

`TeammateIdle` é o mais importante: garante que `seguranca`/`testes`/
`protecao-dados` não ficam idle sem ter gravado o veredito.

Script: `~/.claude/hooks/check-teammate-verdict.sh`
- Lê `TEAMMATE_NAME` do contexto do hook
- Se nome ∈ {seguranca, pz-seguranca, testes, pz-testes, protecao-dados}:
  procura `harness/*.md` correspondente no change-dir ativo
- Se não encontrou: exit 2 (bloqueia idle, envia feedback)
- Senão: exit 0

## Sequenciamento de tasks

```
T1 (sdd-apply skill)       — sem deps, standalone
T2 (operador orchestrator) — sem deps, 1 arquivo
T3 (SendMessage em todos)  — sem deps entre si, podem ser paralelas
T4 (sdd-archive paralelo)  — depende de T3 (agentes documentados primeiro)
T5 (sdd-explore paralelo)  — depende de T3
T6 (hooks Agent Teams)     — sem deps de T1-T5
T7 (setup-global.sh)       — depende de T1-T6 (copia tudo que foi criado)
```
