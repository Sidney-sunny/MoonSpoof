---
name: MoonSpoof
description: A matte glyph examination bench for inspectable Unicode evidence.
colors:
  primary: "#78dce8"
  signal-hover: "#a9edf4"
  ground: "#0e1824"
  surface: "#152333"
  line: "#526a80"
  ink: "#eef5fa"
  muted: "#b0c4d5"
  selected: "#203c50"
  error: "#ffb7c3"
  code-string: "#bddbdc"
  brand-paper: "#f4f2f6"
typography:
  display:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "clamp(50px, 5.8vw, 80px)"
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: "-.04em"
  headline:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "36px"
    fontWeight: 500
    lineHeight: 1.2
    letterSpacing: "-.035em"
  title:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "15px"
    fontWeight: 600
  body:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "13px"
    lineHeight: 1.9
  label:
    fontFamily: "Manrope, ui-sans-serif, sans-serif"
    fontSize: "11px"
  mono:
    fontFamily: "Cascadia Code, SFMono-Regular, Consolas, monospace"
  specimen:
    fontFamily: "Georgia, Times New Roman, serif"
    fontSize: "clamp(40px, 5.7vw, 80px)"
    lineHeight: 1.6
    letterSpacing: "-.04em"
rounded:
  square: "0"
spacing:
  compact: "8px"
  small: "12px"
  base: "16px"
  mobile-inset: "20px"
  inset: "24px"
  wide-inset: "32px"
  section-gap: "64px"
components:
  button-primary:
    backgroundColor: "{colors.primary}"
    textColor: "{colors.ground}"
    rounded: "{rounded.square}"
    padding: "14px 18px"
    width: "100%"
  button-primary-hover:
    backgroundColor: "{colors.signal-hover}"
  button-language:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "0 12px"
  button-text:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
  input-identifier:
    backgroundColor: "{colors.ground}"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
    padding: "12px 14px"
    width: "100%"
  tab:
    backgroundColor: "transparent"
    textColor: "{colors.muted}"
    padding: "22px 0"
  tab-selected:
    textColor: "{colors.ink}"
  container:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.square}"
  glyph-selector:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
    rounded: "{rounded.square}"
  candidate-glyph:
    backgroundColor: "transparent"
    textColor: "{colors.ink}"
  candidate-glyph-hover:
    backgroundColor: "{colors.selected}"
  evidence-row-selected:
    backgroundColor: "{colors.selected}"
---

[Chinese](docs/DESIGN_zh.md)

# Design System: MoonSpoof

## Overview

**Creative North Star: "The Glyph Examination Bench"**

The Glyph Examination Bench treats character shapes as specimens and codepoints as evidence. Its world is dark, matte, ruled, and deliberately square. Large serif glyphs create the visual question; precise sans-serif controls and monospace diagnostics make the answer inspectable. The density suits a judge examining working code rather than a promotional catalogue.

Ink blue gives the canvas and working surfaces a quiet tonal separation. Ice cyan connects actions, selected glyphs, and findings; cold white carries primary text. The owner subsequently commissioned a sculpted deep-grape MS identity and matching pearl-white README banner; the showcase retains its existing interface palette. This implementation uses no decorative imagery, gradient surfaces, or shadows.

**Key Characteristics:**

- Matte ink-blue surfaces with ice-cyan actions and evidence.
- Ruled rows, square controls, and flat tonal depth.
- Manrope interface type, serif specimens, and monospace source data.
- Chinese and English share the same controls and retained working state.

