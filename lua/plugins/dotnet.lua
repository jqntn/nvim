return {
  { "Hoffs/omnisharp-extended-lsp.nvim", enabled = false },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        omnisharp = { enabled = false },
        roslyn_ls = {
          settings = {
            ["csharp|background_analysis"] = {
              dotnet_analyzer_diagnostics_scope = "openFiles",
              dotnet_compiler_diagnostics_scope = "openFiles",
            },
          },
        },
      },
    },
  },
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = { "roslyn-language-server" } },
  },
}
