local Settings = {
    ToggleKey = Enum.KeyCode.Q,
    UnloadKey = Enum.KeyCode.End,
    Radius = 180,
    MaxDistance = 2000,
    SmoothSpeed = 14,
    TeamCheck = false,
    VisibilityCheck = true,
    Reacquire = true,
    TargetPart = "Head",
    ShowRadius = true,
    Debug = true
}

local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local player = Players.LocalPlayer

if not player then
    error("AimLock requires a running Roblox client")
end

local environment = _G
if type(getgenv) == "function" then
    local ok, result = pcall(getgenv)
    if ok and type(result) == "table" then
        environment = result
    end
end

local registryKey = "__IDERR_AimLock_v1"
local previous = environment[registryKey]
if type(previous) == "table" and type(previous.Cleanup) == "function" then
    pcall(previous.Cleanup, previous)
end

local Runtime = {
    Settings = Settings,
    Enabled = false,
    Target = nil,
    Stopped = false,
    Connections = {},
    Gui = nil,
    LastError = nil
}

environment[registryKey] = Runtime

local function log(message)
    if Settings.Debug then
        print("[AimLock] " .. tostring(message))
    end
end

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(Runtime.Connections, connection)
    return connection
end

local function create(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    return object
end

local gui = create("ScreenGui", {
    Name = "IDERRAimLock",
    ResetOnSpawn = false,
    DisplayOrder = 100,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = player:WaitForChild("PlayerGui")
})

Runtime.Gui = gui

local panel = create("Frame", {
    Name = "Panel",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 18),
    Size = UDim2.fromOffset(340, 92),
    BackgroundColor3 = Color3.fromRGB(13, 19, 30),
    BorderSizePixel = 0,
    Parent = gui
})

create("UICorner", {
    CornerRadius = UDim.new(0, 12),
    Parent = panel
})

create("UIStroke", {
    Color = Color3.fromRGB(47, 63, 82),
    Thickness = 1,
    Parent = panel
})

local title = create("TextLabel", {
    Name = "Title",
    Position = UDim2.fromOffset(15, 10),
    Size = UDim2.new(1, -30, 0, 15),
    BackgroundTransparency = 1,
    Text = "AIMLOCK  /  CAMERA TARGETING",
    TextColor3 = Color3.fromRGB(139, 158, 183),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = panel
})

local status = create("TextLabel", {
    Name = "Status",
    Position = UDim2.fromOffset(15, 27),
    Size = UDim2.new(1, -130, 0, 27),
    BackgroundTransparency = 1,
    Text = "NOT ACTIVE",
    TextColor3 = Color3.fromRGB(255, 145, 157),
    Font = Enum.Font.GothamBold,
    TextSize = 20,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = panel
})

local targetLabel = create("TextLabel", {
    Name = "Target",
    Position = UDim2.fromOffset(15, 57),
    Size = UDim2.new(1, -130, 0, 18),
    BackgroundTransparency = 1,
    Text = "Target: none",
    TextColor3 = Color3.fromRGB(220, 230, 242),
    Font = Enum.Font.Gotham,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    Parent = panel
})

local toggleButton = create("TextButton", {
    Name = "Toggle",
    Position = UDim2.new(1, -113, 0, 31),
    Size = UDim2.fromOffset(98, 42),
    BackgroundColor3 = Color3.fromRGB(29, 44, 58),
    BorderSizePixel = 0,
    Text = "ENABLE\n[Q]",
    TextColor3 = Color3.fromRGB(87, 226, 195),
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = panel
})

create("UICorner", {
    CornerRadius = UDim.new(0, 8),
    Parent = toggleButton
})

local radiusRing = create("Frame", {
    Name = "Radius",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(Settings.Radius * 2, Settings.Radius * 2),
    BackgroundTransparency = 1,
    Visible = Settings.ShowRadius,
    Parent = gui
})

create("UICorner", {
    CornerRadius = UDim.new(1, 0),
    Parent = radiusRing
})

create("UIStroke", {
    Color = Color3.fromRGB(87, 226, 195),
    Transparency = 0.35,
    Thickness = 1,
    Parent = radiusRing
})

local function cursorPosition(camera)
    if not Input.MouseEnabled or Input.MouseBehavior == Enum.MouseBehavior.LockCenter then
        return camera.ViewportSize / 2
    end
    local inset = GuiService:GetGuiInset()
    return Input:GetMouseLocation() - inset
end

local function characterTarget(candidate)
    if candidate == player then
        return nil
    end
    if Settings.TeamCheck and not player.Neutral and not candidate.Neutral and player.Team == candidate.Team then
        return nil
    end
    local character = candidate.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local part = character and character:FindFirstChild(Settings.TargetPart)
    if not character or not character:IsDescendantOf(workspace) then
        return nil
    end
    if not humanoid or humanoid.Health <= 0 or not part or not part:IsA("BasePart") then
        return nil
    end
    return character, humanoid, part
end

local function visible(camera, character, part)
    if not Settings.VisibilityCheck then
        return true
    end
    local origin = camera.CFrame.Position
    local offset = part.Position - origin
    if offset.Magnitude <= 0.001 then
        return true
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, offset, params)
    return result == nil or result.Instance:IsDescendantOf(character)
