#!/usr/bin/env python3
"""Commit message for a flake update (.github/workflows/flake-update.yml).

    report.py OLD_LOCK NEW_LOCK OLD_DIR NEW_DIR > message

OLD_DIR and NEW_DIR hold one inspect.nix result per desktop preset (<preset>.json), for the
configuration before and after the update. A preset that failed to evaluate has
<preset>.error instead. The first line is the summary ("updated X inputs, Y packages and Z options");
the body lists the inputs, packages, options and warnings that changed.
"""

import json
import sys
from datetime import datetime, timezone
from pathlib import Path

LIMIT = 150  # lines per section before "... and N more"


def lock_inputs(path):
    """Every locked node, keyed by its input path from the root (hecate/crane, ...)."""
    lock = json.loads(Path(path).read_text())
    nodes = lock["nodes"]
    out = {}

    def visit(node, prefix):
        for name, ref in nodes[node].get("inputs", {}).items():
            if isinstance(ref, list):  # follows another input
                continue
            key = "/".join(prefix + [name])
            if key in out:
                continue
            out[key] = nodes[ref].get("locked", {})
            visit(ref, prefix + [name])

    visit(lock.get("root", "root"), [])
    return out


def describe_rev(locked):
    rev = locked.get("rev", "")[:7] or locked.get("narHash", "")[7:15]
    when = locked.get("lastModified")
    if when:
        rev += " (" + datetime.fromtimestamp(when, timezone.utc).strftime("%Y-%m-%d") + ")"
    return rev


def compare_url(old, new):
    if old.get("type") == "github" and old.get("rev") and new.get("rev"):
        return f"https://github.com/{new['owner']}/{new['repo']}/compare/{old['rev'][:12]}...{new['rev'][:12]}"
    return ""


def load(directory):
    """preset -> inspect.nix result, plus the presets that failed."""
    results, failed = {}, {}
    for f in sorted(Path(directory).glob("*.json")):
        results[f.stem] = json.loads(f.read_text())
    for suffix in ("error", "broken"):
        for f in sorted(Path(directory).glob(f"*.{suffix}")):
            lines = f.read_text().strip().splitlines()
            failed[f.stem] = ([lines[0]] if suffix == "error" else ["does not evaluate:"]) + lines[-1:]
    return results, failed


def merged(results, key):
    """name -> {value: [presets]} across presets."""
    out = {}
    for preset, r in results.items():
        for name, value in r.get(key, {}).items():
            out.setdefault(name, {}).setdefault(value, []).append(preset)
    return out


def show(values, all_presets):
    parts = []
    for value, presets in sorted(values.items()):
        tag = "" if sorted(presets) == sorted(all_presets) else f" [{', '.join(sorted(presets))}]"
        parts.append(f"{value}{tag}")
    return " | ".join(parts)


def diff(old, new, presets):
    """Lines describing what changed between two merged maps."""
    lines = []
    for name in sorted(set(old) | set(new)):
        a, b = old.get(name), new.get(name)
        if a == b:
            continue
        if a is None:
            lines.append(f"+ {name}: {show(b, presets)}")
        elif b is None:
            lines.append(f"- {name}: {show(a, presets)}")
        else:
            lines.append(f"~ {name}: {show(a, presets)} -> {show(b, presets)}")
    return lines


def plural(n, word):
    return f"{n} {word}{'s' * (n != 1)}"


def section(title, lines):
    if not lines:
        return []
    shown = lines[:LIMIT]
    if len(lines) > LIMIT:
        shown.append(f"... and {len(lines) - LIMIT} more")
    return ["", f"{title}:", *shown]


def main():
    old_lock, new_lock, old_dir, new_dir = sys.argv[1:5]

    old_inputs, new_inputs = lock_inputs(old_lock), lock_inputs(new_lock)
    input_lines = []
    for name in sorted(set(old_inputs) | set(new_inputs)):
        a, b = old_inputs.get(name), new_inputs.get(name)
        if a == b:
            continue
        if a is None:
            input_lines.append(f"+ {name}: {describe_rev(b)}")
        elif b is None:
            input_lines.append(f"- {name}")
        else:
            url = compare_url(a, b)
            input_lines.append(f"~ {name}: {describe_rev(a)} -> {describe_rev(b)}" + (f"\n    {url}" if url else ""))

    old, old_failed = load(old_dir)
    new, new_failed = load(new_dir)
    presets = sorted(set(old) | set(new) | set(old_failed) | set(new_failed))
    compared = sorted(set(old) & set(new))
    old_c = {p: old[p] for p in compared}
    new_c = {p: new[p] for p in compared}

    package_lines = diff(merged(old_c, "packages"), merged(new_c, "packages"), compared)
    option_lines = diff(merged(old_c, "options"), merged(new_c, "options"), compared)
    old_warnings = {w for r in old_c.values() for w in r.get("warnings", [])}
    new_warnings = {w for r in new_c.values() for w in r.get("warnings", [])}
    warning_lines = [f"+ {w}" for w in sorted(new_warnings - old_warnings)]
    warning_lines += [f"- {w}" for w in sorted(old_warnings - new_warnings)]

    n_pkg, n_opt = len(package_lines), len(option_lines)
    body = [
        f"chore(flake): updated {plural(len(input_lines), 'input')}, {plural(n_pkg, 'package')} and "
        f"{plural(n_opt, 'option')}",
        "",
        f"{len(input_lines)} flake input{'s' * (len(input_lines) != 1)} changed. Packages and options are "
        f"compared across the desktop presets ({', '.join(compared) or 'none'}); a preset in "
        "brackets means the value only applies there.",
        "Packages: what is installed (system, users, Home Manager, fonts, kernel), by name.",
        "Options: every enabled `*.enable`, and the `*.package` of every enabled module.",
        "(+ added, - removed, ~ changed)",
    ]
    body += section("Inputs", input_lines)
    body += section("Packages", package_lines)
    body += section("Options", option_lines)
    body += section("Evaluation warnings", warning_lines)
    failures = [f"{p} (before the update): {' '.join(e)}" for p, e in old_failed.items()]
    failures += [f"{p} (after the update): {' '.join(e)}" for p, e in new_failed.items()]
    body += section("Presets left out of the comparison", failures)
    print("\n".join(body))


if __name__ == "__main__":
    main()
