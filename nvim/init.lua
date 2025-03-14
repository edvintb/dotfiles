require("config.lazy")
-- Find zsh automatically and make it the default shell:
if vim.fn.executable("zsh") == 1 then
  local zsh_path = vim.fn.system({"which", "zsh"})
  zsh_path = string.gsub(zsh_path, "%s+", "") -- Remove any trailing whitespace
  vim.env.SHELL = zsh_path
end

