local M = {}

---@param lines string[]
function M.extract(lines)
  local code = table.concat(lines, "\n")
  local config = code:match("\n(%-%-%- ?@class snacks%.%w+%.Config.-\n})")
  config = config or code:match("\n(%-%-%- ?@class snacks%.Config.-\n})")
  local mod ---@type string
  local comments = {} ---@type string[]
  local types = {} ---@type string[]

  ---@type {name: string, args: string, comment?: string, types?: string, type: "method"|"function"}[]
  local methods = {}

  for _, line in ipairs(lines) do
    if line:match("^%-%-") then
      table.insert(comments, line)
    else
      local comment = table.concat(comments, "\n")
      if line:find("^local M =") then
        mod = comment
      elseif comment:find("@private") then
      else
        local t, name, args = line:match("^function M([:%.])([%w_%.]+)%((.-)%)")
        if name and args then
          table.insert(methods, {
            name = name,
            args = args,
            type = t,
            comment = comment,
          })
        elseif #comments > 0 and line == "" then
          table.insert(types, table.concat(comments, "\n"))
        end
      end
      comments = {}
    end
  end

  local private = mod and mod:find("@private")
  config = config and config:gsub("local defaults = ", ""):gsub("local config = ", "") or nil

  ---@class snacks.docs.Info
  local ret = {
    config = config,
    mod = mod,
    methods = methods,
    types = types,
  }
  return private and { config = config, methods = {}, types = {} } or ret
end

---@param tag string
---@param readme string
---@param content string
function M.replace(tag, readme, content)
  content = vim.trim(content)
  local pattern = "(<%!%-%- " .. tag .. ":start %-%->).*(<%!%-%- " .. tag .. ":end %-%->)"
  if not readme:find(pattern) then
    error("tag " .. tag .. " not found")
  end
  return readme:gsub(pattern, "%1\n\n" .. content .. "\n\n%2")
end

function M.md(str)
  local comments = {} ---@type string[]
  local lines = vim.split(str, "\n", { plain = true })

  while lines[1] and lines[1]:find("^%-%-") and not lines[1]:find("^%-%-%-%s*@") do
    local line = table.remove(lines, 1):gsub("^[%-]*%s*", "")
    table.insert(comments, line)
  end

  local ret = {} ---@type string[]
  if #comments > 0 then
    table.insert(ret, vim.trim(table.concat(comments, "\n")))
    table.insert(ret, "")
  end
  if #lines > 0 then
    table.insert(ret, "```lua")
    table.insert(ret, vim.trim(table.concat(lines, "\n")))
    table.insert(ret, "```")
  end

  return vim.trim(table.concat(ret, "\n")) .. "\n"
end

---@param name string
---@param info snacks.docs.Info
function M.render(name, info)
  local lines = {} ---@type string[]
  local function add(line)
    table.insert(lines, line)
  end

  local prefix = ("Snacks.%s"):format(name)
  if name == "init" then
    prefix = "Snacks"
  end

  if info.config then
    add("## ⚙️ Config\n")
    add(M.md(info.config))
  end

  if #info.types > 0 then
    add("## 📚 Types\n")
    for _, t in ipairs(info.types) do
      add(M.md(t))
    end
  end

  if info.mod or #info.methods > 0 then
    add("## 📦 Module\n")
  end

  if info.mod then
    local mod_lines = vim.split(info.mod, "\n")
    mod_lines = vim.tbl_filter(function(line)
      local overload = line:match("^%-%-%-%s*@overload (.*)(%s*)$") --[[@as string?]]
      if overload then
        table.insert(info.methods, {
          name = "",
          args = "",
          type = "",
          comment = "---@type " .. overload,
        })
        return false
      elseif line:find("^%s*$") then
        return false
      end
      return true
    end, mod_lines)
    table.insert(mod_lines, prefix .. " = {}")
    add(M.md(table.concat(mod_lines, "\n")))
  end

  table.sort(info.methods, function(a, b)
    if a.type == b.type then
      return a.name < b.name
    end
    return a.type < b.type
  end)

  for _, method in ipairs(info.methods) do
    add(("### `%s%s%s()`\n"):format(method.type == ":" and name or prefix, method.type, method.name))
    local code = ("%s\n%s%s%s(%s)"):format(
      method.comment or "",
      method.type == ":" and name or prefix,
      method.type,
      method.name,
      method.args
    )
    add(M.md(code))
  end

  lines = vim.split(vim.trim(table.concat(lines, "\n")), "\n")
  return lines
end

function M.write(name, lines)
  local path = ("docs/%s.md"):format(name)
  local ok, text = pcall(vim.fn.readfile, path)

  local docgen = "<!-- docgen -->"
  local top = {} ---@type string[]

  if not ok then
    table.insert(top, "# 🍿 " .. name)
    table.insert(top, "")
  else
    for _, line in ipairs(text) do
      if line == docgen then
        break
      end
      table.insert(top, line)
    end
  end
  table.insert(top, docgen)
  table.insert(top, "")
  vim.list_extend(top, lines)

  vim.fn.writefile(top, path)
end

function M.build()
  local skip = { "docs" }
  for file, t in vim.fs.dir("lua/snacks", { depth = 1 }) do
    local name = vim.fn.fnamemodify(file, ":t:r")
    if t == "file" and not vim.tbl_contains(skip, name) then
      print(name .. ".md")
      local path = ("lua/snacks/%s"):format(file)
      local lines = vim.fn.readfile(path)
      local info = M.extract(lines)
      M.write(name, M.render(name, info))
      if name == "init" then
        local readme = table.concat(vim.fn.readfile("README.md"), "\n")
        local example = table.concat(vim.fn.readfile("docs/example.lua"), "\n")
        example = example:gsub(".*\nreturn {", "{", 1)
        readme = M.replace("config", readme, M.md(info.config))
        readme = M.replace("example", readme, M.md(example))
        vim.fn.writefile(vim.split(readme, "\n"), "README.md")
      end
    end
  end
  vim.cmd.checktime()
end

return M
