#!/usr/bin/env bash
# Update every flake input; when at least one changed, commit flake.lock with a report of the
# packages and options that changed (report.py). Run from the repository root by
# .github/workflows/flake-update.yml. Writes `changed=true|false` to $GITHUB_OUTPUT.
set -euo pipefail

ROOT=$(pwd)
HERE="$ROOT/.github/flake-update"
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT
output() { echo "$1" >> "${GITHUB_OUTPUT:-/dev/null}"; }

cp flake.lock "$WORK/old.lock"
nix flake update
if cmp -s flake.lock "$WORK/old.lock"; then
    echo "No flake input changed; nothing to commit."
    output changed=false
    exit 0
fi
cp flake.lock "$WORK/new.lock"

# nixosConfigurations.cakeos needs gen/, which only exists on an installed machine: evaluate it
# once per desktop preset, the way build-vm.sh does, from a copy of the tree (gen/ is
# gitignored, so it has to be a path: flake rather than a git one).
mapfile -t PRESETS < <(find gen-presets -name '*.nix' ! -name '*-hardware.nix' -printf '%f\n' | sed 's/\.nix$//' | sort)
for side in old new; do
    mkdir -p "$WORK/$side"
    for preset in "${PRESETS[@]}"; do
        ws="$WORK/ws-$side-$preset"
        mkdir -p "$ws"
        git archive HEAD | tar -x -C "$ws"
        cp "$WORK/$side.lock" "$ws/flake.lock"
        mkdir -p "$ws/gen"
        cp "gen-presets/$preset.nix" "$ws/gen/cakeos.nix"
        cp gen-presets/cakeos-hardware.nix "$ws/gen/cakeos-hardware.nix"
        echo "::group::Evaluating $preset ($side inputs)"
        out="$WORK/$side/$preset"
        if nix eval --impure --json --no-write-lock-file \
            "path:$ws#nixosConfigurations.cakeos" \
            --apply "import $HERE/inspect.nix" > "$out.json" 2> "$out.log"; then
            echo "ok"
        else
            rm -f "$out.json"
            cat "$out.log"
            # The inspector reads more than a build does; whether the configuration itself
            # still evaluates is what decides if the update is safe.
            if nix eval --raw --no-write-lock-file \
                "path:$ws#nixosConfigurations.cakeos.config.system.build.toplevel.drvPath" \
                > /dev/null 2> "$out.build.log"; then
                { echo "report unavailable (the configuration itself evaluates):"; grep -v '^\s*$' "$out.log" | tail -n 3; } > "$out.error"
            else
                cat "$out.build.log"
                grep -v '^\s*$' "$out.build.log" | tail -n 20 > "$out.broken"
            fi
        fi
        echo "::endgroup::"
        rm -rf "$ws"
    done
done

# Never commit an update that breaks a configuration that evaluated before it.
broken=()
for preset in "${PRESETS[@]}"; do
    if [ ! -e "$WORK/old/$preset.broken" ] && [ -e "$WORK/new/$preset.broken" ]; then
        broken+=("$preset")
    fi
done
if [ ${#broken[@]} -gt 0 ]; then
    for preset in "${broken[@]}"; do
        echo "::error title=$preset no longer evaluates::$(tail -n 3 "$WORK/new/$preset.broken" | tr '\n' ' ')"
    done
    echo "The updated inputs break ${broken[*]}; flake.lock is not committed."
    exit 1
fi

python3 "$HERE/report.py" "$WORK/old.lock" "$WORK/new.lock" "$WORK/old" "$WORK/new" > "$WORK/message"
cat "$WORK/message"
{
    echo '```'
    cat "$WORK/message"
    echo '```'
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"

git add flake.lock
git -c user.name="github-actions[bot]" \
    -c user.email="41898282+github-actions[bot]@users.noreply.github.com" \
    commit -q -F "$WORK/message"
# Another push may have landed while this ran; flake.lock merges cleanly unless it changed too.
for attempt in 1 2 3; do
    if git push origin HEAD:main; then
        output changed=true
        exit 0
    fi
    git pull --rebase origin main
done
echo "Could not push the update."
exit 1
