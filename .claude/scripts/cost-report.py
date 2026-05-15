#!/usr/bin/env python3
"""
Token usage report for a Claude Code session.

Parses the session jsonl + subagent jsonls under
`~/.claude/projects/<encoded-cwd>/` and prints a token usage summary
split between main agent and subagents.

Usage:
    python .claude/scripts/cost-report.py
    python .claude/scripts/cost-report.py --session <sessionId>
    python .claude/scripts/cost-report.py --project /path/to/projects/<dir>
    python .claude/scripts/cost-report.py --markdown          # output em md (default texto)

Sem args, usa a sessão mais recente do projeto cuja cwd casa com o $PWD.
"""

import argparse
import json
import os
import re
import sys
from collections import defaultdict
from pathlib import Path

# Garante UTF-8 no stdout (Windows console default é cp1252 e quebra acentos).
try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass


def encode_cwd(cwd: str) -> str:
    """Encode cwd path the way Claude Code names its projects dir."""
    return re.sub(r"[^a-zA-Z0-9]", "-", cwd)


def find_project_dir(cwd: str | None = None) -> Path | None:
    cwd = cwd or os.getcwd()
    encoded = encode_cwd(cwd)
    base = Path(os.path.expanduser("~/.claude/projects"))
    direct = base / encoded
    if direct.is_dir():
        return direct
    return None


def find_session_jsonl(project_dir: Path, session_id: str | None = None) -> Path | None:
    if session_id:
        p = project_dir / f"{session_id}.jsonl"
        return p if p.exists() else None
    jsonls = sorted(project_dir.glob("*.jsonl"), key=lambda p: p.stat().st_mtime, reverse=True)
    return jsonls[0] if jsonls else None