end

function Runtime:SelectTarget()
    local camera = workspace.CurrentCamera
    if not camera then
        return nil
    end
    local cursor = cursorPosition(camera)
    local cameraPosition = camera.CFrame.Position
    local selected = nil
    local selectedDistance = Settings.Radius
    for _, candidate in ipairs(Players:GetPlayers()) do
        local character, humanoid, part = characterTarget(candidate)
        if character and humanoid and part then
            local worldDistance = (part.Position - cameraPosition).Magnitude
            if worldDistance <= Settings.MaxDistance then
                local point, onScreen = camera:WorldToViewportPoint(part.Position)
                if onScreen and point.Z > 0 then
                    local screenDistance = (Vector2.new(point.X, point.Y) - cursor).Magnitude
                    if screenDistance <= selectedDistance and visible(camera, character, part) then
                        selected = {
                            Player = candidate,
                            Character = character,
                            Humanoid = humanoid,
                            Part = part
                        }
                        selectedDistance = screenDistance
                    end
                end
            end
        end
    end
    return selected
end

local function targetValid(target)
    if not target or not target.Player or target.Player.Parent ~= Players then
        return false
    end
    local character, humanoid, part = characterTarget(target.Player)
    if character ~= target.Character or humanoid ~= target.Humanoid or part ~= target.Part then
        return false
    end
    if (part.Position - workspace.CurrentCamera.CFrame.Position).Magnitude > Settings.MaxDistance then
        return false
    end
    return visible(workspace.CurrentCamera, character, part)
end

local function updateStatus()
    if Runtime.LastError then
        status.Text = "ERROR"
        status.TextColor3 = Color3.fromRGB(255, 145, 157)
        targetLabel.Text = "Targeting stopped: " .. tostring(Runtime.LastError)
        toggleButton.Text = "RETRY\n[Q]"
        return
    end
    if Runtime.Enabled then
        status.Text = "ACTIVE"
        status.TextColor3 = Color3.fromRGB(87, 226, 195)
        toggleButton.Text = "DISABLE\n[Q]"
        targetLabel.Text = Runtime.Target and "Target: " .. Runtime.Target.Player.Name or "Target: searching"
    else
        status.Text = "NOT ACTIVE"
        status.TextColor3 = Color3.fromRGB(255, 145, 157)
        toggleButton.Text = "ENABLE\n[Q]"
        targetLabel.Text = "Target: none"
    end
end

function Runtime:SetEnabled(value)
    if self.Stopped then
        return
    end
    self.LastError = nil
    self.Enabled = value == true
    self.Target = self.Enabled and self:SelectTarget() or nil
    updateStatus()
    log(self.Enabled and "Enabled" or "Disabled")
end

local bindingName = "IDERR_AimLock_Camera"
RunService:UnbindFromRenderStep(bindingName)
RunService:BindToRenderStep(bindingName, Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
    if Runtime.Stopped or not Runtime.Enabled then
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then
        return
    end
    if not targetValid(Runtime.Target) then
        Runtime.Target = Settings.Reacquire and Runtime:SelectTarget() or nil
    end
    local target = Runtime.Target
    if not target then
        updateStatus()
        return
    end
    local origin = camera.CFrame.Position
    local destination = target.Part.Position
    if (destination - origin).Magnitude <= 0.001 then
        return
    end
    local desired = CFrame.lookAt(origin, destination)
    local alpha = 1 - math.exp(-Settings.SmoothSpeed * math.max(deltaTime, 0))
    camera.CFrame = camera.CFrame:Lerp(desired, math.clamp(alpha, 0, 1))
    updateStatus()
end)

connect(RunService.RenderStepped, function()
    if Runtime.Stopped then
        return
    end
    local camera = workspace.CurrentCamera
    if camera then
        local cursor = cursorPosition(camera)
        radiusRing.Position = UDim2.fromOffset(cursor.X, cursor.Y)
        radiusRing.Visible = Settings.ShowRadius
    end
end)

local function toggle()
    local ok, errorMessage = pcall(function()
        Runtime:SetEnabled(not Runtime.Enabled)
    end)
    if not ok then
        Runtime.Enabled = false
        Runtime.Target = nil
        Runtime.LastError = errorMessage
        updateStatus()
        warn("[AimLock] " .. tostring(errorMessage))
    end
end

connect(toggleButton.Activated, toggle)

connect(Input.InputBegan, function(input, processed)
    if Input:GetFocusedTextBox() then
        return
    end
    if input.KeyCode == Settings.UnloadKey then
        Runtime:Cleanup()
        return
    end
    if not processed and input.KeyCode == Settings.ToggleKey then
        toggle()
    end
end)

function Runtime:Cleanup()
    if self.Stopped then
        return
    end
    self.Stopped = true
    self.Enabled = false
    self.Target = nil
    RunService:UnbindFromRenderStep(bindingName)
    for _, connection in ipairs(self.Connections) do
        connection:Disconnect()
    end
    table.clear(self.Connections)
    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
    if environment[registryKey] == self then
        environment[registryKey] = nil
    end
    log("Unloaded")
end

updateStatus()
log("Loaded. Press Q or use the button to toggle.")

return Runtime
