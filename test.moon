export moon = require "moon"
SSv2 = require "init"

file = io.open("testin.ssv2", "r")
str = file\read("*a")
file\close!
obj = SSv2.deserialize(str)
file = io.open("testout.mini.ssv2", "w")
output = SSv2.serialize(obj, true)
file\write(output)
file\close!
file = io.open("testout.ssv2", "w")
file\write(SSv2.serialize(SSv2.deserialize(output)))
file\close!
