return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false, -- the main branch doesn't support lazy-loading
  build = ':TSUpdate',
  config = function()
    -- Parsers are compiled locally with the tree-sitter CLI (Arch: `pacman -S tree-sitter-cli`)
    if vim.fn.executable('tree-sitter') == 1 then
      require('nvim-treesitter').install({ 'bash', 'python', 'rust', 'json', 'yaml', 'toml' })
    else
      vim.notify('tree-sitter CLI not found, skipping parser install', vim.log.levels.WARN)
    end
    vim.api.nvim_create_autocmd('FileType', {
      callback = function(ev)
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
