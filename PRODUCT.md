# Product: WakeBee

<!-- impeccable:product-schema 1 -->

## Platform

macos

Native macOS 14+ menu-bar utility, implemented in Swift 6 with SwiftUI and AppKit. The iOS influence is a visual direction, not an iOS app target.

## Product Purpose

Keep a Mac awake for a manually chosen session and show whether optional closed-lid protection is actually active. A successful interaction ends with a clear session state and an independently truthful lid-protection state.

## Operating Context

The user opens the menu-bar panel, chooses Timer, Until, or Unlimited, and starts a session. Opening the status-item popover gives keyboard focus directly to that panel without app-wide activation. Closing the panel leaves the session running. Settings contains General, Closed Lid, and License pages selected through a compact native segmented control inside the same popover, with a Back button to return to the session. Switching tabs preserves drafts and scroll positions; only the selected page receives input or accessibility focus. The app has no persistent Dock icon.

Sessions end on explicit stop, applicable battery/power rules, explicit system sleep, or quit. They do not restart after relaunch or wake. Relaunch selects Timer, optionally remembering the last countdown duration.

First-launch activation and Finder reopen use the same status-item popover. There are no separate session, license, or Settings windows and no SwiftUI window scenes to restore. AppKit owns startup and the existing status item; all product navigation remains within its non-detachable popover. Normal launches after activation stay in the menu bar until opened. macOS authorization/System Settings and Sparkle update dialogs retain their standard platform presentation.

## Capabilities and Constraints

- Timer supports 1 minute to 24 hours, with 5-, 15-, 30-minute and 1-, 2-, 4-hour presets. Unlimited has no timer deadline; other stopping rules still apply. Timed sessions can be extended by 15 minutes up to the session limit.
- Until uses one editable, locale-aware clock with native time segments and a stepper. “In 30 min,” “In 1 hour,” and “In 2 hours” shortcuts set an end time; a Today/Tomorrow summary shows the remaining duration. A chosen clock time resolves to its next calendar occurrence, usually tomorrow if it has passed, with daylight-saving transitions handled by the calendar. The 24-hour limit still applies; expired or out-of-range selections show “Choose a future time within 24 hours” and cannot start.
- Starting requires a valid Polar license. The existing activation and license-verification rules remain authoritative; there is no shipped unlock bypass.
- General battery rules can end the whole session at a saved cutoff or require a power adapter. “Require a power adapter” defaults to on when no choice is saved; explicitly saved on/off choices survive upgrades and relaunches. Turning it off deliberately allows sessions on battery. Display-sleep prevention is separately configurable.
- Closed-lid protection is optional, starts off after launch, and requires an approved helper signed by the same Apple development team as the app. A normal keep-awake session does not imply lid protection.
- Show “Active” and “You can close the lid” only after helper confirmation, with protection enabled, a running session, registration present, approval complete, and no outstanding issue. Before confirmation, tell the user to keep the lid open. Display full issue text when protection is not ready.
- Helper updates wait for verified sleep restoration before refreshing registration, then require a read-only health check before protection can start. Connection or update failures offer “Repair helper”; repair preserves approval requirements and all safety limits. A healthy connection alone does not mean protection is active.
- Closed-lid battery use is opt-in. The cutoff is 20–80%; its battery-time budget can be 15, 30, 45, 60, 90, or 120 minutes, or No time limit. No time limit removes only that battery-specific timer. The overall four-hour cap, percentage cutoff, thermal checks, valid power readings, and contact watchdog still apply.
- Safety stops remain latched until the user explicitly enables protection again. The helper restores the previous sleep setting when protection ends.
- Automatic app/task detection and agent integrations have been removed. There are no video-export integrations. This remains a development preview; physical lid-close behavior and hardware-specific reliability must not be claimed from simulated tests.
- Sparkle checks for updates daily when enabled. Installation is an explicit user choice, with signed feeds and archives from WakeBee-Releases. Checks and installation are gated on session/helper safety; a Sparkle update cycle blocks new sessions until dismissed or finished. General includes update preferences and a manual check action. Releases require notarization before publication through the release script.

