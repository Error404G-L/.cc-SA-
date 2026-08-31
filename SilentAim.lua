local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

if playerGui:FindFirstChild("SilentAimPrototype") then
    warn("[SilentAim] Already running. Rejoin before testing again.")
    return
end

local settings = {
    Radius = 180,
    TeamCheck = true,
    Debug = true
}

local enabled = false
local target = nil
local localOrigin = nil
local cameraOrigin = nil
local redirected = 0

local gui = Instance.new("ScreenGui")
gui.Name = "SilentAimPrototype"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = playerGui

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(340, 64)
button.Position = UDim2.new(0.5, 0, 0, 20)
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextSize = 15
button.TextWrapped = true
button.TextColor3 = Color3.fromRGB(255, 120, 120)
button.Text = "Silent Aim: NOT ACTIVE"
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local function log(message)
    if settings.Debug then
        print("[SilentAim] " .. message)
    end
end

local required = {
    {"hookmetamethod", hookmetamethod},
    {"getnamecallmethod", getnamecallmethod},
    {"checkcaller", checkcaller},
    {"newcclosure", newcclosure}
}

local missing = {}

for _, entry in ipairs(required) do
    if type(entry[2]) ~= "function" then
        table.insert(missing, entry[1])
    end
end

if #missing > 0 then
    button.Text = "Silent Aim: UNSUPPORTED\nCheck console"
    warn("[SilentAim] Missing: " .. table.concat(missing, ", "))
    return
end

local function updateStatus()
    button.TextColor3 = enabled
        and Color3.fromRGB(100, 255, 150)
        or Color3.fromRGB(255, 120, 120)

    if not enabled then
        button.Text = "Silent Aim: NOT ACTIVE\nQ or click to enable"
    elseif target and target.Parent then
        button.Text = "Silent Aim: ACTIVE\nTarget: " .. target.Parent.Name
    else
        button.Text = "Silent Aim: ACTIVE\nNo target in range"
    end
end

local function findTarget()
    local camera = workspace.CurrentCamera
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local health = character and character:FindFirstChildOfClass("Humanoid")

    cameraOrigin = camera and camera.CFrame.Position
    localOrigin = root and root.Position

    if not camera or not health or health.Health <= 0 then
        return nil
    end

    local closest = nil
    local bestDistance = settings.Radius
    local center = camera.ViewportSize / 2

    for _, other in ipairs(Players:GetPlayers()) do
        if other == player then continue end

        if settings.TeamCheck
            and not player.Neutral
            and not other.Neutral
            and player.Team == other.Team then
            continue
        end

        local model = other.Character
        local head = model and model:FindFirstChild("Head")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")

        if not head or not head:IsA("BasePart")
            or not humanoid or humanoid.Health <= 0 then
            continue
        end

        local point, visible = camera:WorldToViewportPoint(head.Position)

        if visible then
            local distance =
                (Vector2.new(point.X, point.Y) - center).Magnitude

            if distance < bestDistance then
                closest = head
                bestDistance = distance
            end
        end
    end

    return closest
end

local original

local success, result = pcall(function()
    return hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
        local method = getnamecallmethod()

        if enabled
            and self == workspace
            and method == "Raycast"
            and not checkcaller() then

            local arguments = table.pack(...)
            local origin = arguments[1]
            local direction = arguments[2]
            local head = target

            if head and head.Parent
                and typeof(origin) == "Vector3"
                and typeof(direction) == "Vector3" then

                local nearby =
                    (localOrigin and (origin - localOrigin).Magnitude <= 25)
                    or (cameraOrigin and (origin - cameraOrigin).Magnitude <= 25)

                local offset = head.Position - origin
                local length = direction.Magnitude

                if nearby and length > 1 and offset.Magnitude > 0.001 then
                    arguments[2] = offset.Unit * length
                    redirected += 1
                    return original(self, table.unpack(arguments, 1, arguments.n))
                end
            end
        end

        return original(self, ...)
    end))
end)

if not success or type(result) ~= "function" then
    button.Text = "Silent Aim: ERROR\nCheck console"
    warn("[SilentAim] Hook installation failed: " .. tostring(result))
    return
end

original = result

local function toggle()
    enabled = not enabled
    target = enabled and findTarget() or nil
    updateStatus()
    log(enabled and "Enabled" or "Disabled")
end

button.Activated:Connect(toggle)

Input.InputBegan:Connect(function(input, processed)
    if processed or Input:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.Q then
        toggle()
    end
end)

local elapsed = 0
local debugElapsed = 0
local lastCount = 0

RunService.Heartbeat:Connect(function(dt)
    elapsed += dt
    debugElapsed += dt

    if elapsed >= 0.1 then
        elapsed = 0
        target = enabled and findTarget() or nil
        updateStatus()
    end

    if debugElapsed >= 5 then
        debugElapsed = 0

        if enabled then
            log("Raycasts redirected in last interval: " .. (redirected - lastCount))
        end

        lastCount = redirected
    end
end)

updateStatus()
log("Loaded. Press Q or click the indicator.")
