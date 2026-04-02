local M = {}

local _popup       = nil
local _augroup     = nil
local _source_text = nil

-- Word-wrap with tracked width — O(words) FFI calls instead of O(words²).
local function wrap_line(line, max_w)
  if vim.fn.strdisplaywidth(line) <= max_w then
    return { line }
  end
  local result = {}
  local current = ""
  local current_w = 0
  for word in (line .. " "):gmatch("(%S+)%s") do
    local word_w = vim.fn.strdisplaywidth(word)
    local sep_w = current == "" and 0 or 1
    if current_w + sep_w + word_w <= max_w then
      current = current == "" and word or (current .. " " .. word)
      current_w = current_w + sep_w + word_w
    else
      if current ~= "" then result[#result + 1] = current end
      if word_w > max_w then
        local seg, seg_w = "", 0
        for char in word:gmatch(".[\128-\191]*") do
          local cw = vim.fn.strdisplaywidth(char)
          if seg_w + cw <= max_w then
            seg = seg .. char
            seg_w = seg_w + cw
          else
            if seg ~= "" then result[#result + 1] = seg end
            seg, seg_w = char, cw
          end
        end
        current, current_w = seg, seg_w
      else
        current, current_w = word, word_w
      end
    end
  end
  if current ~= "" then result[#result + 1] = current end
  return result
end

local function close()
  if _popup then
    pcall(function() _popup:unmount() end)
    _popup = nil
  end
  if _augroup then
    pcall(vim.api.nvim_del_augroup_by_id, _augroup)
    _augroup = nil
  end
end

-- Shows a translation popup at the cursor.
-- backend_name: "google" | "claude" (shown in border title)
function M.show(source_text, translation, backend_name)
  local ok, Popup = pcall(require, "nui.popup")
  if not ok then
    vim.notify("[nvim-translate] nui.nvim not found. Install MunifTanjim/nui.nvim", vim.log.levels.ERROR)
    return
  end

  close()

  local cfg   = require("nvim_translate.config").get()
  local title = " [" .. (backend_name or "translate") .. "] "

  local max_w = math.min(
    cfg.popup.max_width or 80,
    math.floor(vim.o.columns * 0.80)
  )
  max_w = math.max(max_w, cfg.popup.min_width or 30)

  local raw_lines = vim.split(translation, "\n", { plain = true })
  local lines = {}
  for _, raw in ipairs(raw_lines) do
    local wrapped = wrap_line(raw, max_w - 2)
    for _, wl in ipairs(wrapped) do
      lines[#lines + 1] = wl
    end
  end

  local width = math.max(#title + 2, cfg.popup.min_width or 30)
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 2)
  end
  width = math.min(width, max_w)

  local height = #lines

  local src_buf = vim.api.nvim_get_current_buf()

  local popup = Popup({
    relative  = "cursor",
    position  = { row = 1, col = 0 },
    size      = { width = width, height = height },
    enter     = false,
    focusable = false,
    zindex    = 60,
    border    = {
      style   = "rounded",
      padding = { 0, 1 },
      text    = {
        top       = title,
        top_align = "center",
      },
    },
    buf_options = {
      modifiable = true,
      buftype    = "nofile",
      filetype   = "nvim_translate",
    },
    win_options = {
      winblend     = cfg.popup.winblend or 10,
      wrap         = false,
      winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
    },
  })

  popup:mount()

  vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = popup.bufnr })

  _popup       = popup
  _source_text = source_text

  _augroup = vim.api.nvim_create_augroup("nvim_translate_close", { clear = true })
  vim.api.nvim_create_autocmd(
    { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" },
    {
      group    = _augroup,
      buffer   = src_buf,
      once     = true,
      callback = function()
        vim.schedule(close)
      end,
    }
  )
end

function M.close()
  close()
end

function M.is_open()
  return _popup ~= nil
end

-- Update an existing popup in-place (same position). If the popup was
-- already closed (user moved away), silently discard the result.
function M.update(source_text, translation, backend_name)
  if not _popup or _source_text ~= source_text then return end

  local cfg   = require("nvim_translate.config").get()
  local max_w = math.min(cfg.popup.max_width or 80, math.floor(vim.o.columns * 0.80))
  max_w = math.max(max_w, cfg.popup.min_width or 30)

  local raw_lines = vim.split(translation, "\n", { plain = true })
  local lines = {}
  for _, raw in ipairs(raw_lines) do
    for _, wl in ipairs(wrap_line(raw, max_w - 2)) do
      lines[#lines + 1] = wl
    end
  end

  local width = math.max(cfg.popup.min_width or 30)
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line) + 2)
  end
  width = math.min(width, max_w)

  vim.api.nvim_set_option_value("modifiable", true, { buf = _popup.bufnr })
  vim.api.nvim_buf_set_lines(_popup.bufnr, 0, -1, false, lines)
  vim.api.nvim_set_option_value("modifiable", false, { buf = _popup.bufnr })

  local win = _popup.winid
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_set_width(win, width)
    vim.api.nvim_win_set_height(win, #lines)
  end
end

return M