## Brand Commitments

The name is WakeBee. The approved interface direction is Apple-native Liquid Glass with an iOS-like control feel, while preserving macOS menus, keyboard behavior, settings, and accessibility semantics. Copy is short, direct, and explicit about readiness and errors. Session notices appear once in secondary gray; closed-lid warnings use secondary gray while confirmed protection remains green. Explicit state animation stays within switches and the Timer / Until / Unlimited selector, without animating the surrounding panel content.

## Evidence on Hand

[README.md](README.md) records supported behavior, setup, licensing, and dated verification limits. [Package.swift](Package.swift) defines the native platform and modules. [SessionController.swift](Sources/WakeBeeCore/SessionController.swift), [ClosedLidService.swift](Sources/WakeBee/Services/ClosedLidService.swift), and [ClosedLidControl.swift](Sources/WakeBee/Views/ClosedLidControl.swift) are canonical behavior sources. [Preferences.swift](Sources/WakeBee/Stores/Preferences.swift) and [PreferencesTests.swift](Tests/WakeBeeTests/PreferencesTests.swift) record defaults and persistence. [The menu-bar brief](.impeccable/surfaces/menu-bar.md) and [Settings brief](.impeccable/surfaces/settings.md) record the approved surface directions; [DESIGN.md](DESIGN.md) records their shared implemented visual system.

Helper-recovery verification on 2026-10-10: the signed 0.11.1 build 14 passed strict signature verification and 96 Swift tests (80 core and 16 app tests). A user-started session on AC power showed “Active” / “You can close the lid,” with kernel `SleepDisabled = Yes` through multiple renewals and the build-14 helper remaining healthy. An independent native panel and scoped source review returned Ship with no remaining material fixes; the active panel had no observed clipping. The user's session was left running. Physical lid closing, unplugging, and stop/restoration of that live session were not tested in this pass; simulated safety and restoration tests passed. Motion quality, full keyboard coverage, older-macOS fallbacks, and Reduce Motion/Reduce Transparency behavior remain unverified at runtime. Earlier Settings and setup-surface checks are recorded in README.md.

Until-editor verification on 2026-10-10: 102 Swift tests passed (86 core and 16 app tests), including midnight rollover, spring daylight-saving behavior, and the fall-transition 24-hour cap; the signed build 14 was verified. Native UI checks covered the one-hour shortcut, minute and hour arrow-key increments through midnight with a Tomorrow summary, and reset to 30 minutes. No session was started for these checks. Independent review returned Ship with no material fixes or clipping in the 360-point panel, and checked the native End time field, stepper, and shortcut accessibility exposure. This was a scoped control review, not a full accessibility verification or a new closed-lid test.

Settings-navigation verification on 2026-10-10: the signed build passed strict signature verification. Native captures showed the compact toolbar, and Closed Lid → License → General navigation exposed the correct selected segment and only the selected page's accessibility controls. License state was preserved, and the app was left idle on General. Tests were not rerun for this presentation-only change; older macOS and full keyboard/accessibility behavior were not runtime-verified.

## Product Principles

- Starting a session is always an explicit user action.
- Session activity and confirmed closed-lid protection are separate facts.
- Safety limits remain effective regardless of timer mode or visual state.
- Explain an unavailable action or failed protection state without concealing its reason.
- Preserve existing preferences and licensing behavior when changing presentation.

## Accessibility & Inclusion

Use native controls and keyboard actions. Keep meaningful labels on visually unlabeled fields and icon buttons; communicate status with text and symbols as well as color. Error and status details must wrap instead of truncating. Shared glass switches expose one named accessibility toggle with On/Off state and a guarded action; native buttons retain keyboard activation. Reduce Motion suppresses the switch and session-selector transitions. Switches fall back to the native style on older macOS or with Reduce Transparency. Native materials and system typography remain the source of adaptive appearance; this document does not assert a completed accessibility certification.
