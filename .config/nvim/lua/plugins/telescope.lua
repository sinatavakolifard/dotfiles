return {
  'nvim-telescope/telescope.nvim',
  version = '*', -- pin to the latest release tag, as the README recommends
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' },
  },
  cmd = 'Telescope',
  keys = {
    { '<leader>ff', '<cmd>Telescope find_files<cr>', desc = 'Find files' },
    { '<leader>fg', '<cmd>Telescope live_grep<cr>', desc = 'Live grep' },
    { '<leader>fb', '<cmd>Telescope buffers<cr>', desc = 'Buffers' },
  },
  config = function()
    require('telescope').setup {
      defaults = {
        file_ignore_patterns = { '%.git/' }, -- Lua pattern: hide the .git directory everywhere
      },
      pickers = {
        find_files = { hidden = true }, -- include dotfiles (e.g. .config/ in this repo)
      },
    }
    require('telescope').load_extension('fzf')
  end,
}
