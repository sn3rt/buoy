-- Leader key
vim.g.mapleader = " "

-- UI
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = false
vim.opt.showmode = false
vim.opt.showtabline = 2

-- Editing
vim.opt.wrap = false
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Scrolling
vim.opt.scrolloff = 4
vim.opt.sidescrolloff = 8

-- Behavior
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.updatetime = 250
vim.opt.hidden = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- Keymaps
vim.keymap.set("n", "<leader>e", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file tree" })
