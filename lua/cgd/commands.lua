local M = {}

local function run(prompt)
  local ui = require("cgd.ui")
  local selection = require("cgd.selection")
  local api = require("cgd.api")
  local replace = require("cgd.replace")

  if not prompt or vim.trim(prompt) == "" then
    ui.error("Usage: visually select text, then :Cgd <prompt>")
    return
  end

  local sel, err = selection.get()
  if not sel then
    ui.error(err)
    return
  end

  ui.start_loading("thinking...")

  api.complete(prompt, sel.text, function(response, api_err)
    vim.schedule(function()
      ui.stop_loading()
      if api_err then
        ui.error(api_err)
        return
      end
      replace.apply(sel.bufnr, sel.start_line, sel.end_line, response)
      ui.notify("Done")
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("Cgd", function(opts)
    run(opts.args)
  end, {
    nargs = "+",
    range = true,
    desc = "AI edit: visually select text, then :Cgd <prompt>",
  })

  local shorthands = {
    CgdExplain  = "explain this clearly",
    CgdFix      = "fix all bugs in this code",
    CgdOptimize = "optimize this code for performance and readability",
    CgdRewrite  = "rewrite this to be cleaner and more idiomatic",
    CgdTests    = "write comprehensive unit tests for this",
  }

  for name, prompt in pairs(shorthands) do
    local p = prompt
    vim.api.nvim_create_user_command(name, function()
      run(p)
    end, { range = true, desc = "CGD: " .. p })
  end
end

return M
