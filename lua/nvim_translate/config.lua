local M = {}

local defaults = {
  target_lang = "en", -- target language code (e.g. "en", "id", "zh", "ko")
  backend = "google", -- "google" | "claude"
  google = {
    timeout = 10,
  },
  claude = {
    -- uses `claude` CLI (Claude Code subscription auth), no API key needed
    model   = "claude-haiku-4-5-20251001",
    timeout = 20,
  },
  cache_size = 200,
  keymap = {
    normal = "K",
    visual = "<leader>tt",
  },
  popup = {
    max_width = 80,
    min_width = 30,
    winblend  = 10,
  },
}

local _config = vim.deepcopy(defaults)

function M.setup(user_opts)
  _config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), user_opts or {})
end

function M.get()
  return _config
end

return M
