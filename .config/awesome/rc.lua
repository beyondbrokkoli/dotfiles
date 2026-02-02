local gears = require("gears"); local awful = require("awful"); require("awful.autofocus")
local wibox = require("wibox"); local beautiful = require("beautiful"); local naughty = require("naughty")
local menubar = require("menubar"); local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys"); pcall(require, "luarocks.loader")

if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical, title = "Error!", text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end; in_error = true
        naughty.notify({ preset = naughty.config.presets.critical, title = "Error!", text = tostring(err) })
        in_error = false
    end)
end

beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
terminal = "alacritty"; editor = os.getenv("EDITOR") or "nano"; editor_cmd = terminal .. " -e " .. editor; modkey = "Mod4"

awful.layout.layouts = {
    awful.layout.suit.floating
--   ,awful.layout.suit.tile, awful.layout.suit.tile.left,
--    awful.layout.suit.tile.bottom, awful.layout.suit.tile.top, awful.layout.suit.fair,
--    awful.layout.suit.fair.horizontal, awful.layout.suit.spiral, awful.layout.suit.spiral.dwindle,
--    awful.layout.suit.max, awful.layout.suit.max.fullscreen, awful.layout.suit.magnifier, awful.layout.suit.corner.nw
}

myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "manual", terminal .. " -e man awesome" }, { "edit config", editor_cmd .. " " .. awesome.conffile },
   { "restart", awesome.restart }, { "quit", function() awesome.quit() end }
}
mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon }, { "open terminal", terminal } } })
mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon, menu = mymainmenu })
menubar.utils.terminal = terminal; mykeyboardlayout = awful.widget.keyboardlayout(); mytextclock = wibox.widget.textclock()

local t_btns = gears.table.join(
    awful.button({ }, 1, function(t) t:view_only() end),
    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
    awful.button({ }, 3, awful.tag.viewtoggle),
    awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end),
    awful.button({ }, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({ }, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tk_btns = gears.table.join(
    awful.button({ }, 1, function (c) if c == client.focus then c.minimized = true else c:emit_signal("request::activate", "tasklist", {raise = true}) end end),
    awful.button({ }, 3, function() awful.menu.client_list({ theme = { width = 250 } }) end),
    awful.button({ }, 4, function () awful.client.focus.byidx(1) end),
    awful.button({ }, 5, function () awful.client.focus.byidx(-1) end)
)

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wp = beautiful.wallpaper; if type(wp) == "function" then wp = wp(s) end
        gears.wallpaper.maximized(wp, s, true)
    end
end

screen.connect_signal("property::geometry", set_wallpaper)
awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)
    awful.tag({ "1" }, s, awful.layout.layouts[1])
    s.mypromptbox = awful.widget.prompt(); s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
        awful.button({ }, 1, function () awful.layout.inc( 1) end), awful.button({ }, 3, function () awful.layout.inc(-1) end),
        awful.button({ }, 4, function () awful.layout.inc( 1) end), awful.button({ }, 5, function () awful.layout.inc(-1) end)
    ))
    s.mytaglist = awful.widget.taglist { screen = s, filter = awful.widget.taglist.filter.all, buttons = t_btns }
    s.mytasklist = awful.widget.tasklist { screen = s, filter = awful.widget.tasklist.filter.currenttags, buttons = tk_btns }
    s.mywibox = awful.wibar({ position = "top", screen = s, visible = false })
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { layout = wibox.layout.fixed.horizontal, mylauncher, s.mytaglist, s.mypromptbox },
        s.mytasklist,
        { layout = wibox.layout.fixed.horizontal, mykeyboardlayout, wibox.widget.systray(), mytextclock, s.mylayoutbox }
    }
end)

root.buttons(gears.table.join(
    awful.button({ }, 3, function () mymainmenu:toggle() end),
    awful.button({ }, 4, awful.tag.viewnext), awful.button({ }, 5, awful.tag.viewprev)
))

