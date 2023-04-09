{ stdenv, pkgs, fetchFromGitHub, lib }:

stdenv.mkDerivation {
  name = "nvchad";

  src = fetchFromGitHub {
    owner = "nvchad";
    repo = "nvchad";
    rev  = "74e374ef7be0dac71c8c7d6a16b4cc1b0ebcb2e5";
    sha256 = "sha256-V/ROrXVPp1vfDX/WOF5N2iuLO92EF2mSJDIsVuCcOxA=";
  };

  buildInputs = [
    pkgs.makeWrapper
  ];

  config_chadrc = pkgs.writeText "chadrc.lua" ''
    local M = {}

    M.mappings = require "custom.mappings"

    local opt = vim.opt
    opt.relativenumber = true

    opt.runtimepath:append('/home/vagrant/.cache/nvim')

    M.plugins = {
      ["neovim/nvim-lspconfig"] = {
        config = function()
          require "plugins.configs.lspconfig"
          require "custom.plugins.lspconfig"
        end,
      },
      ["christoomey/vim-tmux-navigator"] = { },
      ["tpope/vim-obsession"] = { },
      ["wbthomason/packer.nvim"] = {
        override_options = {
          compile_path = "/home/vagrant/.cache/nvim/plugin/packer_compiled.lua"
        },
      },

      ["williamboman/mason.nvim"] = {
        override_options = {
          ensure_installed = {
            "bashls",
            "cfn-lint",
            "css-lsp",
            "clangd",
            "eslint-lsp",
            "dockerfile-language-server",
            "html-lsp",
            "json-lsp",
            "lua-language-server",
            "markdownlint",
            "omnisharp",
            "pyright",
            "rnix-lsp",
            "shfmt",
            "solargraph",
            "tailwindcss-language-server",
            "tflint",
            "vim-language-server",
            "yaml-language-server",
            "tailwindcss-language-server",
            "typescript-language-server",
            "stylua",
            "shfmt",
            "shellcheck",
          },
        }
      },
      ["nvim-treesitter/nvim-treesitter"] = {
        override_options = {
          ensure_installed = {
            "cmake",
            "comment",
            "c_sharp",
            "c",
            "cpp",
            "css",
            "dockerfile",
            "fish",
            "go",
            "hcl",
            "help",
            "html",
            "http",
            "java",
            "javascript",
            "jsdoc",
            "json",
            "lua",
            "nix",
            "php",
            "python",
            "ruby",
            "toml",
            "tsx",
            "typescript",
            "vim",
            "yaml",
          },
        }
      }
    }

    return M
  '';

  config_plugins_lspconfig = pkgs.writeText "lspconfig.lua" ''
    local on_attach = require("plugins.configs.lspconfig").on_attach
    local capabilities = require("plugins.configs.lspconfig").capabilities
    local lspconfig = require "lspconfig"
    local servers = {
      "html",
      "eslint",
      "cssls",
      "ansiblels",
      "clangd",
      "cmake",
      "dockerls",
      "java_language_server",
      "jsonls",
      "omnisharp",
      "pyright",
      "rnix",
      "solargraph",
      "sumneko_lua",
      "tailwindcss",
      "terraformls",
    }

    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup {
        on_attach = on_attach,
        capabilities = capabilities,
      }
    end
  '';

  custom_mappings = pkgs.writeText "mappings.lua" ''
    local M = {}

    M.tmux = {
      n = {
        ["<C-l>"] = { "<cmd> TmuxNavigateRight <CR>", "Tmux nav pane right" },
        ["<C-j>"] = { "<cmd> TmuxNavigateDown <CR>", "Tmux nav pane down" },
        ["<C-k>"] = { "<cmd> TmuxNavigateUp <CR>", "Tmux nav pane up" },
        ["<C-h>"] = { "<cmd> TmuxNavigateLeft <CR>", "Tmux nav pane left" },
      },
    }

    return M
  '';

  installPhase = ''
    cp -r . $out
    makeWrapper ${pkgs.callPackage ./neovim.nix {}}/bin/nvim $out/bin/nvim
  '';

  patchPhase = ''
    mkdir -p lua/custom/plugins
    cp $custom_mappings lua/custom/mappings.lua
    cp $config_plugins_lspconfig lua/custom/plugins/lspconfig.lua
    cp $config_chadrc lua/custom/chadrc.lua
  '';
}

