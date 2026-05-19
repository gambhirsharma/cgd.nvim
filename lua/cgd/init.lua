local M = {}

function M.setup(opts)
  require("cgd.config").setup(opts)
  require("cgd.commands").setup()

  local cfg = require("cgd.config").get()
  if cfg.keymap then
    vim.keymap.set("v", cfg.keymap, function()
      M.prompt()
    end, { desc = "CGD AI edit (prompt)" })
  end
end

-- Trigger vim.ui.input prompt then run. Call from keymaps.
function M.prompt()
  require("cgd.commands").prompt()
end

return M
