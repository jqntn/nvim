local function biome_cmd(dispatchers, config)
  local cmd = "biome"
  local root = (config or {}).root_dir
  if root then
    for _, name in ipairs({ "biome.cmd", "biome" }) do
      local candidate = vim.fs.joinpath(root, "node_modules", ".bin", name)
      if vim.fn.executable(candidate) == 1 then
        cmd = candidate
        break
      end
    end
  end
  return vim.lsp.rpc.start({ cmd, "lsp-proxy" }, dispatchers)
end

local function tsc_bin(root)
  if root then
    for _, name in ipairs({ "tsc.cmd", "tsc" }) do
      local candidate = vim.fs.joinpath(root, "node_modules", ".bin", name)
      if vim.fn.executable(candidate) == 1 then
        return candidate
      end
    end
  end
  return "tsc"
end

local function tsc_cmd(dispatchers, config)
  local bin = tsc_bin((config or {}).root_dir)
  return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
end

local function tsc_root_dir(bufnr, on_dir)
  local root = vim.fs.root(bufnr, {
    "package-lock.json",
    "yarn.lock",
    "pnpm-lock.yaml",
    "bun.lock",
    "bun.lockb",
  })
  if not root then
    return
  end
  local ok, out = pcall(function()
    return vim.system({ tsc_bin(root), "--version" }, { text = true }):wait()
  end)
  if not ok or out.code ~= 0 then
    return
  end
  local version = vim.version.parse(out.stdout or "")
  if version and version.major >= 7 then
    on_dir(root)
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        biome = { cmd = biome_cmd },
        html = {},
        ts_ls = { enabled = false },
        tsc = { cmd = tsc_cmd, mason = false, root_dir = tsc_root_dir },
        vtsls = { enabled = false },
        wasm_language_tools = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        css = { "biome-check" },
        html = { "biome-check" },
        javascript = { "biome-check" },
        json = { "biome-check" },
        jsonc = { "biome-check" },
      },
    },
  },
}
