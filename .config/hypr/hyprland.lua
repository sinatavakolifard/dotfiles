-- Hyprland Lua config, ported from hyprland.conf.
-- Refer to the wiki for more information.
-- https://wiki.hypr.land/configuring/

-- Editor autocompletion: point your Lua LSP at /usr/share/hypr/stubs


------------------
---- MONITORS ----
------------------

-- See https://wiki.hypr.land/configuring/core/monitors/

-- Find the connector whose EDID contains the given text (e.g. a serial or panel name).
-- sysfs has the EDIDs before Hyprland has set up any monitors, so this works on the first load.
local function outputByEdid(text)
    local p = io.popen("grep -l -a " .. text .. " /sys/class/drm/*/edid")
    local path = p:read("l")
    p:close()
    return path and path:match("card%d+%-(.-)/edid$") -- e.g. /sys/class/drm/card1-DP-2/edid -> DP-2
end

-- The two laptops this config runs on. The 0x4193 panel has no name in its EDID,
-- so it is the fallback when the ATNA60CL10-0 panel isn't found.
local laptopPanels = {
    ["0x4193"]       = { mode = "2880x1800@90",  position = "1600x1440", scale = 1.66669 },
    ["ATNA60CL10-0"] = { mode = "2880x1800@120", position = "1600x1440", scale = 1.5 },
}
local laptopOutput  = "eDP-1"
local laptopMonitor = outputByEdid("ATNA60CL10-0") and laptopPanels["ATNA60CL10-0"] or laptopPanels["0x4193"]

hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

local monitors = {
    { output = "desc:Samsung Display Corp. 0x4193",                        mode = laptopPanels["0x4193"].mode,       position = laptopPanels["0x4193"].position,       scale = laptopPanels["0x4193"].scale },
    { output = "desc:Samsung Display Corp. ATNA60CL10-0",                  mode = laptopPanels["ATNA60CL10-0"].mode, position = laptopPanels["ATNA60CL10-0"].position, scale = laptopPanels["ATNA60CL10-0"].scale },
    { output = "desc:Iiyama North America PL2792Q 1226152820953",          mode = "2560x1440@100.00",  position = "0x0",       scale = 1 },
    { output = "desc:Iiyama North America PL2792Q 1226152820959",          mode = "2560x1440@100.00",  position = "2560x0",    scale = 1 },
    { output = "desc:iiyama Corporation PL2792Q 1226152820953",            mode = "2560x1440@100.00",  position = "0x0",       scale = 1 },
    { output = "desc:iiyama Corporation PL2792Q 1226152820959",            mode = "2560x1440@100.00",  position = "2560x0",    scale = 1 },
    { output = "desc:BNQ BenQ G2010W HA805853026",                         mode = "1680x1050@60",      position = "auto-up",   scale = 1 },
    { output = "desc:LG Electronics LG TV 0x01010101",                     mode = "1920x1080@60",      position = "auto",      scale = 1 },
    { output = "desc:Invalid Vendor Codename - RTK T133F demoset-1",       mode = "1920x1080@60",      position = "auto",      scale = 1 },
    { output = "desc:Samsung Electric Company SyncMaster H1AK500000",      mode = "4096x2160@60",      position = "auto",      scale = 2 },
    { output = "desc:Dell Inc. DELL U2724DE CC56734",                      mode = "2560x1440@120.00Hz", position = "auto",     scale = 1 },
}
for _, m in ipairs(monitors) do
    hl.monitor(m)
end
-- hl.monitor({ output = "eDP-1", disabled = true })                                          -- for disabling
-- hl.monitor({ output = "DP-1", mode = "1680x1050@60", position = "auto", scale = 1, mirror = "eDP-1" }) -- for mirroring


--------------------------
---- WORKSPACE LAYOUT ----
--------------------------

-- Pin workspaces to monitors. External monitors are found by serial in their EDID, since the
-- same monitor can report different vendor names (see the duplicate iiyama entries above).
local m953 = outputByEdid("1226152820953")
local m959 = outputByEdid("1226152820959")

if m953 then
    hl.workspace_rule({ workspace = "1", monitor = m953, default = true })
    hl.workspace_rule({ workspace = "2", monitor = m953 })
end
if m959 then
    hl.workspace_rule({ workspace = "3", monitor = m959, default = true })
    hl.workspace_rule({ workspace = "4", monitor = m959 })
end
hl.workspace_rule({ workspace = "9", monitor = laptopOutput, default = true })

-- Monitors are only looked up on config load, so reload when one is plugged in.
-- "config-only" skips re-applying monitors, so the reload doesn't fire monitor.added again.
-- The script redraws waybar and hyprpaper, which don't always pick up returning monitors.
hl.on("monitor.added", function()
    hl.exec_cmd("hyprctl reload config-only")
    hl.exec_cmd("~/.config/hypr/scripts/refresh-bars.sh")
end)


---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "alacritty"
-- local fileManager = "nautilus"
local fileManager = "spf"
local menu        = "wofi --show drun"


-------------------
---- AUTOSTART ----
-------------------

