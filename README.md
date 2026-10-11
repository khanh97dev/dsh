# dsh

Installer for the DeepSeek Harness CLI (`@deepseek-ai/dsh`) and DSH Desktop.

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/install.sh | sh
```

Options (append with `sh -s -- <opts>`): `--cli-only`, `--desktop-only`, `--plugin`, `--version <tag>`.

- Platforms: Linux x64 (AppImage), macOS arm64/x64 (dmg), Windows x64 via Git Bash (setup.exe).
- CLI needs Node.js >= 22.
- `--plugin` also runs `dsh plugin --profile web add @opencode2dsh/dsh-plugin`.

## Plugin: free OpenCode models

```sh
curl -fsSL https://raw.githubusercontent.com/khanh97dev/dsh/main/plugin-opencode2dsh.sh | sh
```

Installs `@opencode2dsh/dsh-plugin` into the terminal harness (`~/.dsh`) and, if present, DSH Desktop's own harness (it uses a separate `DSH_HOME`). Options: `--desktop-only`, `--cli-only`, `--profile <name>`, `--package <spec>`. Restart DSH afterwards and pick a model from the **opencode2dsh** group.
