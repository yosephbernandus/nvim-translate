local detect = require("nvim_translate.detect")

describe("detect.get_lang_hint", function()
  it("returns nil for empty input", function()
    assert.is_nil(detect.get_lang_hint(""))
    assert.is_nil(detect.get_lang_hint(nil))
  end)

  it("returns nil for ASCII-only text", function()
    assert.is_nil(detect.get_lang_hint("hello world"))
    assert.is_nil(detect.get_lang_hint("function foo() end"))
  end)

  it("detects hiragana as Japanese", function()
    assert.are.equal("JA", detect.get_lang_hint("こんにちは"))
  end)

  it("detects katakana as Japanese", function()
    assert.are.equal("JA", detect.get_lang_hint("カタカナ"))
  end)

  it("detects kanji as Japanese", function()
    assert.are.equal("JA", detect.get_lang_hint("漢字"))
  end)

  it("detects Japanese mixed with ASCII", function()
    assert.are.equal("JA", detect.get_lang_hint("hello 世界"))
  end)

  it("detects single hiragana character", function()
    assert.are.equal("JA", detect.get_lang_hint("あ"))
  end)
end)

describe("detect.get_cword", function()
  local original_line, original_cursor

  before_each(function()
    -- Save originals so we can restore
    original_line = vim.api.nvim_get_current_line
    original_cursor = vim.api.nvim_win_get_cursor
  end)

  after_each(function()
    vim.api.nvim_get_current_line = original_line
    vim.api.nvim_win_get_cursor = original_cursor
  end)

  it("returns empty string for empty line", function()
    vim.api.nvim_get_current_line = function() return "" end
    vim.api.nvim_win_get_cursor = function() return { 1, 0 } end
    assert.are.equal("", detect.get_cword())
  end)

  it("extracts contiguous CJK block when cursor is on it", function()
    local line = "hello 世界平和 world"
    vim.api.nvim_get_current_line = function() return line end
    -- byte offset of 世 (after "hello " = 6 bytes): byte index 6 (0-based)
    vim.api.nvim_win_get_cursor = function() return { 1, 6 } end
    assert.are.equal("世界平和", detect.get_cword())
  end)

  it("finds nearest CJK block when cursor is on ASCII near CJK", function()
    local line = "a 漢字 b"
    vim.api.nvim_get_current_line = function() return line end
    -- cursor on the space before 漢字 (byte offset 1)
    vim.api.nvim_win_get_cursor = function() return { 1, 1 } end
    assert.are.equal("漢字", detect.get_cword())
  end)

  it("excludes CJK punctuation from word boundary", function()
    -- 「世界」 — the brackets are CJK punctuation and should not be included
    local line = "「世界」"
    vim.api.nvim_get_current_line = function() return line end
    -- cursor on 世 (after 「 which is 3 bytes)
    vim.api.nvim_win_get_cursor = function() return { 1, 3 } end
    assert.are.equal("世界", detect.get_cword())
  end)
end)