This record covers the shipped web showcase. Tokens were extracted from [the stylesheet](playground/src/style.css), [the app](playground/src/App.jsx), [components](playground/src/components), and [locale handling](playground/src/i18n.jsx), then checked against the four final Chinese/English desktop/mobile captures in `.impeccable/review`. Captures establish resting appearance; source establishes keyboard behavior and state retention. No new runtime or conformance verification was performed for this documentation pass. [Tailwind's semantic colors](playground/tailwind.config.js) reference the same CSS custom properties, and its font families match the implemented sans-serif and monospace stacks.

## Colors

The palette is a cool matte work surface with a single cyan action and evidence accent. The frontmatter preserves the exact CSS values; names below describe their assignments. The sidecar's eight-step OKLCH ramps are synthesized swatch previews, not additional shipped palette tokens.

### Primary

- **Ice Cyan** (`primary`, sourced from `--signal`): primary actions, mapped glyphs, findings, selected tab rules, caret, text selection, focus outlines, and restrained heading emphasis.
- **Pale Ice** (`signal-hover`): hover feedback on enabled primary actions.

### Neutral

- **Ink Blue** (`ground`): page canvas and recessed editable fields.
- **Bench Blue** (`surface`): workbench, code sample, and MoonSpoof comparison column.
- **Steel Rule** (`line`): structural borders, specimen separation, table rules, and scrollbars.
- **Cold White** (`ink`): primary text, active tab text, and unmodified specimens.
- **Mist Blue** (`muted`): explanatory copy, labels, inactive navigation, and diagnostic metadata.
- **Selected Slate** (`selected`): the selected character evidence row and candidate glyph hover background.
- **Error Rose** (`error`): worker and task error text; it is a functional exception to the main accent.
- **Code Mist** (`code-string`): string literals in the MoonBit sample.

**The Shared Signal Rule.** Use the same ice cyan for actions, selected evidence, and findings; retain text and selection marks so color never carries the meaning alone.

## Typography

**Display Font:** Manrope, with the CSS sans-serif fallback stack. Local Latin files supply weights 400, 500, 600, and 700.

**Body Font:** Manrope with system fallback for unsupported characters. The Chinese hero explicitly adds Microsoft YaHei and PingFang SC.

**Label/Mono Font:** Cascadia Code, SFMono-Regular, Consolas, monospace. These are installed-font fallbacks, not bundled font guarantees.

**Specimen Font:** Georgia, Times New Roman, serif. The comparison aside and focused character also use Georgia.

**Character:** The sans-serif interface stays measured and compact while serif specimens expose shape. Monospace identifies stored values, codepoints, source, and runtime metadata; tabular numerals support scanning.

### Hierarchy

- **Display:** medium weight (500), fluid English hero, tight tracking. At the mobile breakpoint the English hero becomes fixed (52px). Chinese uses its own fluid range (`clamp(44px, 5vw, 70px)`), line-height (1.2), and tracking (-.02em); that more specific locale rule remains active on mobile.
- **Headline:** medium weight (500), section headings; compact screens reduce the recurring section heading size (30px).
- **Title:** semibold (600), form and evidence headings. Verdict titles use line-height (1.5).
- **Body:** explanatory section copy. Intro copy is larger (15px, line-height 1.7); it reduces on mobile (13px). Implementation copy is constrained (43ch), and the implementation-boundary paragraph is wider (85ch).
- **Label / Mono:** compact labels and data, with secondary metadata at smaller observed sizes (10px). These are existing density choices, not a universal minimum text-size rule.

**The Specimen Rule.** Serif glyphs are the subject being examined; keep identifiers and codepoints readable in their established roles rather than converting the specimen treatment into decorative icons.

## Layout

The showcase uses one centered content container, capped (1280px) with desktop side space (48px). The actual width formula is `min(1280px, calc(100% - 96px))`. At the medium breakpoint (1100px) the container uses side space (28px); at the compact breakpoint (760px), side space becomes (18px). The body retains a minimum width (320px).

The reusable spatial grammar is one bordered working surface split by rules, with compact internal insets and larger space between sections. The pair-comparison bench has two columns (`minmax(0, 1.15fr)` and `minmax(0, 1fr)`); compact layouts stack specimen above controls and replace the vertical division with a horizontal rule. Other two-column explanatory and tool regions also stack at the compact breakpoint. Desktop section separation (104px) reduces to (64px); these are observed showcase values, not a mandate for every future surface. The page's exact section sequence and composition remain in [the surface brief](.impeccable/surfaces/playground-index-html.md).

Evidence and comparison tables preserve useful column widths (minimums 580px and 940px). Overflow stays inside a named horizontal region. A localized cue appears only while columns overflow; that region becomes keyboard-focusable. Labels, prose, and source code wrap instead of widening the page. The header omits the demo anchor and version on compact screens while preserving comparison, source, and language controls.

## Elevation & Depth

There are no box shadows. Depth comes from the ink-blue ground, a lighter working surface, selected-row tone, and thin steel rules. Editable fields sit visually inside the bench by returning to the ground tone. Hover changes color without lifting controls or adding scale motion.

**The Flat Bench Rule.** Build hierarchy with tone, rules, and spacing; preserve flat surfaces and square controls.

## Shapes

Reusable controls and containers have square corners. Borders and table rules are thin (1px); tab and specimen selection use a stronger underline (2px). Focus is an external cyan outline (2px) with separation (5px), not an inset glow. Glyph-select targets retain an outlined square; native checkboxes use their browser shape with cyan accent.

The canonical identity is the sculpted MS logo in `docs/assets/logo.png`, copied to `playground/public/logo.png`. The transparent grape artwork sits on `--brand-paper` in the header and footer (48px desktop, 36px compact); the same PNG is the favicon. The README uses the matching `docs/assets/banner.png`. These generated assets replace the previous crescent-and-twin-loop identity at the owner's request. Do not trace, stretch or recolor the supplied artwork. The showcase uses inline SVG arrows for navigation and execution, and mathematical equality symbols as comparison content.

## Components

### Buttons

Execution controls are square, wide, and explicit. The primary action spans its form, uses ice cyan against ink blue, and places a literal SVG arrow at the far edge. Its padding is (14px 18px), minimum height (48px), type size (12px), and weight (700). Enabled hover moves to Pale Ice with a background-color transition (160ms ease). Focus uses the shared external outline. Disabled actions show wait cursor and reduced opacity (.55).

The language button is transparent with a steel border, compact horizontal padding (12px), and minimum height (40px); hover turns its border and text cyan. Retry is an underlined text button with minimum height (40px). There is no authored pressed transform or elevation state.

### Cards / Containers

The workbench and source sample are ruled containers, not floating cards. They use Bench Blue, square edges, and a steel border (1px). Separators divide navigation, content, evidence, and footer. Internal desktop insets generally use (24px–36px); mobile bench and tool insets use (20px). Error copy uses Error Rose and an alert role, without adding a separate ornamental container.

### Inputs / Fields

Identifiers and textareas use the monospace stack, Cold White on Ink Blue, a steel border, square corners, padding (12px 14px), and minimum height (46px). Identifier text remains left-to-right and disables spellcheck/autocomplete. Select controls retain native behavior and use Manrope (12px). Textareas resize vertically and use line-height (1.8). Labels are visible and associated with controls; focus uses the shared cyan outline. Native checkbox accent is cyan.

### Navigation

The header uses compact text links and the preserved raster wordmark. Workbench tabs use muted text at rest, white text and a cyan underline when selected, and white text on hover. Desktop tabs have semibold type (12px), minimum height (48px), and vertical padding (22px). Compact tabs distribute across the row, with smaller type (10px), padding (18px), and a width cap (78px). The engine status wraps below the tab row when required.

Tabs expose `tablist`, `tab`, and `tabpanel` roles. Arrow Left/Right wrap selection; Home/End select endpoints. Only the selected tab is in the tab sequence, and panels are separately focusable. All panels stay mounted while hidden, retaining each tool's inputs. A skip link appears on keyboard focus and targets the workbench.

The locale button switches the full translated interface, updates document language/title, and persists `moonspoof-language` when storage is available. Chinese is the default when no English preference is stored. Switching languages does not recreate the tool tree. This is locale persistence, not persisted analysis inputs across page reloads.

### Glyph Evidence

Selecting a candidate glyph or its evidence-table button updates the same selected index. The serif specimen receives a cyan underline, the evidence row receives Selected Slate, and the focus rail shows glyph, codepoint, script, and prototype while the verdict remains visible. Hovering a candidate glyph uses that same Selected Slate background without changing selection; the evidence-table selector instead uses a cyan border and text. Glyph buttons expose their position/codepoint and pressed state. Invisible characters, bidi controls, and all C0/C1 controls receive the functional empty-set marker instead of disappearing. C0/C1 controls receive a textual Control label; the risk description for Safe is No elevated risk signal, which does not imply that no descriptive rule was triggered.

The selected specimen underline reveals over (220ms) with `cubic-bezier(.16, 1, .3, 1)` only when reduced motion is not requested. Findings and errors are textual status/alert outputs. The browser engine runs in a local module worker; the UI exposes readiness, retry, and busy states. The design must continue to display actual results rather than fabricated diagnostics.

### Tables

Tables use collapsed borders, ruled rows, and visible column labels. Character rows provide an outlined selector (minimum 36px square); selected and hovered selectors turn cyan. Semantic captions and column/row header scopes retain context. The overflow cue and named focusable region are part of this component's compact-screen behavior, not decorative helper text.

## Do's and Don'ts

### Do:

- **Do** reuse the matte ink-blue palette and the shared cyan action/evidence signal.
- **Do** preserve square controls, ruled grouping, and flat tonal depth.
- **Do** preserve the supplied sculpted MS raster logo and its asset identity.
- **Do** keep both locales, keyboard navigation, visible focus, retained tool state, and overflow cues intact.
- **Do** distinguish visual specimens from monospace stored data and expose real diagnostic evidence.

### Don't:

- **Don't** replace the supplied MS logo with a newly drawn symbol or revive the rejected amber palette.
- **Don't** add glow, gradient surfaces, or shadows to this matte world.
- **Don't** hide overflowing table columns without the named scroll region and its localized cue.
- **Don't** add decorative starter chips or fabricate diagnostic/performance claims.
