local M = {}

function M.complete(prompt, text, callback)
  local cfg = require("cgd.config").get()

  local token = cfg.token or vim.env[cfg.token_env]
  if not token or token == "" then
    callback(nil, "CGD_TOKEN not set. Run: export CGD_TOKEN=sk-gam-...")
    return
  end

  local filetype = vim.bo.filetype or ""
  local filename = vim.fn.expand("%:t") or ""

  local system_msg = cfg.system_prompt
  if filetype ~= "" then
    system_msg = system_msg .. "\nFile: " .. filename .. " (" .. filetype .. ")"
  end

  local body = vim.json.encode({
    model = cfg.model,
    messages = {
      { role = "system", content = system_msg },
      { role = "user",   content = prompt .. "\n\n" .. text },
    },
    stream = false,
    temperature = 0.3,
  })

  local tmpfile = vim.fn.tempname()
  local f = io.open(tmpfile, "w")
  if not f then
    callback(nil, "Failed to create temp file")
    return
  end
  f:write(body)
  f:close()

  local cmd = {
    "curl", "-s", "-f",
    "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. token,
    "--max-time", tostring(cfg.timeout),
    "-d", "@" .. tmpfile,
    cfg.endpoint,
  }

  vim.system(cmd, { text = true }, function(result)
    vim.fn.delete(tmpfile)

    if result.code ~= 0 then
      local err = (result.stderr ~= "" and result.stderr) or ("curl failed (exit " .. result.code .. ")")
      callback(nil, err)
      return
    end

    local ok, data = pcall(vim.json.decode, result.stdout)
    if not ok then
      callback(nil, "Invalid JSON: " .. result.stdout:sub(1, 200))
      return
    end

    if data.error then
      callback(nil, data.error.message or vim.inspect(data.error))
      return
    end

    local content = vim.tbl_get(data, "choices", 1, "message", "content")
    if not content then
      callback(nil, "No content in response")
      return
    end

    callback(content, nil)
  end)
end

return M
