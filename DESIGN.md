---
name: WakeBee
description: Apple-native glass controls for manual awake sessions and settings.
typography:
  action:
    fontFamily: "system-ui"
    fontWeight: 600
  control:
    fontFamily: "system-ui"
    fontWeight: 500
  countdown:
    fontFamily: "system-ui"
    fontSize: "50pt"
    fontWeight: 300
  duration:
    fontFamily: "system-ui"
    fontSize: "48pt"
    fontWeight: 300
  end-time:
    fontFamily: "system-ui"
    fontSize: "38pt"
    fontWeight: 300
rounded:
  status-card: "20pt"
  options-surface: "18pt"
spacing:
  tight: "4pt"
  control-gap: "8pt"
  action-gap: "10pt"
  status-gap: "12pt"
  card-inset: "16pt"
  editor-gap: "18pt"
  panel-inset: "20pt"
  section-gap: "22pt"
  settings-inset: "24pt"
components:
  button-primary:
    typography: "{typography.action}"
  button-secondary:
    typography: "{typography.control}"
  preset:
    typography: "{typography.control}"
  session-panel:
    width: "360pt"
    padding: "{spacing.panel-inset}"
  closed-lid-card:
    rounded: "{rounded.status-card}"
    padding: "{spacing.card-inset}"
  settings-popover:
    width: "400pt"
    height: "600pt"
  settings-page:
    padding: "{spacing.settings-inset}"
  settings-section:
    rounded: "{rounded.status-card}"
    padding: "{spacing.card-inset}"
  glass-switch:
    width: "52pt"
    height: "30pt"
  glass-switch-thumb:
    size: "24pt"
  session-mode-picker:
    padding: "{spacing.tight}"
  session-mode-segment:
    height: "36pt"
  options-surface:
    rounded: "{rounded.options-surface}"
    width: "30pt"
    height: "30pt"
  duration-field:
    typography: "{typography.duration}"
    width: "96pt"
    height: "58pt"
  countdown:
    typography: "{typography.countdown}"
  end-time:
    typography: "{typography.end-time}"
---

# Design System: WakeBee

## Overview

**Creative North Star: "Apple-native Liquid Glass"**

A compact, calm control panel built from SwiftUI system controls, adaptive materials, SF Symbols, and clear status copy. Large, light numerals give the session its focus; glass capsules and a dedicated protection card keep actions and readiness easy to distinguish.

This records the shared menu-bar, Settings, and license activation system. Compact native Settings navigation leads to scrollable glass sections with concise labels; switches and session selection carry the same iOS-like control feel. Native SwiftUI rendering is authoritative: the sidecar's HTML previews are schematic references, not reproductions of Apple's glass renderer. Dimensions above are macOS logical points; system fonts resolve through the platform rather than bundled font files.

**Key Characteristics:**

- System typography with light, rounded session numerals.
- Adaptive glass sections, capsule actions, and glass switch thumbs.
- Compact composition with scrollable settings and fully wrapping status details.
- Text, symbols, and semantic color convey protection state together.

## Colors

The palette uses SwiftUI semantic styles and system colors; it has no app-defined fixed swatch palette. These dynamic APIs cannot be represented faithfully as fixed CSS color tokens, so the frontmatter deliberately omits color primitives.

Primary actions and selected presets use `Color.accentColor`, with the platform accent determining the actual tint. Confirmed lid protection uses `.green`; session notices and unconfirmed closed-lid status use the secondary foreground style, appearing as adaptive gray. Symbols and complete text retain the distinction between information and a warning. Primary, secondary, and tertiary foreground styles distinguish main content, supporting copy, and the duration separator. Settings can use system red for errors. The glass switch uses the accent for its on track, secondary color at 22% opacity for its off track, and native glass tinted with white at 85% opacity for the thumb. The session selector rests on quaternary style at 50% opacity; its selected label is primary and other labels are secondary.

**The Confirmation Rule.** Green protection status accompanies a confirmed helper state and explicit success copy; selecting the switch or starting a session alone cannot produce it.

## Typography

All text uses the system San Francisco family. `Font.headline` identifies WakeBee; `.body.weight(.semibold)` labels primary actions; `.callout` supports controls and session deadlines; `.caption` carries supporting labels and status detail. Settings section titles use `.headline`; license titles use `.title2.weight(.semibold)`. Settings rows use `.body`, with `.caption` supporting notes. These semantic roles remain system-sized rather than fixed in the token layer.

The frontmatter records the three explicit session-number sizes. Countdown and duration fields use `.system(..., weight: .light, design: .rounded)` with `.monospacedDigit()`. The editable Until clock uses AppKit's plain `.systemFont(ofSize: 38, weight: .light)`; preserve the native time segments rather than applying the rounded display treatment. Infinity symbols use the system SF Symbol at the corresponding display size. Keep units and hints in smaller secondary text.

## Layout

