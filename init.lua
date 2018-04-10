local SSv2 = {
  VERSION = "2.0.0"
}
local split
split = function(str, separator)
  local sections = { }
  local pattern = string.format("([^%s]+)", separator)
  str:gsub(pattern, function(c)
    return table.insert(sections, c)
  end)
  return sections
end
local starts
starts = function(str, start)
  return str:sub(1, start:len()) == start
end
local trim
trim = function(str)
  return (str:gsub("^%s*(.-)%s*$", "%1"))
end
local evaluateValue
evaluateValue = function(str, line)
  local n = tonumber(str)
  if not (n == nil) then
    return n
  end
  if str == "true" or str == "yes" or str == "y" then
    return true
  end
  if str == "false" or str == "no" or str == "n" then
    return false
  end
  if str == "null" or str == "nil" then
    return 
  end
  if starts(str, "'") then
    str = str:sub(2, str:len() - 1)
    if str:len() ~= 1 then
      error("character is not one character: line " .. tostring(line))
    end
  elseif starts(str, "\"") then
    str = str:sub(2, str:len() - 1)
  end
  return str
end
local serializeValue
serializeValue = function(value)
  return tostring(value)
end
local getIndentation
getIndentation = function(line)
  local i = 0
  while starts(line, "\t") do
    i = i + 1
    line = line:sub(2)
  end
  return i
end
local deserialize
deserialize = function(lines, index)
  if #lines == 0 then
    return { }
  end
  local first = lines[index]
  local indentation = getIndentation(first)
  local obj = { }
  local lastKey = nil
  local indexCount = 1
  local i = index
  while i <= #lines do
    local _continue_0 = false
    repeat
      local line = lines[i]
      local ind = getIndentation(line)
      local comment = line:match(".*()//")
      if comment then
        line = line:sub(1, comment - 1)
      end
      line = trim(line)
      if line:len() == 0 then
        i = i + 1
        _continue_0 = true
        break
      end
      if ind < indentation then
        return obj, i
      elseif ind > indentation then
        local o, jump = deserialize(lines, i)
        i = jump
        if lastKey == nil then
          obj[indexCount] = o
          indexCount = indexCount + 1
        else
          obj[lastKey] = o
          lastKey = nil
        end
        _continue_0 = true
        break
      else
        if starts(line, "-") then
          line = trim(line:sub(2))
          lastKey = nil
          if line:len() == 0 then
            lastKey = indexCount
          end
          obj[indexCount] = line
          indexCount = indexCount + 1
        else
          local sections = split(line, ":")
          local key = evaluateValue(trim(table.remove(sections, 1), i))
          local value = evaluateValue(trim(table.concat(sections, ":")), i)
          lastKey = key
          obj[key] = value
        end
      end
      i = i + 1
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return obj, #lines + 1
end
local serialize
local printTable
printTable = function(obj, keys, indentation, mini, tables, ignoreRecursion, ignoreMetaValues)
  if tables == nil then
    tables = { }
  end
  local outStr = ""
  local numeric = 1
  local total = 0
  for _index_0 = 1, #keys do
    local _continue_0 = false
    repeat
      local k = keys[_index_0]
      if ignoreMetaValues and starts(k, "__") then
        _continue_0 = true
        break
      end
      local v = obj[k]
      if type(k) == "number" then
        if k == numeric then
          numeric = numeric + 1
          k = nil
        end
      end
      if type(v) == "table" then
        if table.contains(tables, v) then
          if ignoreRecursion then
            table.insert(tables, v)
            _continue_0 = true
            break
          end
          error("recursion in serialization")
        else
          table.insert(tables, v)
        end
        local str, t = serialize(v, indentation + 1, mini, table.copy(tables, false)(false, ignoreRecursion, ignoreMetaValues))
        if t == 0 then
          outStr = outStr .. "{}"
        else
          outStr = outStr .. "\n" .. tostring(str)
        end
      elseif type(v) == "function" then
        _continue_0 = true
        break
      end
      local str = ""
      for i = 1, indentation do
        str = str .. "\t"
      end
      if k == nil then
        str = str .. "-"
        if not (mini) then
          str = str .. " "
        end
      else
        str = str .. tostring(k) .. ":"
        if not (mini) then
          str = str .. " "
        end
      end
      str = str .. tostring(v)
      str = str
      if outStr:len() ~= 0 then
        str = "\n" .. str
      end
      outStr = outStr .. str
      total = total + 1
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  return outStr, total
end
serialize = function(obj, indentation, mini, tables, root, ignoreRecursion, ignoreMetaValues)
  if root == nil then
    root = false
  end
  local outStr = ""
  local numberKeys, stringKeys = { }, { }
  for k, _ in pairs(obj) do
    if type(k) == "number" then
      table.insert(numberKeys, k)
    else
      table.insert(stringKeys, k)
    end
  end
  table.sort(numberKeys)
  table.sort(stringKeys)
  outStr = outStr .. printTable(obj, numberKeys, indentation, mini, tables, ignoreRecursion, ignoreMetaValues)
  if not (outStr:len() == 0) then
    outStr = outStr .. "\n"
  end
  outStr = outStr .. printTable(obj, stringKeys, indentation, mini, tables, ignoreRecursion, ignoreMetaValues)
  if not (mini or not root) then
    outStr = outStr .. "\n"
  end
  return outStr
end
SSv2.deserialize = function(str)
  local lines = split(str, "\n")
  return (deserialize(lines, 1))
end
SSv2.serialize = function(obj, mini, ignoreRecursion, ignoreMetaValues)
  if mini == nil then
    mini = false
  end
  if ignoreRecursion == nil then
    ignoreRecursion = false
  end
  if ignoreMetaValues == nil then
    ignoreMetaValues = true
  end
  return serialize(obj, 0, mini, nil, true, ignoreRecursion, ignoreMetaValues)
end
return SSv2
