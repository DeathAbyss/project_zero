# Convenções — single source of truth

Este arquivo é a fonte canônica de regras que se repetiriam em vários
docs e agentes do template. Skills, agents e CLAUDE.md devem
**referenciar** este arquivo em vez de duplicar conteúdo.

> Se você está editando uma regra que aparece aqui, edite **somente
> aqui** e ajuste os outros lugares pra apontar pra cá. Duplicar regra
> = drift garantido.

## Regras pra docs compactos (project_map, GLOSSARY, decisions, etc.)

### Tamanho

- 50-150 linhas por doc.
- Passar de 200 → dividir.
- Ficar < 30 linhas → considera anexar a outro doc.

### Forma

1. **Tabela > parágrafo** sempre que comparar/listar 3+ itens.
2. **`file:line` em tudo.** Sem isso, doc vira prosa. Confira o número
   antes de salvar.
3. **Cross-link > duplicar.** Se a info já existe em outro doc, linka
   em vez de copiar.
4. **Sem exemplos de código.** Código vive no fonte. Trazer pra doc =
   drift garantido.
5. **Sem prosa explicativa longa.** Frase curta funcional > parágrafo
   descritivo.
6. **Sem emoji, sem ASCII art, sem divisor decorativo** (`====`,
   `----`). IDE mostra estrutura por dobramento.

### Naming

- Lowercase, inglês, descritivo: `auth.md`, `routing.md`, `payments.md`.
- Numerar quando há vários do mesmo tipo: `domain_1.md`,
  `domain_2.md`.
- Evitar `THE_AUTH_FLOW.md`, `auth-system-explained.md`.

## Regras pra código

### Comentários

- Default é **não escrever** comentário.
- Só quando o "porquê" é não-óbvio (gotcha histórico, workaround pra
  bug específico, hidden constraint, edge case surpreendente).
- Se apagar não confunde ninguém, o comentário é ruído.
- Sem emoji, sem ASCII art, sem doc-comment trivial (JSDoc/Javadoc/
  docstring/KDoc que só repete o nome), sem TODO órfão (sem
  owner/condição), sem comentário-tag (`// fix bug`, `// added by X`).

### Estilo

- Nomes em inglês.
- Arquivos pequenos — passou de ~400 linhas, considera dividir.

## Regras pra saída de IA (texto pro usuário)

- Sem prefácio ("Entendi seu pedido, vou agora...", "Ótima pergunta!").
- Sem banner/header decorativo em resposta curta.
- Sem confirmação trivial entre passos.
- Sem resumo redundante do diff.
- Cap natural: 1-2 frases por turno na maioria dos casos.
- Markdown só quando agrega (3+ itens comparáveis → tabela).
- Português direto + técnico. Sem suavização ("talvez seria
  interessante..."), sem qualificadores defensivos.

## Padrão do briefing entre agentes

Formato canônico que operador entrega e analista repassa pros próximos
agentes (dev/escriba/etc.):

```text
## Objetivo
<1-2 frases — o que precisa acontecer>

## Paths relevantes
- `path/file.ext:linha` — papel desse arquivo
- ...

## Constraints
- <regra dura que não pode quebrar>
- ...

## Saída esperada
<o que o principal vai fazer com o output deste agente>
```

Briefing inline no `prompt` do `Agent()` é o canal padrão. Custa zero
extra. Fallback em arquivo (`.claude/tmp/briefing_<task>.md`) só pra
briefing > 5k tokens.
