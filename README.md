# nvim-translate

Hover translation for Neovim. Press a key on any non-English text and get an instant translation in a floating window. No API keys required for the default backend.

Designed for developers working with foreign-language codebases. Japanese comments, Chinese docs, Korean strings, or anything else. The source text stays untouched; you just see the translation on demand.

## Features

- **Hover translate** translates the word or block under cursor in normal mode
- **Visual translate** select text and translate the whole selection
- **Custom keymaps** bind to any key you want
- **Multi-backend** Google Translate (default) or Claude CLI
- **Session cache** translated text is cached in memory, no repeat API calls
- **Japanese optimized** auto-detects Japanese for better source language hints
- **Any language** works with Chinese, Korean, French, Arabic, and more (auto-detect)
- **Configurable target** translate to English, Indonesian, Chinese, or any language
- **LSP fallthrough** on English or code text, falls through to LSP hover as normal

## Requirements

- Neovim >= 0.10
- [nui.nvim](https://github.com/MunifTanjim/nui.nvim)
- [translate-shell](https://github.com/soimort/translate-shell) (`trans` CLI) for the Google backend

## Installation

### 1. Install translate-shell

```bash
# macOS
brew install translate-shell

# Ubuntu / Debian
sudo apt install translate-shell

# Arch
sudo pacman -S translate-shell

# Fedora
sudo dnf install translate-shell
```

### 2. Add the plugin

**lazy.nvim (minimal)**

```lua
{
  'yosephbernandus/nvim-translate',
  dependencies = { 'MunifTanjim/nui.nvim' },
  event = 'VeryLazy',
  keys = {
    { 'K', function() require('nvim_translate').translate_word() end,   mode = 'n', desc = 'Translate word under cursor' },
    { 'K', function() require('nvim_translate').translate_visual() end, mode = 'v', desc = 'Translate selection' },
  },
  opts = {},
}
```

**With custom keymaps and options:**

```lua
{
  'yosephbernandus/nvim-translate',
  dependencies = { 'MunifTanjim/nui.nvim' },
  event = 'VeryLazy',
  keys = {
    -- use whatever keymaps you prefer
    { '<leader>k', function() require('nvim_translate').translate_word() end,   mode = 'n', desc = 'Translate word' },
    { '<leader>k', function() require('nvim_translate').translate_visual() end, mode = 'v', desc = 'Translate selection' },
  },
  opts = {
    target_lang = 'en',
    backend = 'google',
    keymap = {
      normal = '',          -- disable built-in keymaps (using lazy.nvim keys above)
      visual = '',
    },
    claude = {
      -- Available models: https://docs.anthropic.com/en/docs/about-claude/models
      model = 'claude-haiku-4-5-20251001',
    },
  },
}
```

## Usage

### Keymaps

The plugin provides two functions you can bind to any key:

| Function | Description |
|----------|-------------|
| `require('nvim_translate').translate_word()` | Translate word or block under cursor |
| `require('nvim_translate').translate_visual()` | Translate visual selection |

Bind them however you like via lazy.nvim `keys`, `vim.keymap.set`, or the built-in `keymap` config option.

If the text under cursor is pure ASCII, `translate_word()` falls through to `vim.lsp.buf.hover()`, so sharing a key with LSP hover works without conflict.

### Commands

| Command | Description |
|---------|-------------|
| `:Translate` | Translate word under cursor |
| `:TranslateV` | Translate visual selection |
| `:TranslateBackend google` | Switch to Google Translate |
| `:TranslateBackend claude` | Switch to Claude |

### Health check

```vim
:checkhealth nvim_translate
```

## Backends

### Google (default)

Uses [translate-shell](https://github.com/soimort/translate-shell) (`trans` CLI) which calls Google Translate's public endpoint. No API key needed.

```bash
# verify it works
trans -b ja:en "これはテストです"
```

### Claude

Uses the `claude` CLI from [Claude Code](https://claude.ai/claude-code). Requires an active Claude subscription. No separate API key needed.

```vim
:TranslateBackend claude
```

## Configuration

Full default configuration:

```lua
require('nvim_translate').setup({
  target_lang = 'en',       -- target language code
  backend = 'google',       -- 'google' | 'claude'
  google = {
    timeout = 10,           -- seconds
  },
  claude = {
    -- Available models: https://docs.anthropic.com/en/docs/about-claude/models
    model   = 'claude-haiku-4-5-20251001',
    timeout = 20,           -- seconds
  },
  cache_size = 200,         -- max cached translations per session
  keymap = {
    normal = 'K',           -- built-in normal mode keymap (set '' to disable)
    visual = '<leader>tt',  -- built-in visual mode keymap (set '' to disable)
  },
  popup = {
    max_width = 80,
    min_width = 30,
    winblend  = 10,         -- popup transparency (0 = opaque, 100 = invisible)
  },
})
```

## How it works

1. Press your configured key. The plugin grabs the contiguous non-ASCII text block around the cursor.
2. Checks the session cache. If already translated, shows instantly.
3. Detects if the text is Japanese for a better source-language hint.
4. Calls the active backend asynchronously (`trans` CLI or `claude` CLI).
5. Shows the translation in a floating window at the cursor.
6. Float auto-closes when you move the cursor.

## Architecture

```
You install the plugin (interface + display).
You bring your own backend (your machine, your tools).

No shared API keys. No centralized endpoints. Fully self-contained.
```

## License

MIT
