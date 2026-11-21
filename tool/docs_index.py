#!/usr/bin/env python3
"""Régénère docs/INDEX.md : une ligne par note (lien, titre, première phrase).

Sert de sommaire à Claude : il lit l'index, puis seulement les notes utiles.
Usage : python3 tool/docs_index.py
"""
import collections
import os
import re

ROOT = "docs"
MAX = 110


def describe(lines):
    for line in lines:
        s = line.strip()
        if not s or s.startswith(("#", "|", "```", "<", "---", ">", "!", "[", "==")):
            continue
        s = re.sub(r"[*_`]", "", s).lstrip("-* ").strip()
        if len(s) < 25:
            continue
        return s if len(s) <= MAX else s[: MAX - 3].rsplit(" ", 1)[0] + "…"
    return ""


def main():
    groups = collections.OrderedDict()
    for dp, dn, fn in sorted(os.walk(ROOT)):
        dn.sort()
        for f in sorted(fn):
            if not f.endswith(".md") or f == "INDEX.md":
                continue
            path = os.path.join(dp, f)
            rel = os.path.relpath(path, ROOT)
            lines = open(path, encoding="utf-8", errors="ignore").read().splitlines()
            title = next((l.lstrip("#").strip() for l in lines if l.startswith("#")), f[:-3])
            groups.setdefault(os.path.dirname(rel) or "(racine)", []).append(
                (rel, title, describe(lines)))
    out = [
        "# Sommaire de la documentation", "",
        "Lire ce sommaire d'abord, puis seulement la ou les notes utiles. "
        "Une ligne par note : lien, titre, première phrase.",
        "Régénérer après ajout de notes : `python3 tool/docs_index.py`.", "",
    ]
    for group, items in groups.items():
        out += [f"## {group}", ""]
        out += [f"- [{t}]({r})" + (f" — {d}" if d else "") for r, t, d in items]
        out.append("")
    with open(os.path.join(ROOT, "INDEX.md"), "w", encoding="utf-8") as fh:
        fh.write("\n".join(out))
    print(f"docs/INDEX.md : {sum(len(v) for v in groups.values())} notes")


if __name__ == "__main__":
    main()