[SessionPanel](Sources/WakeBee/Views/SessionPanel.swift) owns a fixed-width panel with content-driven height, panel insets, and section spacing from the tokens. The sequence is header/options menu, setup or active session, any session/license message, then closed-lid status. Do not force a fixed height that clips error explanations.

[SessionSetupView](Sources/WakeBee/Views/SessionSetupView.swift) places `SessionModePicker` above the mode-specific editor and full-width Start action. [DurationEditor](Sources/WakeBee/Views/DurationEditor.swift) uses two centered, unboxed numeric fields and a three-column, two-row preset grid. [SessionEndTimeEditor](Sources/WakeBee/Views/SessionEndTimeEditor.swift) centers one editable native clock above a wrapping day/duration summary and a single row of three equal-width shortcuts, with 16-point vertical spacing. The active session replaces setup with the countdown or infinity state and an action row.

[SettingsView](Sources/WakeBee/Views/SettingsView.swift) stays in the status-item popover. A compact Back button and Settings label precede the text-only General / Closed Lid / License segmented picker. There is no window toolbar or traffic-light chrome. AppKit owns startup without a SwiftUI Settings or Window scene; `MenuBarController` owns the sole product presentation and explicitly prevents detachment.

All three Settings pages remain mounted in a `ZStack` within the settings-popover dimensions, preserving drafts and scroll positions across tabs. Unselected pages are transparent, disabled, excluded from hit testing, and hidden from accessibility; selection and settings routes share the existing `AppModel` value. General and Closed Lid use `SettingsScrollPage`: a `ScrollView`, glass group, page insets, and section spacing from the tokens. `SettingsGlassSection` places a headline above its glass content, with 10-point title/content spacing, 12-point row spacing, and wrapping optional detail below. General groups Startup, Sessions, Battery & Power, and Updates. Closed Lid separates live confirmation, battery limits, permanent safeguards, and a disclosure for longer guidance.

License is also scrollable in Settings. [LicenseView](Sources/WakeBee/Views/LicenseView.swift) uses a centered 48-point app icon, short heading and purchase-email guidance, followed by a native secure field, Activate action, and quiet purchase link. It uses 24-point page insets and section spacing, with a maximum content width of 480 points. The unactivated menu-bar license panel is 380 points wide with content-driven height, including any error or notice. These are native macOS layouts with no web responsive breakpoints.

## Elevation & Depth

[GlassComponents](Sources/WakeBee/Views/GlassComponents.swift) centralizes availability handling. On macOS 26+, `AwakeGlassGroup` wraps related controls in `GlassEffectContainer(spacing: 4)`. Its small sampling distance preserves the separation of adjacent controls. `awakeGlassSurface` uses `.glassEffect(.regular, in: RoundedRectangle(..., style: .continuous))`; earlier systems use `.regularMaterial`. The menu panel and Settings root backgrounds use `.ultraThinMaterial`. Settings and license sections reuse this same surface helper.

Buttons use tinted regular `GlassButtonStyle` for prominent actions on macOS 26.1+, `.glassProminent` on 26.0, and `.borderedProminent` before 26. Secondary buttons use `.glass` or the earlier `.bordered` fallback. Hover, focus, pressed, disabled, and material behavior belong to these native styles. There are no custom shadow tokens. The shared switch animates state with `.smooth(duration: 0.22)`; the session selector uses `.smooth(duration: 0.25)` scoped only to the horizontal offset of one persistent glass capsule, with zero vertical offset. Both omit those explicit animations when Reduce Motion is enabled. Selector labels remain stationary above the glass container. Mode selection changes the editor and panel content without an explicit animation; session messages and surrounding layout also remain outside these control animations. The sidecar records these native motion values; its CSS previews do not reproduce the platform glass animation.

**The Native Material Rule.** Reuse the availability-aware glass helpers; do not replace adaptive system rendering with fixed blur, painted highlights, or screenshot-derived colors.

## Shapes

Start, End, extension, and preset actions use `.buttonBorderShape(.capsule)`. The closed-lid card, settings and license sections, and options surface use the continuous rounded rectangles recorded in the tokens. Numeric fields have plain text-field styling; license entry retains a native rounded-border SecureField. The custom glass switch has a capsule track and circular thumb. Session-mode buttons and their surrounding track are capsules; the segment token records their fixed height. Native date fields, menu pickers, and availability fallbacks retain platform geometry.

## Components

