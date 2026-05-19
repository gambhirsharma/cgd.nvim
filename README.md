# cgd.nvim

AI text editing for Neovim. Select text, run `:Cgd <prompt>`, get replacement.

## Requirements

- Neovim 0.10+ (uses `vim.system()`)
- `curl`, `jq`
- API key from [chat.gambhir.dev](https://chat.gambhir.dev)

## Install

**lazy.nvim:**

```lua
{
  dir = "~/coding/cgd.nvim",   -- or GitHub path once published
  config = function()
    require("cgd").setup({
      -- endpoint = "https://chat.gambhir.dev/v1/chat/completions",
      -- model = "qwen2.5",
      -- token = "sk-gam-...",  -- or set CGD_TOKEN env var
    })
  end,
}
```

**Environment:**

```bash
export CGD_TOKEN=sk-gam-...
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

**Keymap:**

```lua
vim.keymap.set("v", "<leader>ai", function()
  vim.ui.input({ prompt = "CGD prompt: " }, function(input)
    if input and input ~= "" then
      require("cgd.commands")  -- commands already registered
      vim.cmd("'<,'>Cgd " .. input)
    end
  end)
end, { desc = "CGD AI edit" })
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
  endpoint  = "https://chat.gambhir.dev/v1/chat/completions",
  model     = "qwen2.5",
  token     = nil,        -- falls back to CGD_TOKEN env var
  token_env = "CGD_TOKEN",
  timeout   = 30,         -- seconds
  system_prompt = "...",  -- override the system prompt
})
```
