// Parametric poker chip with an SVG logo inlaid on both faces.
// Pick the logo with logo_file; build.sh builds one chip per logos/*.svg.
// Units: mm. Standard casino chip: 39 mm x 3.3 mm.
//
// Tip for multi-color printing: set `part` to "body" and "inlay"
// and export each as its own STL, then assign colors in your slicer.

/* [Chip] */
chip_d        = 39;     // chip diameter
chip_h        = 3.3;    // chip thickness
rim_w         = 3.2;    // width of raised outer rim
face_recess   = 0.5;    // relief style only: how deep the face is recessed inside the rim (per side)
edge_spots    = 8;      // number of edge inserts/notches
spot_w        = 5;      // width of each edge spot
spot_depth    = 0.8;    // how far the spots cut into the edge

/* [Logo] */
logo_file     = "logos/claude-ai-symbol.svg";  // SVG logo to place on the chip (path relative to this file)
logo_h        = 22;     // max logo height
logo_w        = 22;     // max logo width (logo is scaled uniformly to fit in logo_w x logo_h)
face_style    = "flush"; // [flush, relief]
// flush:  flat faces; logo is inlaid flush, only inlay_depth deep. Fast to slice/print,
//         because the chip core is plain solid discs with no logo-shaped skin layers.
// relief: raised logo inside a recessed face. Looks embossed, but the slicer adds
//         logo-shaped top/bottom skins under the recessed floor through most of the chip.
inlay_depth   = 0.6;    // flush style only: inlay thickness per face (aim for 2-3 layers)
logo_raise    = 0.5;    // relief style only: logo height above the recessed face (= face_recess keeps chips stackable)
ring_inset    = 1.2;    // gap between rim and the decorative inner ring
ring_w        = 0.6;    // decorative inner ring width
both_sides    = true;   // put the logo on both faces

/* [Output] */
part = "all";           // [all, body, inlay]

$fn = 96;

// ---------------------------------------------------------------
// Logo: any single-color SVG (kept in logos/).
// Centered on its bounding box and scaled uniformly (aspect kept) to the
// largest size that fits inside a logo_w x logo_h box.
//
// Notes:
// - OpenSCAD 2021.01 misreads SVG arcs written with packed flags
//   (e.g. "a1 1 0 01 2 3"); run such files through
//   normalize_svg_path.py first so the numbers are spaced out.
// - The tiny offset() grow/shrink below cleans up near-duplicate
//   points that some SVGs (e.g. the ChatGPT mark) produce, which
//   otherwise fail extrusion with "mesh is not closed".
// ---------------------------------------------------------------
module logo_2d() {
    offset(delta = 0.01) offset(delta = -0.01)
        fit_2d(logo_w, logo_h)
            // normalize to mm scale, then clean, before fit_2d's 3D step
            offset(delta = 0.01) offset(delta = -0.01)
                resize([0, logo_h], auto = true)
                    import(logo_file, center = true);
}

// Uniformly scale a centered 2D child to fit within w x h.
// OpenSCAD 2021 can't measure a shape, and resize() with both dimensions
// set stretches it. Workaround: resize the child together with a helper
// copy (rotated 90 deg, scaled [w/h, h/w]) on a separate Z level. The
// helper makes the combined bounding box force the same scale on X and Y,
// min(w/child_w, h/child_h). Then a cut at z=0 keeps only the child.
module fit_2d(w, h) {
    projection(cut = true)
        resize([w, h, 0])
            union() {
                translate([0, 0, -0.5]) linear_extrude(1) children();
                translate([0, 0, 5]) linear_extrude(1)
                    scale([w / h, h / w]) rotate(90) children();
            }
}

// ---------------------------------------------------------------
// Chip geometry
// ---------------------------------------------------------------
face_r = chip_d / 2 - rim_w;

module edge_spot_cutters() {
    for (i = [0 : edge_spots - 1])
        rotate([0, 0, i * 360 / edge_spots])
            translate([chip_d / 2 - spot_depth, -spot_w / 2, -1])
                cube([spot_depth + 1, spot_w, chip_h + 2]);
}

module face_recesses() {
    // top
    translate([0, 0, chip_h - face_recess])
        cylinder(r = face_r, h = face_recess + 1);
    // bottom
    translate([0, 0, -1])
        cylinder(r = face_r, h = face_recess + 1);
}

// 2D artwork for one face: logo + decorative ring
module face_art_2d() {
    logo_2d();
    difference() {
        circle(r = face_r - ring_inset);
        circle(r = face_r - ring_inset - ring_w);
    }
}

// Places a 2D shape on the top face and (mirrored so it reads correctly
// when the chip is flipped) on the bottom face, each `depth` thick.
// `extra` extends it outward past the chip surface, for clean cutting.
module on_faces(depth, extra = 0) {
    translate([0, 0, chip_h - depth]) linear_extrude(depth + extra) children();
    if (both_sides)
        translate([0, 0, -extra]) linear_extrude(depth + extra)
            mirror([1, 0, 0]) children();
}

module chip_blank() {
    difference() {
        // body with a small chamfer on both edges
        hull() {
            translate([0, 0, 0.4]) cylinder(d = chip_d, h = chip_h - 0.8);
            cylinder(d = chip_d - 0.8, h = chip_h);
        }
        edge_spot_cutters();
    }
}

module chip_body() {
    difference() {
        chip_blank();
        if (face_style == "relief") face_recesses();
        else on_faces(inlay_depth, extra = 1) face_art_2d();
    }
}

module inlay() {
    if (face_style == "relief") {
        // raised art sitting on the recessed face floor
        translate([0, 0, chip_h - face_recess])
            linear_extrude(logo_raise) face_art_2d();
        if (both_sides)
            translate([0, 0, face_recess - logo_raise])
                linear_extrude(logo_raise) mirror([1, 0, 0]) face_art_2d();
    } else {
        on_faces(inlay_depth) face_art_2d();
    }
}

if (part == "all") {
    color("crimson") chip_body();
    color("white")   inlay();
} else if (part == "body") {
    chip_body();
} else if (part == "inlay") {
    inlay();
}
