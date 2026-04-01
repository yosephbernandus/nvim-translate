local M = {}

-- UTF-8 byte patterns for Japanese text (no utf8 library needed)
local JP_PATTERNS = {
  "[\xE3][\x81-\x83][\x80-\xBF]",      -- hiragana + katakana (U+3040-U+30FF)
  "[\xE4-\xE9][\x80-\xBF][\x80-\xBF]", -- CJK unified + extension A (U+4E00-U+9FFF)
  "[\xEF][\xBE-\xBF][\x80-\xBF]",      -- halfwidth katakana (U+FF65-U+FF9F)
}

-- Returns "JA" if text contains Japanese bytes, nil otherwise.
function M.get_lang_hint(text)
  if not text or text == "" then return nil end
  for _, pat in ipairs(JP_PATTERNS) do
    if text:match(pat) then return "JA" end
  end
  return nil
end

-- Pure Lua UTF-8 decoder. Single pass, zero FFI calls.
-- Returns array of { cp = codepoint, pos = 1-indexed byte offset, len = byte length }.
local function utf8_chars(str)
  local chars = {}
  local i = 1
  local n = #str
  while i <= n do
    local b = str:byte(i)
    local cp, len
    if b < 0x80 then
      cp, len = b, 1
    elseif b < 0xE0 then
      cp  = (b - 0xC0) * 64 + (str:byte(i + 1) - 0x80)
      len = 2
    elseif b < 0xF0 then
      cp  = (b - 0xE0) * 4096 + (str:byte(i + 1) - 0x80) * 64
            + (str:byte(i + 2) - 0x80)
      len = 3
    else
      cp  = (b - 0xF0) * 262144 + (str:byte(i + 1) - 0x80) * 4096
            + (str:byte(i + 2) - 0x80) * 64 + (str:byte(i + 3) - 0x80)
      len = 4
    end
    chars[#chars + 1] = { cp = cp, pos = i, len = len }
    i = i + len
  end
  return chars
end

-- Returns true if codepoint is a non-ASCII, non-space character.
local function is_foreign(cp)
  return cp > 0x7F and cp ~= 0x3000  -- 0x3000 = ideographic space
end

-- Binary search: find the char index whose byte pos is <= target byte.
local function find_char_at_byte(chars, byte_col_1)
  local lo, hi = 1, #chars
  local best = 1
  while lo <= hi do
    local mid = math.floor((lo + hi) / 2)
    if chars[mid].pos <= byte_col_1 then
      best = mid
      lo = mid + 1
    else
      hi = mid - 1
    end
  end
  return best
end

-- Returns the text block under the cursor.
-- For foreign (non-ASCII) chars: scans left+right to grab the full contiguous segment.
-- For ASCII: falls back to <cWORD> (whitespace-delimited).
function M.get_cword()
  local line = vim.api.nvim_get_current_line()
  if not line or line == "" then return "" end

  local chars = utf8_chars(line)
  if #chars == 0 then return "" end

  local byte_col = vim.api.nvim_win_get_cursor(0)[2]
  local cursor_idx = find_char_at_byte(chars, byte_col + 1)

  local cp = chars[cursor_idx].cp

  if not is_foreign(cp) then
    local found = nil
    local max_delta = math.max(cursor_idx, #chars - cursor_idx)
    for delta = 1, max_delta do
      local ri = cursor_idx + delta
      if ri <= #chars and is_foreign(chars[ri].cp) then
        found = ri; break
      end
      local li = cursor_idx - delta
      if li >= 1 and is_foreign(chars[li].cp) then
        found = li; break
      end
    end
    if not found then
      return vim.trim(vim.fn.expand("<cWORD>"))
    end
    cursor_idx = found
  end

  local left = cursor_idx
  while left > 1 and is_foreign(chars[left - 1].cp) do
    left = left - 1
  end

  local right = cursor_idx
  while right < #chars and is_foreign(chars[right + 1].cp) do
    right = right + 1
  end

  local byte_start = chars[left].pos
  local last = chars[right]
  local byte_end = last.pos + last.len - 1
  return vim.trim(line:sub(byte_start, byte_end))
end

-- Returns the visual selection as a single string.
function M.get_visual_selection()
  local ok, lines = pcall(function()
    local start_pos = vim.fn.getpos("'<")
    local end_pos   = vim.fn.getpos("'>")
    return vim.fn.getregion(start_pos, end_pos, { type = vim.fn.visualmode() })
  end)
  if not ok or not lines then return "" end
  return vim.trim(table.concat(lines, "\n"))
end

return M
