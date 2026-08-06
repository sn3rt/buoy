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
        priority = 1,
        render = function(ctx)
          local user = ctx.env.USER or ctx.env.LOGNAME or "?"
          local host = ctx.env.HEXE_PROMPT_HOST or "?"
          local remote = ctx.env.SSH_CONNECTION
            or ctx.env.SSH_CLIENT
            or ctx.env.SSH_TTY
          local identity = remote and (user .. "@" .. host) or user
          return {
            { text = "", style = "fg:0" },
            {
              text = identity,
              style = hexe.style("prompt.identity"),
            },
          }
        end,
      }),
      segment({
        name = "directory",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.directory({
            style = hexe.style("prompt.directory"),
            prefix = { output = "", style = "fg:0 bg:8" },
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "git_branch",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.git_branch({
            style = hexe.style("prompt.git"),
            prefix = { output = " ", style = "fg:8 bg:6" },
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
          })
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
        name = "empty",
        priority = 1,
        render = function(_)
          return nil
        end,
      }),
    },
  },

  ses = {
    layouts = { layout },
  },
})
