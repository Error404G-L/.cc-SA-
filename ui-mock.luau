local originalObject = object
object = function(className, parent)
    local item = originalObject(className, parent)
    getmetatable(item).__index = function(self, key)
        if methods[key] then return methods[key] end
        if self._props[key] ~= nil then return self._props[key] end
        return methods.FindFirstChild(self, key)
    end
    return item
end
Instance.new = object
methods.GetChildren = function(self) return table.clone(self._children) end
local wallClock = 0
local os = {clock = function() return wallClock end}
local function advance()
    wallClock += 0.2
    RunService.RenderStepped:Fire(0.2)
end
local camera = object("Camera", workspace)
camera.ViewportSize = Vector2.new(1280, 720)
camera.WorldToViewportPoint = function(self, position) return position, true end
camera.WorldToScreenPoint = camera.WorldToViewportPoint
camera.GetPartsObscuringTarget = function() return {} end
camera.CFrame = CFrame.new(0, 0, 0)
workspace.CurrentCamera = camera
game.PlaceId = 123974602339071
game.PlaceVersion = 1084
makeCharacter(localPlayer, 512, 384, 0)
local function addRoot(character, x, y, z)
    local root = object("Part", character)
    root.Name = "HumanoidRootPart"
    root.Position = Vector3.new(x, y, z)
    return root
end
addRoot(localPlayer.Character, 512, 384, 0)
local candidate, enemyHead = enemy("TestTarget", 525, 384, 100)
candidate.Character.Name = "TestTarget"
addRoot(candidate.Character, 525, 384, 100)
local testTool = object("Tool", localPlayer.Character)
testTool.Name = "TestGun"
services.GuiService = {GetGuiInset = function() return Vector2.new(0, 0) end}
local files = {}
local jsonValues = {}
local serial = 0
services.HttpService = {
    JSONEncode = function(self, value)
        serial += 1
        local key = "json" .. serial
        jsonValues[key] = table.clone(value)
        return key
    end,
    JSONDecode = function(self, value) return table.clone(assert(jsonValues[value])) end
}
local function isfolder() return true end
local function makefolder() end
local function listfiles()
    local result = {}
    for name in pairs(files) do table.insert(result, name) end
    return result
end
local function writefile(name, value) files[name] = value end
local function readfile(name) return assert(files[name]) end
local DrawingObjects = {}
local Drawing = {new = function(kind)
    local drawing = {Kind = kind}
    function drawing:Remove() self.Removed = true end
    table.insert(DrawingObjects, drawing)
    return drawing
end}
local Random = {new = function() return {NextNumber = function() return 0.5 end} end}
local controlOptions, controlToggles = {}, {}
environment.Options = controlOptions
environment.Toggles = controlToggles
environment.hookmetamethod = hookmetamethod
environment.getnamecallmethod = getnamecallmethod
environment.checkcaller = checkcaller
environment.newcclosure = newcclosure
local uiLibrary = {Signals = {}, Notifications = {}, Labels = {}, Buttons = {}, Tabs = {}, MenuVisible = true}
uiLibrary.Font = Enum.Font.Gotham
uiLibrary.GetDarkerColor = function(self, color) return color end
uiLibrary.UpdateColorsUsingRegistry = function() end
uiLibrary.SetWatermark = function(self, text) self.Watermark = text end
uiLibrary.SetWatermarkVisibility = function() end
uiLibrary.Notify = function(self, text) table.insert(self.Notifications, text) end
uiLibrary.GiveSignal = function(self, connection) table.insert(self.Signals, connection) end
uiLibrary.OnUnload = function(self, callback) self.UnloadCallback = callback end
uiLibrary.Unload = function(self)
    for _, connection in ipairs(self.Signals) do connection:Disconnect() end
    if self.UnloadCallback then self.UnloadCallback() end
end
uiLibrary.Toggle = function() uiLibrary.MenuVisible = not uiLibrary.MenuVisible end
local Control = {}
Control.__index = Control
function Control:OnChanged(callback)
    self.Callback = callback
    callback(self.Value)
