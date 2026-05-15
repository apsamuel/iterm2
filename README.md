# vendor/iterm2

> iTerm2 profiles and configuration management.

This vendor submodule stores iTerm2 configuration profiles. Terminal color
schemes (for iTerm2, Alacritty, Kitty, VS Code, and others) are now provided
by the top-level `vendor/themes` submodule
([mbadolato/iTerm2-Color-Schemes](https://github.com/mbadolato/iTerm2-Color-Schemes)).

---

## Structure

```
vendor/iterm2/
├── config/
│   ├── Default.json       Default iTerm2 profile
│   ├── Profiles.json      All profiles (imported into iTerm2)
│   └── quake.json         Quake-mode dropdown terminal profile
└── scripts/
    └── dump-preferences.sh
```

---

## Usage

The root `dot` Makefile provides a `config-iterm` target that symlinks or
copies iTerm2 profiles into place:

```bash
make config-iterm              # configure iTerm2
DRY=1 make config-iterm        # preview only
```

---

## Color Schemes

Color schemes have moved to the top-level `vendor/themes` submodule.
To apply one:

1. Open iTerm2 → Preferences → Profiles → Colors → Color Presets…
2. Import from `vendor/themes/schemes/<name>.itermcolors`

Or use the profiles in `config/` which already reference preferred schemes.

---

## Related

- Root target: `make config-iterm`
- Themes: `vendor/themes/` (top-level submodule)
- [vendor/README.md](../README.md)
