# SSv2
SaveStuff v2 (SSv2) is a new version of my file format SaveStuff (https://github.com/MarkSill/savestuff).

SSv2 is a simple file format that combines YAML-like syntax with Lua's table structure, allowing for both arrays and hashes to coexist.

## Example File
Input file:
```ssv2
//Comments are made by using traditional C syntax (two slashes).
//They can be used at the end of any line. All text after the slashes is part of the comment.
//Comments are completely ignored by the parser, and as such will not be seen in the output file.
simpleval: 5.2 //This is a comment at the end of a line.
another_val: 5.2a
a_char: '@'
boolean: true
another_boolean: no
nullval: null
a_table:
	- first
	- second
	test: a test
	- third
	-
		- This is another table.
		with: Its own values
	3: How will this appear in output?
	6: How about this?

//Variables can also have wonky (by normal standards) names as a result of permissive naming. With newly introduced changes, keys can no longer start with numbers.
//Personally, I would recommend NOT using names similar to the following:
Does this work?: "hello"
32---- fgewg44 34t  fds/.?<?.,#@%)1473523: hello again
```

Output when loaded:
```ssv2
32---- fgewg44 34t  fds/.?<?.,#@%)1473523: hello again
Does this work?: hello
a_char: @
a_table: 
	- first
	- second
	- How will this appear in output?
	- 
		- This is another table.
		with: Its own values
	6: How about this?
	test: a test
another_boolean: false
another_val: 5.2a
boolean: true
simpleval: 5.2
```

## MoonScript Library
This repository includes a library that can be used with MoonScript to serialize and deserialize SSv2 files. It includes two public functions:

### SSv2.deserialize(str)
Loads a Lua table from the given string.

### SSv2.serialize(obj, mini=false)
Converts a Lua table to a string, optionally minifying the output.

### Lua
If you need to access the library from Lua, you can do so by compiling `init.moon` with `moonc init.moon`.
