if vim.g.loaded_nvim_translate then return end
vim.g.loaded_nvim_translate = 1

vim.api.nvim_create_user_command("Translate", function()
  require("nvim_translate").translate_word()
end, { desc = "Translate word under cursor" })

vim.api.nvim_create_user_command("TranslateV", function()
  require("nvim_translate").translate_visual()
end, { range = true, desc = "Translate visual selection" })

vim.api.nvim_create_user_command("TranslateBackend", function(opts)
  require("nvim_translate").set_backend(opts.args)
end, {
  nargs = 1,
  complete = function()
    return { "google", "claude" }
  end,
  desc = "Switch translation backend (:TranslateBackend google|claude)",
})
