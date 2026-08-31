if not game:IsLoaded() then
    game.Loaded:Wait()
end

local SessionEnvironment = getgenv()
local SessionKey = "__IDERR_SilentAim_UIEdition_Started"
if SessionEnvironment[SessionKey] then
    warn("[SilentAim] This edition already ran in this session. Restart Roblox before running it again.")
    return
end
SessionEnvironment[SessionKey] = true

if not syn or not protectgui then
    getgenv().protectgui = function() end
end

local SilentAimSettings = {
    Enabled = false,
    AutoEnableOnStart = true,

    ClassName = "Universal Silent Aim - Averiias, Stefanuk12, xaxa",
    ToggleKey = "RightAlt",
end

local function getPositionOnScreen(Vector)
    Camera = workspace.CurrentCamera
    if not Camera then return Vector2.new(0, 0), false end
    local Vec3, OnScreen = WorldToScreen(Camera, Vector)
    return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end
end

local function getDirection(Origin, Position)
    return (Position - Origin).Unit * 1000
    local offset = Position - Origin
    if offset.Magnitude <= 0.0001 then return Vector3.new(0, 0, 0) end
    return offset.Unit * 1000
end

local function getMousePosition()
    local PlayerCharacter = Player.Character
    local LocalPlayerCharacter = LocalPlayer.Character

    if not (PlayerCharacter or LocalPlayerCharacter) then return end
    local CurrentCamera = workspace.CurrentCamera
    if not PlayerCharacter or not LocalPlayerCharacter or not CurrentCamera then return false end

    local PlayerRoot = FindFirstChild(PlayerCharacter, Options.TargetPart.Value) or FindFirstChild(PlayerCharacter, "HumanoidRootPart")

    if not PlayerRoot then return end

    local CastPoints, IgnoreList = {PlayerRoot.Position, LocalPlayerCharacter, PlayerCharacter}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(Camera, CastPoints, IgnoreList)
    local CastPoints, IgnoreList = {PlayerRoot.Position}, {LocalPlayerCharacter, PlayerCharacter}
    local ObscuringObjects = #GetPartsObscuringTarget(CurrentCamera, CastPoints, IgnoreList)

    return ((ObscuringObjects == 0 and true) or (ObscuringObjects > 0 and false))
end
    end
end))

logEvent("INFO", "Interface loaded. Original targeting implementation retained.")
logEvent("INFO", "Interface loaded. Installing hooks before automatic activation.")
RefreshStatus()

local InstallOK, InstallError = pcall(function()
assert(type(hookmetamethod) == "function", "hookmetamethod is unavailable")
assert(type(getnamecallmethod) == "function", "getnamecallmethod is unavailable")
assert(type(checkcaller) == "function", "checkcaller is unavailable")
assert(type(newcclosure) == "function", "newcclosure is unavailable")
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
    local self = ...
    if not Toggles.aim_Enabled.Value or self ~= workspace or checkcaller() then
        return oldNamecall(...)
    end
    local Method = getnamecallmethod()
    local SelectedMethod = Options.Method.Value
    if Method ~= SelectedMethod and not (SelectedMethod == "FindPartOnRay" and Method == "findPartOnRay") then
        return oldNamecall(...)
    end
    local Arguments = {...}
    local self = Arguments[1]
    local chance = CalculateChance(SilentAimSettings.HitChance)
    if Toggles.aim_Enabled.Value and self == workspace and not checkcaller() and chance == true then
        if Method == "FindPartOnRayWithIgnoreList" and Options.Method.Value == Method then
    end
    return oldNamecall(...)
end))
assert(type(oldNamecall) == "function", "Namecall hook did not return its original function; restart Roblox")

local oldIndex = nil
oldIndex = hookmetamethod(game, "__index", newcclosure(function(self, Index)
    if self == Mouse and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" and getClosestPlayer() then
    local TargetProperty = Index == "Target" or Index == "target" or Index == "Hit" or Index == "hit" or Index == "UnitRay"
    if self == Mouse and TargetProperty and not checkcaller() and Toggles.aim_Enabled.Value and Options.Method.Value == "Mouse.Hit/Target" then
