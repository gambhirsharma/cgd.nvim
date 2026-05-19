local M = {}

local function build_cmd(token, tmpfile, cfg)
  return {
    "curl", "-s", "-f", "-N",
    "-X", "POST",
    "-H", "Content-Type: application/json",
    "-H", "Authorization: Bearer " .. token,
    "--max-time", tostring(cfg.timeout),
    "-d", "@" .. tmpfile,
    cfg.endpoint,
  }
end

local function build_body(prompt, text, cfg, stream)
  local filetype = vim.bo.filetype or ""
  local filename = vim.fn.expand("%:t") or ""
  local system_msg = cfg.system_prompt
  if filetype ~= "" then
    system_msg = system_msg .. "\nFile: " .. filename .. " (" .. filetype .. ")"
  end
  return vim.json.encode({
    model = cfg.model,
    messages = {
      { role = "system", content = system_msg },
      { role = "user",   content = prompt .. "\n\n" .. text },
    },
    stream = stream,
    temperature = 0.3,
  })
end

local function write_tmp(content)
  local path = vim.fn.tempname()
  local f = io.open(path, "w")
  if not f then return nil end
  f:write(content)
  f:close()
  return path
end

function M.complete(prompt, text, callback)
  local cfg = require("cgd.config").get()
  local token = cfg.token or vim.env[cfg.token_env]
  if not token or token == "" then
    callback(nil, "CGD_TOKEN not set. Run: export CGD_TOKEN=sk-gam-...")
    return
  end

  local tmpfile = write_tmp(build_body(prompt, text, cfg, false))
  if not tmpfile then
    callback(nil, "Failed to create temp file")
    return
  end

  vim.system(build_cmd(token, tmpfile, cfg), { text = true }, function(result)
    os.remove(tmpfile)
    if result.code ~= 0 then
      callback(nil, (result.stderr ~= "" and result.stderr) or ("curl exit " .. result.code))
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

-- on_token(token_str, full_response_so_far) — called from main thread
-- on_done(full_response | nil, err | nil)   — called from main thread
function M.stream(prompt, text, on_token, on_done)
  local cfg = require("cgd.config").get()
  local token = cfg.token or vim.env[cfg.token_env]
  if not token or token == "" then
    on_done(nil, "CGD_TOKEN not set. Run: export CGD_TOKEN=sk-gam-...")
    return
  end

  local tmpfile = write_tmp(build_body(prompt, text, cfg, true))
  if not tmpfile then
    on_done(nil, "Failed to create temp file")
    return
  end

  local leftover = ""
  local full = ""

  vim.system(build_cmd(token, tmpfile, cfg), {
    text = true,
    stdout = function(_, data)
      if not data then return end
      local chunk = leftover .. data
      local pos = 1
      while true do
        local nl = chunk:find("\n", pos, true)
        if not nl then break end
        local line = vim.trim(chunk:sub(pos, nl - 1))
        pos = nl + 1
        if vim.startswith(line, "data: ") then
          local json_str = line:sub(7)
          if json_str ~= "[DONE]" then
            local ok, parsed = pcall(vim.json.decode, json_str)
            if ok then
              local tok = vim.tbl_get(parsed, "choices", 1, "delta", "content")
              if tok then
                full = full .. tok
                local snapshot = full
                vim.schedule(function()
                  on_token(tok, snapshot)
                end)
              end
            end
          end
        end
      end
      leftover = chunk:sub(pos)
    end,
  }, function(result)
    os.remove(tmpfile)
    local final = full
    vim.schedule(function()
      if result.code ~= 0 then
        on_done(nil, (result.stderr ~= "" and result.stderr) or ("curl exit " .. result.code))
      else
        on_done(final, nil)
      end
    end)
  end)
end

return M