def sum_usage(jsonl_path: Path, only_sidechain: bool | None = None):
    """Sum usage tokens. only_sidechain=False = só principal, True = só sidechain, None = tudo."""
    totals = defaultdict(int)
    by_model = defaultdict(lambda: defaultdict(int))
    turns = 0
    with open(jsonl_path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            if d.get("type") != "assistant":
                continue
            if only_sidechain is not None and d.get("isSidechain") != only_sidechain:
                continue
            usage = d.get("message", {}).get("usage")
            if not usage:
                continue
            model = d.get("message", {}).get("model", "unknown")
            for key in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens"):
                v = usage.get(key, 0) or 0
                totals[key] += v
                by_model[model][key] += v
            turns += 1
    return dict(totals), {m: dict(b) for m, b in by_model.items()}, turns


def total_in(totals: dict) -> int:
    return (
        totals.get("input_tokens", 0)
        + totals.get("cache_creation_input_tokens", 0)
        + totals.get("cache_read_input_tokens", 0)
    )


def total_out(totals: dict) -> int:
    return totals.get("output_tokens", 0)


def fmt(n: int) -> str:
    if n >= 1_000_000:
        return f"{n / 1_000_000:.2f}M"
    if n >= 1_000:
        return f"{n / 1_000:.1f}k"
    return str(n)


def section(title: str, markdown: bool) -> str:
    return f"## {title}" if markdown else f"\n--- {title} ---"


def render_totals(totals: dict, indent: str = "  ") -> str:
    lines = []
    lines.append(f"{indent}input (não-cache):           {fmt(totals.get('input_tokens', 0))}")
    lines.append(f"{indent}input cache (criação):       {fmt(totals.get('cache_creation_input_tokens', 0))}")
    lines.append(f"{indent}input cache (leitura):       {fmt(totals.get('cache_read_input_tokens', 0))}")
    lines.append(f"{indent}output:                      {fmt(totals.get('output_tokens', 0))}")
    lines.append(f"{indent}TOTAL in:                    {fmt(total_in(totals))}")
    lines.append(f"{indent}TOTAL out:                   {fmt(total_out(totals))}")
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Relatório de tokens da sessão atual do Claude Code.")
    parser.add_argument("--session", help="Session ID (sem .jsonl) — default: mais recente")
    parser.add_argument("--project", help="Path absoluto do project dir (default: encoded de $PWD)")
    parser.add_argument("--cwd", help="cwd a usar pra encontrar project dir (default: $PWD)")
    parser.add_argument("--markdown", action="store_true", help="Formato markdown")
    args = parser.parse_args()

    if args.project:
        project_dir = Path(args.project)
    else:
        project_dir = find_project_dir(args.cwd)

    if not project_dir or not project_dir.is_dir():
        cwd = args.cwd or os.getcwd()
        print(f"Erro: project dir não encontrado.", file=sys.stderr)
        print(f"  cwd: {cwd}", file=sys.stderr)
        print(f"  encoded: {encode_cwd(cwd)}", file=sys.stderr)
        print(f"  procurado em: ~/.claude/projects/", file=sys.stderr)
        return 1

    session_jsonl = find_session_jsonl(project_dir, args.session)
    if not session_jsonl:
        print(f"Erro: nenhum .jsonl encontrado em {project_dir}.", file=sys.stderr)
        return 1

    session_id = session_jsonl.stem
    out = []

    title = f"Relatório de tokens — sessão {session_id}"
    if args.markdown:
        out.append(f"# {title}\n")
    else:
        out.append(title)
        out.append("=" * len(title))
    out.append(f"Project: {project_dir}")
    out.append(f"Arquivo: {session_jsonl.name}")

    # Principal
    main_totals, main_models, main_turns = sum_usage(session_jsonl, only_sidechain=False)
    out.append(section("Agente principal", args.markdown))
    if main_turns == 0:
        out.append("  (sem turnos no transcript)")
    else:
        out.append(f"  Turnos: {main_turns}")
        out.append(render_totals(main_totals))
        if len(main_models) > 1:
            out.append("  Por modelo:")
            for m, b in main_models.items():
                out.append(f"    {m}: in={fmt(total_in(b))} / out={fmt(total_out(b))}")
        elif main_models:
            (m,) = main_models.keys()
            out.append(f"  Modelo: {m}")

    # Subagentes
    subagents_dir = project_dir / session_id / "subagents"
    sub_totals = defaultdict(int)
    sub_count = 0
    out.append(section("Subagentes", args.markdown))
    if subagents_dir.is_dir():
        agents = sorted(subagents_dir.glob("agent-*.jsonl"))
    else:
        agents = []
    if not agents:
        out.append("  (nenhum subagente nesta sessão)")
    else:
        for agent_path in agents:
            meta_path = agent_path.with_suffix(".meta.json")
            meta = {}
            if meta_path.exists():
                try:
                    meta = json.loads(meta_path.read_text(encoding="utf-8"))
                except Exception:
                    pass
            agent_totals, agent_models, agent_turns = sum_usage(agent_path)
            agent_type = meta.get("agentType", "?")
            desc = meta.get("description", "")
            sub_count += 1
            for k, v in agent_totals.items():
                sub_totals[k] += v

            label = f"  - [{agent_type}] {agent_path.stem}"
            if desc:
                label += f" — {desc[:60]}"
            out.append(label)
            out.append(f"    Turnos: {agent_turns}")
            out.append(render_totals(agent_totals, indent="    "))
            if agent_models:
                models_list = ", ".join(agent_models.keys())
                out.append(f"    Modelo(s): {models_list}")
        out.append("")
        out.append(f"  SUBTOTAL ({sub_count} subagente(s)):")
        out.append(render_totals(dict(sub_totals)))

    # Resumo
    grand_in = total_in(main_totals) + total_in(dict(sub_totals))
    grand_out = total_out(main_totals) + total_out(dict(sub_totals))
    out.append(section("Resumo", args.markdown))
    out.append(f"  Principal:    {fmt(total_in(main_totals))} in / {fmt(total_out(main_totals))} out")
    if sub_count:
        out.append(f"  Subagentes:   {fmt(total_in(dict(sub_totals)))} in / {fmt(total_out(dict(sub_totals)))} out  ({sub_count} agente(s))")
    out.append(f"  TOTAL:        {fmt(grand_in)} in / {fmt(grand_out)} out")

    print("\n".join(out))
    return 0


if __name__ == "__main__":
    sys.exit(main())
