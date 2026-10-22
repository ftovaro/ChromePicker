# ChromePicker

A tiny native macOS utility that intercepts link clicks and asks which Chrome profile to open them in. Like Choosy, but free and built specifically for Chrome profiles.

## How it works

1. ChromePicker registers itself as a browser with macOS and lives in the menu bar
2. You set it as your default browser
3. Whenever you click a link anywhere (Slack, Mail, Terminal, etc.) a small picker appears next to your mouse
4. Pick a profile → Chrome opens the link in that exact profile

**Picker shortcuts:** `1`–`9` to pick a profile, `↑`/`↓` + `Return`, `Esc` or click outside to cancel.

## Build & Install

**Requirements:** macOS 13+, Apple Silicon, Xcode Command Line Tools (`xcode-select --install`), Google Chrome

```bash
git clone git@github.com:ftovaro/ChromePicker.git
cd ChromePicker
./build.sh
```

This compiles the app, installs it to `~/Applications/ChromePicker.app` and launches it.

## Setup

Open the ChromePicker menu bar icon and:

1. Choose **Set as Default Browser…** and confirm the macOS prompt
2. Enable **Launch at Login**

If your menu bar is crowded and the icon is hidden behind the notch, open ChromePicker again from Spotlight while it's running and the same menu appears at your mouse.

## Menu bar options

- **Pause Picker** — links go straight to Chrome's last used profile, no picker
- **Launch at Login**
- **Set as Default Browser…** — only shown when it isn't already
- **Quit ChromePicker** — note macOS relaunches it on the next link click while it's the default browser

## Notes

- Profiles are read from Chrome's `Local State` file in `~/Library/Application Support/Google/Chrome/`
- No data is collected or sent anywhere — it's entirely local

## Uninstall

1. Set your default browser back to Chrome in System Settings → Desktop & Dock
2. Quit ChromePicker from its menu (Launch at Login is removed with the app)
3. Delete `~/Applications/ChromePicker.app`
