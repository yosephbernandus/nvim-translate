local M = {}

-- Translates text via the `claude` CLI (Claude Code subscription, no API key needed).
-- lang_hint: "JA" or nil
-- target_lang: target language code (e.g. "en", "id", "zh")
-- callback: function(err: string|nil, translation: string|nil)
function M.translate(text, lang_hint, target_lang, cfg, callback)
  if vim.fn.executable("claude") == 0 then
    callback("'claude' CLI not found in PATH. Install Claude Code first.", nil)
    return
  end

  -- Map common codes to full names for the prompt
  local lang_names = {
    en = "English", id = "Indonesian", ja = "Japanese", zh = "Chinese",
    ko = "Korean", fr = "French", de = "German", es = "Spanish",
    pt = "Portuguese", ru = "Russian", ar = "Arabic", th = "Thai",
    vi = "Vietnamese", nl = "Dutch", it = "Italian",
  }
  local tl = target_lang or "en"
  local target_name = lang_names[tl] or tl

  local prompt
  if lang_hint == "JA" then
    prompt = "Translate this Japanese text to " .. target_name .. ". Return only the translation, no explanation:\n\n" .. text
  else
    prompt = "Translate the following text to " .. target_name .. ". Return only the translation, no explanation:\n\n" .. text
  end

  local model = cfg.model or "claude-haiku-4-5-20251001"
  local cmd = { "claude", "--max-turns", "1", "--model", model, "-p", prompt }

  vim.system(cmd, { text = true, timeout = (cfg.timeout or 20) * 1000 }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err = vim.trim(result.stderr or "")
        callback("claude error: " .. (err ~= "" and err or "exit code " .. result.code), nil)
        return
      end
      local translation = vim.trim(result.stdout or "")
      if translation == "" then
        callback("Empty response from claude CLI", nil)
        return
      end
      callback(nil, translation)
    end)
  end)
end

return M
