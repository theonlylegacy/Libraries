local Legacy = {
	Settings = {
		Name = true,
		Tool = true,
		Flag = true,

		Health = {
			Text = true,
			Bar = true,
		},

		Tracer = {
			Enabled = true,
			AttachSquare = true,
		},

		Square = {
			Enabled = true,
			Fill = true,
		},

		Color = Color3.fromRGB(255, 255, 255),
		FlagColor = Color3.fromRGB(255, 55, 55),
		OutlineColor = Color3.fromRGB(0, 0, 0),
		FillColor = Color3.fromRGB(255, 55, 55),
		HealthColor = Color3.fromRGB(25, 255, 25),
	},

	Characters = {},
}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Client = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local spawn = task.spawn
local defer = task.defer
local cancel = task.cancel
local wait = task.wait

local _WorldToViewportPoint = Camera.WorldToViewportPoint
local WorldToViewportPoint = function(...)
	return _WorldToViewportPoint(Camera, ...)
end

local CFrame_new = CFrame.new
local Vector2_new = Vector2.new
local Viewport = Camera.ViewportSize
local floor = math.floor

function Legacy:HasESP(Character)
	if Character and Character.Name ~= nil and self.Characters[Character.Name] then
		return true
	end

	return false
end

function Legacy:GetBoundingVectors(Root) --//Not mine
	local RootCFrame, RootSize = Root.CFrame, Root.Size
	local SizeX, SizeY, SizeZ = RootSize.X, RootSize.Y, RootSize.Z

	return {
		
        RootCFrame * CFrame_new(SizeX, SizeY * 1.3, SizeZ),
		RootCFrame * CFrame_new(-SizeX, SizeY * 1.3, SizeZ),
		RootCFrame * CFrame_new(SizeX, SizeY * 1.3, -SizeZ),
		RootCFrame * CFrame_new(-SizeX, SizeY * 1.3, -SizeZ),
		RootCFrame * CFrame_new(SizeX, -SizeY * 1.6, SizeZ),
		RootCFrame * CFrame_new(-SizeX, -SizeY * 1.6, SizeZ),
		RootCFrame * CFrame_new(SizeX, -SizeY * 1.6, -SizeZ),
		RootCFrame * CFrame_new(-SizeX, -SizeY * 1.6, -SizeZ),
	}
end

function Legacy:AddCharacter(PlayerTable)
	if PlayerTable and PlayerTable._alive then
		local CharacterTable = PlayerTable._thirdPersonObject

		if self:HasESP(CharacterTable._character) then
			return
		end

		if CharacterTable._torso then
			self.Characters[CharacterTable._character.Name] = {
				Name = CharacterTable._character.Name,
				DisplayName = CharacterTable._player.Name,
				Flag = "",
				PlayerTable = PlayerTable,
				CharacterTable = CharacterTable,

				Strings = {
					["Name"] = Drawing.new("Text"),
					["Tool"] = Drawing.new("Text"),
					["Health"] = Drawing.new("Text"),
					["Flag"] = Drawing.new("Text"),
				},

				Lines = {
					["Tracer"] = Drawing.new("Line"),
					["TracerOutline"] = Drawing.new("Line"),
					["Health"] = Drawing.new("Line"),
					["HealthOutline"] = Drawing.new("Line"),
				},

				Squares = {
					["Square"] = Drawing.new("Square"),
					["SquareOutline"] = Drawing.new("Square"),
					["SquareFill"] = Drawing.new("Square"),
				},
			}

			return self.Characters[CharacterTable._character.Name]
		end
	end
end

function Legacy:RemoveCharacter(PTable)
	for _, Table in self.Characters do
		if type(Table) == "table" and Table == PTable then
			if Table.Strings then
				for _, Drawing in Table.Strings do
					Drawing:Remove()
				end
			end

			if Table.Lines then
				for _, Drawing in Table.Lines do
					Drawing:Remove()
				end
			end

			if Table.Squares then
				for _, Drawing in Table.Squares do
					Drawing:Remove()
				end
			end

			self.Characters[Table.Name] = nil
		end
	end
end

