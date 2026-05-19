local M = {}

function M.get()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2]
  local end_line = end_pos[2]

  if start_line == 0 or end_line == 0 then
    return nil, "No visual selection. Select text first, then run :Cgd <prompt>"
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line - 1, end_line, false)

  if #lines == 0 then
    return nil, "Empty selection"
  end

  return {
    lines = lines,
    text = table.concat(lines, "\n"),
    start_line = start_line,
    end_line = end_line,
    bufnr = bufnr,
  }
end

return M
