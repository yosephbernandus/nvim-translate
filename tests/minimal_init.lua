-- Minimal init for running tests with nvim --headless
-- Usage: NVIM_APPNAME=nvim-translate-test nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests/ {minimal_init = 'tests/minimal_init.lua'}"

-- Add plenary to rtp
vim.opt.rtp:append(vim.fn.expand("~/.local/share/nvim/lazy/plenary.nvim"))

-- Add the plugin itself to rtp
vim.opt.rtp:append(vim.fn.getcwd())
