local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = game:GetObjects("rbxassetid://73794524403098")[1]
Module.Parent = ReplicatedStorage

local OldRequire = nil
OldRequire = hookfunction(require, function(Script)
    return loadstring(Script.Source)()
end)

local Iris = require(Module).Init()

hookfunction(require, OldRequire)

return Iris
