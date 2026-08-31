
local Players = game:GetService("Players")
local Input = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local target = nil
local radius = 180
local debugging = true

local gui = Instance.new("ScreenGui")
gui.Name = "AimLockIndicator"
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.Parent = player:WaitForChild("PlayerGui")

local button = Instance.new("TextButton")
button.Size = UDim2.fromOffset(300, 48)
button.Position = UDim2.new(0.5, 0, 0, 20)
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
button.BorderSizePixel = 0
button.Font = Enum.Font.GothamBold
button.TextSize = 16
button.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = button

local function setStatus(message)
    button.Text = target
        and "AimLock: ACTIVE | Q"
        or "AimLock: NOT ACTIVE | Q"

    button.TextColor3 = target
        and Color3.fromRGB(100, 255, 150)
        or Color3.fromRGB(255, 120, 120)

    if debugging then
        print("[AimLock] " .. message)
    end
end

local function getHead(otherPlayer)
    local character = otherPlayer.Character
    if not character then return nil end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local head = character:FindFirstChild("Head")

    if humanoid and humanoid.Health > 0
        and head and head:IsA("BasePart")
        and head:IsDescendantOf(workspace) then
        return head
    end

    return nil
end

local function findTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local center = camera.ViewportSize / 2
    local closest = nil
    local bestDistance = radius

    for _, otherPlayer in ipairs(Players:GetPlayers()) do
        if otherPlayer == player then continue end

        local head = getHead(otherPlayer)
        if not head then continue end

        local point, visible =
            camera:WorldToViewportPoint(head.Position)

        if visible then
            local distance =
                (Vector2.new(point.X, point.Y) - center).Magnitude

            if distance < bestDistance then
                closest = otherPlayer
                bestDistance = distance
            end
        end
    end

    return closest
end

local function toggle()
    if target then
        target = nil
        setStatus("Disabled")
        return
    end

    target = findTarget()

    if target then
        setStatus("Locked onto " .. target.Name)
    else
        setStatus("No target found near the screen center")
    end
end

button.Activated:Connect(toggle)

Input.InputBegan:Connect(function(input, processed)
    if processed or Input:GetFocusedTextBox() then return end

    if input.KeyCode == Enum.KeyCode.Q then
        toggle()
    end
end)

player.CharacterRemoving:Connect(function()
    target = nil
    setStatus("Disabled on respawn")
end)

RunService:BindToRenderStep(
    "CameraAimLock",
    Enum.RenderPriority.Camera.Value + 1,
    function()
        if not target then return end

        local head = target.Parent == Players and getHead(target)

        if not head then
            target = nil
            setStatus("Target lost")
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then return end

        local origin = camera.CFrame.Position

        if (head.Position - origin).Magnitude > 0.001 then
            camera.CFrame = CFrame.lookAt(origin, head.Position)
        end
    end
)

setStatus("Ready. Press Q or click the indicator")
