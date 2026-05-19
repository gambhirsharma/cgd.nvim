local M = {}

local spinner_frames = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_timer = nil
local spinner_idx = 1

function M.start_loading(msg)
  spinner_idx = 1
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
  end
  spinner_timer = vim.uv.new_timer()
  spinner_timer:start(0, 100, vim.schedule_wrap(function()
    spinner_idx = (spinner_idx % #spinner_frames) + 1
    vim.api.nvim_echo(
      { { " " .. spinner_frames[spinner_idx] .. " CGD: " .. (msg or "thinking..."), "DiagnosticInfo" } },
      false, {}
    )
  end))
end

function M.stop_loading()
  if spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
  vim.api.nvim_echo({ { "", "Normal" } }, false, {})
end

function M.notify(msg, level)
  vim.notify("[CGD] " .. msg, level or vim.log.levels.INFO)
end

function M.error(msg)
  vim.notify("[CGD] " .. msg, vim.log.levels.ERROR)
end

-- Floating streaming preview -----------------------------------------------

local float = { bufnr = nil, winnr = nil, content = "" }

function M.open_float(title)
  if float.winnr and vim.api.nvim_win_is_valid(float.winnr) then
    vim.api.nvim_win_close(float.winnr, true)
  end

  local width  = math.min(math.floor(vim.o.columns * 0.72), 110)
  local height = math.floor(vim.o.lines * 0.45)
  local col    = math.floor((vim.o.columns - width) / 2)
  local row    = math.floor((vim.o.lines - height) / 2)

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.bo[bufnr].buftype  = "nofile"
  vim.bo[bufnr].swapfile = false

  local win_opts = {
    relative  = "editor",
    width     = width,
    height    = height,
    col       = col,
    row       = row,
    style     = "minimal",
    border    = "rounded",
    title     = " " .. (title or "CGD") .. " ",
    title_pos = "center",
  }
  -- footer requires nvim 0.10+
  pcall(function() win_opts.footer = " streaming... " end)
  pcall(function() win_opts.footer_pos = "center" end)

  local winnr = vim.api.nvim_open_win(bufnr, false, win_opts)
  vim.wo[winnr].wrap      = true
  vim.wo[winnr].linebreak = true
  vim.wo[winnr].cursorline = false

  float.bufnr   = bufnr
  float.winnr   = winnr
  float.content = ""
end

function M.update_float(_, full_content)
  if not float.bufnr or not vim.api.nvim_buf_is_valid(float.bufnr) then return end
  float.content = full_content
  local lines = vim.split(full_content, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(float.bufnr, 0, -1, false, lines)
  if float.winnr and vim.api.nvim_win_is_valid(float.winnr) then
    pcall(vim.api.nvim_win_set_cursor, float.winnr, { #lines, 0 })
  end
end

-- Call when streaming is done. on_accept(content), on_reject() called from main thread.
function M.finalize_float(on_accept, on_reject)
  if not float.bufnr or not vim.api.nvim_buf_is_valid(float.bufnr) then return end

  -- Update footer hint
  if float.winnr and vim.api.nvim_win_is_valid(float.winnr) then
    pcall(vim.api.nvim_win_set_config, float.winnr, {
      footer     = " <CR> accept · q/Esc reject ",
      footer_pos = "center",
    })
    vim.api.nvim_set_current_win(float.winnr)
  end

  local bufnr = float.bufnr

  local function close()
    if float.winnr and vim.api.nvim_win_is_valid(float.winnr) then
      vim.api.nvim_win_close(float.winnr, true)
    end
    float.bufnr = nil
    float.winnr = nil
  end

  vim.keymap.set("n", "<CR>", function()
    local content = float.content
    close()
    on_accept(content)
  end, { buffer = bufnr, nowait = true })

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      close()
      on_reject()
    end, { buffer = bufnr, nowait = true })
  end
end

function M.close_float()
  if float.winnr and vim.api.nvim_win_is_valid(float.winnr) then
    vim.api.nvim_win_close(float.winnr, true)
  end
  float.bufnr = nil
  float.winnr = nil
end

return M
