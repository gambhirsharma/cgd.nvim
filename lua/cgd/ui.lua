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

return M
