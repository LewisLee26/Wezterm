-- Pull in the wezterm API
local wezterm = require("wezterm")
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.disable_default_key_bindings = true

-- -- Colorscheme
config.colors = {
  foreground = "#f0f3f6", -- fg.default
  background = "#0a0c10", -- canvas.default

  cursor_bg = "#f0f3f6", -- fg.default
  cursor_border = "#f0f3f6", -- fg.default
  cursor_fg = "#0a0c10", -- canvas.default

  selection_bg = "rgba(64,158,255,0.4)", -- selectionBg
  selection_fg = "#f0f3f6", -- fg.default

  scrollbar_thumb = "#7a828e", -- border.default
  split = "#7a828e", -- border.default

  ansi = {
    "#0a0c10", -- black
    "#ff9492", -- red
    "#71b7ff", -- green "#26cd4d"
    "#f0b72f", -- yellow
    "#0a0c10", -- blue "#71b7ff"
    "#cb9eff", -- magenta
    "#39c5cf", -- cyan
    "#d9dee3", -- white
  },
  brights = {
    "#9ea7b3", -- blackBright
    "#ffb1af", -- redBright
    "#f0f3f6", -- greenBright "#4ae168"
    "#f7c843", -- yellowBright
    "#91cbff", -- blueBright
    "#dbb7ff", -- magentaBright
    "#ffb1af", -- cyanBright
    "#ffffff", -- whiteBright
  },
}

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.default_prog = { "wsl" }
config.font_size = 11.0
config.enable_kitty_graphics = false
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.status_update_interval = 1000
config.tab_max_width = 60
config.tab_bar_at_bottom = false

-- Panes
config.inactive_pane_hsb = {
  saturation = 0.8,
  brightness = 0.6,
}

wezterm.on("update-right-status", function(window, pane)
  local workspace_or_leader = window:active_workspace()
  -- Change the worspace name status if leader is active
  if window:active_key_table() then
    workspace_or_leader = window:active_key_table()
  end
  if window:leader_is_active() then
    workspace_or_leader = "LEADER"
  end

  local time = wezterm.strftime("%H:%M")
  local battery = ""
  for _, b in ipairs(wezterm.battery_info()) do
    battery = string.format("%.0f%%", b.state_of_charge * 100)
  end

  window:set_right_status(wezterm.format({
    { Foreground = { Color = "FFB86C" } },
    "ResetAttributes",
    { Text = wezterm.nerdfonts.oct_table .. " " .. workspace_or_leader },
    { Text = " | " },
    { Text = " " .. battery .. " " },
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock .. " " .. time },
    { Text = " | " },
  }))
end)

-- Function to check if the pane is running Neovim
local function is_vim(pane)
  return pane:get_user_vars().IS_NVIM == "true"
end

-- Direction keys mapping
local direction_keys = {
  Left = "h",
  Down = "j",
  Up = "k",
  Right = "l",
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

-- Function to create navigation and resize actions
local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == "resize" and "META" or "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
        }, pane)
      else
        if resize_or_move == "resize" then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

-- Define keybindings
config.keys = {
  -- Splitting panes
  {
    mods = "LEADER",
    key = "-",
    action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    mods = "LEADER",
    key = "=",
    action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  -- Maximizing a pane
  {
    mods = "LEADER",
    key = "m",
    action = wezterm.action.TogglePaneZoomState,
  },
  -- Rotating panes
  {
    mods = "LEADER",
    key = "Space",
    action = wezterm.action.RotatePanes("Clockwise"),
  },
  -- Swapping panes
  {
    mods = "LEADER",
    key = "0",
    action = wezterm.action.PaneSelect({
      mode = "SwapWithActive",
    }),
  },
  -- Activate copy mode
  {
    key = "Enter",
    mods = "LEADER",
    action = wezterm.action.ActivateCopyMode,
  },
  {
    key = "r",
    mods = "LEADER",
    action = wezterm.action.ActivateKeyTable({ name = "resize_pane", one_shot = false }),
  },

  -- -- Move between split panes
  -- split_nav("move", "h"),
  -- split_nav("move", "j"),
  -- split_nav("move", "k"),
  -- split_nav("move", "l"),
  -- -- Resize panes
  -- split_nav("resize", "h"),
  -- split_nav("resize", "j"),
  -- split_nav("resize", "k"),
  -- split_nav("resize", "l"),
  -- Existing keybindings
  {
    key = "f",
    mods = "LEADER",
    action = wezterm.action.ToggleFullScreen,
  },
  {
    key = "P",
    mods = "SHIFT|CTRL",
    action = wezterm.action.ActivateCommandPalette,
  },
  {
    key = "x",
    mods = "LEADER",
    action = wezterm.action.CloseCurrentPane({ confirm = false }),
  },
  {
    key = "X",
    mods = "LEADER",
    action = wezterm.action.CloseCurrentTab({ confirm = false }),
  },
  {
    key = "m",
    mods = "LEADER",
    action = wezterm.action.ActivateKeyTable({ name = "move_tab", one_shot = false }),
  },
  {
    key = "t",
    mods = "LEADER",
    action = wezterm.action.ShowTabNavigator,
  },
  {
    key = "n",
    mods = "LEADER",
    action = wezterm.action.SpawnTab("CurrentPaneDomain"),
  },
  { mods = "LEADER", key = "h", action = wezterm.action.ActivateTabRelative(-1) },
  { mods = "LEADER", key = "l", action = wezterm.action.ActivateTabRelative(1) },
  -- Rename tab
  {
    key = ",",
    mods = "LEADER",
    action = wezterm.action.PromptInputLine({
      description = "Enter new tab title",
      action = wezterm.action_callback(function(window, _, line)
        if line then
          window:perform_action(wezterm.action.SetTabTitle(line), window:active_pane())
        end
      end),
    }),
  },
  -- Workspace
  {
    key = "w",
    mods = "LEADER",
    action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
  },
  {
    key = "W",
    mods = "LEADER",
    action = wezterm.action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter name for new workspace" },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace({
              name = line,
            }),
            pane
          )
        end
      end),
    }),
  },
  {
    key = "[",
    mods = "LEADER",
    action = wezterm.action.SwitchWorkspaceRelative(1),
  },
  {
    key = "]",
    mods = "LEADER",
    action = wezterm.action.SwitchWorkspaceRelative(-1),
  },
  {
    key = "Q",
    mods = "LEADER",
    action = wezterm.action.QuitApplication,
  },
  {
    key = "z",
    mods = "LEADER",
    action = wezterm.action.TogglePaneZoomState,
  },
}

-- Quick tab movement
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = wezterm.action.ActivateTab(i - 1),
  })
end

config.key_tables = {
  resize_pane = {
    { key = "h", action = wezterm.action.AdjustPaneSize({ "Left", 1 }) },
    { key = "j", action = wezterm.action.AdjustPaneSize({ "Down", 1 }) },
    { key = "k", action = wezterm.action.AdjustPaneSize({ "Up", 1 }) },
    { key = "l", action = wezterm.action.AdjustPaneSize({ "Right", 1 }) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
  move_tab = {
    { key = "h", action = wezterm.action.MoveTabRelative(-1) },
    { key = "j", action = wezterm.action.MoveTabRelative(-1) },
    { key = "k", action = wezterm.action.MoveTabRelative(1) },
    { key = "l", action = wezterm.action.MoveTabRelative(1) },
    { key = "Escape", action = "PopKeyTable" },
    { key = "Enter", action = "PopKeyTable" },
  },
}

-- Return the configuration to wezterm
return config
