-- Native Hyprland Lua config.

local home = os.getenv("HOME") or "."

hl.monitor({
    output = "eDP-1",
    mode = "preferred",
    position = "0x0",
    scale = 1,
})

local terminal = "kitty --single-instance --listen-on unix:/tmp/dots-kitty-$(id -u).sock"
local lock = "pidof hyprlock || hyprlock"
local browser = "flatpak run app.zen_browser.zen"
local mainMod = "SUPER"
local startup = home .. "/.local/bin/hypr-startup"
local hotplug = home .. "/.local/bin/hypr-hotplug"
local monitorLayoutTimer = nil
local floatingClampTimer = nil
local clampFloatingWindows

local function scheduleFloatingWindowClamp(delay)
    if floatingClampTimer then
        floatingClampTimer:set_enabled(false)
    end
    floatingClampTimer = hl.timer(function()
        floatingClampTimer = nil
        clampFloatingWindows()
    end, { timeout = delay or 250, type = "oneshot" })
end

local function scheduleMonitorLayout(command, delay)
    if monitorLayoutTimer then
        monitorLayoutTimer:set_enabled(false)
    end
    monitorLayoutTimer = hl.timer(function()
        monitorLayoutTimer = nil
        hl.exec_cmd(command)
        scheduleFloatingWindowClamp(1200)
    end, { timeout = delay or 750, type = "oneshot" })
end

hl.on("hyprland.start", function()
    hl.exec_cmd(startup)
end)

hl.on("config.reloaded", function()
    scheduleMonitorLayout(hotplug .. " --reload", 750)
end)

hl.on("monitor.added", function()
    scheduleMonitorLayout(hotplug)
end)
hl.on("monitor.removed", function()
    scheduleMonitorLayout(hotplug .. " --layout-only")
end)

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Run apps natively on Wayland so they render crisply at fractional monitor
-- scales on fractional outputs. Without these, Qt/Electron/SDL fall back to
-- XWayland and get bilinear-resampled -> blurry on scaled displays.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("SDL_VIDEODRIVER", "wayland")
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
hl.env("MOZ_ENABLE_WAYLAND", "1")

