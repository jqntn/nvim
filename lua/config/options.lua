-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

if vim.fn.has("win32") == 1 then
  local cache_file = vim.fs.joinpath(vim.fn.stdpath("cache"), "msvc-env.json")

  local function find_clang()
    local roots = "C:/Program Files,C:/Program Files (x86)"
    for _, pattern in ipairs({ "LLVM/bin/clang.exe", "Microsoft Visual Studio/*/*/VC/Tools/Llvm/x64/bin/clang.exe" }) do
      local hit = vim.fn.globpath(roots, pattern, true, true)[1]
      if hit then
        return vim.fs.dirname(hit)
      end
    end
  end

  local function apply(env)
    if type(env) ~= "table" or not (env.INCLUDE and env.LIB and env.BIN) then
      return false
    end
    if vim.fn.filereadable(vim.fs.joinpath(vim.split(env.BIN, ";", { plain = true })[1], "cl.exe")) == 0 then
      return false
    end
    vim.env.INCLUDE = env.INCLUDE
    vim.env.LIB = env.LIB
    vim.env.LIBPATH = env.LIBPATH
    vim.env.PATH = env.BIN .. ";" .. vim.env.PATH
    if env.CLANG and vim.fn.filereadable(vim.fs.joinpath(env.CLANG, "clang.exe")) == 1 then
      vim.env.PATH = env.CLANG .. ";" .. vim.env.PATH
    end
    return true
  end

  local function read_cache()
    if vim.fn.filereadable(cache_file) == 0 then
      return nil
    end
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(cache_file), "\n"))
    return ok and decoded or nil
  end

  local function probe()
    local vcvars = vim.fn.globpath(
      "C:/Program Files,C:/Program Files (x86)",
      "Microsoft Visual Studio/*/*/VC/Auxiliary/Build/vcvars64.bat",
      true,
      true
    )[1]
    if not vcvars then
      return nil
    end
    local script = vim.fn.tempname() .. ".bat"
    local dump = vim.fn.tempname() .. ".env"
    vim.fn.writefile({ "@echo off", 'call "' .. vcvars .. '"', 'set > "' .. dump .. '"' }, script)
    local result = vim.system({ "cmd.exe", "/c", script }, { text = true }):wait()
    if result.code ~= 0 or vim.fn.filereadable(dump) == 0 then
      return nil
    end
    local env = {}
    for _, line in ipairs(vim.fn.readfile(dump)) do
      local key, value = line:match("^([^=]+)=(.*)$")
      if key then
        key = key:upper()
        if key == "INCLUDE" or key == "LIB" or key == "LIBPATH" then
          env[key] = value
        elseif key == "PATH" then
          local bin = {}
          for _, entry in ipairs(vim.split(value, ";", { plain = true })) do
            if entry:lower():find("hostx64", 1, true) then
              table.insert(bin, entry)
            end
          end
          env.BIN = table.concat(bin, ";")
        end
      end
    end
    env.CLANG = find_clang()
    return env
  end

  if vim.env.INCLUDE == nil and vim.env.LIB == nil and vim.fn.executable("gcc") == 0 then
    if not apply(read_cache()) then
      local probed = probe()
      if apply(probed) then
        pcall(vim.fn.writefile, { vim.json.encode(probed) }, cache_file)
      end
    end
  end

  if vim.env.CC == nil then
    for _, compiler in ipairs({ "cl", "gcc", "clang" }) do
      if vim.fn.executable(compiler) == 1 then
        vim.env.CC = compiler
        break
      end
    end
  end
end
