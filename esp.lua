-- default services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")

-- default settings
local DefaultSettings = {
    Box = { Enabled = true, Color = Color3.fromRGB(128, 0, 0), Thickness = 1, Filled = false },
    Name = { Enabled = true, UseDisplayName = true, Color = Color3.new(1,1,1), Size = 14, Transparency = 1, ZIndex = 3 },
    Distance = { Enabled = true, Color = Color3.new(1,1,1), Size = 14, Transparency = 1, ZIndex = 3 },
    HealthBar = { Enabled = true, Width = 2 },
    Inventory = { Enabled = true, Mode = 2, Color = Color3.new(1,1,1), Size = 14, ZIndex = 3 },
    ExcludedItems = {
        ["Fist"] = true, ["Phone"] = true, ["Water"] = true, ["Knife"] = true,
        ["Machete"] = true, ["Gelatin"] = true, ["Bacon Egg and Cheese"] = true,
        ["SkiMask"] = true, ["Bandana"] = true, -- add other exclusions as needed
    },
}

local ESPLibrary = {}
ESPLibrary.__index = ESPLibrary

-- deep-merge helper
local function mergeSettings(defaults, custom)
    local merged = {}
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            merged[k] = mergeSettings(v, (custom and custom[k]) or {})
        else
            merged[k] = v
        end
    end
    if custom then
        for k,v in pairs(custom) do
            merged[k] = v
        end
    end
    return merged
end

-- drawing creation helpers
local function createText(settings)
    local txt = Drawing.new("Text")
    txt.Size = settings.Size
    txt.Center = true
    txt.Outline = true
    txt.Font = 3
    txt.Color = settings.Color
    txt.Transparency = settings.Transparency or 1
    txt.ZIndex = settings.ZIndex or 1
    txt.Visible = false
    return txt
end

local function createBox(settings)
    local sq = Drawing.new("Square")
    sq.Color = settings.Color
    sq.Thickness = settings.Thickness
    sq.Filled = settings.Filled
    sq.Visible = false
    return sq
end

local function createHealthBar(settings)
    local bar = Drawing.new("Line")
    bar.Thickness = settings.Width
    bar.Transparency = 1
    bar.Visible = false
    return bar
end

-- inventory helper
function ESPLibrary:GetInventory(player)
    local items = {}
    local backpack = player:FindFirstChildOfClass("Backpack")
    if backpack then
        for _, tool in ipairs(backpack:GetChildren()) do
            if tool:IsA("Tool") and not self.Settings.ExcludedItems[tool.Name] then
                table.insert(items, tool.Name)
            end
        end
    end
    if player.Character then
        for _, tool in ipairs(player.Character:GetChildren()) do
            if tool:IsA("Tool") and not self.Settings.ExcludedItems[tool.Name] then
                table.insert(items, tool.Name)
            end
        end
    end
    return items
end

-- create esp objects
function ESPLibrary:CreateESP(player)
    if player == Players.LocalPlayer then return end
    local espData = {
        Box = createBox(self.Settings.Box),
        Name = createText(self.Settings.Name),
        Distance = createText(self.Settings.Distance),
        HealthBar = createHealthBar(self.Settings.HealthBar),
        Inventory = createText(self.Settings.Inventory)
    }
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then
            for _, obj in pairs(espData) do obj:Remove() end
            self.ESPs[player] = nil
        end
    end)
    self.ESPs[player] = espData
end

-- render-loop update
function ESPLibrary:Start()
    for _, p in ipairs(Players:GetPlayers()) do self:CreateESP(p) end
    Players.PlayerAdded:Connect(function(p) self:CreateESP(p) end)

    RunService.RenderStepped:Connect(function()
        local closest, minDist = nil, math.huge
        local mousePos = UserInputService:GetMouseLocation()
        if self.Settings.Inventory.Mode == 2 then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local pos, onScreen = Camera:WorldToViewportPoint(p.Character.HumanoidRootPart.Position)
                    if onScreen then
                        local d = (mousePos - Vector2.new(pos.X, pos.Y)).Magnitude
                        if d < minDist then minDist, closest = d, p end
                    end
                end
            end
        end
        for player, esp in pairs(self.ESPs) do
            local char = player.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local head = char and char:FindFirstChild("Head")
            local hum = char and char:FindFirstChild("Humanoid")
            if hrp and head and hum and hum.Health > 0 then
                local top = head.Position + Vector3.new(0,1.5,0)
                local bottom = hrp.Position - Vector3.new(0,3,0)
                local topS, v1 = Camera:WorldToViewportPoint(top)
                local botS, v2 = Camera:WorldToViewportPoint(bottom)
                if v1 and v2 then
                    local h = math.abs(topS.Y - botS.Y)
                    local w = h / 1.8
                    local x, y = botS.X - w/2, topS.Y
                    esp.Box.Size = Vector2.new(w, h)
                    esp.Box.Position = Vector2.new(x, y)
                    esp.Box.Visible = self.Settings.Box.Enabled
                    esp.Name.Text = (self.Settings.Name.UseDisplayName and player.DisplayName or player.Name)
                    esp.Name.Position = Vector2.new(botS.X, y - 15)
                    esp.Name.Visible = self.Settings.Name.Enabled
                    local dist = math.floor((Camera.CFrame.Position - hrp.Position).Magnitude)
                    esp.Distance.Text = string.format("[%d]", dist)
                    esp.Distance.Position = Vector2.new(botS.X, y + h + 2)
                    esp.Distance.Visible = self.Settings.Distance.Enabled
                    local ratio = math.clamp(hum.Health/hum.MaxHealth, 0,1)
                    esp.HealthBar.From = Vector2.new(x-4, y+h)
                    esp.HealthBar.To = Vector2.new(x-4, y+h*(1-ratio))
                    esp.HealthBar.Color = Color3.fromRGB(0,0,0):Lerp(Color3.new(0,1,0), ratio)
                    esp.HealthBar.Visible = self.Settings.HealthBar.Enabled
                    local showInv = self.Settings.Inventory.Mode == 1 or (self.Settings.Inventory.Mode == 2 and player == closest)
                    if showInv then
                        local items = self:GetInventory(player)
                        if #items > 0 then
                            local lines = {}
                            for i=1,#items,3 do
                                table.insert(lines, table.concat({items[i], items[i+1], items[i+2]}, ", "))
                            end
                            esp.Inventory.Text = "["..table.concat(lines, "\n").."]"
                            esp.Inventory.Position = Vector2.new(x + w + 5, y)
                            esp.Inventory.Visible = true
                        else esp.Inventory.Visible = false end
                    else esp.Inventory.Visible = false end
                else
                    for _, obj in pairs(esp) do obj.Visible = false end
                end
            else for _, obj in pairs(esp) do obj.Visible = false end end
        end
    end)
end

-- constructor
function ESPLibrary.new(customSettings)
    local self = setmetatable({ ESPs = {}, Settings = mergeSettings(DefaultSettings, customSettings) }, ESPLibrary)
    return self
end

return ESPLibrary
