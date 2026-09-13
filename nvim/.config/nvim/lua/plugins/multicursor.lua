-- Multi-cursor editing, carried over from the macOS LazyVim setup.
-- Shift+Down / Shift+Up add a cursor on the next / previous line, which makes it
-- quick to uncomment whole blocks (e.g. the file list in a git commit message).
-- Note: <C-d> and <C-a> replace vim's half-page scroll and number increment.
return {
  {
    "mg979/vim-visual-multi",
    lazy = false,
    init = function()
      -- Configure vim-visual-multi for better visibility
      vim.g.VM_theme = 'iceblue'
      vim.g.VM_highlight_matches = 'underline'
      vim.g.VM_maps = {
        ["Find Under"] = "<C-d>",
        ["Find Subword Under"] = "<C-d>",
        ["Select Cursor Down"] = "<S-Down>",
        ["Select Cursor Up"] = "<S-Up>",
        ["Select All"] = "<C-a>",
        ["Visual All"] = "<C-a>",
        ["Undo"] = "u",
        ["Redo"] = "<C-r>",
        ["Add Cursor At Pos"] = "<C-q>"
      }
      -- Ensure cursors are visible during editing
      vim.g.VM_persistent_cursors = 1
      vim.g.VM_show_warnings = 0
      vim.g.VM_silent_exit = 0

      -- Enhanced visibility settings
      vim.g.VM_Mono_hl = 'DiffText'
      vim.g.VM_Extend_hl = 'DiffAdd'
      vim.g.VM_Cursor_hl = 'Visual'
      vim.g.VM_Insert_hl = 'DiffChange'

      -- Ensure real-time updates at all cursor positions
      vim.g.VM_live_editing = 1
    end
  }
}