-- See https://wiki.hypr.land/configuring/core/autostart/
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar & hyprpaper & swaync & hypridle")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("udiskie")
    hl.exec_cmd("kanshi")

    -- for libadwaita gtk4 apps
    hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")
    -- for gtk3 apps you need the adw-gtk3 theme (sudo pacman -S adw-gtk-theme)
    hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'")

    -- Open the browsers on their workspaces
    hl.exec_cmd("firefox", { workspace = "1 silent" })
    hl.exec_cmd("brave",   { workspace = "2 silent" })
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- See https://wiki.hypr.land/configuring/core/environment-variables/
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "adw-gtk3-dark")
hl.env("QT_STYLE_OVERRIDE", "Fusion")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- Refer to https://wiki.hypr.land/configuring/core/config-options/
hl.config({
    general = {
        gaps_in  = 0,
        gaps_out = 0,

        border_size = 1,

        col = {
            active_border   = { colors = { "rgb(34B7CB)", "rgb(DBB6F0)" }, angle = 90 },
            inactive_border = "rgb(595959)",
        },

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,

        -- Please see https://wiki.hypr.land/configuring/extra/tearing/ before you turn this on
        allow_tearing = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 2,
        rounding_power = 2,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = false,
            range        = 5,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = false,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },

    -- See https://wiki.hypr.land/configuring/layouts/dwindle-layout/
    dwindle = {
        preserve_split = true, -- You probably want this
    },

    -- See https://wiki.hypr.land/configuring/layouts/master-layout/
    master = {
        new_status = "master",
    },

    misc = {
        force_default_wallpaper = -1,   -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },

    -- unscale XWayland
    xwayland = {
        force_zero_scaling = true,
    },
})

-- Default curves and animations, see https://wiki.hypr.land/configuring/core/animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-- Ref https://wiki.hypr.land/configuring/core/rules/workspace-rules/
-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0, rounding = 0 })
-- hl.window_rule({ match = { float = false, workspace = "f[1]" },   border_size = 0, rounding = 0 })


---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us,de,ir",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:win_space_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.gesture({
    fingers   = 3,
    direction = "horizontal",
    action    = "workspace",
})

-- See https://wiki.hypr.land/configuring/core/devices/
--hl.device({
--    name          = "lenovo-pro-bluetooth-mouse",
--    sensitivity   = -0.7,
--    accel_profile = "adaptive",
--})


---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER" -- Sets "Windows" key as main modifier

-- See https://wiki.hypr.land/configuring/core/binds/
hl.bind(mainMod .. " + return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q",      hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + C",      hl.dsp.window.close())
-- hl.bind(mainMod .. " + M",   hl.dsp.exit())
hl.bind(mainMod .. " + L",      hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(terminal .. " -e " .. fileManager))
hl.bind(mainMod .. " + V",      hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + R",      hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P",      hl.dsp.window.pseudo()) -- dwindle
hl.bind(mainMod .. " + F",         hl.dsp.window.fullscreen_state({ internal = 1, client = -1 }))
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = 3, client = -1 }))
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.exec_cmd("systemctl suspend"))

-- Take screenshots
local function screenshot(grimArgs)
    return [[COMPLETE_DATE=$(date +%F-%H%M%S) && mkdir -p ~/Pictures/Screenshots && FILE=~/Pictures/Screenshots/Screenshot-"$COMPLETE_DATE".png && ]]
        .. "grim " .. grimArgs .. [[ - | wl-copy && wl-paste > "$FILE" && ]]
        .. [[notify-send -i "$FILE" -t 5000 "Screenshot taken" "Screenshot is saved to $FILE"]]
end
hl.bind("Print",         hl.dsp.exec_cmd(screenshot("")))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("REGION=$(slurp) && " .. screenshot('-g "$REGION"')))

-- Move focus with mainMod + arrow keys
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + SHIFT + [0-9]
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(mainMod .. " + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys for volume and LCD brightness
local function volumeNotify(title)
    return " && swaync-client --hide-latest && notify-send -t 1000 -i ~/.config/swaync/icons/volume-high.png"
        .. " --hint=boolean:transient:true '" .. title .. "' \"$(wpctl get-volume @DEFAULT_AUDIO_SINK@)\""
end
local mediaOpts = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ --limit 1" .. volumeNotify("Volume increased")), mediaOpts)
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-" .. volumeNotify("Volume decreased")),          mediaOpts)
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   mediaOpts)
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), mediaOpts)
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl s 5%+"), mediaOpts)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"), mediaOpts)

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Closing and opening lid: turn the laptop panel off/on directly, no hyprctl round-trip
hl.bind("switch:on:Lid Switch", function()
    hl.monitor({ output = laptopOutput, disabled = true })
end, { locked = true })
hl.bind("switch:off:Lid Switch", function()
    -- disabled = false is needed to override the rule set on lid close
    hl.monitor({ output = laptopOutput, mode = laptopMonitor.mode, position = laptopMonitor.position, scale = laptopMonitor.scale, disabled = false })
end, { locked = true })


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

-- See https://wiki.hypr.land/configuring/core/rules/

hl.window_rule({
    -- Ignore maximize requests from all apps
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    -- Fix some dragging issues with XWayland
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
})

-- Floating
for _, class in ipairs({ "^(blueberry\\.py)$", "^(steam)$", "^(guifetch)$" }) do
    hl.window_rule({ match = { class = class }, float = true })
end

-- Floating, centered, 45% of the screen
for _, class in ipairs({
    "^(pavucontrol)$",
    "^(org.pulseaudio.pavucontrol)$",
    "^(nm-connection-editor)$",
    "^(com\\.saivert\\.pwvucontrol)$",
}) do
    hl.window_rule({
        match  = { class = class },
        float  = true,
        size   = { "monitor_w * 0.45", "monitor_h * 0.45" },
        center = true,
    })
end

hl.window_rule({ match = { float = true }, border_size = 1, rounding = 8 })
