local hexe = require("hexe")

local function segment(spec)
  return hexe.segment(spec)
end

local function focused_float(key)
  return function(ctx)
    local pane = ctx.pane(0)
    return pane and pane.focus_float and pane.float_key == key
  end
end

local function prompt_identity(ctx)
  local user = ctx.env.USER or ctx.env.LOGNAME or "?"
  local host = ctx.env.HEXE_PROMPT_HOST or "?"
  local remote = ctx.env.SSH_CONNECTION
    or ctx.env.SSH_CLIENT
    or ctx.env.SSH_TTY
  return remote and (user .. "@" .. host) or user
end

local function middle_shorten(text, max_width)
  if max_width <= 0 then
    return ""
  end
  if #text <= max_width then
    return text
  end
  if max_width <= 3 then
    return text:sub(1, max_width)
  end

  local available = max_width - 3
  local left = math.floor((available + 1) / 2)
  local right = available - left
  if right == 0 then
    return text:sub(1, left) .. "..."
  end
  return text:sub(1, left) .. "..." .. text:sub(-right)
end

local function split_path(path)
  local components = {}
  for component in path:gmatch("[^/]+") do
    table.insert(components, component)
  end
  return components
end

local function adaptive_path(cwd, home, max_width)
  if max_width <= 0 then
    return nil
  end

  local path = cwd or "/"
  if home and home ~= "" and (path == home or path:sub(1, #home + 1) == home .. "/") then
    path = "~" .. path:sub(#home + 1)
  end

  if #path <= max_width then
    return path
  end

  local prefix = ""
  local body = path
  if path:sub(1, 1) == "~" then
    prefix = "~"
    body = path:sub(2)
  elseif path:sub(1, 1) == "/" then
    prefix = "/"
    body = path:sub(2)
  end

  local components = split_path(body)
  if #components == 0 then
    return prefix ~= "" and prefix or "/"
  end

  local separator = prefix == "/" and "" or "/"
  if #components == 1 then
    local head = prefix .. separator
    return head .. middle_shorten(components[1], max_width - #head)
  end

  local marker
  if prefix == "~" then
    marker = "~/.../"
  elseif prefix == "/" then
    marker = "/.../"
  else
    marker = ".../"
  end

  local current = middle_shorten(components[#components], max_width - #marker)
  local tail = { current }
  local result = marker .. current

  -- Add the nearest parents while at least one omitted ancestor remains.
  for index = #components - 1, 2, -1 do
    local candidate_tail = components[index] .. "/" .. table.concat(tail, "/")
    local candidate = marker .. candidate_tail
    if #candidate > max_width then
      break
    end
    table.insert(tail, 1, components[index])
    result = candidate
  end

  return result
end

local layout = hexe.layout("default", {
  enabled = true,
  root = ".",
  tabs = {
    hexe.tab("main", {
      enabled = true,
      root = hexe.pane({ cwd = "." }),
    }),
  },
  floats = {
    hexe.float("codex", {
      key = "p",
      title = "Codex",
      command = "hexe-agent-launch codex",
      size = { width = 90, height = 90 },
      attrs = {
        exclusive = true,
        global = true,
        sticky = true,
        per_cwd = true,
        inherit_env = true,
      },
    }),
    hexe.float("claude", {
      key = "b",
      title = "Claude",
      command = "hexe-agent-launch claude",
      size = { width = 90, height = 90 },
      attrs = {
        exclusive = true,
        global = true,
        sticky = true,
        per_cwd = true,
        inherit_env = true,
      },
    }),
    hexe.float("yazi", {
      key = "e",
      title = "Yazi",
      command = "yazi",
      size = { width = 90, height = 90 },
      attrs = {
        exclusive = true,
        global = true,
        sticky = true,
        per_cwd = true,
        inherit_env = true,
      },
    }),
    hexe.float("fzf", {
      key = "f",
      title = "FZF",
      command = "hexe-fzf",
      size = { width = 90, height = 90 },
      attrs = {
        exclusive = true,
        global = false,
        destroy = true,
        inherit_env = true,
      },
    }),
  },
})

return hexe.setup({
  theme = hexe.theme({
    colors = {
      bg = 0,
      fg = 7,
      accent = 6,
      muted = 8,
      good = 2,
      warn = 3,
      error = 1,
    },
    styles = {
      ["status.session"] = "bg:6 fg:0 bold",
      ["status.title"] = "bg:0 fg:7",
      ["status.active"] = "bg:6 fg:0 bold",
      ["status.inactive"] = "bg:0 fg:8",
      ["status.base"] = "bg:0 fg:7",
      ["prompt.identity"] = "bg:0 fg:6",
      ["prompt.directory"] = "bg:8 fg:7 bold",
      ["prompt.git"] = "bg:6 fg:0",
      ["prompt.success"] = "fg:2 bold",
      ["prompt.error"] = "fg:1 bold",
    },
  }),

  keys = {
    hexe.key({ hexe.key.alt, hexe.key.h }, hexe.action.focus.move("left")),
    hexe.key({ hexe.key.alt, hexe.key.j }, hexe.action.focus.move("down")),
    hexe.key({ hexe.key.alt, hexe.key.k }, hexe.action.focus.move("up")),
    hexe.key({ hexe.key.alt, hexe.key.l }, hexe.action.focus.move("right")),
    hexe.key({ hexe.key.alt, hexe.key.left }, hexe.action.focus.move("left")),
    hexe.key({ hexe.key.alt, hexe.key.down }, hexe.action.focus.move("down")),
    hexe.key({ hexe.key.alt, hexe.key.up }, hexe.action.focus.move("up")),
    hexe.key({ hexe.key.alt, hexe.key.right }, hexe.action.focus.move("right")),

    hexe.key({ hexe.key.alt, hexe.key.q }, hexe.action.split.horizontal()),
    hexe.key({ hexe.key.alt, hexe.key.shift, hexe.key.q }, hexe.action.split.vertical()),
    hexe.key({ hexe.key.alt, hexe.key.x }, hexe.action.pane.close()),
    hexe.key({ hexe.key.alt, hexe.key.u }, hexe.action.tab.prev()),
    hexe.key({ hexe.key.alt, hexe.key.o }, hexe.action.tab.next()),

    hexe.key({ hexe.key.alt, hexe.key.p }, hexe.action.float.toggle("p")),
    hexe.key({ hexe.key.alt, hexe.key.b }, hexe.action.float.toggle("b")),
    hexe.key({ hexe.key.alt, hexe.key.e }, hexe.action.float.toggle("e")),
    hexe.key({ hexe.key.alt, hexe.key.f }, hexe.action.float.toggle("f")),
    hexe.key({ hexe.key.alt, hexe.key.c }, hexe.action.float.toggle("p"), { when = focused_float("p") }),
    hexe.key({ hexe.key.alt, hexe.key.c }, hexe.action.float.toggle("b"), { when = focused_float("b") }),
    hexe.key({ hexe.key.alt, hexe.key.c }, hexe.action.float.toggle("e"), { when = focused_float("e") }),
    hexe.key({ hexe.key.alt, hexe.key.c }, hexe.action.float.toggle("f"), { when = focused_float("f") }),

    hexe.key({ hexe.key.alt, hexe.key.s }, hexe.action.pane.select()),
    hexe.key({ hexe.key.alt, hexe.key.z }, hexe.action.pane.zoom()),
    hexe.key({ hexe.key.alt, hexe.key.slash }, hexe.action.search.enter()),
    hexe.key({ hexe.key.alt, hexe.key.y }, hexe.action.copy.enter()),
    hexe.key({ hexe.key.alt, hexe.key.r }, hexe.action.config.reload()),
    hexe.key({ hexe.key.ctrl, hexe.key.alt, hexe.key.p }, hexe.action.overlay.sprite_toggle()),
    hexe.key({ hexe.key.ctrl, hexe.key.alt, hexe.key.d }, hexe.action.detach()),
  },

  mux = {
    confirm = {
      exit = true,
      detach = true,
      disown = true,
      close = true,
    },
    selection_color = 8,
    splits = {
      color = { active = 6, passive = 8 },
    },
    floats = {
      defaults = {
        color = { active = 6, passive = 8 },
        style = {
          title = {
            name = "title",
            render = function(ctx)
              local title = hexe.segment.title(ctx)
              return {
                { text = " ", style = "" },
                { text = title, style = "fg:6 bold" },
                { text = " ", style = "" },
              }
            end,
            position = "topleft",
          },
        },
      },
      adhoc = {
        color = { active = 6, passive = 8 },
      },
    },
  },

  status = {
    enabled = true,
    left = {
      segment({
        name = "session",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.session({
            style = hexe.style("status.session"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "title",
        priority = 5,
        builtin = function(_)
          return hexe.segment.builtin.title({
            style = hexe.style("status.title"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "spinner",
        priority = 10,
        builtin = function(ctx)
          local pane = ctx.pane(0)
          local running = pane
            and ((pane.shell_running and not pane.alt_screen) or pane.adhoc_float)
          if not running and (ctx.jobs or 0) > 0 then
            running = true
          end
          if not running then
            return nil
          end
          return hexe.segment.builtin.spinner({
            kind = "knight_rider",
            width = 8,
            step = 40,
            hold = 10,
            colors = { 8, 6, 14, 7, 14, 6, 8 },
            bg = 0,
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
    },
    center = {
      segment({
        name = "tabs",
        priority = 1,
        render = function(ctx)
          return hexe.segment.tabs(ctx)
        end,
        tab_title = "name",
        active_style = hexe.style("status.active"),
        inactive_style = hexe.style("status.inactive"),
        separator = " ",
        separator_style = hexe.style("status.base"),
      }),
    },
    right = {
      segment({
        name = "date_time",
        priority = 1,
        render = function(_)
          return {
            {
              text = " " .. os.date("%a %d %b  %H:%M") .. " ",
              style = hexe.style("status.session"),
            },
          }
        end,
      }),
    },
  },

  prompt = {
    left = {
      segment({
        name = "identity",
        priority = 10,
        render = function(ctx)
          return {
            { text = "", style = "fg:0" },
            {
              text = prompt_identity(ctx),
              style = hexe.style("prompt.identity"),
            },
          }
        end,
      }),
      segment({
        name = "directory",
        priority = 2,
        render = function(ctx)
          -- Hexe currently budgets UTF-8 byte lengths. Reserve the byte widths
          -- of the character and decorations so they cannot be pushed out.
          local half_width = math.floor((ctx.terminal_width or 80) / 2)
          local character_width = #" " + #"❯"
          local decoration_width = #"" + 2
          local identity_width = #"" + #prompt_identity(ctx)
          local with_identity = half_width
            - character_width
            - decoration_width
            - identity_width
          local path_width = with_identity >= 8
            and with_identity
            or half_width - character_width - decoration_width
          local path = adaptive_path(ctx.cwd, ctx.home, path_width)
          if not path or path == "" then
            return nil
          end
          return {
            { text = "", style = "fg:0 bg:8" },
            {
              text = " " .. path .. " ",
              style = hexe.style("prompt.directory"),
            },
          }
        end,
      }),
      segment({
        name = "character",
        priority = 1,
        render = function(ctx)
          local style = (ctx.exit_status or 0) == 0
            and hexe.style("prompt.success")
            or hexe.style("prompt.error")
          return {
            { text = " ", style = "fg:6" },
            { text = "❯", style = style },
          }
        end,
      }),
    },
    right = {
      segment({
        name = "git_branch",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.git_branch({
            style = hexe.style("prompt.git"),
            prefix = { output = "", style = "fg:6" },
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "git_status",
        priority = 15,
        builtin = function(_)
          return hexe.segment.builtin.git_status({
            style = hexe.style("prompt.git"),
            suffix = " ",
          })
        end,
      }),
    },
  },

  ses = {
    layouts = { layout },
  },
})