hl.config({
    general = {
        gaps_in = 1,
        gaps_out = 2,
        border_size = 2,
        col = {
            active_border = { colors = { "rgba(009999d9)", "rgba(002b33d9)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },
    decoration = {
        rounding = 16,
        rounding_power = 2,
        active_opacity = 1,
        inactive_opacity = 0.98,
        shadow = {
            enabled = true,
            range = 4,
            render_power = 3,
            color = "rgba(1a1a1aee)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.1696,
        },
    },
    animations = {
        enabled = true,
    },
    dwindle = {
        preserve_split = true,
    },
    master = {
        new_status = "master",
    },
    misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo = true,
        animate_manual_resizes = false,
    },
    input = {
        kb_layout = "us",
        kb_variant = "",
        kb_model = "",
        kb_options = "",
        kb_rules = "",
        follow_mouse = 1,
        sensitivity = 0.3,
        numlock_by_default = true,
        touchpad = {
            natural_scroll = false,
            disable_while_typing = false,
        },
    },
})

hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace", scale = 1.0 })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen", mods = "SUPER", scale = 1.5 })

-- SUPER + 3-finger swipe carries the focused window to the prev/next workspace
-- on the CURRENT display (m±1 = monitor-relative), following it.
local function move_window_to_workspace(selector)
    return function()
        hl.dispatch(hl.dsp.window.move({ workspace = selector }))
    end
end

local function normal_workspace_ids_on_monitor(monitorName)
    local ids = {}
    for _, workspace in ipairs(hl.get_workspaces()) do
        if workspace.id > 0
            and workspace.monitor
            and workspace.monitor.name == monitorName
        then
            table.insert(ids, workspace.id)
        end
    end
    table.sort(ids)
    return ids
end

local function used_normal_workspace_ids()
    local used = {}
    for _, workspace in ipairs(hl.get_workspaces()) do
        if workspace.id > 0 then
            used[workspace.id] = true
        end
    end
    return used
end

local function first_unused_workspace_id()
    local used = used_normal_workspace_ids()
    for id = 1, 10 do
        if not used[id] then
            return id
        end
    end
    return nil
end

local function unused_temporary_workspace_id()
    local used = used_normal_workspace_ids()
    for id = 1000, 1099 do
        if not used[id] then
            return id
        end
    end
    return nil
end

local function adjacent_workspace_on_current_monitor(delta)
    local monitor = hl.get_active_monitor()
    local active = hl.get_active_workspace()
    if not monitor or not active or active.id <= 0 then
        return nil
    end

    local ids = normal_workspace_ids_on_monitor(monitor.name)
    if #ids == 0 then
        return active.id
    end

    local activeIndex = nil
    for index, id in ipairs(ids) do
        if id == active.id then
            activeIndex = index
            break
        end
    end

    if not activeIndex then
        return active.id
    end

    if delta > 0 then
        if activeIndex < #ids then
            return ids[activeIndex + 1]
        end
        return first_unused_workspace_id() or ids[1]
    else
        if activeIndex > 1 then
            return ids[activeIndex - 1]
        end
        return ids[#ids]
    end
end

local function focus_adjacent_workspace(delta)
    return function()
        local target = adjacent_workspace_on_current_monitor(delta)
        if target then
            hl.dispatch(hl.dsp.focus({ workspace = target }))
        end
    end
end

local function move_window_to_adjacent_workspace(delta)
    return function()
        local target = adjacent_workspace_on_current_monitor(delta)
        if target then
            hl.dispatch(hl.dsp.window.move({ workspace = target }))
        end
    end
end

local function adjacent_existing_workspace_on_current_monitor(delta)
    local monitor = hl.get_active_monitor()
    local active = hl.get_active_workspace()
    if not monitor or not active or active.id <= 0 then
        return nil, nil
    end

    local ids = normal_workspace_ids_on_monitor(monitor.name)
    if #ids < 2 then
        return active.id, nil
    end

    for index, id in ipairs(ids) do
        if id == active.id then
            if delta > 0 then
                return active.id, ids[index < #ids and index + 1 or 1]
            else
                return active.id, ids[index > 1 and index - 1 or #ids]
            end
        end
    end

    return active.id, nil
end

local function move_windows_between_workspaces(windows, workspaceId)
    for _, window in ipairs(windows) do
        hl.dispatch(hl.dsp.window.move({
            workspace = workspaceId,
            window = window,
        }))
    end
end

local function swap_workspace_contents_on_current_monitor(delta)
    return function()
        local currentId, targetId = adjacent_existing_workspace_on_current_monitor(delta)
        if not currentId or not targetId or currentId == targetId then
            return
        end

        local temporaryId = unused_temporary_workspace_id()
        if not temporaryId then
            return
        end

        local currentWindows = hl.get_workspace_windows(currentId)
        local targetWindows = hl.get_workspace_windows(targetId)

        move_windows_between_workspaces(currentWindows, temporaryId)
        move_windows_between_workspaces(targetWindows, currentId)
        move_windows_between_workspaces(currentWindows, targetId)
        hl.dispatch(hl.dsp.focus({ workspace = targetId }))
    end
end

hl.gesture({ fingers = 3, direction = "right", mods = "SUPER", action = move_window_to_workspace("m-1") })
hl.gesture({ fingers = 3, direction = "left",  mods = "SUPER", action = move_window_to_workspace("m+1") })

hl.device({
    name = "epic-mouse-v1",
    sensitivity = -0.5,
})

local function exec(command)
    return hl.dsp.exec_cmd(command)
end

hl.bind(mainMod .. " + Q", exec(terminal))
hl.bind(mainMod .. " + C", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + T", hl.dsp.layout("togglesplit"))
hl.bind(mainMod .. " + Escape", exec(lock))
hl.bind(mainMod .. " + F", exec(browser))

hl.bind("Print", exec("~/.local/bin/capture-menu"))
hl.bind("SHIFT + Print", exec("~/.local/bin/capture-action screenshot-area"))
hl.bind(mainMod .. " + F12", exec(terminal .. " --class dropdown"))

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.swap({ direction = "down" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.swap({ direction = "right" }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))

local function monitor_center(monitor)
    return {
        x = monitor.x + monitor.width / 2,
        y = monitor.y + monitor.height / 2,
    }
end

local function clamp(value, min, max)
    if value < min then
        return min
    elseif value > max then
        return max
    end
    return value
end

local function cursor_position_for_monitor_swap(fromMonitor, toMonitor)
    local cursor = hl.get_cursor_pos()
    local x = toMonitor.x + toMonitor.width / 2
    local y = toMonitor.y + toMonitor.height / 2

    if cursor then
        local relX = fromMonitor.width > 0 and (cursor.x - fromMonitor.x) / fromMonitor.width or 0.5
        local relY = fromMonitor.height > 0 and (cursor.y - fromMonitor.y) / fromMonitor.height or 0.5
        x = toMonitor.x + toMonitor.width * clamp(relX, 0, 1)
        y = toMonitor.y + toMonitor.height * clamp(relY, 0, 1)
    end

    return {
        x = math.floor(x),
        y = math.floor(y),
    }
end

local function move_cursor_to(position)
    hl.dispatch(hl.dsp.cursor.move(position))
end

local function rect_value(rect, key, index)
    if type(rect) == "table" then
        return rect[key] or rect[index]
    end
    return nil
end

local function window_geometry(window)
    local x = rect_value(window.at, "x", 1)
    local y = rect_value(window.at, "y", 2)
    local width = rect_value(window.size, "x", 1) or rect_value(window.size, "width", 1)
    local height = rect_value(window.size, "y", 2) or rect_value(window.size, "height", 2)

    if not x or not y or not width or not height then
        return nil
    end

    return x, y, width, height
end

local function is_drawer_window(window)
    local class = window.class or ""
    return class == "dropdown"
        or class == "dropdown-yazi"
        or class == "dropdown-launcher"
        or class == "dropdown-wifi"
end

clampFloatingWindows = function()
    for _, window in ipairs(hl.get_windows()) do
        if window.mapped
            and window.floating
            and not window.pinned
            and not is_drawer_window(window)
            and (not window.fullscreen or window.fullscreen == 0)
            and (not window.workspace or not window.workspace.special)
        then
            local monitor = window.monitor or hl.get_active_monitor()
            local x, y, width, height = window_geometry(window)

            if monitor and x and y and width and height then
                local visibleWidth = math.max(
                    0,
                    math.min(x + width, monitor.x + monitor.width) - math.max(x, monitor.x)
                )
                local visibleHeight = math.max(
                    0,
                    math.min(y + height, monitor.y + monitor.height) - math.max(y, monitor.y)
                )
                local visibleArea = visibleWidth * visibleHeight
                local windowArea = width * height

                if windowArea > 0 and visibleArea / windowArea < 0.25 then
                    hl.dispatch(hl.dsp.window.center({ window = window }))
                end
            end
        end
    end
end

local function monitor_in_direction(direction)
    local current = hl.get_active_monitor()
    if not current then
        return nil
    end

    local currentCenter = monitor_center(current)
    local best = nil
    local bestDistance = nil

    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.name ~= current.name then
            local center = monitor_center(monitor)
            local dx = center.x - currentCenter.x
            local dy = center.y - currentCenter.y
            local inDirection = false
            local primaryDistance = 0
            local secondaryDistance = 0

            if direction == "left" then
                inDirection = dx < 0 and math.abs(dx) >= math.abs(dy) / 2
                primaryDistance = -dx
                secondaryDistance = math.abs(dy)
            elseif direction == "right" then
                inDirection = dx > 0 and math.abs(dx) >= math.abs(dy) / 2
                primaryDistance = dx
                secondaryDistance = math.abs(dy)
            elseif direction == "up" then
                inDirection = dy < 0 and math.abs(dy) >= math.abs(dx) / 2
                primaryDistance = -dy
                secondaryDistance = math.abs(dx)
            elseif direction == "down" then
                inDirection = dy > 0 and math.abs(dy) >= math.abs(dx) / 2
                primaryDistance = dy
                secondaryDistance = math.abs(dx)
            end

            if inDirection then
                local distance = primaryDistance * 100000 + secondaryDistance
                if not bestDistance or distance < bestDistance then
                    best = monitor
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function swap_active_workspace_with_monitor(direction)
    return function()
        local current = hl.get_active_monitor()
        local target = monitor_in_direction(direction)
        if not current or not target then
            return
        end

        local cursorPosition = cursor_position_for_monitor_swap(current, target)
        hl.dispatch(hl.dsp.workspace.swap_monitors({
            monitor1 = current.name,
            monitor2 = target.name,
        }))
        hl.dispatch(hl.dsp.focus({ monitor = target.name }))
        hl.timer(function()
            move_cursor_to(cursorPosition)
        end, { timeout = 50, type = "oneshot" })
    end
end

local function move_active_window_to_monitor(direction)
    return function()
        local window = hl.get_active_window()
        local current = hl.get_active_monitor()
        local target = monitor_in_direction(direction)
        if not window or not current or not target then
            return
        end

        local cursorPosition = cursor_position_for_monitor_swap(current, target)
        hl.dispatch(hl.dsp.window.move({ monitor = target.name }))
        hl.dispatch(hl.dsp.focus({ monitor = target.name }))
        hl.timer(function()
            move_cursor_to(cursorPosition)
        end, { timeout = 50, type = "oneshot" })
    end
end

local function focus_monitor(direction)
    return function()
        local target = monitor_in_direction(direction)
        if target then
            hl.dispatch(hl.dsp.focus({ monitor = target.name }))
        end
    end
end

hl.bind(mainMod .. " + CTRL + SHIFT + left", swap_active_workspace_with_monitor("left"))
hl.bind(mainMod .. " + CTRL + SHIFT + right", swap_active_workspace_with_monitor("right"))
hl.bind(mainMod .. " + CTRL + SHIFT + up", swap_active_workspace_with_monitor("up"))
hl.bind(mainMod .. " + CTRL + SHIFT + down", swap_active_workspace_with_monitor("down"))
hl.bind(mainMod .. " + CTRL + H", move_window_to_adjacent_workspace(-1))
hl.bind(mainMod .. " + CTRL + L", move_window_to_adjacent_workspace(1))
hl.bind(mainMod .. " + CTRL + K", move_active_window_to_monitor("up"))
hl.bind(mainMod .. " + CTRL + J", move_active_window_to_monitor("down"))
hl.bind(mainMod .. " + ALT + H", focus_adjacent_workspace(-1))
hl.bind(mainMod .. " + ALT + L", focus_adjacent_workspace(1))
hl.bind(mainMod .. " + ALT + K", focus_monitor("up"))
hl.bind(mainMod .. " + ALT + J", focus_monitor("down"))
hl.bind(mainMod .. " + ALT + SHIFT + H", swap_workspace_contents_on_current_monitor(-1))
hl.bind(mainMod .. " + ALT + SHIFT + L", swap_workspace_contents_on_current_monitor(1))
hl.bind(mainMod .. " + ALT + SHIFT + K", swap_active_workspace_with_monitor("up"))
hl.bind(mainMod .. " + ALT + SHIFT + J", swap_active_workspace_with_monitor("down"))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind("XF86AudioRaiseVolume", exec("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", exec("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true })
hl.bind("XF86AudioMicMute", exec("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp", exec("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", exec("brightnessctl s 10%-"), { locked = true, repeating = true })
hl.bind("XF86AudioNext", exec("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", exec("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", exec("playerctl previous"), { locked = true })

local drawerSizes = {}

local function drawer_rule(class, workspace, widthFactor, heightFactor)
    drawerSizes[class] = {
        width = widthFactor,
        height = heightFactor,
    }
    hl.window_rule({
        name = "drawer-" .. class,
        match = { class = "^(" .. class .. ")$" },
        float = true,
        size = "(monitor_w*" .. widthFactor .. ") (monitor_h*" .. heightFactor .. ")",
        center = true,
        workspace = "special:" .. workspace,
    })
end

hl.window_rule({
    name = "dropdown",
    match = { class = "^(dropdown)$" },
    float = true,
    size = "(monitor_w*0.7) (monitor_h*0.35)",
    center = true,
})

local drawerLaunchPending = {}
local drawerLaunchTimers = {}
local drawerResizeTimers = {}

local function get_drawer(class)
    for _, window in ipairs(hl.get_windows()) do
        if window.class == class then
            return window
        end
    end
end

local function drawer_is_visible(workspace)
    for _, monitor in ipairs(hl.get_monitors()) do
        local activeSpecialWorkspace = monitor.active_special_workspace
        if activeSpecialWorkspace and activeSpecialWorkspace.name == "special:" .. workspace then
            return true
        end
    end
    return false
end

local function schedule_drawer_resize(class, monitorName)
    local size = drawerSizes[class]
    if not size then
        return
    end
    if drawerResizeTimers[class] then
        drawerResizeTimers[class]:set_enabled(false)
    end
    drawerResizeTimers[class] = hl.timer(function()
        drawerResizeTimers[class] = nil
        local window = get_drawer(class)
        local monitor = hl.get_monitor(monitorName)
        if not window or not monitor then
            return
        end
        hl.dispatch(hl.dsp.window.resize({
            x = math.floor(monitor.width * size.width),
            y = math.floor(monitor.height * size.height),
            window = window,
        }))
        hl.dispatch(hl.dsp.window.center({ window = window }))
    end, { timeout = 50, type = "oneshot" })
end

hl.on("window.open", function(window)
    drawerLaunchPending[window.class] = nil
    scheduleFloatingWindowClamp(250)
end)

local function toggle_drawer(workspace, class, command)
    return function()
        if not get_drawer(class) then
            if drawerLaunchPending[class] then
                return
            end
            drawerLaunchPending[class] = true
            hl.exec_cmd(terminal .. " --class " .. class .. " -e " .. command)
            drawerLaunchTimers[class] = hl.timer(function()
                drawerLaunchPending[class] = nil
                drawerLaunchTimers[class] = nil
            end, { timeout = 1500, type = "oneshot" })
            return
        end
        local monitor = hl.get_active_monitor()
        local hiding = drawer_is_visible(workspace)
        hl.dispatch(hl.dsp.workspace.toggle_special(workspace))
        if monitor and not hiding then
            schedule_drawer_resize(class, monitor.name)
        end
    end
end

drawer_rule("dropdown-yazi", "yazi", 0.75, 0.65)
drawer_rule("dropdown-launcher", "launcher", 0.4, 0.25)
drawer_rule("dropdown-wifi", "wifi", 0.45, 0.45)

local desktopYazi = "env YAZI_CONFIG_HOME=" .. home .. "/.config/yazi-desktop yazi"
hl.bind(mainMod .. " + E", toggle_drawer("yazi", "dropdown-yazi", desktopYazi))
local toggleLauncher = toggle_drawer("launcher", "dropdown-launcher", "~/.local/bin/desktop-app-launcher")
hl.bind(mainMod .. " + SPACE", toggleLauncher)
hl.bind(mainMod .. " + N", toggle_drawer("wifi", "dropdown-wifi", "~/.local/bin/wifi-iwctl-launcher"))

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = {
        class = "^$",
        title = "^$",
        xwayland = true,
        float = true,
        fullscreen = false,
        pin = false,
    },
    no_focus = true,
})
