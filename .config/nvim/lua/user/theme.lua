local M = {}

local function hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

local function fg(color)
  return { ctermfg = color }
end

local function bg(color)
  return { ctermbg = color }
end

local function pair(foreground, background, extra)
  return vim.tbl_extend("force", { ctermfg = foreground, ctermbg = background }, extra or {})
end

function M.apply()
  vim.opt.termguicolors = false
  vim.g.colors_name = "buoy-terminal"

  hl("Normal", {})
  hl("NormalFloat", bg(0))
  hl("FloatBorder", fg(5))
  hl("FloatTitle", { ctermfg = 11, bold = true })
  hl("SignColumn", bg(0))
  hl("EndOfBuffer", fg(0))
  hl("LineNr", fg(8))
  hl("CursorLine", bg(0))
  hl("CursorLineNr", { ctermfg = 6, bold = true })
  hl("Cursor", pair(0, 6))
  hl("Visual", pair(0, 6))
  hl("Search", pair(0, 11))
  hl("IncSearch", pair(0, 5))
  hl("MatchParen", { ctermfg = 11, ctermbg = 0, bold = true })
  hl("Pmenu", pair(7, 0))
  hl("PmenuSel", { ctermfg = 0, ctermbg = 5, bold = true })
  hl("StatusLine", { ctermfg = 0, ctermbg = 6, bold = true })
  hl("StatusLineNC", pair(8, 0))
  hl("WinSeparator", fg(8))
  hl("VertSplit", { link = "WinSeparator" })
  hl("TabLine", pair(8, 0))
  hl("TabLineSel", { ctermfg = 0, ctermbg = 5, bold = true })
  hl("TabLineFill", bg(0))

  hl("Comment", { ctermfg = 8, italic = true })
  hl("Constant", fg(13))
  hl("String", fg(2))
  hl("Character", fg(2))
  hl("Number", fg(11))
  hl("Boolean", { ctermfg = 11, bold = true })
  hl("Identifier", fg(7))
  hl("Function", fg(4))
  hl("Statement", { ctermfg = 5, bold = true })
  hl("Conditional", { ctermfg = 5, bold = true })
  hl("Repeat", { ctermfg = 5, bold = true })
  hl("Label", fg(6))
  hl("Operator", fg(6))
  hl("Keyword", { ctermfg = 5, bold = true })
  hl("PreProc", fg(13))
  hl("Type", fg(3))
  hl("Special", fg(6))
  hl("Underlined", { ctermfg = 4, underline = true })
  hl("Error", { ctermfg = 1, bold = true })
  hl("Todo", { ctermfg = 0, ctermbg = 3, bold = true })

  hl("DiagnosticError", fg(1))
  hl("DiagnosticWarn", fg(3))
  hl("DiagnosticInfo", fg(4))
  hl("DiagnosticHint", fg(6))
  hl("DiagnosticOk", fg(2))

  hl("@comment", { link = "Comment" })
  hl("@string", { link = "String" })
  hl("@number", { link = "Number" })
  hl("@boolean", { link = "Boolean" })
  hl("@function", { link = "Function" })
  hl("@function.call", { link = "Function" })
  hl("@keyword", { link = "Keyword" })
  hl("@keyword.function", { link = "Keyword" })
  hl("@type", { link = "Type" })
  hl("@variable", fg(7))
  hl("@variable.builtin", { ctermfg = 13, italic = true })
  hl("@constant", { link = "Constant" })
  hl("@constructor", fg(3))
  hl("@property", fg(6))
  hl("@punctuation", fg(8))

  hl("NvimTreeNormal", bg(0))
  hl("NvimTreeFolderName", fg(4))
  hl("NvimTreeOpenedFolderName", { ctermfg = 4, bold = true })
  hl("NvimTreeGitDirty", fg(3))
  hl("NvimTreeGitNew", fg(2))
  hl("NvimTreeGitDeleted", fg(1))

  hl("TelescopeNormal", bg(0))
  hl("TelescopeBorder", fg(5))
  hl("TelescopePromptBorder", fg(6))
  hl("TelescopeSelection", { ctermfg = 11, ctermbg = 0, bold = true })
  hl("TelescopeMatching", { ctermfg = 5, bold = true })

  hl("BufferLineFill", bg(0))
  hl("BufferLineBackground", pair(8, 0))
  hl("BufferLineBufferSelected", { ctermfg = 7, bold = true })
  hl("BufferLineSeparator", pair(0, 0))
  hl("BufferLineSeparatorSelected", pair(0, 0))
end

function M.setup()
  M.apply()

  vim.api.nvim_create_user_command("BuoyThemeReload", function()
    M.apply()
  end, {})

  vim.api.nvim_create_autocmd({ "ColorScheme", "VimEnter" }, {
    group = vim.api.nvim_create_augroup("BuoyTheme", { clear = true }),
    callback = function()
      M.apply()
    end,
  })
end

return M
