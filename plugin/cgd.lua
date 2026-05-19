if vim.g.cgd_loaded then return end
vim.g.cgd_loaded = true

-- Register commands with defaults. Override via require("cgd").setup({...})
require("cgd.commands").setup()
