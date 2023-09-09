{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the
  # paths it should manage.
  home.username = "vagrant";
  home.homeDirectory = "/home/vagrant";

  programs.git = {
    enable = true;
    userName = "jamesla";
    userEmail = "jamesgmccallum@gmail.com";
  };

  programs.chromium = {
    enable = true;
    extensions = [
      "dbepggeogbaibhgnhhndojpepiihcmeb" # vimium
    ];
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs; [
      tmuxPlugins.sensible
      tmuxPlugins.yank
      tmuxPlugins.dracula
      tmuxPlugins.open
      {
        plugin = tmuxPlugins.resurrect;
        extraConfig = ''
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes '~nvim'
          set -g @resurrect-capture-pane-contents 'on'
        '';
      }
      {
        plugin = tmuxPlugins.continuum;
        extraConfig = ''
          set -g @continuum-boot 'on'
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '1';
          set -g status-right 'Continuum status: #{continuum_status}'
        '';
      }
    ];
    extraConfig = ''
      set-option -g pane-active-border-style "bg=colour208"
      set-option -ag pane-active-border-style "fg=black"
      bind down resize-pane -D 40
      bind up resize-pane -U 40
      bind left resize-pane -U 10
      bind right resize-pane -D 10
      is_vim='echo "#{pane_current_command}" | grep -iqE "(^|\/)g?(view|n?vim?)(diff)?$"'
      bind -n C-h if-shell "$is_vim" "send-keys C-h" "select-pane -L"
      bind -n C-j if-shell "$is_vim" "send-keys C-j" "select-pane -D"
      bind -n C-k if-shell "$is_vim" "send-keys C-k" "select-pane -U"
      bind -n C-l if-shell "$is_vim" "send-keys C-l" "select-pane -R"
      setw -g mode-keys vi
      bind-key -T copy-mode-vi 'v' send -X begin-selection
      bind-key -T copy-mode-vi 'y' send -X copy-selection
      set -g @continuum-restore 'on'
      bind '%' split-window -h -c '#{pane_current_path}'  # Split panes horizontal
      bind '"' split-window -v -c '#{pane_current_path}'  # Split panes vertically
      bind 'c' run-shell "tmux new-window -c '~'; tmux split-window -h -c '~'; tmux select-pane -R"
      run-shell ${pkgs.tmuxPlugins.yank}/yank.tmux
    '';
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    extraConfig = ''
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
          lspconfig.terraform_lsp.setup{}

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
      pkgs.vimPlugins.vim-sensible
      pkgs.vimPlugins.vim-tmux-navigator
      pkgs.vimPlugins.nvim-treesitter
    ];

    extraPackages = [
      pkgs.terraform-lsp
    ];
  };

  home.stateVersion = "23.05";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
