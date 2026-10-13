# AwakeMac — first test release

AwakeMac is a menu-bar app for manual keep-awake sessions, with optional closed-lid protection. This is a development preview for testing.

## Install

1. Download [AwakeMac-0.12.1.dmg](https://github.com/jswladitya/AwakeMac-Releases/releases/download/v0.12.1/AwakeMac-0.12.1.dmg) and open it.
2. Drag **AwakeMac** onto **Applications** in the installer window. Open AwakeMac from Applications, then eject the installer. Requires macOS 14 or later; includes Apple silicon and Intel binaries.
3. Enter your AwakeMac license key. This build requires a valid license; downloading it does not unlock it.
4. Click the sun icon in the menu bar. There is no permanent Dock icon.

The app and DMG are Developer ID signed and notarized. A [ZIP download](https://github.com/jswladitya/AwakeMac-Releases/releases/download/v0.12.1/AwakeMac-0.12.1.zip) is also available; unzip it and move AwakeMac.app to Applications. Do not disable Gatekeeper or run commands to bypass macOS security warnings; report a launch problem instead.

## Try a session

- Connect your charger first; requiring a power adapter is on by default.
- Start a short **Timer**, check the countdown, then use **End session**.
- Try **Until** and **Unlimited**. Quit ends a session; reopening never resumes it automatically.
- In **Settings → General → Updates**, choose **Check for Updates…**.

## Optional closed-lid test

1. Keep the lid open and use a hard, ventilated surface.
2. Open **Settings → Closed Lid**. Install the helper and approve it in System Settings if asked.
3. Enable closed-lid mode, then start a short session with the charger connected.
4. Close the lid only after the app shows **Active — You can close the lid**. A running timer alone does not confirm lid protection.
5. Reopen the lid, end the session, and confirm the protection status turns off.

Battery use is opt-in. Closed-lid protection has battery, thermal, connection, and maximum-duration safeguards. Test on your Mac before relying on unattended work, and keep the lid open during app updates.

## Send feedback

Share your macOS version, Mac model, AwakeMac version, whether the charger was connected, steps to reproduce, and a screenshot of any error. Do not include your license key or passwords. Physical lid behavior across Mac models is still being tested.
