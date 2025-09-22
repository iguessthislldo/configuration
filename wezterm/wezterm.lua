-- https://wezfurlong.org/wezterm/config/files.html
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Decaf (base16)'

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.front_end = "WebGpu"
  config.launch_menu = {
    {
      label = "UCRT64 / MSYS2 zsh",
      args = { "C:\\msys64\\msys2_shell.cmd", "-defterm", "-here", "-no-start", "-ucrt64", "-shell", "zsh", "-l" },
      cwd = "C:\\msys64\\home\\" ..  os.getenv("USERNAME"),
    },
    {
      label = "Command Prompt",
      args = { "cmd.exe" },
    },
  }
else
  config.font = wezterm.font("Monofur Nerd Font")
end


return config
