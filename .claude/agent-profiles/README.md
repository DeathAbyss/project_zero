# Agent profiles

Conjuntos alternativos de agentes pro Claude Code. O profile ativo
fica copiado em `.claude/agents/` (que é o que o Claude Code lê).

## Profiles

### `fibonacci/` (atual default)

4 agentes especializados por disciplina. Decompõe trabalho por papel
e despacha em pipeline.

- **analista** — read-only, investiga e devolve relatório
- **dev** — implementa a partir de spec
- **escriba** — atualiza docs
- **operador** — planejador Opus de demandas complexas

Filosofia: cada agente é melhor naquilo, mesmo pagando o pedágio de
hand-off entre eles.

### `lean/` (alternativa)

2 agentes generalistas, segmentados por *natureza do trabalho* (não
por disciplina).

- **worker** — executor generalista (busca + edita + doc na mesma cabeça)
- **architect** — planejador Opus de demandas vagas/arquiteturais

Filosofia: o pedágio de hand-off entre disciplinas custa mais que o
ganho de especialização. Worker absorve o trabalho do analista + dev +
escriba; architect substitui operador com decomposição mais simples
(só "principal faz" vs "worker faz").

## Agentes de harness (sempre presentes)

Independente do profile ativo, os 3 agentes do gate de verificação
ficam em todos os profiles:

- **seguranca** — audita o diff por vuln/authz/input/segredo
- **testes** — roda a suíte, avalia cobertura
- **protecao-dados** — checa privacidade (LGPD/GDPR via config)

São ortogonais ao eixo planejar-vs-implementar dos profiles. Ao criar
profile novo, inclua os 3 (clonar de `fibonacci` ou `lean` já traz).
Doutrina do gate: [`../docs/05-harness.md`](../docs/05-harness.md).

## Trocar profile

```bash
# Ver profile ativo + disponíveis
bash .claude/switch-agents.sh

# Trocar
bash .claude/switch-agents.sh lean
bash .claude/switch-agents.sh fibonacci
```

O script:
1. Apaga os `.md` em `.claude/agents/`
2. Copia os `.md` do profile escolhido pra `.claude/agents/`
3. Atualiza `.claude/agent-profiles/.active` com o nome do profile

## Criar profile novo

```bash
# Criar vazio (popular manual depois)
bash .claude/switch-agents.sh create meu-perfil

# Criar clonado de outro (pra divergir aos poucos)
bash .claude/switch-agents.sh create experimental fibonacci
```

Validações do script:
- Nome só aceita `[a-zA-Z0-9._-]+` (sem espaço, sem `/`, sem `..`)
- Recusa se profile com mesmo nome já existe
- Recusa se profile-base no clone não existe
- Criação **não ativa** automaticamente — rode `switch-agents.sh <nome>`
  depois pra ativar

## Atalho via skill (linguagem natural)

A skill [`switch-agent-profile`](../skills/switch-agent-profile/SKILL.md)
traduz frases tipo:

- "qual profile tá ativo?" → roda listagem
- "troca pro lean" → roda switch
- "cria profile X baseado em fibonacci" → roda create clonado

Útil pra não decorar a sintaxe do script.

## Editar agentes

**Sempre edite em `agent-profiles/<profile>/`**, não em `.claude/agents/`.
Os arquivos em `.claude/agents/` são cópias que o switch sobrescreve.

Depois de editar, re-rode `bash .claude/switch-agents.sh <profile>` se
o profile editado for o ativo, pra propagar a mudança.

## Quando alternar

Os profiles testam hipóteses diferentes. Roda cada um por uma janela
real de trabalho (≥ 1 semana se der) e observa:

| Sinal | Indica que `lean` ganha | Indica que `fibonacci` ganha |
|---|---|---|
| Principal hesita "qual agente?" | sim | não |
| Hand-offs custam mais que poupam | sim | não |
| Especialização gera output melhor (relatórios mais limpos do analista, doc mais consistente do escriba) | não | sim |
| Demandas frequentemente cruzam 2+ disciplinas | sim | não |

Não existe profile "certo" — existe o que casa com o seu workflow.
