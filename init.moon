--This is the first attempt at implementing SSv2.
SSv2 = {
	VERSION: "2.0.0"
}

split = (str, separator) ->
	sections = {}
	pattern = string.format("([^%s]+)", separator)
	str\gsub(pattern, (c) -> table.insert(sections, c))
	sections

starts = (str, start) -> str\sub(1, start\len!) == start

trim = (str) -> (str\gsub("^%s*(.-)%s*$", "%1"))

evaluateValue = (str, line) ->
	n = tonumber(str)
	return n unless n == nil
	return true if str == "true" or str == "yes" or str == "y"
	return false if str == "false" or str == "no" or str == "n"
	return if str == "null" or str == "nil"
	if starts(str, "'")
		str = str\sub(2, str\len! - 1)
		error("character is not one character: line #{line}") if str\len! ~= 1
	elseif starts(str, "\"")
		str = str\sub(2, str\len! - 1)
	str

serializeValue = (value) -> tostring(value)

getIndentation = (line) ->
	i = 0
	while starts(line, "\t")
		i += 1
		line = line\sub(2)
	i

deserialize = (lines, index) ->
	return {} if #lines == 0
	first = lines[index]
	indentation = getIndentation(first)
	obj = {}
	lastKey = nil
	indexCount = 1
	i = index
	while i <= #lines
		line = lines[i]
		ind = getIndentation(line)

		comment = line\match(".*()//")
		if comment
			line = line\sub(1, comment - 1)
		line = trim(line)
		if line\len! == 0
			i += 1
			continue

		if ind < indentation
			return obj, i
		elseif ind > indentation
			o, jump = deserialize(lines, i)
			i = jump
			if lastKey == nil
				obj[indexCount] = o
				indexCount += 1
			else
				obj[lastKey] = o
				lastKey = nil
			continue
		else
			if starts(line, "-")
				line = trim(line\sub(2))
				lastKey = nil
				lastKey = indexCount if line\len! == 0
				obj[indexCount] = line
				indexCount += 1
			else
				sections = split(line, ":")
				key = evaluateValue(trim(table.remove(sections, 1), i))
				value = evaluateValue(trim(table.concat(sections, ":")), i)
				lastKey = key
				obj[key] = value
		i += 1
	obj, #lines + 1

local serialize

printTable = (obj, keys, indentation, mini, tables={}, ignoreRecursion, ignoreMetaValues) ->
	outStr = ""
	numeric = 1
	total = 0
	for k in *keys
		continue if ignoreMetaValues and starts(k, "__")
		v = obj[k]
		if type(k) == "number"
			if k == numeric
				numeric += 1
				k = nil
		if type(v) == "table"
			if table.contains(tables, v)
				if ignoreRecursion
					table.insert(tables, v)
					continue
				error("recursion in serialization")
			else
				table.insert(tables, v)
			-- Table is copied so if a table is referenced elsewhere in the structure (but not a child), it can still be printed out.
			str, t = serialize(v, indentation + 1, mini, table.copy(tables, false), false, ignoreRecursion, ignoreMetaValues)
			print(str, t)
			if str\len! == 0
				continue
			if t == 0 or str\len! == 0
				outStr ..= "{}"
			else
				outStr ..= "\n#{str}"
		elseif type(v) == "function"
			continue
		str = ""
		for i = 1, indentation do str ..= "\t"
		if k == nil
			str ..= "-"
			str ..= " " unless mini
		else
			str ..= "#{k}:"
			str ..= " " unless mini
		str ..= tostring(v)
		str = "\n" .. str if outStr\len! ~= 0
		outStr ..= str
		total += 1
	outStr, total

serialize = (obj, indentation, mini, tables, root=false, ignoreRecursion, ignoreMetaValues) ->
	outStr = ""
	numberKeys, stringKeys = {}, {}
	for k, _ in pairs obj
		if type(k) == "number"
			table.insert(numberKeys, k)
		else
			table.insert(stringKeys, k)
	table.sort(numberKeys)
	table.sort(stringKeys)
	outStr ..= printTable(obj, numberKeys, indentation, mini, tables, ignoreRecursion, ignoreMetaValues)
	outStr ..= "\n" unless outStr\len! == 0
	outStr ..= printTable(obj, stringKeys, indentation, mini, tables, ignoreRecursion, ignoreMetaValues)
	outStr ..= "\n" unless mini or not root
	outStr

SSv2.deserialize = (str) ->
	lines = split(str, "\n")
	(deserialize(lines, 1))

SSv2.serialize = (obj, mini=false, ignoreRecursion=false, ignoreMetaValues=true) ->
	serialize(obj, 0, mini, nil, true, ignoreRecursion, ignoreMetaValues)

SSv2
