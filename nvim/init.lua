-- Find zsh automatically and make it the default shell (set before plugins load).
local zsh_path = vim.fn.exepath("zsh")
if zsh_path ~= "" then
  vim.env.SHELL = zsh_path
end

require("config.lazy")
