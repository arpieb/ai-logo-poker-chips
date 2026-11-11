#!/bin/bash
# Regenerate chip STLs and previews from poker_chip.scad.
#
#   ./build.sh                  build every logos/*.svg
#   ./build.sh muse chatgpt     build only these logos (basenames in logos/)
#   JOBS=2 ./build.sh           limit parallel OpenSCAD runs (default: CPU count)
#   OPENSCAD=/path/to/openscad ./build.sh
#
# For each logo it writes stl/<logo>_{all,body,inlay}.stl and
# previews/chip_<logo>.png. Extra OpenSCAD args can go in SCAD_ARGS,
# e.g. SCAD_ARGS='-D face_style="relief"' ./build.sh

set -u
cd "$(dirname "$0")"

if [ -z "${OPENSCAD:-}" ]; then
    if command -v openscad >/dev/null 2>&1; then
        OPENSCAD=openscad
    elif [ -x /Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD ]; then
        OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD
    else
        echo "OpenSCAD not found; set OPENSCAD=/path/to/openscad" >&2
        exit 1
    fi
fi
export OPENSCAD
export SCAD_ARGS="${SCAD_ARGS:-}"
JOBS="${JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || nproc 2>/dev/null || echo 4)}"

if [ $# -gt 0 ]; then
    logos="$*"
else
    logos=$(cd logos && ls *.svg | sed 's/\.svg$//')
fi
for logo in $logos; do
    [ -f "logos/$logo.svg" ] || { echo "No such logo: logos/$logo.svg" >&2; exit 1; }
done

mkdir -p stl previews
LOGDIR=$(mktemp -d)
export LOGDIR

# Runs one OpenSCAD job: <logo> <part|preview>
run_one() {
    logo=$1 what=$2
    if [ "$what" = preview ]; then
        out="previews/chip_$logo.png"
        set -- -o "$out" --imgsize=500,500 -D "logo_file=\"logos/$logo.svg\""
    else
        out="stl/${logo}_$what.stl"
        set -- -o "$out" -D "logo_file=\"logos/$logo.svg\"" -D "part=\"$what\""
    fi
    log="$LOGDIR/${logo}_$what.log"
    # SCAD_ARGS is intentionally word-split
    if "$OPENSCAD" "$@" $SCAD_ARGS poker_chip.scad >"$log" 2>&1 \
        && ! grep -q 'ERROR' "$log"; then
        echo "ok    $out"
    else
        echo "FAIL  $out  (log: $log)"
        grep -E 'ERROR|WARNING' "$log" | sed 's/^/      /'
        return 1
    fi
}
export -f run_one

start=$(date +%s)
for logo in $logos; do
    for what in body inlay all preview; do
        echo "$logo $what"
    done
done | xargs -P "$JOBS" -n 2 bash -c 'run_one "$@"' _
status=$?

echo "Done in $(( $(date +%s) - start ))s"
if [ $status -ne 0 ]; then
    echo "Some builds failed; logs kept in $LOGDIR" >&2
    exit 1
fi
rm -rf "$LOGDIR"
