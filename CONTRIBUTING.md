# Contributing to WakeBee

Thanks for helping improve WakeBee. Small, focused changes are welcome—especially clearer setup, reliable session behavior, accessibility, and documentation.

## Report a bug

[Open an issue](https://github.com/jswladitya/WakeBee/issues/new) with:

- Your Mac model and chip, macOS version, and WakeBee version.
- What you expected, what happened, and steps to reproduce it.
- A screenshot or the relevant error message.
- For power or closed-lid issues: charger state, selected mode, and any message in **Setup details**.

Remove license keys, passwords, and personal information before posting. If the issue affects sleep or lid behavior, keep the lid open while collecting details.

## Make a change

1. Fork the repository and create a branch for your change.
2. Follow the [development guide](docs/DEVELOPMENT.md) to build locally.
3. Keep the change focused. For larger changes to power behavior, licensing, or the helper protocol, open an issue to discuss the approach first.
4. Run the checks relevant to your change:

   ```sh
   swift test --disable-sandbox
   python3 -m unittest discover -s script -p 'test_*.py'
   ```

5. Open a pull request describing the problem, the resulting behavior, and how you checked it. Include before/after screenshots for interface changes.

Documentation-only changes do not need an app build; check links, commands, and wording against the current source.

## Keep the project easy to maintain

- Put session and policy logic in `WakeBeeCore`; keep platform integration in the app or helper.
- Preserve power limits, authenticated XPC, and recovery behavior. A timer running is not proof that closed-lid mode is ready.
- Use test doubles for licensing and power settings. Do not make automated tests depend on real purchases or alter the host's sleep policy.
- Keep generated bundles, credentials, Keychain exports, and real license keys out of commits.
- Say which behavior you tested on hardware and which you checked only in code or simulations.

Contributions are made under the repository's [GNU Affero General Public License, version 3 only](LICENSE) (`AGPL-3.0-only`).
