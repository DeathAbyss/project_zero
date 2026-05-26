# SESSION_LOCK — coordenação de sessões paralelas

> Use quando rodar mais de uma sessão do agente no mesmo projeto ao
> mesmo tempo. Cada sessão **reclama escopo + arquivos** antes de
> editar. Quem chega segundo lê este arquivo e respeita ou pede pra
> trocar.

Se você só roda uma sessão por vez, este arquivo é overhead — pode
apagar. Vale a pena quando:
- Trabalho de UI rolando em paralelo com refactor de back
- Sessão "longa" (análise/planejamento) + sessão "curta" (bug fix)
- Múltiplas máquinas / pessoas no mesmo repo

---

## Formato de reivindicação

Toda sessão ativa adiciona uma seção como esta no topo da lista:

```markdown
### Sessão A — <timestamp ISO> — <username>

**Escopo**: descrição em 1 linha do que está fazendo.
**Arquivos reservados**:
- `path/to/file_a.ext`
- `path/to/file_b.ext`
**Estimativa**: <quanto tempo>
**Status**: ativa | pausada | concluída
```

Quando concluir, deixa por 1 dia como histórico e depois apaga.

---

## Regras

1. **Antes de editar**: ler este arquivo. Se outro escopo cobre um
   arquivo que você ia tocar, pergunta ao usuário antes.
2. **Reivindicar é barato; não reivindicar custa caro.** Mesmo pra
   sessão curta, gasta os 30 segundos.
3. **Sessões ativas no topo, concluídas embaixo.** Histórico ajuda a
   ver o que rolou recentemente.
4. **Conflito = pergunta humano.** Não tente resolver sozinho qual
   sessão tem precedência.

---

## Sessões ativas

_(nenhuma — adicione aqui ao começar)_

---

## Histórico recente

_(sessões concluídas nos últimos 1-2 dias)_
