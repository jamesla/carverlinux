{ config, pkgs, ... }:
{
  enable = true;
  defaultEditor = true;
  viAlias = true;
  vimAlias = true;

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
        lua <<EOF

        -- Setup language servers.
        local lspconfig = require('lspconfig')

        -- Global mappings.
        -- See `:help vim.diagnostic.*` for documentation on any of the below functions
        vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
        vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
        vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
        vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

        -- Use LspAttach autocommand to only map the following keys
        -- after the language server attaches to the current buffer
        vim.api.nvim_create_autocmd('LspAttach', {
          group = vim.api.nvim_create_augroup('UserLspConfig', {}),
          callback = function(ev)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
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

        EOF
      '';
    }
    pkgs.vimPlugins.nerdtree
    {
      plugin = pkgs.vimPlugins.vim-tmux-navigator;
      config = ''
        " bind nerdtree
        nnoremap <C-n> :NERDTree<CR>

        " Start NERDTree and put the cursor back in the other window.
        autocmd VimEnter * NERDTree | wincmd p

        " Exit Vim if NERDTree is the only window remaining in the only tab.
        autocmd BufEnter * if tabpagenr('$') == 1 && winnr('$') == 1 && exists('b:NERDTree') && b:NERDTree.isTabTree() | quit | endif
      '';
    }
    pkgs.vimPlugins.vim-gitgutter
    {
      plugin = pkgs.vimPlugins.vim-gitgutter;
      config = ''
        set updatetime=100
      '';
    }
    pkgs.vimPlugins.mason-nvim
    {
      plugin = pkgs.vimPlugins.mason-nvim;
      config = ''
        lua require("mason").setup()
      '';
    }
    pkgs.vimPlugins.mason-lspconfig-nvim
    {
      plugin = pkgs.vimPlugins.mason-lspconfig-nvim;
      config = ''
        lua <<EOF
          require("mason-lspconfig").setup({
            ensure_installed = { "ts_ls", "terraformls", "eslint" }
          })
        EOF
      '';
    }
    pkgs.vimPlugins.nvim-lspconfig
    {
      plugin = pkgs.vimPlugins.nvim-lspconfig;
      config = ''
        lua require('lspconfig').ts_ls.setup {}
        lua require('lspconfig').eslint.setup{}
        lua require('lspconfig').terraformls.setup {}
      '';
    }
    pkgs.vimPlugins.hardtime-nvim
    {
      plugin = pkgs.vimPlugins.hardtime-nvim;
      config = ''
        lua require("hardtime").setup()
      '';
    }
    pkgs.vimPlugins.neoscroll-nvim
    {
      plugin = pkgs.vimPlugins.neoscroll-nvim;
      config = ''
        lua require('neoscroll').setup()
      '';
    }
    pkgs.vimPlugins.vim-sensible
    pkgs.vimPlugins.vim-tmux-navigator
    pkgs.vimPlugins.nvim-treesitter
    pkgs.vimPlugins.telescope-nvim
    {
      plugin = pkgs.vimPlugins.telescope-nvim;
      config = ''
        nnoremap <leader>ff :Telescope find_files<CR>
        nnoremap <leader>fg :Telescope live_grep<CR>
        nnoremap <leader>fb :Telescope buffers<CR>
        nnoremap <leader>fh :Telescope help_tags<CR>
      '';
    }
  ];

  extraPackages = [
    pkgs.ripgrep
    pkgs.fd
  ];
}
