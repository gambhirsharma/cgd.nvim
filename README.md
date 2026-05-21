# cgd.nvim

AI text editing for Neovim. Select text, run `:Cgd <prompt>`, get replacement.

## Requirements

- Neovim 0.10+ (uses `vim.system()`)
- `curl`, `jq`
- API key from [openrouter.ai](https://openrouter.ai/keys)

## Install

**lazy.nvim:**

```lua
{
  "gambhirsharma/cgd.nvim",
  config = function()
    require("cgd").setup({
      -- endpoint = "https://openrouter.ai/api/v1/chat/completions",
      -- model = "openai/gpt-4o-mini",
      -- token = "sk-or-...",  -- or set OPENROUTER_API_KEY env var
    })
  end,
}
```

**Environment:**

```bash
export OPENROUTER_API_KEY=sk-or-...
```

## Usage

1. Visually select text (`v`, `V`, or `<C-v>`)
2. Run a command:

```vim
:Cgd rewrite professionally
:Cgd optimize this code
:Cgd fix the bug
:Cgd add error handling
```

**Shorthands:**

```vim
:CgdFix        " fix all bugs
:CgdOptimize   " optimize for performance
:CgdRewrite    " cleaner, more idiomatic
:CgdExplain    " explain clearly
:CgdTests      " write unit tests
```

**Keymaps:**

```lua
vim.keymap.set("v", "<leader>ai",  ":<C-u>lua require('cgd.commands').prompt()<CR>", { desc = "CGD: prompt" })
vim.keymap.set("v", "<leader>aif", ":<C-u>CgdFix<CR>",      { desc = "CGD: fix" })
vim.keymap.set("v", "<leader>aie", ":<C-u>CgdExplain<CR>",  { desc = "CGD: explain" })
vim.keymap.set("v", "<leader>aio", ":<C-u>CgdOptimize<CR>", { desc = "CGD: optimize" })
vim.keymap.set("v", "<leader>air", ":<C-u>CgdRewrite<CR>",  { desc = "CGD: rewrite" })
vim.keymap.set("v", "<leader>ait", ":<C-u>CgdTests<CR>",    { desc = "CGD: tests" })
```

## CLI

```bash
# Install
cp scripts/cgd ~/.local/bin/cgd

# Use
echo "hello world" | cgd "rewrite professionally"
cat file.py | cgd "add type hints"
```

## Config

```lua
require("cgd").setup({
  endpoint  = "https://openrouter.ai/api/v1/chat/completions",
  model     = "openai/gpt-4o-mini",
  token     = nil,        -- falls back to OPENROUTER_API_KEY env var
  token_env = "OPENROUTER_API_KEY",
  timeout   = 30,         -- seconds
  system_prompt = "...",  -- override the system prompt
})
```
