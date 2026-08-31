if not game:IsLoaded() then
    game.Loaded:Wait()
end

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,

    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",

    TeamCheck = false,
    VisibleCheck = false,
    TargetPart = "HumanoidRootPart",
    SilentAimMethod = "Raycast",

    FOVRadius = 130,
    FOVVisible = false,
    ShowSilentAimTarget = false,

    MouseHitPrediction = false,
    MouseHitPredictionAmount = 0.165,
    HitChance = 100
}

getgenv().SilentAimSettings = SilentAimSettings
local Options, Toggles
local MainFileName = "UniversalSilentAim"
local SelectedFile, FileToSave = "", ""

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local GetChildren = game.GetChildren
local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local WorldToViewportPoint = Camera.WorldToViewportPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local RenderStepped = RunService.RenderStepped
local GuiInset = GuiService.GetGuiInset
local GetMouseLocation = UserInputService.GetMouseLocation

local resume = coroutine.resume
local create = coroutine.create

local ValidTargetParts = {"Head", "HumanoidRootPart"}
local PredictionAmount = 0.165

local mouse_box = Drawing.new("Square")
mouse_box.Visible = false
mouse_box.ZIndex = 999
mouse_box.Color = Color3.fromRGB(54, 57, 241)
mouse_box.Thickness = 20
mouse_box.Size = Vector2.new(20, 20)
mouse_box.Filled = true

local fov_circle = Drawing.new("Circle")
fov_circle.Thickness = 1
fov_circle.NumSides = 100
fov_circle.Radius = 180
fov_circle.Filled = false
fov_circle.Visible = false
fov_circle.ZIndex = 999
fov_circle.Transparency = 1
fov_circle.Color = Color3.fromRGB(54, 57, 241)

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean", "boolean"
        }
    },
    FindPartOnRayWithWhitelist = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Ray", "table", "boolean"
        }
    },
    FindPartOnRay = {
        ArgCountRequired = 2,
        Args = {
            "Instance", "Ray", "Instance", "boolean", "boolean"
        }
    },
    Raycast = {
        ArgCountRequired = 3,
        Args = {
            "Instance", "Vector3", "Vector3", "RaycastParams"
        }
    }
}

function CalculateChance(Percentage)

    Percentage = math.floor(Percentage)

    local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100

    return chance <= Percentage / 100
end

 do
    if not isfolder(MainFileName) then
        makefolder(MainFileName);
    end

    if not isfolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId))) then
        makefolder(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
    end
end

local Files = listfiles(string.format("%s/%s", "UniversalSilentAim", tostring(game.PlaceId)))

local function GetFiles()
    Files = listfiles(string.format("%s/%s", MainFileName, tostring(game.PlaceId)))
	local out = {}
	for i = 1, #Files do
		local file = Files[i]
		if file:sub(-4) == '.lua' then

			local pos = file:find('.lua', 1, true)
			local start = pos

			local char = file:sub(pos, pos)
			while char ~= '/' and char ~= '\\' and char ~= '' do
				pos = pos - 1
				char = file:sub(pos, pos)
			end

			if char == '/' or char == '\\' then
				table.insert(out, file:sub(pos + 1, start - 1))
			end
		end
	end

	return out
end

local function UpdateFile(FileName)
    assert(type(FileName) == "string" and #FileName > 0 and #FileName <= 48 and FileName:match("^[%w _%-]+$"), "Use 1-48 letters, numbers, spaces, hyphens or underscores.");
    writefile(string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName), HttpService:JSONEncode(SilentAimSettings))
end

local function LoadFile(FileName)
    assert(type(FileName) == "string" and #FileName > 0 and #FileName <= 48 and FileName:match("^[%w _%-]+$"), "Use 1-48 letters, numbers, spaces, hyphens or underscores.");

    local File = string.format("%s/%s/%s.lua", MainFileName, tostring(game.PlaceId), FileName)
    local ConfigData = HttpService:JSONDecode(readfile(File))
    for Index, Value in next, ConfigData do
        SilentAimSettings[Index] = Value
    end
end

local function getPositionOnScreen(Vector)
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
    local Matches = 0
    if #Args < RayMethod.ArgCountRequired then
        return false
    end
    for Pos, Argument in next, Args do
        if typeof(Argument) == RayMethod.Args[Pos] then
            Matches = Matches + 1
        end
    end
    return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
end

local function getMousePosition()
    return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player)
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character

    if not (PlayerCharacter or LocalPlayerCharacter) then return end

    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")

    if not PlayerRoot then return end

    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)

    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end

