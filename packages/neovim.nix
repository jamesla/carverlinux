{ config, pkgs, ... }:
{
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;
  withRuby = false;
  withPython3 = false;

  extraConfig = ''
    map <Space> <Leader>
    set noswapfile
    set number relativenumber
    set clipboard+=unnamedplus
    set tabstop=2
    set shiftwidth=2
    set expandtab
    set smartindent
    set cursorline
    hi cursorline cterm=none term=none
    autocmd WinEnter * setlocal cursorline
    autocmd WinLeave * setlocal nocursorline
    highlight CursorLine guibg=#303000 ctermbg=234
  '';

  plugins = [
    pkgs.vimPlugins.nvim-lspconfig
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;
      config = ''
        local lspconfig = require('lspconfig')

        vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
        vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

            local opts = { buffer = ev.buf }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set('n', '<space>wl', function()
              print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, opts)
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<space>f', function()
              vim.lsp.buf.format { async = true }
            end, opts)
          end,
        })
      '';
    }
    pkgs.vimPlugins.nerdtree
    {
      plugin = pkgs.vimPlugins.vim-tmux-navigator;
      config = ''
        vim.keymap.set('n', '<C-n>', ':NERDTree<CR>')

        vim.api.nvim_create_autocmd('VimEnter', {
          callback = function()
            vim.cmd('NERDTree | wincmd p')
          end,
        })

        vim.api.nvim_create_autocmd('BufEnter', {
          callback = function()
            if vim.fn.tabpagenr('$') == 1 and vim.fn.winnr('$') == 1 then
              local nerdtree = vim.b.NERDTree
              if nerdtree ~= nil and nerdtree.isTabTree() then
                vim.cmd('quit')
              end
            end
          end,
        })
      '';
    }
    pkgs.vimPlugins.vim-gitgutter
    {
      plugin = pkgs.vimPlugins.vim-gitgutter;
      config = ''
        vim.opt.updatetime = 100
      '';
    }
    pkgs.vimPlugins.mason-nvim
    {
      plugin = pkgs.vimPlugins.mason-nvim;
      config = ''
        require("mason").setup()
      '';
    }
    pkgs.vimPlugins.mason-lspconfig-nvim
    {
      plugin = pkgs.vimPlugins.mason-lspconfig-nvim;
      config = ''
        require("mason-lspconfig").setup({
          ensure_installed = { "ts_ls", "terraformls", "eslint" }
        })
      '';
    }
    pkgs.vimPlugins.nvim-lspconfig
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;
      config = ''
        local lspconfig = require('lspconfig')
        lspconfig.ts_ls.setup {}
        lspconfig.eslint.setup {}
        lspconfig.terraformls.setup {}
      '';
    }
    #{
    #  plugin = pkgs.vimPlugins.hardtime-nvim;
    #  config = ''
    #    require("hardtime").setup()
    #  '';
    #}
    pkgs.vimPlugins.neoscroll-nvim
    {
      plugin = pkgs.vimPlugins.neoscroll-nvim;
      config = ''
        require('neoscroll').setup()
      '';
    }
    pkgs.vimPlugins.vim-sensible
    pkgs.vimPlugins.vim-tmux-navigator
    pkgs.vimPlugins.nvim-treesitter
    pkgs.vimPlugins.telescope-nvim
    {
      plugin = pkgs.vimPlugins.telescope-nvim;
      config = ''
        vim.keymap.set('n', '<leader>ff', ':Telescope find_files<CR>')
        vim.keymap.set('n', '<leader>fg', ':Telescope live_grep<CR>')
        vim.keymap.set('n', '<leader>fb', ':Telescope buffers<CR>')
        vim.keymap.set('n', '<leader>fh', ':Telescope help_tags<CR>')
      '';
    }
  ];

  extraPackages = [
    pkgs.ripgrep
    pkgs.fd
  ];
}
