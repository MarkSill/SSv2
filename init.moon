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
				key = evaluateValue(trim(sections[1]), i)
				table.remove(sections, 1)
				value = evaluateValue(trim(table.concat(sections, ":")), i)
				lastKey = key
				obj[key] = value
		i += 1
	obj, #lines + 1

serialize = nil

printTable = (obj, keys, indentation, mini) ->
	outStr = ""
	numeric = 1
	for k in *keys
		v = obj[k]
		if type(k) == "number"
			if k == numeric
				numeric += 1
				k = nil
		if type(v) == "table"
			v = "\n" .. serialize(v, indentation + 1, mini)
		str = ""
		for i = 1, indentation do str ..= "\t"
		if k == nil
			str ..= "-"
			str ..= " " unless mini
		else
			str ..= "#{k}:"
			str ..= " " unless mini
		str ..= tostring(v)
		str = str
		str = "\n" .. str if outStr\len! ~= 0
		outStr ..= str
	outStr

serialize = (obj, indentation, mini, root=false) ->
	outStr = ""
	numberKeys, stringKeys = {}, {}
	for k, _ in pairs obj
		if type(k) == "number"
			table.insert(numberKeys, k)
		else
			table.insert(stringKeys, k)
	table.sort(numberKeys)
	table.sort(stringKeys)
	outStr ..= printTable(obj, numberKeys, indentation, mini)
	outStr ..= "\n" unless outStr\len! == 0
	outStr ..= printTable(obj, stringKeys, indentation, mini)
	outStr ..= "\n" unless mini or not root
	outStr

SSv2.deserialize = (str) ->
	lines = split(str, "\n")
	(deserialize(lines, 1))

SSv2.serialize = (obj, mini=false) ->
	serialize(obj, 0, mini, true)

SSv2
