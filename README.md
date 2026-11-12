# AI Logo Poker Chips

3D-printable, two-color poker chips with AI company logos, generated from a
single parametric OpenSCAD model. Drop any single-color SVG into `logos/` and
you get a chip for it.

| | | | | | | |
|:-:|:-:|:-:|:-:|:-:|:-:|:-:|
| ![ChatGPT](previews/chip_chatgpt.png) | ![Claude](previews/chip_claude-ai-symbol.png) | ![DeepSeek](previews/chip_deepseek.png) | ![Gemini](previews/chip_google-gemini-sparkle.png) | ![Muse](previews/chip_muse.png) | ![Ollama](previews/chip_ollama-icon.png) | ![OpenRouter](previews/chip_openrouter.png) |
| ChatGPT | Claude | DeepSeek | Gemini | Muse | Ollama | OpenRouter |

Chips are standard casino size: 39 mm across and 3.3 mm thick. The logo and a
decorative ring are inlaid flush on both faces, mirrored on the back so they
read correctly when flipped. Notches around the edge give the classic chip
look.

## Printing

Ready-made STLs are in `stl/`. Each logo has three files:

| File | Use |
|---|---|
| `<logo>_body.stl` | the chip in the main color |
| `<logo>_inlay.stl` | logo and ring in the second color |
| `<logo>_all.stl` | both merged; for previewing only |

### PrusaSlicer (MMU, XL, or another multi-material printer)

1. Import `<logo>_body.stl` and `<logo>_inlay.stl` together. When asked
   whether to load them as a single object with multiple parts, choose
   **Yes** so they stay aligned.
2. In the object list, set the body to extruder 1 and the inlay to
   extruder 2.
3. Use 0.2 mm layers with a 0.2 mm first layer, so the 0.6 mm inlay is
   exactly 3 layers per face.
4. Turn off **Interface shells** (Print Settings › Multiple Extruders ›
   Advanced).
5. Optional: to cut purge waste, set the object's wipe options to
   **Wipe into this object's infill**.
6. Put several chips on one plate. Color changes happen per layer, so
   waste per chip drops as you add more.

With a single-extruder printer you can still print these using manual
filament swaps (`M600` as the tool-change G-code). Each plate needs about
10–12 swaps, since the top and bottom 0.6 mm of each chip mix both colors.

## Building from source

Requires [OpenSCAD](https://openscad.org/) (tested with 2021.01).

```bash
./build.sh                                      # rebuild every logo in logos/
./build.sh muse chatgpt                         # rebuild only these logos
SCAD_ARGS='-D face_style="relief"' ./build.sh   # override model parameters
```

The script writes STLs to `stl/` and preview images to `previews/`. It finds
OpenSCAD on your `PATH` or in `/Applications`; set `OPENSCAD=/path/to/openscad`
to use another copy.

You can also open `poker_chip.scad` in OpenSCAD and adjust parameters in the
Customizer.

### Main parameters

| Parameter | Default | Meaning |
|---|---|---|
| `logo_file` | `logos/claude-ai-symbol.svg` | SVG to put on the chip |
| `logo_w`, `logo_h` | 22, 22 | box the logo is scaled to fit, keeping its proportions |
| `face_style` | `flush` | `flush` gives flat faces with an inlaid logo. `relief` gives a raised logo in a recessed face, which looks embossed but is much slower to print. |
| `inlay_depth` | 0.6 | inlay thickness per face (flush style) |
| `part` | `all` | `body`, `inlay`, or `all` |
| `chip_d`, `chip_h` | 39, 3.3 | chip diameter and thickness |
| `edge_spots` | 8 | number of edge notches |
| `both_sides` | true | put the logo on both faces |

## Adding a logo

1. Save a single-color SVG to `logos/`. Colors and gradients are ignored;
   only the shape is used.
2. Run `./build.sh <name>`, where `<name>` is the file name without
   `.svg`.
3. Check `previews/chip_<name>.png`. A broken SVG still builds without
   errors, just with no logo.

If OpenSCAD mangles the logo, the SVG may use compact arc syntax that
OpenSCAD 2021.01 misreads. Fix it with:

```bash
python3 normalize_svg_path.py logos/in.svg logos/out.svg
```

## License

The code and models are released under the [WTFPL](LICENSE.md). The logos
are trademarks of their respective owners and are not covered by this
license. This is a fan project and is not affiliated with or endorsed by
any of those companies.
