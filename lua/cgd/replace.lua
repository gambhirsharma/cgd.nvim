local M = {}

function M.apply(bufnr, start_line, end_line, response_text)
  local new_lines = vim.split(response_text, "\n", { plain = true })

  -- Trim trailing blank line that AI often appends
  if #new_lines > 0 and new_lines[#new_lines] == "" then
    table.remove(new_lines)
  end

  vim.api.nvim_buf_set_lines(bufnr, start_line - 1, end_line, false, new_lines)
end

return M
