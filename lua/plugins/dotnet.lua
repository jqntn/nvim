return {
  { "Hoffs/omnisharp-extended-lsp.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
        roslyn_ls = {},
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "roslyn-language-server" } },
  },
}
