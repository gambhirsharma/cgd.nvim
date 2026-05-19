local M = {}

function M.setup(opts)
  require("cgd.config").setup(opts)
  require("cgd.commands").setup()
end

return M
