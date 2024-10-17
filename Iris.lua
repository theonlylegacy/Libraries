local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Module = game:GetObjects("rbxassetid://73794524403098")[1]
Module.Parent = ReplicatedStorage

local OldRequire = nil
OldRequire = hookfunction(require, function(Script)
    if Script.Name == "config" then
        local config = loadstring(Script.Source)()

        for i, v in config do
            if v.TextFont then
                config[i].TextFont = Font.fromEnum(Enum.Font.Arial)
            end
        end
        
        return config
    end

    return loadstring(Script.Source)()
end)

local Iris = require(Module).Init()

hookfunction(require, OldRequire)

return Iris
