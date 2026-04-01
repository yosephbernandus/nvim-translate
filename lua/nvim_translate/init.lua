local M = {}

local config  = require("nvim_translate.config")
local detect  = require("nvim_translate.detect")
local ui      = require("nvim_translate.ui")
local Cache   = require("nvim_translate.cache")

local backends = {
  google = require("nvim_translate.backends.google"),
  claude = require("nvim_translate.backends.claude"),
}

local _cache          = nil
local _active_backend = "google"

function M.setup(opts)
  config.setup(opts)
  local cfg = config.get()
  _cache          = Cache.new(cfg.cache_size)
  _active_backend = cfg.backend or "google"

  local km = cfg.keymap or {}

  local augroup = vim.api.nvim_create_augroup("nvim_translate_keys", { clear = true })

  if km.normal and km.normal ~= "" then
    local function set_keys()
      vim.keymap.set("n", km.normal, M.translate_word, {
        buffer  = true,
        silent  = true,
        noremap = true,
        desc    = "Translate word/block under cursor",
      })
      vim.keymap.set("v", km.normal, M.translate_visual, {
        buffer  = true,
        silent  = true,
        noremap = true,
        desc    = "Translate visual selection",
      })
    end
    vim.api.nvim_create_autocmd("BufEnter", {
      group    = augroup,
      callback = function() vim.schedule(set_keys) end,
    })
    vim.schedule(set_keys)
  end

  if km.visual and km.visual ~= "" and km.visual ~= km.normal then
    vim.keymap.set("v", km.visual, M.translate_visual, {
      silent  = true,
      noremap = true,
      desc    = "Translate visual selection",
    })
  end
end

function M.set_backend(name)
  if not backends[name] then
    vim.notify("[nvim-translate] Unknown backend: " .. tostring(name) .. ". Use 'google' or 'claude'", vim.log.levels.WARN)
    return
  end
  _active_backend = name
  _cache = Cache.new(require("nvim_translate.config").get().cache_size)
  vim.notify("[nvim-translate] Backend: " .. name .. " (cache cleared)")
end

function M.get_backend()
  return _active_backend
end

local function do_translate(text)
  if not text or text == "" or not text:match("[\x80-\xFF]") then
    vim.lsp.buf.hover()
    return
  end

  local cached = _cache:get(text)
  if cached then
    ui.show(text, cached, _active_backend)
    return
  end

  local cfg         = config.get()
  local backend     = backends[_active_backend]
  local lang_hint   = detect.get_lang_hint(text)
  local target_lang = cfg.target_lang or "en"
  local bcfg        = cfg[_active_backend] or {}

  ui.show(text, "Translating\xe2\x80\xa6", _active_backend)

  backend.translate(text, lang_hint, target_lang, bcfg, function(err, translation)
    if err then
      ui.show(text, "Error: " .. err, _active_backend)
    else
      _cache:set(text, translation)
      ui.show(text, translation, _active_backend)
    end
  end)
end

function M.translate_word()
  local text = detect.get_cword()
  do_translate(text)
end

function M.translate_visual()
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "x", false)
  vim.schedule(function()
    local text = detect.get_visual_selection()
    do_translate(text)
  end)
end

return M