local function getClosestPlayer()
    if not Options.TargetPart.Value then return end
    local Closest
    local DistanceToMouse
    for _, Player in next, GetPlayers(Players) do
        if Player == LocalPlayer then continue end
        if Toggles.TeamCheck.Value and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end

        if Toggles.VisibleCheck.Value and not IsPlayerVisible(Player) then continue end

        local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
        local Humanoid = FindFirstChild(Character, "Humanoid")
        if not HumanoidRootPart or not Humanoid or Humanoid and Humanoid.Health <= 0 then continue end

        local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
        if not OnScreen then continue end

        local Distance = (getMousePosition() - ScreenPosition).Magnitude
        if Distance <= (DistanceToMouse or Options.Radius.Value or 2000) then
            Closest = ((Options.TargetPart.Value == "Random" and Character[ValidTargetParts[math.random(1, #ValidTargetParts)]]) or Character[Options.TargetPart.Value])
            DistanceToMouse = Distance
        end
    end
    return Closest
end

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/Library.lua"))()
Options = getgenv().Options
Toggles = getgenv().Toggles

Library.MainColor = Color3.fromRGB(20, 27, 40)
Library.BackgroundColor = Color3.fromRGB(12, 18, 29)
Library.OutlineColor = Color3.fromRGB(47, 63, 82)
Library.AccentColor = Color3.fromRGB(78, 222, 192)
Library.AccentColorDark = Library:GetDarkerColor(Library.AccentColor)
Library.FontColor = Color3.fromRGB(229, 237, 247)
Library.Font = Enum.Font.Gotham
Library.NotifyOnError = true
Library:UpdateColorsUsingRegistry()
Library:SetWatermark("Silent Aim | UI Edition")
Library:SetWatermarkVisibility(false)

local HooksReady = false
local HookError = nil
local ObserverError = nil
local Stopped = false
local StartedAt = os.clock()
local DebugEnabled = true
local TargetEvents = false
local Notifications = true
local LogLines = {}
local LogLabels = {}
local LastTargetName = ""
local LastWeaponName = ""
local LastObserverError = nil
local StatusLabel, ModeLabel, TargetLabel, WeaponLabel, HookLabel
local RefreshStatus

local function concise(value, limit)
    local text = tostring(value):gsub("[\r\n]", " ")
    return #text > limit and text:sub(1, limit - 3) .. "..." or text
end

local function renderLog()
    for index, label in ipairs(LogLabels) do
        label:SetText(LogLines[#LogLines - index + 1] or " ")
    end
end

local function logEvent(level, message)
    local entry = string.format("[%06.1f] %s | %s", os.clock() - StartedAt, level, concise(message, 140))
    table.insert(LogLines, entry)
    if #LogLines > 40 then
        table.remove(LogLines, 1)
    end
    renderLog()
    if DebugEnabled then
        if level == "ERROR" then
            warn("[SilentAim] " .. entry)
        else
            print("[SilentAim] " .. entry)
        end
    end
end

local function notify(message)
    if Notifications and not Stopped then
        Library:Notify(message, 3)
    end
end

local Viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
local Window = Library:CreateWindow({
    Title = "SILENT AIM  /  CONTROL CENTER",
    Center = true,
    AutoShow = true,
    Size = UDim2.fromOffset(math.clamp(Viewport.X - 40, 320, 680), math.clamp(Viewport.Y - 80, 360, 570)),
    TabPadding = 12,
    MenuFadeTime = 0.15
})

local ControlTab = Window:AddTab("Control")
local VisualTab = Window:AddTab("Visuals")
local ProfileTab = Window:AddTab("Profiles")
local DebugTab = Window:AddTab("Diagnostics")

local Main = ControlTab:AddLeftGroupbox("Targeting")
Main:AddToggle("aim_Enabled", {Text = "Enable silent aim", Default = false})
    :AddKeyPicker("aim_Enabled_KeyPicker", {
        Default = SilentAimSettings.ToggleKey,
        SyncToggleState = true,
        Mode = "Toggle",
        Text = "Silent aim",
        NoUI = false
    })

Toggles.aim_Enabled:OnChanged(function()
    if Stopped then
        Toggles.aim_Enabled.Value = false
        SilentAimSettings.Enabled = false
        return
    end
    if Toggles.aim_Enabled.Value and not HooksReady then
        Toggles.aim_Enabled:SetValue(false)
        logEvent("ERROR", HookError or "Hooks are not ready")
        return
    end
    SilentAimSettings.Enabled = Toggles.aim_Enabled.Value
    ObserverError = nil
    LastTargetName = ""
    mouse_box.Visible = false
    logEvent("STATE", SilentAimSettings.Enabled and "ACTIVE" or "NOT ACTIVE")
    notify(SilentAimSettings.Enabled and "Silent aim enabled" or "Silent aim disabled")
    if RefreshStatus then
        RefreshStatus()
    end
end)

Main:AddDropdown("Method", {
    Text = "Weapon method",
    Default = SilentAimSettings.SilentAimMethod,
    Values = {"Raycast", "FindPartOnRay", "FindPartOnRayWithWhitelist", "FindPartOnRayWithIgnoreList", "Mouse.Hit/Target"}
}):OnChanged(function()
    SilentAimSettings.SilentAimMethod = Options.Method.Value
    logEvent("METHOD", Options.Method.Value)
end)

Main:AddDropdown("TargetPart", {
    Text = "Target part",
    Default = SilentAimSettings.TargetPart,
    Values = {"Head", "HumanoidRootPart", "Random"}
}):OnChanged(function()
    SilentAimSettings.TargetPart = Options.TargetPart.Value
    logEvent("SETTING", "Target part: " .. tostring(Options.TargetPart.Value))
end)

Main:AddToggle("TeamCheck", {Text = "Ignore teammates", Default = SilentAimSettings.TeamCheck}):OnChanged(function()
    SilentAimSettings.TeamCheck = Toggles.TeamCheck.Value
    logEvent("SETTING", "Team check: " .. tostring(Toggles.TeamCheck.Value))
end)
Main:AddToggle("VisibleCheck", {Text = "Visibility check", Default = SilentAimSettings.VisibleCheck}):OnChanged(function()
    SilentAimSettings.VisibleCheck = Toggles.VisibleCheck.Value
    logEvent("SETTING", "Visibility check: " .. tostring(Toggles.VisibleCheck.Value))
end)
Main:AddSlider("HitChance", {
    Text = "Redirection chance",
    Default = SilentAimSettings.HitChance,
    Min = 0,
    Max = 100,
    Rounding = 0,
    Suffix = "%"
}):OnChanged(function()
    SilentAimSettings.HitChance = Options.HitChance.Value
end)

local Live = ControlTab:AddRightGroupbox("Live status")
StatusLabel = Live:AddLabel("Status: NOT ACTIVE")
ModeLabel = Live:AddLabel("Method: Raycast", true)
TargetLabel = Live:AddLabel("Target: none", true)
WeaponLabel = Live:AddLabel("Weapon: none detected", true)
HookLabel = Live:AddLabel("Hooks: preparing", true)
Live:AddDivider()
Live:AddLabel("ACTIVE means enabled. Target selection is not proof of a server-accepted hit.", true)
Live:AddLabel("Weapon detection is informational. Custom guns do not always use Roblox Tools.", true)

local Prediction = ControlTab:AddRightGroupbox("Mouse prediction")
Prediction:AddToggle("Prediction", {
    Text = "Enable Mouse.Hit prediction",
    Default = SilentAimSettings.MouseHitPrediction
}):OnChanged(function()
    SilentAimSettings.MouseHitPrediction = Toggles.Prediction.Value
end)
Prediction:AddSlider("Amount", {
    Text = "Prediction multiplier",
    Default = SilentAimSettings.MouseHitPredictionAmount,
    Min = 0.165,
    Max = 1,
    Rounding = 3
}):OnChanged(function()
    PredictionAmount = Options.Amount.Value
    SilentAimSettings.MouseHitPredictionAmount = Options.Amount.Value
end)
Prediction:AddLabel("Applies only to the original Mouse.Hit/Target method.", true)

local Fov = VisualTab:AddLeftGroupbox("Targeting radius")
Fov:AddToggle("Visible", {Text = "Show FOV circle", Default = SilentAimSettings.FOVVisible})
    :AddColorPicker("Color", {Default = Library.AccentColor})
Toggles.Visible:OnChanged(function()
    SilentAimSettings.FOVVisible = Toggles.Visible.Value
    fov_circle.Visible = Toggles.Visible.Value
end)
Fov:AddSlider("Radius", {
    Text = "Radius in pixels",
    Default = SilentAimSettings.FOVRadius,
    Min = 0,
    Max = 360,
    Rounding = 0
}):OnChanged(function()
    SilentAimSettings.FOVRadius = Options.Radius.Value
    fov_circle.Radius = Options.Radius.Value
end)

local Marker = VisualTab:AddLeftGroupbox("Target marker")
Marker:AddToggle("MousePosition", {
    Text = "Show selected target",
    Default = SilentAimSettings.ShowSilentAimTarget
}):AddColorPicker("MouseVisualizeColor", {Default = Library.AccentColor})
Toggles.MousePosition:OnChanged(function()
    SilentAimSettings.ShowSilentAimTarget = Toggles.MousePosition.Value
    mouse_box.Visible = false
end)

local Interface = VisualTab:AddRightGroupbox("Interface")
Interface:AddToggle("UI_StatusCard", {Text = "Show status card", Default = true})
Interface:AddToggle("UI_Notifications", {Text = "State notifications", Default = true}):OnChanged(function()
    Notifications = Toggles.UI_Notifications.Value
end)
Interface:AddLabel("Menu key"):AddKeyPicker("UI_MenuKey", {
    Default = "RightShift",
    NoUI = true,
    Text = "Show or hide menu"
})
Library.ToggleKeybind = Options.UI_MenuKey
Interface:AddLabel("Right Alt toggles targeting. Right Shift hides only the menu. End unloads this edition.", true)

local Credits = VisualTab:AddRightGroupbox("About this edition")
Credits:AddLabel("Original targeting: Averiias, Stefanuk12, xaxa.", true)
Credits:AddLabel("UI library: LinoriaLib. The original remote library dependency is retained.", true)
Credits:AddLabel("Run once in a fresh session. This edition does not remove hooks left by other scripts.", true)

local Profiles = ProfileTab:AddLeftGroupbox("Save profile")
Profiles:AddInput("CreateConfigTextBox", {
    Text = "Profile name",
    Default = "",
    Placeholder = "Example: test setup",
    Finished = true
}):OnChanged(function()
    FileToSave = Options.CreateConfigTextBox.Value
end)
Profiles:AddLabel("Use up to 48 letters, numbers, spaces, hyphens or underscores.", true)

local LoadProfiles = ProfileTab:AddRightGroupbox("Load profile")
LoadProfiles:AddDropdown("LoadConfigurationDropdown", {
    Text = "Saved profiles",
    AllowNull = true,
    Values = GetFiles()
})

Profiles:AddButton("Save current settings", function()
    local ok, err = pcall(UpdateFile, FileToSave)
    if not ok then
        logEvent("ERROR", err)
        notify("Could not save profile. See Diagnostics.")
        return
    end
    Options.LoadConfigurationDropdown:SetValues(GetFiles())
    logEvent("PROFILE", "Saved " .. FileToSave)
    notify("Profile saved")
end)

local function applyProfile()
    Toggles.aim_Enabled:SetValue(false)
    Toggles.TeamCheck:SetValue(SilentAimSettings.TeamCheck)
    Toggles.VisibleCheck:SetValue(SilentAimSettings.VisibleCheck)
    Options.TargetPart:SetValue(SilentAimSettings.TargetPart)
    Options.Method:SetValue(SilentAimSettings.SilentAimMethod)
    Toggles.Visible:SetValue(SilentAimSettings.FOVVisible)
    Options.Radius:SetValue(SilentAimSettings.FOVRadius)
    Toggles.MousePosition:SetValue(SilentAimSettings.ShowSilentAimTarget)
    Toggles.Prediction:SetValue(SilentAimSettings.MouseHitPrediction)
    Options.Amount:SetValue(SilentAimSettings.MouseHitPredictionAmount)
    Options.HitChance:SetValue(SilentAimSettings.HitChance)
end

LoadProfiles:AddButton("Load selected profile", function()
    local name = Options.LoadConfigurationDropdown.Value
    if not name then
        notify("Select a profile first")
        return
    end
    local ok, err = pcall(function()
        LoadFile(name)
        applyProfile()
    end)
    if ok then
        logEvent("PROFILE", "Loaded " .. name .. "; targeting remains disabled")
        notify("Profile loaded. Targeting remains disabled.")
    else
        logEvent("ERROR", err)
        notify("Could not load profile. See Diagnostics.")
    end
end)
LoadProfiles:AddButton("Refresh profiles", function()
    local ok, files = pcall(GetFiles)
    if ok then
        Options.LoadConfigurationDropdown:SetValues(files)
        logEvent("PROFILE", "Profile list refreshed")
    else
        logEvent("ERROR", files)
    end
end)
LoadProfiles:AddLabel("Profiles retain the original per-place storage location. Loading never automatically enables targeting.", true)

local DebugControls = DebugTab:AddLeftGroupbox("Logging")
DebugControls:AddToggle("UI_DebugConsole", {Text = "Print events to console", Default = true}):OnChanged(function()
    DebugEnabled = Toggles.UI_DebugConsole.Value
end)
DebugControls:AddToggle("UI_TargetEvents", {Text = "Log target changes", Default = false}):OnChanged(function()
    TargetEvents = Toggles.UI_TargetEvents.Value
end)
DebugControls:AddButton("Print diagnostic snapshot", function()
    print("[SilentAim] PlaceId:", game.PlaceId)
    print("[SilentAim] Enabled:", Toggles.aim_Enabled.Value)
    print("[SilentAim] Method:", Options.Method.Value)
    print("[SilentAim] Hooks installed:", HooksReady)
    print("[SilentAim] Last target:", LastTargetName)
    print("[SilentAim] Equipped tool:", LastWeaponName)
    for _, entry in ipairs({
        {"hookmetamethod", hookmetamethod},
        {"getnamecallmethod", getnamecallmethod},
        {"checkcaller", checkcaller},
        {"newcclosure", newcclosure}
    }) do
        print("[SilentAim]", entry[1], type(entry[2]))
    end
    logEvent("INFO", "Snapshot printed to console; it does not verify hits")
end)
DebugControls:AddButton("Clear event log", function()
    table.clear(LogLines)
    renderLog()
end)
DebugControls:AddLabel("The log records state and observed targets. It does not claim confirmed shots, damage or universal compatibility.", true)

local Events = DebugTab:AddRightGroupbox("Recent events")
for index = 1, 6 do
    LogLabels[index] = Events:AddLabel(" ", true)
end

local function create(className, properties)
    local object = Instance.new(className)
    for key, value in pairs(properties) do
        object[key] = value
    end
    return object
end

local HudGui = create("ScreenGui", {
    Name = "SilentAimStatusCard",
    ResetOnSpawn = false,
    DisplayOrder = 99,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    Parent = LocalPlayer:WaitForChild("PlayerGui")
})
local Card = create("Frame", {
    Name = "StatusCard",
    Size = UDim2.fromOffset(336, 146),
    Position = UDim2.new(0, 18, 1, -18),
    AnchorPoint = Vector2.new(0, 1),
    BackgroundColor3 = Color3.fromRGB(12, 18, 29),
    BorderSizePixel = 0,
    Parent = HudGui
})
create("UICorner", {CornerRadius = UDim.new(0, 12), Parent = Card})
create("UIStroke", {Color = Color3.fromRGB(47, 63, 82), Thickness = 1, Parent = Card})
local HudScale = create("UIScale", {Scale = 1, Parent = Card})

local function cardLabel(name, text, y, size, color)
    return create("TextLabel", {
        Name = name,
        Text = text,
        Position = UDim2.fromOffset(16, y),
        Size = UDim2.new(1, -32, 0, size + 5),
        BackgroundTransparency = 1,
        TextColor3 = color,
        Font = Enum.Font.Gotham,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = Card
    })
end

cardLabel("Eyebrow", "SILENT AIM  /  LIVE STATUS", 12, 10, Color3.fromRGB(139, 158, 183))
local CardStatus = cardLabel("Status", "NOT ACTIVE", 29, 23, Color3.fromRGB(255, 154, 163))
CardStatus.Font = Enum.Font.GothamBold
local CardTarget = cardLabel("Target", "No target selected", 62, 12, Color3.fromRGB(229, 237, 247))
local CardDetail = cardLabel("Method", "Raycast", 83, 11, Color3.fromRGB(139, 158, 183))
local CardToggle = create("TextButton", {
    Name = "Toggle",
    Text = "ENABLE",
    Position = UDim2.fromOffset(16, 111),
    Size = UDim2.fromOffset(145, 25),
    BackgroundColor3 = Color3.fromRGB(28, 48, 58),
    BorderSizePixel = 0,
    TextColor3 = Library.AccentColor,
    Font = Enum.Font.GothamBold,
    TextSize = 11,
    Parent = Card
})
create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = CardToggle})
local MenuButton = create("TextButton", {
    Name = "Menu",
    Text = "SHOW / HIDE MENU",
    Position = UDim2.fromOffset(173, 111),
    Size = UDim2.fromOffset(147, 25),
    BackgroundColor3 = Color3.fromRGB(27, 37, 53),
    BorderSizePixel = 0,
    TextColor3 = Color3.fromRGB(229, 237, 247),
    Font = Enum.Font.Gotham,
    TextSize = 10,
    Parent = Card
})
create("UICorner", {CornerRadius = UDim.new(0, 6), Parent = MenuButton})
Library:GiveSignal(CardToggle.Activated:Connect(function()
    Toggles.aim_Enabled:SetValue(not Toggles.aim_Enabled.Value)
end))
Library:GiveSignal(MenuButton.Activated:Connect(function()
    if Library.Toggle then
        Library.Toggle()
    end
end))

RefreshStatus = function()
    local active = Toggles.aim_Enabled.Value and HooksReady and not Stopped
    local state = HookError and "ERROR" or (ObserverError and "ERROR" or (active and "ACTIVE" or "NOT ACTIVE"))
    local color = active and Color3.fromRGB(78, 222, 192) or Color3.fromRGB(255, 154, 163)
    CardStatus.Text = state
    CardStatus.TextColor3 = color
    CardToggle.Text = active and "DISABLE" or "ENABLE"
    CardTarget.Text = HookError and "Hook installation failed. See Diagnostics."
        or (ObserverError and "Target check failed. See Diagnostics."
        or (active and (LastTargetName ~= "" and "Target: " .. LastTargetName or "Searching within radius")
        or "Targeting is disabled"))
    CardDetail.Text = tostring(Options.Method.Value) .. "  |  " .. tostring(Options.Radius.Value) .. " px"
    StatusLabel:SetText("Status: " .. state)
    StatusLabel.TextLabel.TextColor3 = color
    ModeLabel:SetText("Method: " .. tostring(Options.Method.Value))
    TargetLabel:SetText("Target: " .. (active and LastTargetName ~= "" and concise(LastTargetName, 48) or "none"))
    WeaponLabel:SetText("Weapon: " .. concise(LastWeaponName ~= "" and LastWeaponName or "no Tool detected", 48))
    HookLabel:SetText("Hooks: " .. (HookError and "installation failed" or (HooksReady and "installed; hits unverified" or "preparing")))
    Card.Visible = Toggles.UI_StatusCard.Value
    local camera = workspace.CurrentCamera
    if camera then
        HudScale.Scale = math.min(1, math.max(0.1, (camera.ViewportSize.X - 36) / 336))
    end
end

local function stop()
    if Stopped then
        return
    end
    Stopped = true
    SilentAimSettings.Enabled = false
    Toggles.aim_Enabled.Value = false
    mouse_box.Visible = false
    fov_circle.Visible = false
    pcall(function() mouse_box:Remove() end)
    pcall(function() fov_circle:Remove() end)
    HudGui:Destroy()
    logEvent("STATE", "Unloaded; this edition's hooks are disabled, not removed")
end

Library:OnUnload(stop)
Interface:AddButton("Unload this edition", function()
    Library:Unload()
end)
Library:GiveSignal(UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and not UserInputService:GetFocusedTextBox() and input.KeyCode == Enum.KeyCode.End then
        Library:Unload()
    end
end))

local nextRefresh = 0
local visualTarget = nil
Library:GiveSignal(RenderStepped:Connect(function()
    if Stopped then
        return
    end
    local now = os.clock()
    if now >= nextRefresh then
        nextRefresh = now + 0.15
        local previous = LastTargetName
        if HooksReady and Toggles.aim_Enabled.Value then
            local ok, selected = pcall(getClosestPlayer)
            if ok then
                visualTarget = selected
                ObserverError = nil
                LastObserverError = nil
            else
                visualTarget = nil
                ObserverError = tostring(selected)
                if LastObserverError ~= ObserverError then
                    logEvent("ERROR", ObserverError)
                    LastObserverError = ObserverError
                end
                SilentAimSettings.Enabled = false
                Toggles.aim_Enabled.Value = false
            end
        else
            visualTarget = nil
        end
        LastTargetName = visualTarget and visualTarget.Parent and visualTarget.Parent.Name or ""
        if TargetEvents and previous ~= LastTargetName then
            logEvent("TARGET", LastTargetName ~= "" and LastTargetName or "No target")
        end
        local character = LocalPlayer.Character
        local tool = character and character:FindFirstChildOfClass("Tool")
        local weapon = tool and tool.Name or ""
        if weapon ~= LastWeaponName then
            LastWeaponName = weapon
            logEvent("WEAPON", weapon ~= "" and weapon or "No equipped Tool")
        end
        RefreshStatus()
    end

    fov_circle.Visible = Toggles.Visible.Value
    fov_circle.Radius = Options.Radius.Value
    fov_circle.Color = Options.Color.Value
    if fov_circle.Visible then
        fov_circle.Position = getMousePosition()
    end

    mouse_box.Visible = false
    if Toggles.MousePosition.Value and Toggles.aim_Enabled.Value and visualTarget and visualTarget.Parent then
        local camera = workspace.CurrentCamera
        if camera then
            local point, visible = camera:WorldToViewportPoint(visualTarget.Position)
            mouse_box.Position = Vector2.new(point.X, point.Y)
            mouse_box.Color = Options.MouseVisualizeColor.Value
            mouse_box.Visible = visible
        end
    end
end))

logEvent("INFO", "Interface loaded. Original targeting implementation retained.")
RefreshStatus()

local InstallOK, InstallError = pcall(function()
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local Method = getnamecallmethod()
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "FindPartOnRayWithWhitelist" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithWhitelist) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif (Method == "FindPartOnRay" or Method == "findPartOnRay") and Options.Method.Value:lower() == Method:lower() then
            if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRay) then
                local A_Ray = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    local Origin = A_Ray.Origin
                    local Direction = getDirection(Origin, HitPart.Position)
                    Arguments[2] = Ray.new(Origin, Direction)

                    return oldNamecall(unpack(Arguments))
                end
            end
        elseif Method == "Raycast" and Options.Method.Value == Method then
            if ValidateArguments(Arguments, ExpectedArguments.Raycast) then
                local A_Origin = Arguments[2]

                local HitPart = getClosestPlayer()
                if HitPart then
                    Arguments[3] = getDirection(A_Origin, HitPart.Position)

                    return oldNamecall(unpack(Arguments))
                end
            end
        end
    end
    return oldNamecall(...)
end))

local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
        local HitPart = getClosestPlayer()

        if Index == "Target" or Index == "target" then
            return HitPart
        elseif Index == "Hit" or Index == "hit" then
            return ((Toggles.Prediction.Value and (HitPart.CFrame + (HitPart.Velocity * PredictionAmount))) or (not Toggles.Prediction.Value and HitPart.CFrame))
        elseif Index == "X" or Index == "x" then
            return self.X
        elseif Index == "Y" or Index == "y" then
            return self.Y
        elseif Index == "UnitRay" then
            return Ray.new(self.Origin, (self.Hit - self.Origin).Unit)
        end
    end

    return oldIndex(self, Index)
end))
end)

if InstallOK then
    HooksReady = true
    logEvent("HOOK", "Installation completed; server-accepted hits are not verified")
    notify("Ready. Right Alt toggles targeting.")
else
    HookError = tostring(InstallError)
    SilentAimSettings.Enabled = false
    Toggles.aim_Enabled.Value = false
    logEvent("ERROR", HookError)
    notify("Hook installation failed. Open Diagnostics.")
end

RefreshStatus()
