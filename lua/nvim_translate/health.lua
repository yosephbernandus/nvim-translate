local M = {}

function M.check()
  local h = vim.health

  h.start("nvim-translate")

  -- Neovim version
  if vim.fn.has("nvim-0.10") == 1 then
    h.ok("Neovim >= 0.10")
  else
    h.error("Neovim >= 0.10 required (vim.system and vim.fn.getregion)")
  end

  -- trans CLI (translate-shell) — required for google backend
  if vim.fn.executable("trans") == 1 then
    h.ok("trans (translate-shell) found — google backend ready")
  else
    h.warn("trans not found — google backend will not work. Install: brew install translate-shell")
  end

  -- claude CLI — required for claude backend
  if vim.fn.executable("claude") == 1 then
    h.ok("claude CLI found — claude backend ready")
  else
    h.warn("claude CLI not found — claude backend will not work. Install Claude Code.")
  end

  -- nui.nvim
  local ok = pcall(require, "nui.popup")
  if ok then
    h.ok("nui.nvim found")
  else
    h.error("nui.nvim not found. Add MunifTanjim/nui.nvim as a dependency.")
  end

  -- active backend
  local cfg = require("nvim_translate.config").get()
  h.info("Active backend: " .. (cfg.backend or "google"))
  h.info("Target language: " .. (cfg.target_lang or "en"))
end

return M
