# DMG installer

Mode: Operate. Extend the user-pinned Apple-native design into the requested drag-to-Applications installer. Use a real Finder disk-image window, the existing app icon, and a real Applications link. Code-led, precisely specified narrow task; no concept seed or comp round.

## Direction contract

THESIS: Install Untiring in one familiar drag, without a separate installer application or setup wizard.

OWN-WORLD: White background, the existing blue sun icon, native Applications folder, and a light gray arrow, directly following the user's image 2 reference. Finder owns window chrome, icon labels, selection, dragging, and keyboard behavior. No other text or decoration.

STORY: See Untiring, drag it to Applications, then open the installed copy. License activation and menu-bar onboarding remain inside the app.

FIRST VIEWPORT: A compact 520-by-260-point Finder content area. Two 96-point icons at (130, 112) and (390, 112), a centered horizontal arrow, and native filenames beneath. No headings, instruction paragraphs, footer, cards, badges, or extra files.

FORM: User-specified native drag-to-Applications convention, inherited Apple visual identity. No seed applies. The only motion is Finder's actual drag and copy interaction.

FINISH: Finish review disposition is **ship**, with no material fixes. The implemented surface and verification limits are recorded below. This ordinary extension preserves the incumbent `DESIGN.md` and `.impeccable/design.json`; the static Finder background introduces no app UI tokens.

Constraints: Reuse the signed, notarized 0.12.1 build 16 app unchanged. Verify the mounted Finder layout, the Applications link, app signature and ticket. Sign, notarize, staple, and publish the DMG as an additional release asset without changing the ZIP or Sparkle feed.

## Implemented surface

[`script/build_dmg.py`](../../script/build_dmg.py) sets the content area to 520 × 260 logical points and places the real app and `/Applications` link at the contracted coordinates with 96-point icons. The volume is titled “Install Untiring.” Finder supplies the existing app icon, system Applications folder, native filenames, selection, and installation interaction. Keep these real items and their compact arrangement intact.

[`script/create_dmg_background.swift`](../../script/create_dmg_background.swift) draws only white artwork and a centered, light gray, round-ended arrow. The generated TIFF carries 520 × 260 and 1040 × 520 pixel representations at 72 and 144 DPI, plus an embedded image description identifying the source script, the user's minimal reference, and Finder's ownership of icons and labels. These fixed artwork values are local to the installer, not a change to the app's adaptive colors or Liquid Glass system.

## Evidence and review

Documentation checked `PRODUCT.md`, `DESIGN.md`, `.impeccable/design.json`, this direction contract, both implementation scripts, and the [native Finder capture](../review/installer.png). The capture is a valid 1040 × 564 JPEG stored with a `.png` filename; it shows the mounted installer with two clear native filenames, separated icons, the centered arrow, and no additional content or clipping. Its dark window chrome belongs to Finder. The capture supports the requested composition on the reviewed Mac; it is not an app-rendered mockup.

The finish review returned **ship**, with no material fixes. Preserve the minimal two-item content area and native behavior. This documentation pass did not exercise dragging/copying, keyboard installation, VoiceOver, other appearances, or other macOS versions. Packaging, signing, and notarization evidence belongs to the release workflow and was not duplicated in this documentation pass.

The installer requires no shared design-system change. One pre-existing documentation mismatch was observed outside this surface: the sidecar's “Options menu trigger” description omits “Check for Updates…”, which is present in `SessionPanel.swift` and documented in `DESIGN.md`. It is reported here without changing the incumbent files or app code.
