local M = {}

-- Translates text via the `trans` CLI (translate-shell).
-- No API key needed — uses Google Translate's public endpoint.
-- Install: brew install translate-shell
-- lang_hint: "JA" or nil
-- target_lang: target language code (e.g. "en", "id", "zh")
-- callback: function(err: string|nil, translation: string|nil)
function M.translate(text, lang_hint, target_lang, cfg, callback)
  if vim.fn.executable("trans") == 0 then
    callback("'trans' not found. Install translate-shell: brew install translate-shell", nil)
    return
  end

  local tl = target_lang or "en"
  -- "ja:en" when source is known Japanese; ":en" lets trans auto-detect source
  local lang_pair = (lang_hint == "JA") and ("ja:" .. tl) or (":" .. tl)

  -- -b = brief mode: returns only the translated text, no phonetics or definitions
  local cmd = { "trans", "-b", lang_pair, text }

  vim.system(cmd, { text = true, timeout = (cfg.timeout or 10) * 1000 }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        local err = vim.trim(result.stderr or "")
        callback("trans error: " .. (err ~= "" and err or "exit code " .. result.code), nil)
        return
      end
      local translation = vim.trim(result.stdout or "")
      if translation == "" then
        callback("Empty response from trans", nil)
        return
      end
      callback(nil, translation)
    end)
  end)
end

return M
