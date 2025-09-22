-- https://wezfurlong.org/wezterm/config/files.html
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.color_scheme = 'Decaf (base16)'

if wezterm.target_triple == "x86_64-pc-windows-msvc" then
  config.front_end = "WebGpu"
  local msys2_zsh = { "C:\\msys64\\msys2_shell.cmd", "-defterm", "-here", "-no-start", "-ucrt64", "-shell", "zsh", "-l" }
  local msys2_home = "C:\\msys64\\home\\" ..  os.getenv("USERNAME")
  config.default_prog = msys2_zsh
  config.default_cwd = msys2_home
  config.launch_menu = {
    {
      label = "UCRT64 / MSYS2 zsh",
      args = msys2_zsh,
      cwd = msys2_home,
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