globalkeys = gears.table.join(
    awful.key({ modkey }, "s", hotkeys_popup.show_help, {description="help", group="awesome"}),
    awful.key({ modkey }, "Left", awful.tag.viewprev, {description = "prev tag", group = "tag"}),
    awful.key({ modkey }, "Right", awful.tag.viewnext, {description = "next tag", group = "tag"}),
    awful.key({ modkey }, "Escape", awful.tag.history.restore, {description = "back", group = "tag"}),
    awful.key({ modkey }, "j", function () awful.client.focus.byidx(1) end, {description = "focus next", group = "client"}),
    awful.key({ modkey }, "k", function () awful.client.focus.byidx(-1) end, {description = "focus prev", group = "client"}),
    awful.key({ modkey }, "w", function () mymainmenu:show() end, {description = "menu", group="awesome"}),
    awful.key({ modkey, "Shift" }, "j", function () awful.client.swap.byidx(1) end),
    awful.key({ modkey, "Shift" }, "k", function () awful.client.swap.byidx(-1) end),
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative(1) end),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
    awful.key({ modkey }, "u", awful.client.urgent.jumpto),
    awful.key({ modkey }, "Tab", function () awful.client.focus.history.previous(); if client.focus then client.focus:raise() end end),
    awful.key({ modkey }, "Return", function () awful.spawn(terminal) end),
    awful.key({ modkey, "Control" }, "r", awesome.restart),
    awful.key({ modkey, "Shift" }, "q", awesome.quit),
    awful.key({ modkey }, "l", function () awful.tag.incmwfact(0.05) end),
    awful.key({ modkey }, "h", function () awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Shift" }, "h", function () awful.tag.incnmaster(1, nil, true) end),
    awful.key({ modkey, "Shift" }, "l", function () awful.tag.incnmaster(-1, nil, true) end),
    awful.key({ modkey }, "space", function () awful.layout.inc(1) end),
    awful.key({ modkey, "Shift" }, "space", function () awful.layout.inc(-1) end),
    awful.key({ modkey, "Control" }, "n", function () local c = awful.client.restore(); if c then c:emit_signal("request::activate", "key.unminimize", {raise = true}) end end),
    awful.key({ modkey }, "r", function () awful.screen.focused().mypromptbox:run() end),
    awful.key({ modkey }, "x", function () awful.prompt.run { prompt = "Lua: ", textbox = awful.screen.focused().mypromptbox.widget, exe_callback = awful.util.eval } end)
)

clientkeys = gears.table.join(
    awful.key({ modkey }, "f", function (c) c.fullscreen = not c.fullscreen; c:raise() end),
    awful.key({ modkey, "Shift" }, "c", function (c) c:kill() end),
    awful.key({ modkey, "Control" }, "space", awful.client.floating.toggle),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
    awful.key({ modkey }, "n", function (c) c.minimized = true end),
    awful.key({ modkey }, "m", function (c) c.maximized = not c.maximized; c:raise() end)
)

for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function () local t = awful.screen.focused().tags[i]; if t then t:view_only() end end),
        awful.key({ modkey, "Control" }, "#" .. i + 9, function () local t = awful.screen.focused().tags[i]; if t then awful.tag.viewtoggle(t) end end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function () if client.focus then local t = client.focus.screen.tags[i]; if t then client.focus:move_to_tag(t) end end end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function () if client.focus then local t = client.focus.screen.tags[i]; if t then client.focus:toggle_tag(t) end end end)
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}) end),
    awful.button({ modkey }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}); awful.mouse.client.move(c) end),
    awful.button({ modkey }, 3, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}); awful.mouse.client.resize(c) end)
)

root.keys(globalkeys)
awful.rules.rules = {
    { rule = { }, properties = { border_width = beautiful.border_width, border_color = beautiful.border_normal, focus = awful.client.focus.filter, raise = true, keys = clientkeys, buttons = clientbuttons, screen = awful.screen.preferred, placement = awful.placement.no_overlap+awful.placement.no_offscreen } },
    { rule_any = { instance = { "DTA", "copyq", "pinentry" }, class = { "Arandr", "Blueman-manager", "Gpick", "Kruler", "Sxiv", "Wpa_gui", "veromix" } }, properties = { floating = true } },
    { rule_any = { type = { "normal", "dialog" } }, properties = { titlebars_enabled = false } }
}

client.connect_signal("manage", function (c) if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then awful.placement.no_offscreen(c) end end)
client.connect_signal("request::titlebars", function(c)
    local btns = gears.table.join(
        awful.button({ }, 1, function() c:emit_signal("request::activate", "titlebar", {raise = true}); awful.mouse.client.move(c) end),
        awful.button({ }, 3, function() c:emit_signal("request::activate", "titlebar", {raise = true}); awful.mouse.client.resize(c) end)
    )
    awful.titlebar(c) : setup {
        { awful.titlebar.widget.iconwidget(c), buttons = btns, layout = wibox.layout.fixed.horizontal },
        { { align = "center", widget = awful.titlebar.widget.titlewidget(c) }, buttons = btns, layout = wibox.layout.flex.horizontal },
        { awful.titlebar.widget.floatingbutton(c), awful.titlebar.widget.maximizedbutton(c), awful.titlebar.widget.closebutton(c), layout = wibox.layout.fixed.horizontal() },
        layout = wibox.layout.align.horizontal
    }
end)
--client.connect_signal("mouse::enter", function(c) c:emit_signal("request::activate", "mouse_enter", {raise = false}) end)
client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- AUTOSTART
awful.spawn.with_shell("xrandr --output DP-0 --mode 1920x1080 --rate 239.96")
awful.spawn.with_shell("numlockx on")
