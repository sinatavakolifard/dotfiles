return {
  -- Quickstart configs for LSP
  { 'neovim/nvim-lspconfig' },
  -- Fuzzy picker
  { 'ibhagwan/fzf-lua', cmd = 'FzfLua', opts = { fzf_colors = true } },
  -- Autocompletion
  { 'nvim-mini/mini.completion', event = 'InsertEnter', opts = {} },
  -- Enhanced quickfix/loclist
  { 'stevearc/quicker.nvim', event = 'FileType qf', opts = {} },
  -- Git integration
  { 'lewis6991/gitsigns.nvim', event = { 'BufReadPre', 'BufNewFile' }, opts = {} },
}