- **Primary and secondary actions:** `awakeGlassButton(prominent:)` is the shared style API. Start and End are prominent; the selected duration preset is prominent; extension and other presets are secondary. Start is the default Return action. End uses Command-Return. Invalid or unlicensed starts are disabled.
- **Mode navigation:** [SessionModePicker](Sources/WakeBee/Views/SessionModePicker.swift) owns Timer / Until / Unlimited. On macOS 26+, a single persistent 36-point regular-glass capsule sits inside `GlassEffectContainer` and slides only horizontally between equal-width segments. Three native plain buttons are overlaid after the glass container, keeping their labels stationary and readable above it. Buttons are 36 points high, with 4-point gaps and outer inset producing a fixed 44-point track. Selected text is semibold and carries the selected accessibility trait; the group is named “Session type” and implements left/right move commands. Selection uses the short smooth transition described above, without changing glass effect identities. Earlier macOS uses the large native segmented `Picker`. Until uses the editable clock described below. Unlimited displays infinity and “Until you stop it.” Live mode selection and selected accessibility state were verified; Timer and Unlimited captures showed readable labels and an aligned track. Horizontal-only motion is constrained in source, without video-frame verification.
- **Glass switches:** [AwakeGlassToggleStyle](Sources/WakeBee/Views/GlassToggleStyle.swift) is shared by Settings and the protection status card. On macOS 26+ without Reduce Transparency, the track and thumb use the token dimensions; the thumb moves between horizontal offsets of −11 and +11 points. The thumb is rendered with native interactive regular glass, not a painted glass effect. A native Button owns keyboard activation; its hidden accessibility representation is replaced by one named toggle exposing On/Off and an action guarded by `isEnabled`. Disabled controls have 50% opacity. Earlier macOS or Reduce Transparency uses a large native `.switch`, preserving whether the label is shown. Geometry, accessibility declarations, and Reduce Motion handling are source-verified; keyboard and accessibility-setting behavior and motion quality have not been runtime-verified.
- **Settings sections and license:** `SettingsScrollPage`, `SettingsGlassSection`, and `SettingsValueRow` share the menu panel’s glass helpers and semantic text hierarchy. Value rows combine their label and value for accessibility. Section headings carry the header trait; details and errors wrap. License entry has no enclosing glass card; saved-license details retain a glass surface. Secure entry, native confirmation, busy states, and action restrictions remain available in both settings and the menu-bar panel.
- **Duration fields and presets:** `DurationEditor` owns plain hours/minutes text fields, their accessible labels and hints, six capsule presets, and the invalid-duration hint. Selection has an accessibility selected trait as well as visual emphasis.
- **Until clock and shortcuts:** [SessionEndTimeEditor](Sources/WakeBee/Views/SessionEndTimeEditor.swift) uses [NativeTimePicker](Sources/WakeBee/Support/NativeTimePicker.swift), an unbordered, transparent `NSDatePicker` with hour/minute segments, locale-appropriate AM/PM, and a native stepper. The 38-point light system font makes the clock itself editable without a duplicate display or numeric date field. Preserve its “End time” accessible label, native keyboard stepping, and intrinsic size within a minimum 60-point editor area. A secondary caption shows Today/Tomorrow and relative duration; invalid selections show “Choose a future time within 24 hours.” “In 30 min,” “In 1 hour,” and “In 2 hours” are secondary glass capsules with explicit accessibility hints. Calendar-based next-occurrence selection and the 24-hour validity guard remain authoritative.
- **Active session:** [TimerActivityView](Sources/WakeBee/Views/TimerActivityView.swift) owns the once-per-second countdown, deadline text, optional +15 min action, and End session. The ordinary session state must not be styled as proof of closed-lid protection.
- **Session notice:** `SessionPanel` renders one wrapping `statusMessage` with an `info.circle`, caption typography, and secondary foreground style. Keep the notice separate from the closed-lid readiness card and do not repeat it as an orange error block.
- **Options menu:** `SessionPanel` uses an ellipsis on a glass surface. Native menu items open General or Closed Lid settings, check for updates, and quit. Preserve accessible “WakeBee options” naming and system keyboard shortcuts.
- **Update settings:** General adds an Updates glass section using existing section and control styles. A toggle controls automatic checks; a secondary check button and last-check timestamp share a row. Short supporting text explains that installation is chosen by the user or that checks wait for a session to end. Sparkle owns its standard update dialogs.
- **Protection status card:** [ClosedLidControl](Sources/WakeBee/Views/ClosedLidControl.swift) combines the laptop symbol, title, settings info button, switch or setup action, status label, and full detail. Status precedence is issue → confirmed active → checking → approval → setup → off → starting/ready. Only its `confirmed` predicate renders green “Active” / “You can close the lid”; a renewal in progress does not replace an already confirmed active state with “Checking.” Unconfirmed states use secondary gray, and full issue text wraps below “Not ready.” Transport or update failures expose a secondary glass “Repair helper” action, disabled while busy; repair does not imply readiness.

## Do's and Don'ts

- **Do** reuse the native glass helpers and semantic text styles.
- **Do** keep session controls and closed-lid confirmation visually distinct.
- **Do** retain complete wrapping status and error explanations.
- **Do** preserve native control semantics, keyboard actions, and accessible names.
- **Do** respect Reduce Motion and keep the native switch fallback for Reduce Transparency and older macOS.
- **Do** scope explicit state animation to switches and the session selector, leaving panel content changes unanimated.
- **Don't** infer protection from a running countdown or an enabled switch.
- **Don't** hard-code colors sampled from one wallpaper, appearance, or OS version.
- **Don't** introduce a second custom glass, shadow, or animation system for these surfaces.
