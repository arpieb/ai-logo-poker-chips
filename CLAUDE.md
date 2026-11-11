# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single parametric OpenSCAD model, `poker_chip.scad`, that produces 39 × 3.3 mm poker chips with a logo inlaid on both faces. The logo comes from the `logo_file` parameter, and each SVG in `logos/` is one chip variant. Units are mm.

## Building

`./build.sh` regenerates the STLs and previews for every `logos/*.svg` in parallel, in about 1.5 minutes. `./build.sh muse chatgpt` builds only the named logos. `SCAD_ARGS='-D face_style="relief"' ./build.sh` passes extra parameters. It exits non-zero if any OpenSCAD run fails or logs `ERROR`.

To run a single part by hand: OpenSCAD is installed as an app, not on `PATH`, so call the binary directly. `logo_file` is relative to the `.scad` file.

```bash
OPENSCAD=/Applications/OpenSCAD.app/Contents/MacOS/OpenSCAD

# One part for one logo. Output naming: stl/<svg-basename>_<part>.stl
$OPENSCAD -o stl/chatgpt_body.stl -D 'logo_file="logos/chatgpt.svg"' -D 'part="body"' poker_chip.scad

# Preview PNG (previews/ uses 500x500, named chip_<svg-basename>.png)
$OPENSCAD -o previews/chip_chatgpt.png --imgsize=500,500 -D 'logo_file="logos/chatgpt.svg"' poker_chip.scad
```

Each logo gets three STLs: `part="body"` (chip without art), `part="inlay"` (logo plus decorative ring, both faces), and `part="all"` (both, colored, for previewing). Body and inlay are meant to be loaded together in a slicer as a multi-color print.

## Geometry notes

- `face_style` picks one of two face designs:
  - `flush` (default): flat faces. The body is a solid chip with logo-shaped pockets `inlay_depth` deep on each face, and the inlay fills them. This style exists for print speed. The only exposed surfaces are full discs, so the slicer's top/bottom skin layers are plain circles instead of logo shapes. In this mode the merged `part="all"` STL is just a plain disc, because STL stores no color.
  - `relief`: raised logo inside a recessed face. The face is recessed by `face_recess`, and the art rises `logo_raise` from that floor. Keep these two equal so chips stack. Downside: the slicer adds logo-shaped skins under the recessed floor through most of the 3.3 mm chip, which is slow to print.
- The bottom-face art is mirrored in X (`mirror([1,0,0])` in 2D) so it reads correctly once the chip is flipped. `on_faces()` handles placing art on both faces.
- `logo_2d()` scales logos uniformly to fit a `logo_w` × `logo_h` box (22 × 22 by default, inside the ring's ~29 mm inner diameter), so wide or tall SVGs need no per-logo overrides. OpenSCAD 2021 can't measure shapes, so `fit_2d()` resizes the logo together with a hidden helper copy on a separate Z level, then cuts the helper away.
- Before `fit_2d()`'s 3D step, the logo is resized to `logo_h` and cleaned with `offset(+0.01) offset(-0.01)` in 2D. The resize matters because SVGs import at very different raw sizes. The cleanup removes near-duplicate points (the ChatGPT SVG has these), without which extrusion fails with "mesh is not closed".

## Adding a new logo

- Drop the SVG into `logos/` and run `./build.sh <basename>`. Check the preview: a broken SVG still builds without errors, just with no logo.
- Use a single-color SVG. Fills and colors are ignored, and only the geometry is imported.
- OpenSCAD 2021.01 misreads arc commands written with packed flags (e.g. `a1 1 0 01 2 3`). Normalize those files first:
  `python3 normalize_svg_path.py in.svg out.svg`
  The script rewrites every `d=` attribute so each number is separated by a space.
