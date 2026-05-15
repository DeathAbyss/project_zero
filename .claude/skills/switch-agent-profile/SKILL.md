---
name: switch-agent-profile
description: |
  Gerencia profiles de agentes em `.claude/agent-profiles/` chamando
  `.claude/switch-agents.sh`. Faz três coisas: listar profile ativo +
  disponíveis, trocar de profile, criar profile novo (vazio ou clonado
  de outro).

  Triggers manuais (user fala):
    - Listar: "qual profile tá ativo?", "lista os profiles", "tá rodando qual?"
    - Trocar: "troca pro lean", "muda profile pra fibonacci", "ativa o X"
    - Criar: "cria profile X", "duplica fibonacci como X", "cria profile X baseado em lean"
    - Slash: "/switch-profile", "/switch-agent-profile"

  NÃO usa pra: editar conteúdo de um agente (faça direto em
  `.claude/agent-profiles/<profile>/<agente>.md`); deletar profile
  (não suportado — apaga manual); decidir qual profile usar (devolve
  pro user, skill executa, não recomenda).

  NÃO roda proativamente. Só sob comando explícito.
---

# switch-agent-profile

Wrapper natural-language em cima de `.claude/switch-agents.sh`. O
script faz o trabalho real (apaga `.md` em `.claude/agents/`, copia do
profile escolhido, atualiza `.claude/agent-profiles/.active`, cria
diretórios novos). Esta skill traduz pedidos em PT-BR pra invocação
correta e reporta o resultado.

## Quando rodar

**Sob demanda** (user fala):

| Intenção | Frases típicas | Ação |
|---|---|---|
| Listar profiles + ver ativo | "qual profile tá ativo?", "lista os profiles", "tá rodando qual?" | `bash .claude/switch-agents.sh` (sem argumento) |
| Trocar pra profile específico | "troca pro lean", "muda pra fibonacci", "ativa o X" | `bash .claude/switch-agents.sh <profile>` |
| Trocar com nome incerto | "muda os agentes" (sem nome) | Roda listagem e pergunta qual |
| Criar profile vazio | "cria profile X", "novo profile chamado X" | `bash .claude/switch-agents.sh create <X>` |
| Criar profile clonado | "duplica fibonacci como X", "cria profile X baseado em lean", "copia o lean como Y" | `bash .claude/switch-agents.sh create <X> <base>` |

**Pula quando**:
- User só perguntou *sobre* os profiles (filosofia, quando usar cada) — isso é conversa, não execução. Responda direto sem rodar a skill.
- User pediu pra editar um agente — não é troca/criação, é edição direta no profile.
- User pediu pra deletar profile — não suportado pelo script. Devolva: "Apaga manual com `rm -rf .claude/agent-profiles/<nome>/`."

## Workflow

### 1. Identifique a intenção

Da fala do user, classifique em **listar**, **trocar**, **criar vazio**
ou **criar clonado**. Pra criar, extrai:
- **Nome do novo profile** (obrigatório, deve casar `^[a-zA-Z0-9._-]+$`)
- **Profile base** (opcional — "baseado em X", "duplica X como Y",
  "copia X")

Se nome contém espaço, caractere especial ou path (`/`, `\`, `..`) →
não chuta. Pede ao user pra reformular com nome válido.

### 2. Valide antes de executar

**Pra trocar**: confirma que profile alvo existe.
```bash
ls .claude/agent-profiles/<nome>/
```
Se não existe → mostra disponíveis e pergunta.

**Pra criar**: confirma que profile alvo NÃO existe.
```bash
ls .claude/agent-profiles/<novo-nome>/ 2>/dev/null
```
Se já existe → para. Skill não sobrescreve profile existente.

**Pra criar clonado**: confirma que base existe.

### 3. Execute

```bash
# Listar
bash .claude/switch-agents.sh

# Trocar
bash .claude/switch-agents.sh <profile>

# Criar vazio
bash .claude/switch-agents.sh create <nome>

# Criar clonado
bash .claude/switch-agents.sh create <nome> <base>
```

O script já cuida de:
- Validar nomes
- Recusar overwrite
- Listar disponíveis em caso de erro
- Tolerar profile vazio na troca (não quebra)

### 4. Reporte ao user

**Pra troca:**
```text
Profile trocado: <antigo> → <novo>
Agentes ativos:
  - <agente1>
  - <agente2>
```

**Pra criação:**
```text
Profile '<nome>' criado em .claude/agent-profiles/<nome>/.
[Se clonado:] Arquivos copiados de '<base>':
  - <agente1>.md
  - <agente2>.md
[Se vazio:] Vazio — popule manualmente.

Pra ativar: bash .claude/switch-agents.sh <nome>
```

**Pra listagem:** passa o output do script direto.

### 5. Pós-troca (informacional, só em troca real)

Se trocou entre profiles canônicos, 1 linha sobre o que muda na prática:

- `fibonacci` → `lean`: "Delegação agora é binária (worker pra executar, architect pra planejar). Sem hand-off entre disciplinas."
- `lean` → `fibonacci`: "Voltou pros 4 agentes especializados (analista/dev/escriba/operador). Hand-off entre disciplinas reativado."
- Outros: não inventa descrição. Aponta `.claude/agent-profiles/README.md`.

### 6. Pós-criação (sugestões úteis)

Se criou profile **vazio**, sugere ao user:
- "Quer que eu popule com stubs de agentes? Me diz os nomes (ex.: `worker.md`, `reviewer.md`) que eu crio com YAML frontmatter mínimo."
- Ou apontar pra copiar de outro: `cp .claude/agent-profiles/fibonacci/*.md .claude/agent-profiles/<novo>/`

Se criou profile **clonado**, sugere:
- "Os agentes são cópias do '<base>'. Editar em `.claude/agent-profiles/<nome>/` pra divergir. Quer ativar agora? (sim/não)"

**Não ativa automaticamente** após criar — espera o user pedir.

## Regras duras

1. **Não edita conteúdo de agente.** Skill só GERENCIA profiles
   (trocar/criar/listar). Edição vai em `agent-profiles/<profile>/<agente>.md`.
2. **Não sobrescreve profile existente.** Se user pede "cria fibonacci"
   e ele já existe, para e avisa. Pra "resetar", user apaga manual e recria.
3. **Não deleta profile.** Operação destrutiva fica fora do escopo —
   user faz `rm -rf` manual com consciência.
4. **Não recomenda profile.** Se user pergunta "qual devo usar?",
   aponta a tabela em `.claude/agent-profiles/README.md`.
5. **Não ativa profile recém-criado.** Criação e ativação são passos
   separados — user decide quando ativar.
6. **Idempotente em troca.** Trocar pro profile que já é o ativo não
   é erro — roda mesmo assim (re-sincroniza caso `.md` do profile
   source tenha sido editado).

## Output esperado

Reportar em formato compacto. Não duplicar o output do script — se o
script já imprimiu o suficiente, só ecoa as linhas relevantes.

```text
switch-agent-profile:
  Ação: <listar | trocar | criar-vazio | criar-clonado>
  [Pra troca] <antigo> → <novo> | Agentes: <lista>
  [Pra criar] Profile '<nome>' criado [clonado de '<base>' | vazio]
  [Pra listar] Ativo: <nome> | Disponíveis: <lista>
```
