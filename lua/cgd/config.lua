local M = {}

M.defaults = {
  endpoint    = "https://openrouter.ai/api/v1/chat/completions",
  model       = "openai/gpt-4o-mini",
  token_env   = "OPENROUTER_API_KEY",
  token       = nil,
  timeout     = 120,
  keymap      = "<leader>ai",  -- false to disable
  system_prompt = "You are a code editor assistant. The user will provide selected text and an editing instruction. Return ONLY the modified text with no explanation, no markdown fences, and no preamble. Preserve the original indentation and line structure unless the instruction asks you to change it.",
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.get()
  if vim.tbl_isempty(M.options) then
    M.options = vim.deepcopy(M.defaults)
  end
  return M.options
end

return M