function Legacy:UpdateCharacters(PTable)
	local PlayerTable = PTable.PlayerTable
	local CharacterTable = PTable.CharacterTable

	if PlayerTable and CharacterTable then
		local Strings = PTable.Strings
		local Lines = PTable.Lines
		local Squares = PTable.Squares

		if PlayerTable._alive == true and CharacterTable._character then
			local Health = PlayerTable:getHealth()
			local Tool = CharacterTable._weaponname
			local Root = CharacterTable._torso

			if Root then
				local RootPosition = Root.Position
				local CameraPosition = Camera.CFrame.Position
				local DistanceFromCamera = (RootPosition - CameraPosition).Magnitude

				local OnScreenPosition, VisibleOnScreen = WorldToViewportPoint(RootPosition)
				local Dimensions = self:GetBoundingVectors(Root)

				local Size = math.clamp(8 + (200 / DistanceFromCamera), 11, 14)
				local TextBounds = 0
				local YMinimal = Viewport.X
				local YMaximal = 0
				local XMinimal = Viewport.X
				local XMaximal = 0

				for _, Preset in Dimensions do
					local PresetPosition = WorldToViewportPoint(Preset.Position)

					if PresetPosition.X < XMinimal then
						XMinimal = PresetPosition.X
					end
					if PresetPosition.X > XMaximal then
						XMaximal = PresetPosition.X
					end
					if PresetPosition.Y < YMinimal then
						YMinimal = PresetPosition.Y
					end
					if PresetPosition.Y > YMaximal then
						YMaximal = PresetPosition.Y
					end
				end

				local SquareSize = (Vector2_new(floor(XMinimal - XMaximal), floor(YMinimal - YMaximal)))
				local SquarePosition = (Vector2_new(floor(XMaximal + SquareSize.X / XMinimal), floor(YMaximal + SquareSize.Y / YMinimal)))

				if self.Settings.Name and VisibleOnScreen then
					Strings["Name"].ZIndex = 4
					Strings["Name"].Text = "Name: " .. PTable.DisplayName
					Strings["Name"].Visible = true
					Strings["Name"].Outline = true
					Strings["Name"].Center = false
					Strings["Name"].Color = self.Settings.Color
					Strings["Name"].Size = Size
					Strings["Name"].Position = Vector2_new(SquarePosition.X + 4, SquarePosition.Y + SquareSize.Y - TextBounds)

					TextBounds = Strings["Name"].TextBounds.Y
				else
					Strings["Name"].Visible = false
				end

				if self.Settings.Tool and VisibleOnScreen then
					Strings["Tool"].ZIndex = 4
					Strings["Tool"].Text = `Tool: {tostring(Tool) ~= nil and Tool or "None"}`
					Strings["Tool"].Visible = true
					Strings["Tool"].Outline = true
					Strings["Tool"].Center = false
					Strings["Tool"].Color = self.Settings.Color
					Strings["Tool"].Size = Size
					Strings["Tool"].Position = Vector2_new(SquarePosition.X + 4, SquarePosition.Y + SquareSize.Y + TextBounds)

					TextBounds = TextBounds + Strings["Tool"].TextBounds.Y
				else
					Strings["Tool"].Visible = false
				end

				if self.Settings.Health.Text and VisibleOnScreen then
					Strings["Health"].ZIndex = 4
					Strings["Health"].Text = `Health: {floor(Health)}`
					Strings["Health"].Visible = true
					Strings["Health"].Outline = true
					Strings["Health"].Center = false
					Strings["Health"].Color = self.Settings.Color
					Strings["Health"].Size = Size
					Strings["Health"].Position = Vector2_new(SquarePosition.X + 4, SquarePosition.Y + SquareSize.Y + TextBounds)

					TextBounds = TextBounds + Strings["Health"].TextBounds.Y
				else
					Strings["Health"].Visible = false
				end

				if self.Settings.Flag and VisibleOnScreen then
					Strings["Flag"].ZIndex = 4
					Strings["Flag"].Text = `{PTable.Flag}`
					Strings["Flag"].Visible = true
					Strings["Flag"].Outline = true
					Strings["Flag"].Center = false
					Strings["Flag"].Color = self.Settings.FlagColor
					Strings["Flag"].Size = Size
					Strings["Flag"].Position = Vector2_new(SquarePosition.X + 4, SquarePosition.Y + SquareSize.Y + TextBounds)

					TextBounds = TextBounds + Strings["Flag"].TextBounds.Y
				else
					Strings["Flag"].Visible = false
				end

				if self.Settings.Health.Bar and VisibleOnScreen then
					local Length = (YMaximal - YMinimal) * (Health / 100)

					Lines["Health"].ZIndex = 3
					Lines["Health"].Visible = true
					Lines["Health"].Thickness = 1
					Lines["Health"].Color = self.Settings.HealthColor
					Lines["Health"].From = Vector2_new(XMinimal - 5, YMaximal)
					Lines["Health"].To = Vector2_new(XMinimal - 5, YMaximal - Length)

					Lines["HealthOutline"].ZIndex = 3
					Lines["HealthOutline"].Visible = true
					Lines["HealthOutline"].Thickness = 3
					Lines["HealthOutline"].Color = self.Settings.OutlineColor
					Lines["HealthOutline"].From = Vector2_new(XMinimal - 5, YMaximal)
					Lines["HealthOutline"].To = Vector2_new(XMinimal - 5, YMaximal - (YMaximal - YMinimal))
				else
					Lines["Health"].Visible = false
					Lines["HealthOutline"].Visible = false
				end

				if self.Settings.Tracer.Enabled and VisibleOnScreen then
					Lines["Tracer"].ZIndex = 3
					Lines["Tracer"].Visible = true
					Lines["Tracer"].Thickness = 1
					Lines["Tracer"].Color = self.Settings.Color
					Lines["Tracer"].From = Vector2_new(Viewport.X / 2, Viewport.Y / 1)

					Lines["TracerOutline"].ZIndex = 2
					Lines["TracerOutline"].Visible = true
					Lines["TracerOutline"].Thickness = 3
					Lines["TracerOutline"].Color = self.Settings.OutlineColor
					Lines["TracerOutline"].From = Vector2_new(Viewport.X / 2, Viewport.Y / 1)

					if self.Settings.Tracer.AttachSquare and self.Settings.Square.Enabled then
						Lines["Tracer"].To = Vector2_new(SquareSize.X / 2 + SquarePosition.X, YMaximal + 1)
						Lines["TracerOutline"].To = Vector2_new(SquareSize.X / 2 + SquarePosition.X, YMaximal + 1)
					else
						Lines["Tracer"].To = Vector2_new(OnScreenPosition.X, OnScreenPosition.Y)
						Lines["TracerOutline"].To = Vector2_new(OnScreenPosition.X, OnScreenPosition.Y)
					end
				else
					Lines["Tracer"].Visible = false
					Lines["TracerOutline"].Visible = false
				end

				if self.Settings.Square.Enabled and VisibleOnScreen then
					Squares["Square"].ZIndex = 3
					Squares["Square"].Visible = true
					Squares["Square"].Filled = false
					Squares["Square"].Color = self.Settings.Color
					Squares["Square"].Size = SquareSize
					Squares["Square"].Position = SquarePosition

					Squares["SquareOutline"].ZIndex = 2
					Squares["SquareOutline"].Thickness = 3
					Squares["SquareOutline"].Visible = true
					Squares["SquareOutline"].Filled = false
					Squares["SquareOutline"].Color = self.Settings.OutlineColor
					Squares["SquareOutline"].Size = SquareSize
					Squares["SquareOutline"].Position = SquarePosition
				else
					Squares["Square"].Visible = false
					Squares["SquareOutline"].Visible = false
				end

				if self.Settings.Square.Enabled and self.Settings.Square.Fill and VisibleOnScreen then
					Squares["SquareFill"].ZIndex = 1
					Squares["SquareFill"].Transparency = 0.5
					Squares["SquareFill"].Visible = true
					Squares["SquareFill"].Filled = true
					Squares["SquareFill"].Color = self.Settings.FillColor
					Squares["SquareFill"].Size = SquareSize
					Squares["SquareFill"].Position = SquarePosition
				else
					Squares["SquareFill"].Visible = false
				end
			else
				self:RemoveCharacter(PTable)
			end
		else
			self:RemoveCharacter(PTable)
		end
	else
		self:RemoveCharacter(PTable)
	end
end

spawn(function()
	while true do
		wait(0.03)
		Viewport = Camera.ViewportSize

		for _, Table in Legacy.Characters do
			Legacy:UpdateCharacters(Table)
		end
	end
end)

getgenv().Legacy = Legacy
return Legacy
