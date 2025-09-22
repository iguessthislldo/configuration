-- https://wezfurlong.org/wezterm/config/files.html
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Decaf (base16)'

if os.getenv("IGTD_MSYS2") == "true" then
  config.front_end = "WebGpu"
  config.launch_menu = {
    {
      label = "Command Prompt",
      args = { "cmd.exe" },
    },
    {
      label = "UCRT64 / MSYS2 zsh",
      args = { "C:\\msys64\\msys2_shell.cmd", "-defterm", "-here", "-no-start", "-ucrt64", "-shell", "zsh", "-l" },
      cwd = "C:\\msys64\\home\\" ..  os.getenv("USERNAME"),
    },
  }
else
  config.font = wezterm.font("Monofur Nerd Font")
end


return config
