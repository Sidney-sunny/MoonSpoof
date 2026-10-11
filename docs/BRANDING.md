# MoonSpoof brand

[Chinese](BRANDING_zh.md)

The canonical identity is the sculpted MS ligature with MoonSpoof lettering in `docs/assets/logo.png`. The lunar negative space and differing contours connect the mark to Unicode lookalikes. The matching README banner is `docs/assets/banner.png`. Both were generated with the built-in image tool, following the owner's request for a different style and rejection of the vermilion concept.

The brand direction is deep grape `#49304F` on pearl white `#F4F2F6`, with pale lilac `#E4DEE9` in the banner. These are generation palette references; preserve the delivered artwork rather than assuming every raster pixel equals a flat token. The logo retains transparency. Exact generation prompts are embedded in the PNG metadata.

The showcase copies the logo into `playground/public/logo.png` for its header, footer and favicon. Header/footer logo images sit on a pearl-white CSS ground to keep the grape artwork legible on the dark interface. Do not stretch, recolor or replace the supplied mark. The previous raster assets are recoverable from Git history.

The owner requested a distinct showcase palette because the earlier amber treatment matched another project. The current matte palette is ink blue `#0e1824`, surface `#152333`, cold white `#eef5fa`, muted blue `#b0c4d5`, ice cyan `#78dce8`, and structural line `#526a80`. Cyan marks actions, selected characters and findings. Error text is `#ffb7c3`; states also carry text or selection indicators. No neon glow, gradients or decorative cards.

The showcase is a glyph examination bench: large paired specimens, editable comparison, direct verdict, selectable codepoint evidence, sourced competitor matrix and explicit implementation boundaries. It is implemented in React with the JavaScript MoonBit target in a worker, and supports Chinese and English. Detailed tokens, breakpoints, focus and motion rules belong in [DESIGN.md](../DESIGN.md).
