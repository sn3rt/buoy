-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

  ---------------------------------------------------------------------------
  -- Colorscheme (Catppuccin)
  ---------------------------------------------------------------------------
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- latte, frappe, macchiato, mocha
        integrations = {
          treesitter = true,
          native_lsp = true,
          nvimtree = true,
          bufferline = true,
          telescope = true,
          mason = true,
          cmp = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  ---------------------------------------------------------------------------
  -- Treesitter
  ---------------------------------------------------------------------------
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      local parsers = {
        "lua", "python", "javascript", "typescript",
        "html", "css", "bash", "json", "yaml",
        "toml", "markdown", "markdown_inline",
        "c", "cpp", "rust",
      }

      require("nvim-treesitter").install(parsers)

      vim.api.nvim_create_autocmd("FileType", {
        pattern = parsers,
        callback = function()
          if pcall(vim.treesitter.start) then
            vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- File tree
  ---------------------------------------------------------------------------
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("nvim-tree").setup()
    end,
  },

  ---------------------------------------------------------------------------
  -- Bufferline
  ---------------------------------------------------------------------------
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup()

      vim.keymap.set("n", "<Tab>", "<cmd>bnext<CR>", { desc = "Next buffer" })
      vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<CR>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<leader>q", "<cmd>bd<CR>", { desc = "Close buffer" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Copilot (robuste mappings, geen <80>@7 bug)
  ---------------------------------------------------------------------------
  {
    "github/copilot.vim",
    config = function()
      vim.g.copilot_no_tab_map = true

      vim.keymap.set("i", "<C-j>", function()
        local suggestion = vim.fn["copilot#Accept"]("")
        if suggestion ~= "" then
          vim.api.nvim_feedkeys(suggestion, "i", true)
        end
      end, { silent = true, desc = "Copilot Accept" })

      vim.keymap.set("i", "<C-k>", function()
        vim.fn["copilot#Dismiss"]()
      end, { silent = true, desc = "Copilot Dismiss" })

      vim.keymap.set("n", "<leader>cp", "<cmd>Copilot panel<CR>", { desc = "Copilot Panel" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Copilot Chat
  ---------------------------------------------------------------------------
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
      "github/copilot.vim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("CopilotChat").setup({
        window = {
          position = "right",
          width = 0.25,
        },
      })

      vim.keymap.set("n", "<leader>cc", function()
        require("CopilotChat").open()
      end, { desc = "Copilot Chat" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Mason (LSP installer)
  ---------------------------------------------------------------------------
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          -- Web
          "ts_ls", "html", "cssls", "jsonls",

          -- Programming
          "pyright", "rust_analyzer", "clangd",
          "bashls", "lua_ls",

          -- Config / markup
          "yamlls", "marksman", "taplo",
          "dockerls",
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- LSP config (Neovim 0.11+ native: vim.lsp.config / vim.lsp.enable)
  ---------------------------------------------------------------------------
  {
    "neovim/nvim-lspconfig",
    config = function()
      -- Definieer alle server configs hier
      local servers = {
        pyright = {},
        rust_analyzer = {},
        ts_ls = {},
        clangd = {},
        bashls = {},
        html = {},
        cssls = {},
        jsonls = {},
        yamlls = {},
        taplo = {},
        dockerls = {},

        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
            },
          },
        },
      }

      -- Registreer configs (nvim 0.11+)
      for name, cfg in pairs(servers) do
        vim.lsp.config(name, cfg)
      end

      -- Enable ze allemaal
      vim.lsp.enable(vim.tbl_keys(servers))

      -- LSP keymaps (globaal)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
      vim.keymap.set("n", "K", vim.lsp.buf.hover, { desc = "Hover docs" })
      vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { desc = "Rename symbol" })
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { desc = "Code action" })
    end,
  },

  ---------------------------------------------------------------------------
  -- Autocomplete (nvim-cmp)
  ---------------------------------------------------------------------------
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
    config = function()
      local cmp = require("cmp")

      cmp.setup({
        mapping = {
          ["<Tab>"] = cmp.mapping.confirm({ select = true }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },

  ---------------------------------------------------------------------------
  -- Telescope
  ---------------------------------------------------------------------------
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({})

      local builtin = require("telescope.builtin")

      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep,  { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers,    { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags,  { desc = "Help" })
    end,
  },

})
