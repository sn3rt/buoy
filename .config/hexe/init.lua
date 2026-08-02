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
      title = "Files",
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
      ["status.active"] = "bg:6 fg:0 bold",
      ["status.inactive"] = "bg:0 fg:8",
      ["status.base"] = "bg:0 fg:7",
      ["prompt.primary"] = "bg:6 fg:0 bold",
      ["prompt.secondary"] = "bg:0 fg:7",
      ["prompt.error"] = "bg:1 fg:0 bold",
    },
    chars = {
      split_vertical = "│",
      split_horizontal = "─",
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
    mouse = {
      selection_override = { "ctrl", "alt" },
    },
    splits = {
      color = { active = 6, passive = 8 },
      chars = {
        vertical = "│",
        horizontal = "─",
      },
    },
    floats = {
      defaults = {
        color = { active = 6, passive = 8 },
      },
      adhoc = {
        size = { width = 90, height = 90 },
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
            style = hexe.style("status.active"),
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
        name = "time",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.time({
            style = hexe.style("status.base"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
    },
  },

  prompt = {
    left = {
      segment({
        name = "username",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.username({
            style = hexe.style("prompt.primary"),
            prefix = " ",
          })
        end,
      }),
      segment({
        name = "hostname",
        priority = 5,
        builtin = function(_)
          return hexe.segment.builtin.hostname({
            style = hexe.style("prompt.primary"),
            prefix = "@",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "directory",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.directory({
            style = hexe.style("prompt.secondary"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "git_branch",
        priority = 10,
        builtin = function(_)
          return hexe.segment.builtin.git_branch({
            style = hexe.style("prompt.primary"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "git_status",
        priority = 15,
        builtin = function(_)
          return hexe.segment.builtin.git_status({
            style = hexe.style("prompt.primary"),
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "status",
        priority = 2,
        builtin = function(_)
          return hexe.segment.builtin.status({
            style = hexe.style("prompt.error"),
            prefix = " ",
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "character",
        priority = 1,
        builtin = function(_)
          return hexe.segment.builtin.character({
            style = hexe.style("prompt.secondary"),
            prefix = " ",
          })
        end,
      }),
    },
    right = {
      segment({
        name = "duration",
        priority = 10,
        builtin = function(_)
          return hexe.segment.builtin.duration({
            style = hexe.style("prompt.secondary"),
            suffix = " ",
          })
        end,
      }),
      segment({
        name = "jobs",
        priority = 5,
        builtin = function(_)
          return hexe.segment.builtin.jobs({
            style = hexe.style("prompt.primary"),
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
