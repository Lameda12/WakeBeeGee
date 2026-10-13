# WakeBee

A native macOS menu-bar app for manual keep-awake sessions. Choose a countdown, an exact end time, or keep running until you stop it. Optional closed-lid protection uses a signed helper. License activation uses Polar.

## WakeBee rename

The website is [wakebee.app](https://www.wakebee.app). Version **0.15.2 (29)**
is published with Apple bundle ID `app.wakebee.WakeBee`, helper/XPC service
`app.wakebee.helper`, and license service `app.wakebee.WakeBee.license`.
Source modules also use WakeBee. Polar checkout and product identifiers are unchanged.

This identity change requires a **one-time manual installation** from 0.14 or earlier.
Follow [the migration instructions](Updates/RELEASE.md) before replacing the old app.
Preferences migrate once without overwriting current choices. License migration
retains the Polar activation, requires online validation, and may request Keychain
access. Login-item and background-helper approvals must be set up again.
The old helper must be removed through the old app before new closed-lid setup;
the new helper refuses leases while the old service or recovery journal exists.

Legacy strings remain for migration, historical records, and the local Apple
notarization profile. The Sparkle account is now `app.wakebee.updates`, with the
same key. The approved notarization-profile rename remains incomplete: Apple
stores it in a protected Keychain access group, and Keychain Access control was
denied by the tool. The working profile remains `AwakeMac-Notary`; no credential
was replaced or rotated.

The supplied bee artwork is kept unchanged in `Resources/WakeBee.png`.
`script/create_icon.swift` generates every macOS icon size from it; the build
script regenerates `Resources/WakeBee.icns` when the artwork or converter changes.
The menu bar shows the app icon and optional session countdown. The session
popover starts with the mode selector, with Settings and additional options in
the footer. The installer uses the display name **WakeBee.app**.
Closed Lid settings describe the current state in plain language. Battery
controls appear when General settings allow battery use; otherwise a direct
link explains the charger requirement. Setup failures offer a retry, with
visible diagnostic details and a Copy setup details button. Setup removal remains in an expandable section. Battery,
temperature, connection, and duration limits are unchanged.
For local artwork review, `python3 script/build_dmg.py build <bundle-directory> --preview`
creates a signed `-preview.dmg` without uploading to Apple. Preview images are not
notarized release assets; the normal build and release notarization checks still apply.

New installs use `WakeBee.app`. Sparkle can match updates by bundle identifier;
an existing installation may retain its old on-disk filename while showing the
new product name. Full in-place Sparkle installation remains a separate check; do
not rename a running bundle or rewrite the signed historical feed. The build destination guard
also detects the old executable name inside a bundle being replaced.

## Everyday use

1. Click WakeBee in the menu bar.
2. Choose **Timer**, **Until**, or **Unlimited**.
3. In Timer, enter hours/minutes or choose a 5-, 15-, 30-minute, 1-, 2-, or 4-hour preset. In Until, edit the large time directly or choose In 30 min, In 1 hour, or In 2 hours. A clock time that has passed today selects its next occurrence, with Today or Tomorrow and the remaining duration shown below. The deadline must remain within the next 24 hours. Unlimited runs until you stop it or another stopping rule applies.
4. Choose **Start session** or press Return.
5. **+15 min** extends a timed session; **End session** finishes any session. Until-stopped sessions show **On** in the menu bar when countdown display is enabled.
6. Open the **settings icon** menu for Settings, Closed-lid settings, Check for Updates, or Quit.

The panel uses native Liquid Glass controls on macOS 26+, with material and bordered-control fallbacks on earlier supported versions. Its large time display, capsule presets, and segmented session choices keep the main flow compact.

Settings shares the panel's glass sections and capsule actions. Switches use iOS-like proportions and the system Liquid Glass material; their motion and the session selector's moving glass highlight respect Reduce Motion. Switches fall back to the native macOS switch with Reduce Transparency or on older supported versions. General, Closed Lid, and License remain native settings tabs.

Countdowns range from one minute to 24 hours, including extensions. Hours and minutes accept only whole numbers while typing or pasting: hours 0–24 and minutes 0–59, with at most two digits per field. Choosing 24 hours resets minutes to zero. Invalid edits are rejected without changing the displayed duration; clearing both fields disables Start. Exact end times use the selected minute; past times and deadlines beyond 24 hours cannot start. Until-stopped sessions have no timer deadline but still honor battery rules, explicit system sleep, quit, and license validity. Closed-lid mode always has its own shorter limits.

Manual sessions follow your chosen duration and battery/power rules. Opening another app does not start a session. Starting requires an activated license. Closing the panel leaves the session running. Quitting or explicit system sleep ends it; sessions never restart after relaunch or wake. Relaunch selects a countdown, using the last countdown duration if enabled.

In **Settings → General → Battery & Power**:

- **End sessions on low battery** is on by default. At or below the selected cutoff, the whole session ends and its idle-sleep assertions are released. It also prevents starting a session while already below the cutoff.
- **Battery cutoff** uses the same saved 20–80% threshold as closed-lid protection; default 30%. Existing user choices are preserved. A normal session ignores the cutoff on AC power. Closed-lid protection retains its own always-on safety checks.
- **Require a power adapter** is on by default for new installations. It prevents starting on battery and ends a running session when unplugged. Turn it off deliberately to allow battery sessions. Upgrades preserve existing saved choices. This overrides permission to use closed-lid protection on battery.

Missing power readings stop a session when a power/battery rule requires them. Reconnecting power never automatically restarts a session. The background session monitor checks these rules even with all windows closed. Closed-lid battery limits are also independently enforced by the helper. Turn closed-lid protection off before editing the shared cutoff.

General settings also contains launch at login, remembered countdown duration, the menu-bar countdown, and display sleep control. Closed-lid setup and license management have their own settings tabs. WakeBee intentionally has no persistent Dock icon.

## Closed-lid protection

**Keep the lid open until WakeBee says “You can close the lid.”** A normal idle-sleep assertion does not override lid sleep.

Open the info button beside **Closed-lid mode**, or choose **settings icon → Closed-lid settings…**, then install and approve the helper if needed. Enable the closed-lid switch and start a session. The card shows **Active** and **You can close the lid** only after helper confirmation. Before confirmation it shows the setup, approval, or starting state; **Not ready** displays the full error in the panel. Battery and safety controls remain in Closed Lid settings. The toggle starts off after every app launch. Closed-lid protection requires:

- App and helper signed by the same Apple development team.
- Helper approval in System Settings.
- Verified power/battery readings and no serious/critical thermal pressure.
- A power adapter by default. Optional battery use is configured in **Settings → Closed Lid → On battery**.
- An active manual session.

### Battery settings (version 0.8)

Battery use is off by default. With protection off, enable **Allow closed-lid sessions on battery** and choose:

- **Stop protection at:** 20–80%, in five-point increments; default **30%**. Protection stops at or below the selected level.
- **Maximum time on battery:** **No time limit**, or 15, 30, 45, 60, 90, or 120 minutes; default **30 minutes**. No time limit removes only the battery-specific timer; the percentage cutoff, thermal checks, contact watchdog, and overall four-hour limit still apply.

Then enable closed-lid protection and start a session. Unplugging continues protection only when battery use was enabled and all limits are met. Time on battery is cumulative within a closed-lid session: reconnecting the adapter pauses the budget without resetting it. Power transitions are accounted conservatively at the watchdog sampling interval. The first reached helper limit ends closed-lid protection. A battery percentage cutoff also ends the whole session when the General low-battery rule is enabled; the separate battery-time limit or thermal stop can leave an ordinary session running with the lid open. A safety stop stays latched until the user explicitly enables protection again. Settings are saved locally, but protection itself always starts off after app launch. Turn protection off before editing these settings.

The signed helper independently validates the allowed configuration and enforces the cutoff, battery time, power readings, and thermal checks every second. Missing/invalid readings stop protection. On the adapter, the original battery-above-20% requirement remains. Serious/critical thermal pressure cannot be overridden. All closed-lid sessions still have a **four-hour continuous limit**, even if the regular timer runs longer. Loss of contact with the app also stops protection. Use a hard, ventilated surface and test on your Mac before relying on unattended work.

When upgrading, keep the lid open. WakeBee checks the bundled helper version and health at launch. If the registered helper is stale, it first waits for verified sleep restoration, awaits removal, then registers the current signed helper. Interrupted updates resume on the next launch. System Settings approval is still required when macOS requests it. **Repair helper** is available after a connection failure; repair never bypasses approval or power and thermal limits. A failed runtime connection stops protection and requires explicit recovery.

The SMAppService helper authenticates the app over XPC and temporarily changes the system-wide `pmset disablesleep` setting. It exposes only a read-only health check, renew/release operations, and bounded battery-policy values, with no arbitrary shell commands or paths. Health confirmation does not itself enable protection. The legacy renewal method retains adapter-only defaults. A private root-owned recovery journal is flushed before changing the setting. The helper checks the effective `IOPMrootDomain SleepDisabled` Boolean after each change. Missing or malformed registry data prevents activation.

Leases expire after 30 seconds without renewal; the app renews every ten seconds while a timer needs protection. A one-second helper watchdog checks power, thermal state, expiry, and restoration. Ending a timer or losing the client connection restores the previous setting. Failed restoration keeps the recovery journal and retries. Uninstall confirms restoration before removing the helper. A background session monitor keeps this working when all app windows are closed.

Physical lid closing, unplugging, thermal conditions, crash/reboot recovery, older macOS versions, and Intel hardware remain areas for further validation. Publishing a release does not change those recorded test limits.

## License activation

An unactivated installation displays **Unlock WakeBee**. **Buy a license** opens the supplied [Polar checkout](https://buy.polar.sh/polar_cl_HMkc1qGmstC5HhR91Tz3XMqlAbV2MLKp1JvyS2xPMrC). Paste the purchased key and choose **Activate**. Empty keys cannot submit; invalid-key, connection, device-limit, and Keychain errors stay visible without unlocking the app. Manage the saved license in **Settings → License**.

Validation pins WakeBee's public organization and license-key benefit IDs. Other products' keys cannot unlock the app. Unlimited-device keys validate directly; limited-device keys allocate a device and save its activation ID before final validation. A retry reuses a saved allocation. An interrupted activation response can still leave an allocation on Polar; manage devices through the Polar purchase if its limit is reached.

The key and last verified state are stored in device-local macOS Keychain, never UserDefaults or logs. HTTPS uses an ephemeral session without cookies or disk caching and refuses redirects. Only the license key, public product identifiers, optional activation ID, and the generic activation label “WakeBee on Mac” are sent. No organization access token is embedded in the app.

Verification is due every 24 hours and retries at most hourly on failure. A verified license works offline for up to seven days, bounded by its expiry. Definitive rejection invalidates the cache. Existing timed sessions keep their original deadline if verification lapses; an until-stopped session ends, and new sessions/extensions are blocked. Removing a license releases its device allocation before deleting the Keychain entry and is available after the timer ends. Local caching is a usability measure, not tamper-proof DRM.

There is no shipped test key or unlock bypass, including in development builds. Tests inject fake storage and server responses. A real license remains necessary for end-to-end activation.

## Upgrading from app/task detection

Version 0.7 removes the Apps interface, lifecycle event listener, process monitoring, hook installer, activity CLI, and IPC targets. Former app-watching preferences are retired. Display/timer preferences and the existing license remain intact. A saved indefinite duration becomes 30 minutes.

For an older development installation, preview and remove only AwakeMac-marked integrations:

```sh
python3 script/remove_legacy_integrations.py
python3 script/remove_legacy_integrations.py --apply
```

The migration supports both `# awakemac:v1` and `# awakemac:activity:v2`. It preserves unrelated hooks/settings and writes exact, private backups. The installed activity executable is replaced with a tiny no-op that drains stdin and returns `{}`; this prevents errors in already-open agents with cached hook commands. It does not inspect tasks, send events, or hold power assertions. Newly opened sessions load the cleaned configuration. Fresh installations do not install this bridge.

## Build and verification

Requires macOS 14+, Xcode with Swift 6, and Python 3 for the build destination guard. Sparkle 2.10.0 is pinned through Swift Package Manager and `Package.resolved`.

```sh
./script/build_and_run.sh --verify
swift test --disable-sandbox
python3 script/test_remove_legacy_integrations.py
python3 script/test_release_update.py
python3 script/test_check_build_destination.py
```

The bundle is `dist/WakeBee.app`. The script builds into a temporary staging bundle, signs the helper and app, and verifies the complete bundle before replacing the installed development bundle. It uses `AWAKEMAC_SIGN_IDENTITY`, then the gitignored `.signing-identity` certificate fingerprint, otherwise an ad-hoc signature. The helper requires a real signing identity. No private key or password is stored in the project. Use `--build-only` to bundle without launching. Distribution still needs notarization; this script does not notarize.

Build-only refuses to replace a running destination, and every mode checks again immediately before replacing the bundle. Replacing an executable while its process remains alive can leave macOS service registration using stale bundle information. Quit that copy before rebuilding, or set `AWAKEMAC_DESTINATION` to a separate output path. Release preparation already uses a separate versioned destination. For everyday use, open `/Applications/WakeBee.app` and close any duplicate project build.

## Automatic updates

Version 0.12.0 added Sparkle. **Settings → General → Updates** controls daily automatic checks; **Check for Updates…** is also in the menu-bar options. Automatic checks default to on and can be disabled. Installing an update requires the user's choice in Sparkle's standard macOS dialog; silent automatic installation is disabled. System profiling is off.

Checks wait while a keep-awake session or helper operation is active. With a registered helper, updating also requires a verified restored kernel sleep setting. Starting a new session is blocked while the Sparkle update dialog/check is in progress; finish or dismiss it to continue. The installation termination boundary rechecks the safety policy. Settings and helper recovery remain in their existing stores. Polar licenses keep the existing Keychain account described above. Relaunch never restarts a session or enables closed-lid protection automatically.

The new identity uses [appcast.xml](https://raw.githubusercontent.com/jswladitya/WakeBee-Releases/main/appcast.xml) in [WakeBee-Releases](https://github.com/jswladitya/WakeBee-Releases), separate from this private source repository. The legacy feed must offer 0.15 as an informational/manual update without an enclosure; never send a different bundle identity through its automatic installer.

Both the feed and update archives must pass Ed25519 signature verification. The public key is in `Resources/Info.plist`; the private key stays in the login Keychain under account `app.wakebee.updates`. Do not regenerate it for each release or commit an exported private key. Keep a secure backup using Sparkle's documented key-export procedure. The build script embeds Sparkle with symlinks intact, preserves its XPC service entitlements, signs nested code before the enclosing framework/app, and copies its license into the bundle.

### Publishing the next update

For first-time notarization setup, run `./script/setup_notarization.sh` interactively in Terminal. It asks for the Apple Developer email, lets Apple's `notarytool` collect the app-specific password in its hidden prompt, validates it with Apple, and saves it in Keychain as `WakeBee-Notary` (existing installations may retain their previous profile name). The project stores only the non-secret profile name in the ignored `.notary-profile`. Never paste the password into chat or put it in a script. Existing App Store Connect API-key profiles can also be used directly with the prepare command.

1. Update `CFBundleShortVersionString` and increase the integer `CFBundleVersion` in `Resources/Info.plist`. Keep the app identifier, signing team, and public update key stable.
2. Add concise HTML release notes at `Updates/<version>.html`.
3. Run the normal tests and complete release testing, including helper upgrade behavior.
4. Use an existing `notarytool` Keychain profile (the profile name is not a password):

   ```sh
   python3 script/release_update.py prepare --notary-profile YOUR_PROFILE_NAME
   ```

   This builds Apple silicon + Intel release binaries separately from the running development app, verifies Developer ID signing, notarizes and staples the app, then generates a signed archive and feed under `dist/updates/<version>-<build>/`. It refuses reused output directories, mismatched update keys, and non-increasing build numbers. `YOUR_PROFILE_NAME` must be configured separately with Apple; no notarization credentials are embedded in the app.

5. Review the local bundle and feed, then publish explicitly:

   ```sh
   python3 script/release_update.py publish dist/updates/<version>-<build>
   ```

   Publishing verifies the prepared files, creates a GitHub release, uploads only the app archive, and updates the signed feed after the download is available. Existing release tags are never overwritten, and concurrent feed changes stop publication. If publication fails after creating a release, inspect that release before retrying; do not replace an asset clients may already have downloaded. GitHub's raw-file cache can delay feed visibility briefly.

Regular releases use `publish dist/updates/<version>-<build> --notes-file Updates/RELEASE.md`, which publishes a non-prerelease and marks it as Latest. Each app change increments the version and build so existing installations can update through Sparkle without replacing previously downloaded assets. The 0.12.0 → 0.12.1 update was verified on this Mac. A valid license key is required; no licensing bypass is included.

`Updates/appcast.xml` is the signed bootstrap feed, not the source of truth for later releases. The release script reads and verifies the current public feed. Never hand-edit a signed feed after generation. Preparing a release does not publish it. The normal build script does not notarize development builds. The release pipeline does; 0.12.1 is notarized and stapled.

Sparkle setup verification on 2026-10-10: 106 Swift tests and three release-publication guard tests passed. Both the local debug app and universal release build passed strict nested signature verification with Developer ID signing. Mach-O deployment targets remain macOS 14. The public bootstrap feed matched its signed local copy; both length-changing and equal-length tampering were rejected. A manual check from the running app reached the public feed and displayed “You're up to date” for 0.12.0. At that initial setup stage, no public binary release or notarization had been performed; the later release verification below supersedes that limit. The publication guard tests use mocks and do not upload a release.

The code is split into `WakeBee` (native UI/platform services), `WakeBeeCore` (timers, licensing, helper lease/recovery logic), and `WakeBeeHelperProtocol` / `WakeBeeHelper` (authenticated XPC and privileged sleep restoration).

On October 10, 2026, the expanded-session build passed **74 Swift tests** in nine suites, covering exact deadlines, invalid/past end times, until-stopped lifecycle, battery/power session termination, license loss, every cutoff and battery-time choice, charger transitions, cumulative battery budgets, latched helper stops, restoration retries, duration parsing, and licensing. The earlier simplified build also passed **8 integration-cleanup tests**; that cleanup code is unchanged. `WAKEBEE_TEST_POWER_REGISTRY=1` additionally enables the read-only host sleep-state check. Helper tests use fake power settings and never change system policy.

The signed 0.7 build was also exercised in the native UI: invalid minutes disabled Start, a one-minute session acquired real system/display idle-sleep assertions, Add 15 min moved the deadline, End session released both assertions, and a separate one-minute timer expired naturally with “Session complete” and no remaining AwakeMac assertions. The saved license remained active. Closed-lid protection stayed off throughout these UI tests; physical lid-close testing was not performed in this pass.

The signed 0.8 build was launched and its helper reinstalled successfully. Native UI verification covered battery opt-in, cutoff/time choices, persistence across relaunch (45% / 15 minutes), and configuration locking while protection is enabled. A subsequent user-started timer showed “Active. You can close the lid.” with the new policy, using the version 8 helper on AC power. That running session was left unchanged. Actual unplugging and physical lid closing were not performed; battery transitions and limits were verified with simulated power states in the core tests.

The signed 0.9 build was exercised in the native UI: a five-minute preset started correctly, an exact-time session displayed the selected 8:45 PM deadline, and an until-stopped session showed its infinity state with End session as the primary action. Each test session was ended. `pmset -g assertions` confirmed real AwakeMac system/display assertions during the countdown and their release after ending; no AwakeMac assertions remained after the final relaunch. General and Closed Lid settings were checked for native layout, labels, and readable battery-rule explanations. The existing 45% / 15-minute battery settings and enabled require-adapter rule were preserved. Closed-lid protection stayed off during these tests; no physical lid-close or unplug test was performed. The final copy/alignment build passed strict bundle signature verification and launched successfully.

Version 0.9.1 adds an explicit **No time limit** battery option, encoded as zero in the saved policy and validated by both app and helper. Existing timed choices and defaults remain intact. **78 Swift tests** passed, including continued battery operation beyond every timed preset and enforcement of the overall four-hour cap, percentage cutoff, thermal stop, unknown readings, and contact loss with the battery timer disabled. The signed app launched, the updated helper registered, and the native picker saved No time limit while retaining the 45% cutoff. A live session confirmed that the helper accepted the new policy; ending it restored `SleepDisabled` to false. Physical lid-close behavior and a long real battery discharge were not tested.

Version 0.9.2 simplifies the menu-bar closed-lid section into a native laptop symbol, two-line title/status, info button, and switch. Battery limits move out of the compact panel into the existing Closed Lid settings. No power-management behavior changed. The signed build launched successfully; live UI checks covered off, ready, active, and the info-button settings route. Accessibility exposes explicit settings and toggle names. An independent native UI review approved the ready/active layouts; setup and error states were reviewed in source only.

Version 0.10.0 redesigns the entire menu-bar panel with native Liquid Glass, Timer / Until / Unlimited segments, large time displays, capsule controls, and an options menu. Closed-lid confirmation now requires a running session, enabled protection, an approved registered helper, and no outstanding issue. Helper setup/removal errors propagate to the visible status. All **78 Swift tests** passed; the signed app and helper passed bundle verification, and the app launched successfully. Native UI checks covered all three setup modes, the active countdown, and the options menu; a user-started protected session exposed **Active / You can close the lid** in accessibility. An independent reviewer approved the final three setup layouts and reviewed confirmation/error logic in source. Helper failure states were not deliberately injected, and physical lid-close behavior was not tested in this UI pass.

Version 0.11.0 extends the glass design to Settings, adds glass switches and a morphing session selector, and defaults new installations to requiring a power adapter. The **78 core tests and two new preference tests** passed, including fresh-install defaults, deliberate battery opt-out, and preservation of saved choices across relaunch/upgrades. The signed app and helper passed strict bundle verification and launched. Native UI checks covered General, Closed Lid, the activated License screen, visible Timer/Until selection, and switching Remember last duration off and back on. Each switch exposes a single labeled accessibility control. Keyboard focus dispatch was inconclusive through the UI tool; Reduce Motion, Reduce Transparency, and older-OS fallbacks were reviewed in source. No license removal, helper installation, or physical lid-close test was performed in this pass.

The independent finish review returned **Ship**, with no material UI/source defects, scoped to live General/Timer captures and source review of the other screens and controls. User interaction prevented reliable independent captures of the other tabs. The review requested synchronization of the design documentation with the implemented controls and window dimensions.

## References

- [Polar license activation](https://polar.sh/docs/api-reference/customer-portal/license-keys/activate)
- [Polar license validation](https://polar.sh/docs/api-reference/customer-portal/license-keys/validate)
- [Apple power-management implementation](https://github.com/apple-oss-distributions/xnu/blob/main/iokit/Kernel/IOPMrootDomain.cpp)


Version 0.11.1 fixes stale helper registration after development updates: this Mac was repeatedly trying to launch an older version-10 registration and exiting with configuration error 78. The current helper is registered as build 14, starts successfully, and is health-checked before use. Update registration retries only the known transient permission race after removal, with at most three attempts. Cancellation during an asynchronous update remains busy until it settles, and interrupted removal leaves a recoverable pending-update marker. The panel shows one secondary-gray session notice; session-mode animation is scoped to the selector, while switches retain their own animation.

The final signed 0.11.1 bundle passed strict signature verification and **96 Swift tests** (80 core and 16 app tests), including helper update sequencing, bounded retries, approval handling, interrupted updates, cancellation during removal, and notice deduplication. Live checks on AC power confirmed build 14 running without relaunch failures, `SleepDisabled = No` before the session, then **Active / You can close the lid** and `SleepDisabled = Yes` through multiple renewals in a user-started session. That session was left running. Physical lid closing, unplugging, and stop/restoration of that live session were not tested in this pass; simulated restoration and power-policy tests passed. Full motion quality, accessibility settings, older macOS, and other hardware remain release-validation work.


The Until setup now uses one large editable native time control with keyboard segment navigation and a stepper, replacing the duplicate clock and full numeric date field. Relative shortcuts set the deadline from the current time; the day label makes midnight rollover explicit. **102 Swift tests** passed (86 core and 16 app), including the six new end-time cases for same-day selection, passed times, the current minute, midnight presets, a missing spring DST time, and preservation of the 24-hour cap on a long fall day. The signed app was exercised with the one-hour shortcut, minute and hour keyboard stepping, and rollover to Tomorrow; it was left idle in Until with the 30-minute shortcut selected.

### First public test release — 2026-10-10

AwakeMac **0.12.1 (16)** was published as a GitHub prerelease with installation and testing instructions. Apple accepted notarization submission `89f1fcf8-af35-489e-bdb8-4f881965c3ea` with status “Ready for distribution” and no reported issues. The universal app is Developer ID signed with hardened runtime and has a stapled ticket. Both executable slices target macOS 14.

The unauthenticated public ZIP matched SHA-256 `be5b0ed1b0c40ec54b1ca60be7f3023475a2f98e26792d2d14ee0e33c898205f`. Its extracted app passed strict signature verification, ticket validation, and Gatekeeper (`Notarized Developer ID`). The public appcast matched the signed local feed. Sparkle in the installed 0.12.0 app discovered 0.12.1, downloaded it, replaced the app with build 16, and relaunched it successfully. The restarted app remained unlocked, showed the remembered two-hour timer, and left closed-lid protection off. No session or physical lid test was performed during this update check.

The release candidate passed 106 Swift tests and four publication guard tests. Intel execution and physical closed-lid behavior on other Mac models still need tester coverage. Testers need a valid license key. The notarization password and Sparkle private key remain in Keychain; the release publishes only distribution artifacts and documentation.

### DMG packaging

The manual installer uses a compact native Finder window: AwakeMac, a subtle arrow, and a real Applications link. Its background contains no instruction paragraphs or simulated controls. The artwork generator creates a two-resolution TIFF for standard and Retina displays; Finder renders draggable icons and accessible filenames.

To package an already notarized release without rebuilding or changing its app:

```sh
npm install --prefix .build/dmg-tools --no-audit --no-fund appdmg@0.6.6
python3 script/build_dmg.py build dist/updates/<version>-<build>
# Mount and inspect the Finder window before finalizing.
python3 script/build_dmg.py notarize dist/updates/<version>-<build> --notary-profile "$(cat .notary-profile)"
gh release upload v<version> dist/updates/<version>-<build>/WakeBee-<version>.dmg --repo jswladitya/WakeBee-Releases
```

The build command refuses to overwrite an existing DMG, verifies the source app's signature, ticket, and Gatekeeper assessment, then signs the disk image. The notarize command requires Apple's Accepted response, staples and verifies the ticket, checks Gatekeeper, and writes `dmg-release.json` with the final SHA-256. Publish only after those checks pass. The signed ZIP and Sparkle appcast stay unchanged; the DMG is the manual download.

The [0.12.1 DMG](https://github.com/jswladitya/AwakeMac-Releases/releases/download/v0.12.1/AwakeMac-0.12.1.dmg) passed Apple notarization (`34d09d8b-f610-4e3c-93ab-e969482a5758`), signature verification, stapled-ticket validation, and Gatekeeper assessment. Its unauthenticated public download matched SHA-256 `06794266bb8a7aed84b2661c196d1daf4a7c73cbab2e8414d3f26f8174ba041d`. The mounted app also passed signature, ticket, and Gatekeeper checks; the Applications link resolved to `/Applications`. The native Retina Finder layout was inspected and received an independent review disposition of **ship**. The ZIP and signed appcast were verified unchanged. Actual Finder copying and keyboard installation were not exercised.

### AwakeMac 0.12.2 — 2026-10-10

Version **0.12.2 (17)** is published as the **Latest** regular GitHub release, with signed and notarized ZIP and DMG downloads. Settings shows only the version number; the current release notes, Sparkle notes, and public download page use regular-release wording. The approved minimal installer layout is unchanged.

The universal release build, four publication guard tests, notarization, strict signature checks, ticket validation, and Gatekeeper assessment passed. The public DMG matched SHA-256 `97fe76d373edf70e3d556fa6e8e15396cb7b4d83416dc02d631e111937950e3d`; the public appcast matched the signed local feed. Sparkle upgraded this Mac from 0.12.1 to 0.12.2 and relaunched successfully. Live Settings displayed `AwakeMac 0.12.2`, and the installed bundle was verified as build 17. No session or physical lid behavior was exercised for this copy-only update.

### Prepared menu-bar focus fix — 0.12.3 (18)

`MenuBarController.show()` no longer activates the whole app before showing the status-item popover. That activation could bring a background Settings window forward. The popover still requests keyboard focus directly and retains its existing outside-click, Escape, and sheet handling. Explicit Settings actions still activate the app intentionally.

The signed local build was installed and launched successfully. Sixteen existing macOS app tests and four release guard tests passed. These tests cover preferences, helper lifecycle, and publication guards; they are not a live status-bar interaction test. UI automation could not access this Mac's status-bar controls, so a complete live reproduction of the reported focus behavior remains unverified.

The universal release app and DMG both passed Apple notarization, stapling, signature verification, and Gatekeeper. The prepared DMG has SHA-256 `dba3bd6834b22df8cec5bdc66d212322d43a2a1479196084635efc57aee4310e`. Publication was blocked by automatic approval review pending explicit authorization for the new GitHub/Sparkle rollout; 0.12.2 remains the public release. The prepared artifacts are in `dist/updates/0.12.3-18`, with a DMG copy on the Desktop.

### Menu-bar-only launch — 0.12.3 (19), local build

Removed `PanelWindowController`, which still opened a separate titled session window on first launch and Finder reopen. These paths now use `MenuBarController.show()`, sharing the same anchored popover as the status item. First-launch presentation waits until the next main-loop pass so the status item is laid out. Reopen is idempotent and continues to suppress SwiftUI's default Settings opening. Explicit Settings actions are unchanged.

The Developer ID signed local app at `dist/AwakeMac.app` was rebuilt and relaunched, with strict signature verification and all 16 existing app tests passing. Native UI inspection after reopening identified the session controls as a popover and captured the anchored, untitled presentation in `artifacts/menu-only/popover.jpg`. Automated follow-up clicks returned `noWindowsAvailable`, so they do not establish interactive control behavior. No session or closed-lid protection was started for this check.

Build 19 was subsequently packaged for manual sharing on 2026-10-10 in `dist/updates/0.12.3-19`. The universal app passed notarization (`280671a7-48ee-4f8f-89f7-2191e343200a`), and the DMG passed notarization (`b92c9542-9c1c-4700-bf49-9cd245435263`), stapling, signature verification, and Gatekeeper assessment. The mounted DMG contained only the real AwakeMac app and Applications link; its app was build 19 with `LSUIElement = true`, and its binary matched the corrected release app. Neither standalone-window code nor the separate sample license-preview executable was present. Both architectures retain a macOS 14 minimum. The installer design is unchanged; a new live Finder layout inspection was not completed in this pass.

The verified sharing copy is `/Users/adityajaiswal/Desktop/AwakeMac-0.12.3-build19.dmg`, SHA-256 `d8081e9e13419b0263e288de2863476873c0ac2269b3e2ed78929dc5b33af660`. The previously prepared build-18 ZIP and DMG do **not** include this additional launch fix and must not be published as the completed fix. Public downloads and Sparkle remain on 0.12.2; publishing build 19 still awaits explicit authorization. Recipients of the manual DMG should quit the old app, replace it in Applications, and open the replacement there.

### Every product screen in the popover — 0.12.4 (20)

The latest user requirement also removes the standalone Settings window. Startup now uses an AppKit application delegate with one status item and no SwiftUI window scenes. `AppModel.showSettings` navigates within the shared root view; General, Closed Lid, and License appear in a 400-by-600-point scrollable popover with a Back button. First-launch license entry stays in that same popover with a bounded scroll area for errors. The panel explicitly refuses detachment. Native Edit shortcuts remain available through `ApplicationMenu`; macOS authorization/System Settings and Sparkle dialogs retain their platform presentation.

The Developer ID signed local build was launched successfully. All 106 Swift regression tests passed (16 app and 90 core). Live native UI checks confirmed Timer → Until, Command-comma opening Settings, General → License → Closed Lid → General, accessibility scrolling to the bottom of General, and Back returning to the existing session draft, all with the accessibility role `popover`. Captures are in `artifacts/all-popover`. CUA's wheel-scrolling API returned `noWindowsAvailable` for the transient popover; the native accessibility Scroll Down action worked. License state and preferences were not changed by these checks. Fresh-key activation, clipboard entry, older-macOS rendering, and physical closed-lid behavior were not re-tested. An update result dialog and enabled closed-lid readiness were also observed during this pass; that state was left intact.

Build 20 supersedes the earlier build-19 sharing package for the all-screens-in-menu-bar requirement. Public downloads and Sparkle remain on 0.12.2 until a separately authorized publication.

The universal release in `dist/updates/0.12.4-20` passed app notarization (`e19b951f-b3a5-4529-a6fb-8d5a4f81e9ba`) and DMG notarization (`cc2e98db-05fb-4f20-8722-09f382cb5c4e`), including stapling, signature verification, and Gatekeeper. Mounted-installer checks confirmed build 20, the menu-bar bundle flag, the exact corrected binary, and only the real app plus Applications shortcut. Obsolete standalone controllers and the sample preview app were absent. The sharing copy is `/Users/adityajaiswal/Desktop/AwakeMac-0.12.4.dmg`, SHA-256 `bf9f8e2491da06408bd302643b004c733962a25c1e590f5ab393733455348e71`. The installer artwork is unchanged; its live Finder layout was not re-inspected in this pass.

### Release 0.12.5 / build 21 — October 11, 2026

Published as the regular Latest release with the notarized universal ZIP and DMG, signed Sparkle feed, and updated public download links. Sessions, activation, and Settings all use one non-detachable menu-bar popover; no SwiftUI window scenes or standalone session controller remain. Every manual cold launch and reopen presents that popover. Apple’s open-application login/service launch markers suppress automatic presentation during background startup.

Validation: 108 Swift tests and four publication guard tests passed. Manual/login/service launch policy tests use synthetic Apple events; an actual logout/login cycle was not performed. The signed local app launched successfully, and native accessibility inspection confirmed the session panel, General Settings, and activated License page all have a popover role. No saved license was removed; fresh-key activation and older macOS/Intel runtime behavior were not retested. Physical lid behavior is unchanged and was not retested.

The universal app and helper contain arm64 and x86_64 slices with macOS 14 minimum deployment targets. Mounted installer checks verified build 21, LSUIElement, matching app/helper binaries, the Applications link, strict nested signing, and the stapled app ticket. App notarization: `43dd4663-8093-4823-9dd6-c2bf734a0bcd`. DMG notarization: `a6b54fc6-b0a5-4310-86eb-cf734ba1a3c3`. Release artifacts are under `dist/updates/0.12.5-21/`; the Desktop copy is `AwakeMac-0.12.5.dmg`.

### Release 0.12.6 / build 22 — October 11, 2026

Published as the regular Latest release with the compact license-entry screen, settings icon, clearer first-time closed-lid setup actions, and centered session guidance with a Reduce Motion-aware horizontal nudge. Public DMG/ZIP downloads and the signed Sparkle feed are updated.

Validation passed: 112 Swift tests (22 app, 90 core), 12 Python release/migration checks, universal app/helper architecture checks, and macOS 14 deployment targets. Apple accepted app notarization `e6c07b6f-f2a5-423c-9d0e-68d1436ba151` and DMG notarization `cb3795f7-7b22-46d3-bd44-988020c8e555`. The native Finder installer was visually inspected; its app/helper matched the release bundle and the Applications shortcut resolved correctly.

Unauthenticated downloads matched the prepared artifacts. The downloaded ZIP and appcast passed Sparkle signature checks; its extracted app passed strict code signing, stapled-ticket validation, and Gatekeeper (`Notarized Developer ID`). DMG SHA-256: `e7de9512d9a022142f85b9f0bae6ff86dbb80b9fc59dd645f493222d8249a279`. A sharing copy is saved on the Desktop as `AwakeMac-0.12.6.dmg`. The running app was not restarted or updated during publication; end-to-end Sparkle installation, physical lid behavior, and Intel execution were not re-tested in this release pass.

### Untiring rename — 0.13.0 (23), local verification

The universal renamed app passed Developer ID signature verification and was installed
at `/Applications/Untiring.app`, with the prior idle copy retained in a temporary backup.
Live UI showed Untiring in the menu-bar popover with the existing license unlocked.
The helper logged successful registration and health verification. Both executable
architectures retain a macOS 14 minimum. No session or physical lid test was run.

112 Swift tests and 19 Python tests passed, including the guard against replacing
a running pre-rename executable. The landing page passed lint, its production webpack
build, and 25 browser tests. Its launch-film ending now shows Untiring and untiring.app.
The release was subsequently notarized and published as described below.

### Release 0.13.0 / build 23 — October 11, 2026

Published **Untiring 0.13.0** as the regular Latest GitHub release. The new DMG,
ZIP, release notes, and signed Sparkle feed use the Untiring name. The existing
repository, bundle identifier, license storage, helper identity, and update key
remain compatible. The feed's product website is `https://untiring.app`.

Apple accepted app notarization `188568a7-d4b2-42a2-86b5-01e0d74f9d25` and DMG
notarization `3a0551bf-02c4-4409-a903-80147a61ac87`. Both artifacts are stapled.
Unauthenticated public downloads matched the prepared SHA-256 hashes. The public
feed and ZIP passed Sparkle signature verification; the extracted app and DMG
passed ticket validation and Gatekeeper as `Notarized Developer ID`. The app and
helper include Intel and Apple silicon, with a macOS 14 minimum.

The installer artwork was inspected in Finder. A sharing copy is on the Desktop
as `Untiring-0.13.0.dmg`; its SHA-256 is
`c7ecb8f9eab54d92f4bec4421b63ad979742e349f8bb2511ab1df961e5efc480`.
The landing page now targets this public DMG, version 0.13.0 / build 23, and passed
lint, a production webpack build, and all 25 browser checks. Website deployment
remains separate. The running app was not restarted during publication. Full
in-place Sparkle installation, physical lid behavior, and Intel execution were
not re-tested in this release pass.

### Release 0.13.1 / build 24 — October 11, 2026

Published as the regular Latest release with the final supplied sun icon. The
menu bar shows only the icon and optional countdown; the popover and installer
use **Untiring.app**. The public DMG, ZIP, release notes, and signed Sparkle feed
are live. The landing page's local download link targets this release; hosting
and domain setup remain separate.

Validation passed: 112 Swift tests, 19 Python checks, scoped website lint, and
the production webpack build. The app and helper contain arm64 and x86_64
slices, and the app's deployment target remains macOS 14. The packaged icon
matches the final artwork's generated ICNS.

Apple accepted app notarization `7203f976-88a9-4239-98d2-09a93324365c` and DMG
notarization `0ae72fa7-b1cf-4a43-b12c-830863c823bd`. Unauthenticated public
downloads match the prepared artifacts. The live feed and ZIP passed Sparkle
signature verification; the downloaded app passed strict code signing, and
both the app and DMG passed stapled-ticket validation and Gatekeeper as
`Notarized Developer ID`.

DMG SHA-256: `3c79e6ebe7f151b150967d5f9a0c3d0f6b906364ebd142f1353b63a8a7d0a0c0`.
ZIP SHA-256: `4a5d3da3ad524cd7c24bbda663c064e6a7d91a82abb1672859dcbd212baeef07`.
Release artifacts are in `dist/updates/0.13.1-24`. The running app was not
restarted during publication. In-place Sparkle installation, physical lid
behavior, and Intel execution were not re-tested in this release pass.

### Release 0.13.2 / build 25 — October 11, 2026

Published as the regular Latest release with the session selector at the top,
Settings and options in the footer, calmer Closed Lid settings, and numeric
timer input validation. Existing licenses, preferences, and closed-lid limits
are unchanged. The final sun icon is retained.

119 Swift tests and 19 Python release-tool tests passed. The landing page passed
scoped lint and a production webpack build; its generated download page points
to 0.13.2. Website hosting remains unconfigured.

Apple accepted app notarization `f3341e6c-a5d2-4f4d-806f-7d36a76a8386` and DMG
notarization `5750c6cd-1d83-4296-911c-fbe6db4ab3af`. Mounted-installer checks
confirmed build 25, matching app/helper/icon files, the Applications shortcut,
strict code signing, and the stapled app ticket. The app and helper include
arm64 and x86_64 slices, both targeting macOS 14.

Unauthenticated public downloads matched the prepared files. The live appcast
and ZIP passed Sparkle signature verification. The downloaded app passed strict
code signing, and both app and DMG passed ticket validation and Gatekeeper as
`Notarized Developer ID`.

DMG SHA-256: `059caedabf5f1f30e45f59b44b4c27d525bc20dda7173bf9e4e66d7697202d71`.
ZIP SHA-256: `8a1d84dd7c27c45a4b97b523f8e5871f82a1b201edf6431d3a829d4dbe083ef8`.
Release artifacts are in `dist/updates/0.13.2-25`. Publication did not restart
the running app. Physical lid-close behavior, Intel execution, and in-place
Sparkle installation were not tested in this release pass. The public notes
explicitly avoid claiming compatibility with every Mac and macOS version.

### WakeBee and Polar — 0.14.0 (26), released 2026-10-13

The final payment provider is Polar, using the owner's supplied checkout link.
The previous Polar organization, benefit, and Keychain account are retained so
existing purchased keys and saved activations remain compatible. The app,
installer, website, and launch film use WakeBee and the final sun icon.

Published as the Latest regular release, with notarized ZIP and DMG downloads
and the signed Sparkle feed. Release artifacts are in `dist/updates/0.14.0-26/`.
Apple accepted app submission `fe1b0321-0394-4769-906f-d8642cc4c395` and installer
submission `2da0b1b1-cb72-4824-8fea-afa9b6fc9f8b`. Both tickets are stapled, and
signature and Gatekeeper checks passed. The mounted installer matched the
release app, helper, and final icon and contained the correct Applications link.
Both executable architectures retain a macOS 14 minimum deployment target.

Unauthenticated public ZIP and DMG downloads matched their recorded SHA-256
hashes. The public feed matched the signed local feed for build 26. The release
repository README now links to WakeBee 0.14.0 and the supplied Polar checkout.
The separate marketing website has not been deployed in this release pass.
Physical closed-lid behavior, Intel execution, a live Polar purchase, and an
in-place Sparkle installation were not exercised in this release pass.

Verification on 2026-10-13: 26 app tests and 96 core tests passed, including
Polar activation, validation, removal, and cached-license behavior. The website
production build, scoped lint, and all 26 browser checks passed. Live checkout
inspection was blocked by automatic approval review citing an older provider
instruction; no real purchase was made.

Brand audit after publication: the public update channel title, description,
and website link were changed to WakeBee and re-signed. Every release item
was verified unchanged. The signed feed revision and original are retained
in `dist/feed-branding-wakebee/`; the original release manifest remains intact.
Apple bundle/helper identities and the Keychain/notarization profile names
retain legacy identifiers pending the owner’s internal-migration decision.

### Internal identity migration — 0.15.0 (27), published

128 Swift tests and 19 Python packaging checks pass, including preference migration,
license-copy retry/precedence/deactivation behavior, and old-helper refusal.
Tests use isolated preferences and fake license storage; they do not establish
real Keychain authorization or physical lid behavior. New public downloads and
feed live in WakeBee-Releases; historical release URLs remain intact.

Apple accepted app notarization `7df8473b-14a3-4b17-b27a-96d6e445c0aa`
and DMG notarization `6357baac-fb96-4ae6-ae84-4f48083b9abd`. Tickets,
strict signatures, Gatekeeper, mounted installer contents, and both macOS 14
architecture targets passed verification. The legacy feed now contains a signed
informational-only update without an enclosure; its historical items are unchanged.
The website production build, scoped lint, and 26 browser checks passed after
rebuilding with the new download URL. Website deployment, real old-to-new Keychain
authorization, physical closed-lid behavior, and Intel runtime remain unverified.

### Credential metadata — October 13, 2026

With explicit owner approval, renamed the Sparkle account to `app.wakebee.updates`
and its display label to `WakeBee Sparkle update signing key`. The public key
remains identical to `SUPublicEDKey`; a temporary feed was signed and verified
under the new account. Release tooling now uses that account by default.
Apple notarization authentication through the existing profile was verified, but
its label could not be changed through the available tools. `.notary-profile`
retains its working value. No public release artifact or feed was modified.

### Keychain removal diagnostics — local build

License storage now preserves macOS Keychain error codes and identifies read,
save, or removal failures. The previous generic message incorrectly described
all failures as saving and assumed the login Keychain was locked. A regression
check verifies that a failed removal reports its status and can be retried.
129 Swift tests pass. The reported user's removal failure is not yet reproduced;
retrying in this local build is needed to identify its actual macOS status.

### Missing-helper setup correction — local build

macOS service-manager logs on October 13 showed `unregister` rejected because
BTM had no record for the new helper. `prepare` now skips unregister for
`.notFound`, as it already does for `.notRegistered`, while retaining the sleep
restoration check and migration guard before registration. The regression test
makes unregister fail and verifies that a missing helper proceeds directly to
registration. All 130 Swift tests pass. The old helper is still present on this
Mac and must be removed through the old app; this fix does not bypass migration
or background-service approval. No new public release was made for this fix.

### Local installed identity cleanup — October 13, 2026

Removed the legacy closed-lid helper using the old app's own Settings action;
launchctl then confirmed that com.awakemac.helper was absent. Replaced the
Applications copy with the signed bee-icon WakeBee build, including the setup
and Keychain diagnostic fixes. The old copy is preserved only as a ZIP under
dist/migration-backup. The retired launch-at-login entry could not be verified
as removed because System Settings control was denied by the tool.

Release commands now accept `WakeBee-Notary` via an ignored local alias file.
The alias resolves to the unchanged protected Apple credential; authentication
was verified without requesting Keychain access. This is a configuration rename,
not a rename of the credential stored by Apple. First-time credential setup
removes the alias after successfully storing a real WakeBee-named credential.
All 21 Python packaging/configuration checks pass.

### Release 0.15.1 (28) — October 13, 2026

Published the bee-icon app and installer, missing-helper setup correction, and
operation-specific Keychain diagnostics in WakeBee-Releases. Apple accepted app
submission `c2a2833c-5c29-4628-9f71-780cbed9169f` and DMG submission
`71748dc4-0b70-4eb3-b54c-d86d79d30a08`. Strict signatures, stapled tickets,
Gatekeeper, mounted installer contents, and arm64/x86_64 macOS 14 targets passed.
The relevant Swift suite has 130 passing tests; 21 packaging/configuration checks
and the website production build plus 26 browser checks pass. The website link
is updated locally; the website has not been deployed. Existing WakeBee identity
users receive the regular signed update; older identities get a signed manual
migration notice. Physical lid behavior, Intel runtime, and the friend's original
setup failure have not been verified by this release process.

### Release 0.15.2 (29) — October 13, 2026

Published the latest supplied bee artwork in the app and installer. No behavioral
code changed from 0.15.1. Apple accepted app notarization
`c146e183-19ce-4ceb-9296-c232542b312a` and installer notarization
`5622dff3-18a8-42c1-ab6f-ea0225868df9`. Strict signatures, tickets, Gatekeeper,
mounted contents, final icon, and universal macOS 14 targets passed verification.
All 21 packaging/configuration checks and the website build with 26 browser
checks passed. Download links are updated locally; the website was not deployed.
The legacy signed feed points to the new manual migration instructions.
