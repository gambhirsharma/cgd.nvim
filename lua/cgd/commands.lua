local M = {}

local function run(prompt)
  local ui        = require("cgd.ui")
  local selection = require("cgd.selection")
  local api       = require("cgd.api")
  local replace   = require("cgd.replace")

  if not prompt or vim.trim(prompt) == "" then
    ui.error("Usage: visually select text, then :Cgd <prompt>")
    return
  end

  local sel, err = selection.get()
  if not sel then
    ui.error(err)
    return
  end

  local edit_winnr = vim.api.nvim_get_current_win()

  ui.open_float("CGD: " .. prompt)

  api.stream(prompt, sel.text,
    function(_, full)
      ui.update_float(nil, full)
    end,
    function(response, api_err)
      if api_err then
        ui.close_float()
        ui.error(api_err)
        return
      end
      if not response or response == "" then
        ui.close_float()
        ui.error("Empty response from API")
        return
      end

      ui.finalize_float(
        function(content)
          if vim.api.nvim_win_is_valid(edit_winnr) then
            vim.api.nvim_set_current_win(edit_winnr)
          end
          replace.apply(sel.bufnr, sel.start_line, sel.end_line, content)
          ui.notify("Applied")
        end,
        function()
          if vim.api.nvim_win_is_valid(edit_winnr) then
            vim.api.nvim_set_current_win(edit_winnr)
          end
          ui.notify("Rejected")
        end
      )
    end
  )
end

-- Called from <leader>ai keymap
function M.prompt()
  vim.ui.input({ prompt = "CGD > " }, function(input)
    if input and vim.trim(input) ~= "" then
      run(input)
    end
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
