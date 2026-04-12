describe("config", function()
  local config

  before_each(function()
    -- Force reload to reset state between tests
    package.loaded["nvim_translate.config"] = nil
    config = require("nvim_translate.config")
  end)

  it("returns defaults before setup", function()
    local cfg = config.get()
    assert.are.equal("en", cfg.target_lang)
    assert.are.equal("google", cfg.backend)
    assert.are.equal(200, cfg.cache_size)
    assert.are.equal("K", cfg.keymap.normal)
  end)

  it("merges user options on setup", function()
    config.setup({ target_lang = "ja", cache_size = 50 })
    local cfg = config.get()
    assert.are.equal("ja", cfg.target_lang)
    assert.are.equal(50, cfg.cache_size)
    -- unset options keep defaults
    assert.are.equal("google", cfg.backend)
    assert.are.equal("K", cfg.keymap.normal)
  end)

  it("deep merges nested options", function()
    config.setup({ popup = { max_width = 100 } })
    local cfg = config.get()
    assert.are.equal(100, cfg.popup.max_width)
    -- other popup defaults preserved
    assert.are.equal(30, cfg.popup.min_width)
    assert.are.equal(10, cfg.popup.winblend)
  end)

  it("handles empty setup call", function()
    config.setup({})
    local cfg = config.get()
    assert.are.equal("en", cfg.target_lang)
  end)

  it("handles nil setup call", function()
    config.setup(nil)
    local cfg = config.get()
    assert.are.equal("en", cfg.target_lang)
  end)

  it("overrides backend-specific options", function()
    config.setup({ claude = { model = "claude-sonnet-4-20250514", timeout = 30 } })
    local cfg = config.get()
    assert.are.equal("claude-sonnet-4-20250514", cfg.claude.model)
    assert.are.equal(30, cfg.claude.timeout)
    -- google defaults preserved
    assert.are.equal(10, cfg.google.timeout)
  end)

  it("does not mutate defaults on repeated setup calls", function()
    config.setup({ target_lang = "ko" })
    assert.are.equal("ko", config.get().target_lang)

    -- Re-require to reset
    package.loaded["nvim_translate.config"] = nil
    config = require("nvim_translate.config")
    assert.are.equal("en", config.get().target_lang)
  end)
end)
