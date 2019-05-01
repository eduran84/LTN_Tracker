local up = {i = 1}
local i = 2


local function foo()
  print(up.i)
  print(i)
end


foo()
up.i = 10
i = 20


foo()
