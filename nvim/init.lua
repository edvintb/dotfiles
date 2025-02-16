require("config.lazy")
-- Find zsh automatically and make it the default shell:
if vim.fn.executable("zsh") == 1 then
  local zsh_path = vim.fn.system({"command", "-v", "zsh"})
  zsh_path = string.gsub(zsh_path, "%s+", "") -- Remove any trailing whitespace
  vim.env.SHELL = zsh_path
end

vim.api.nvim_create_user_command('AddBuckets', function(args)
  local current_file = vim.fn.expand('%:p')
  local file_name = vim.fn.expand('%:t')  -- Get the filename
  local file_extension = vim.fn.expand('%:e') -- Get the file extension
  local file_base = vim.fn.expand('%:t:r')   -- Get the filename without extension

  local output_file
  if file_extension ~= "" then  -- Check if there's an extension
      output_file = vim.fn.expand('%:p:h') .. '/' .. file_base .. '_bucket.' .. file_extension
  else
      output_file = vim.fn.expand('%:p:h') .. '/' .. file_base .. '_bucket'
  end

  local command = string.format('append_buckets.py < "%s" > "%s"', current_file, output_file)
  -- print(command)
  vim.cmd.silent(command)
end, { nargs = 0 })

