--[[
    Magma Hub
    © Commandcracker

    https://github.com/Commandcracker/Magma-Hub
]]

-- Services
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Camera = game:GetService("Workspace").CurrentCamera
local TestService = game:GetService("TestService")
local TweenService = game:GetService("TweenService")

-- Variables
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Anti Kick Hook
if hookmetamethod ~= nil and getnamecallmethod ~= nil then
	local OldNameCall = nil

	OldNameCall = hookmetamethod(game, "__namecall", function(Self, n, ...)
		local NameCallMethod = getnamecallmethod()

		if tostring(string.lower(NameCallMethod)) == "kick" then
			if n == nil then
				game.StarterGui:SetCore(
					"SendNotification",
					{ Title = "Magma Hub", Text = "Kick prevented.", Duration = 2 }
				)
				print("[Magma Hub] Kick prevented.")
			else
				game.StarterGui:SetCore(
					"SendNotification",
					{ Title = "Magma Hub", Text = "Kick " .. '"' .. n .. '"' .. " prevented.", Duration = 2 }
				)
				print("[Magma Hub] Kick " .. '"' .. n .. '"' .. " prevented.")
			end
			return nil
		end

		return OldNameCall(Self, n, ...)
	end)
end

-- Thrad Manager
local function kill(thread: thread, f)
	local env = getfenv(f)
	function env:__index(k)
		if type(env[k]) == "function" and coroutine.running() == thread then
			return function()
				coroutine.yield()
			end
		else
			return env[k]
		end
	end
	setfenv(f, setmetatable({}, env))
	coroutine.resume(thread)
end

local TM = {}
TM.__index = TM

function TM.new()
	return setmetatable({
		threads = {},
	}, TM)
end

function TM:Add(Function)
	local thread = coroutine.create(Function)
	table.insert(self.threads, { thread, Function })
	coroutine.resume(thread)
end

function TM:Cleanup()
	for _, v in pairs(self.threads) do
		kill(v[1], v[2])
	end
end

Threads = TM.new()

-- Better Local Player
BLP = {}

function BLP.Respawn()
	local char = LocalPlayer.Character
	if char:FindFirstChildOfClass("Humanoid") then
		char:FindFirstChildOfClass("Humanoid"):ChangeState(15)
	end
	char:ClearAllChildren()
	local newChar = Instance.new("Model")
	newChar.Parent = workspace
	LocalPlayer.Character = newChar
	wait()
	LocalPlayer.Character = char
	newChar:Destroy()
end

function BLP.Refresh()
	local Human = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid", true)
	local pos = Human and Human.RootPart and Human.RootPart.CFrame
	local pos1 = workspace.CurrentCamera.CFrame
	BLP.Respawn()
	task.spawn(function()
		LocalPlayer.CharacterAdded:Wait():WaitForChild("Humanoid").RootPart.CFrame, workspace.CurrentCamera.CFrame =
			pos, wait() and pos1
	end)
end

function BLP.Teleport(x: number | Vector3 | CFrame, y: number | Vector3, z: number, ...: number)
	if typeof(x) == "CFrame" then
		LocalPlayer.Character.HumanoidRootPart.CFrame = x
	elseif typeof(x) == "Vector3" then
		if typeof(y) == "Vector3" then
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y)
		else
			LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x)
		end
	else
		LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(x, y, z, ...)
	end
end

-- Better Table
Btable = {}

function Btable.Reverse(Table: table)
	local reversedTable = {}
	local itemCount = #Table
	for k, v in ipairs(Table) do
		reversedTable[itemCount + 1 - k] = v
	end
	return reversedTable
end

function Btable.Contains(Table: table, Item)
	for _, value in pairs(Table) do
		if value == Item then
			return true
		end
	end
	return false
end

function Btable.Print(Table: table)
	local function getPointer(...)
		return string.split(tostring(...), " ")[2]
	end

	local function TableToString(Table: table, space: number)
		local out = "{\n"

		if space == nil then
			space = 1
		end

		for key, value in pairs(Table) do
			local keyString
			keyString = "['" .. tostring(key) .. "']"

			local valueString
			if type(value) == "function" then
				valueString = "'" .. "function_" .. getPointer(value) .. "'"
			elseif type(value) == "string" then
				valueString = "'" .. tostring(value) .. "'"
			elseif type(value) == "table" then
				valueString = TableToString(value, space + 1)
			else
				valueString = tostring(value)
			end

			for _ = 1, space * 4 do
				out = out .. " "
			end

			out = out .. keyString .. " = " .. valueString .. ",\n"
		end
		for _ = 1, (space - 1) * 4 do
			out = out .. " "
		end
		return out .. "}"
	end

	local out = "local table_" .. getPointer(Table) .. " = " .. TableToString(Table) .. "\n"
	if rconsoleclear ~= nil then
		rconsoleclear()
	end
	if rconsoleprint ~= nil then
		rconsoleprint(out)
	else
		print(out)
	end
end

-- UI util
local UIutil = {}

function UIutil:DraggingEnabled(frame, parent)
	parent = parent or frame

	local dragging = false
	local dragInput, mousePos, framePos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			mousePos = input.Position
			framePos = parent.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - mousePos
			parent.Position =
				UDim2.new(framePos.X.Scale, framePos.X.Offset + delta.X, framePos.Y.Scale, framePos.Y.Offset + delta.Y)
		end
	end)
end

-- Magma UI
local MagmaUI = {}
local Page = {}

MagmaUI.__index = MagmaUI
Page.__index = Page

function MagmaUI.new()
	local GUI
	if pcall(function()
		return game.CoreGui.Name
	end) then
		GUI = Instance.new("ScreenGui", game.CoreGui)
	else
		GUI = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
	end

	GUI.ResetOnSpawn = false
	GUI.AutoLocalize = false
	GUI.DisplayOrder = 999999999

	local MainFrame = Instance.new("Frame", GUI)
	MainFrame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
	MainFrame.Size = UDim2.new(0, 500, 0, 320)
	MainFrame.Position = UDim2.new(0.5, -250, 0, -356)
	MainFrame.BorderSizePixel = 0

	local RGBBar = Instance.new("Frame", MainFrame)
	RGBBar.BorderSizePixel = 0
	RGBBar.Size = UDim2.new(1, 0, 0, 4)
	RGBBar.BackgroundColor3 = Color3.fromRGB(255, 78, 1)
	RGBBar.ZIndex = 2

	--[[
    Threads:Add(function()
        local function zigzag(X) return math.acos(math.cos(X*math.pi))/math.pi end
        local counter = 0

        while wait(.1) do
            RGBBar.BackgroundColor3 = Color3.fromHSV(zigzag(counter),1,1)
            counter = counter + .01
        end
    end)
    ]]

	local TopBar = Instance.new("Frame", MainFrame)
	TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	TopBar.Size = UDim2.new(1, 0, 0, 35)
	TopBar.BorderSizePixel = 0

	local Title = Instance.new("TextLabel", TopBar)
	Title.Size = UDim2.new(0.5, 0, 1, 0)
	Title.Position = UDim2.new(0, 10, 0, 0)
	Title.Font = Enum.Font.GothamBold
	Title.Text = "Magma Hub"
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.BackgroundTransparency = 1
	Title.TextColor3 = Color3.fromRGB(255, 255, 255)

	local ExitButton = Instance.new("TextButton", TopBar)
	ExitButton.Text = "X"
	ExitButton.BorderSizePixel = 0
	ExitButton.Size = UDim2.new(0, 35, 0, 35)
	ExitButton.Position = UDim2.new(1, -35, 0, 0)
	ExitButton.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
	ExitButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	ExitButton.Font = Enum.Font.GothamBold
	ExitButton.TextSize = 14
	ExitButton.MouseButton1Click:Connect(function()
		MainFrame:TweenPosition(
			UDim2.new(MainFrame.Position.X.Scale, MainFrame.Position.X.Offset, 1, 0),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Sine,
			1
		)
		wait(1)
		GUI:Destroy()
		warn('[Magma Hub] Terminating Threads (ignore errors like "attempt to call a nil value")')
		Threads:Cleanup()
		script:Destroy()
	end)

	--[[
    local MinimizeButton                    = Instance.new("TextButton", TopBar)
    MinimizeButton.Text                     = "─"
    MinimizeButton.BorderSizePixel          = 0
    MinimizeButton.Size                     = UDim2.new(0,35,0,35)
    MinimizeButton.Position                 = UDim2.new(1, -70, 0, 0)
    MinimizeButton.BackgroundColor3         = Color3.fromRGB(10, 10, 10)
    MinimizeButton.TextColor3               = Color3.fromRGB(255, 255, 255)
    MinimizeButton.Font                     = Enum.Font.GothamBold
    MinimizeButton.TextSize                 = 14
    ]]

	local PageFrame = Instance.new("ScrollingFrame", MainFrame)
	PageFrame.Size = UDim2.new(0, 100, 1, -35)
	PageFrame.Position = UDim2.new(0, 0, 0, 35)
	PageFrame.BorderSizePixel = 0
	PageFrame.ScrollBarThickness = 5
	PageFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	PageFrame.ScrollBarImageColor3 = Color3.fromRGB(4, 4, 4)
	PageFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local PageFrame_UIListLayout = Instance.new("UIListLayout", PageFrame)
	PageFrame_UIListLayout.Padding = UDim.new(0, 5)

	return setmetatable({
		MainFrame = MainFrame,
		PageFrame = PageFrame,
	}, MagmaUI)
end

function Page.new(lib, title: string)
	local ModuleList = Instance.new("ScrollingFrame", lib.MainFrame)
	ModuleList.Size = UDim2.new(1, -105, 1, -40)
	ModuleList.Position = UDim2.new(0, 105, 0, 40)
	ModuleList.BorderSizePixel = 0
	ModuleList.ScrollBarThickness = 5
	ModuleList.BackgroundTransparency = 1
	ModuleList.ScrollBarImageColor3 = Color3.fromRGB(4, 4, 4)
	ModuleList.Visible = false
	ModuleList.AutomaticCanvasSize = Enum.AutomaticSize.Y

	local ModuleList_UIListLayout = Instance.new("UIListLayout", ModuleList)
	ModuleList_UIListLayout.Padding = UDim.new(0, 5)

	local Button = Instance.new("TextButton", lib.PageFrame)
	Button.Size = UDim2.new(1, 0, 0, 35)
	Button.Font = Enum.Font.Gotham
	Button.Text = title
	Button.TextSize = 14
	Button.TextColor3 = Color3.fromRGB(255, 255, 255)
	Button.TextWrapped = true
	Button.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	Button.BorderSizePixel = 0
	Button.TextTransparency = 0.65

	return setmetatable({
		lib = lib,
		ModuleList = ModuleList,
		Button = Button,
	}, Page)
end

function Page:Hide()
	self.ModuleList.Visible = false
	self.Button.Font = Enum.Font.Gotham
	self.Button.TextTransparency = 0.65
end

function Page:Show()
	if self.lib.CurrentPage ~= nil then
		self.lib.CurrentPage:Hide()
	end

	self.ModuleList.Visible = true
	self.lib.CurrentPage = self
	self.Button.Font = Enum.Font.GothamSemibold
	self.Button.TextTransparency = 0
end

function Page:addButton(title: string, callback)
	local Button = {}

	Button.Frame = Instance.new("Frame", self.ModuleList)
	Button.Frame.BorderSizePixel = 0
	Button.Frame.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
	Button.Frame.Size = UDim2.new(1, -10, 0, 30)

	Button.TextLabel = Instance.new("TextLabel", Button.Frame)
	Button.TextLabel.TextColor3 = Color3.new(1, 1, 1)
	Button.TextLabel.Text = title
	Button.TextLabel.TextWrapped = true
	Button.TextLabel.Font = Enum.Font.Gotham
	Button.TextLabel.BackgroundTransparency = 1
	Button.TextLabel.Position = UDim2.new(0.02, 0, 0, 0)
	Button.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
	Button.TextLabel.Size = UDim2.new(0, 313, 1, 0)
	Button.TextLabel.TextSize = 12

	Button.Button = Instance.new("TextButton", Button.Frame)
	Button.Button.TextColor3 = Color3.new(1, 1, 1)
	Button.Button.Text = "Run"
	Button.Button.Font = Enum.Font.Gotham
	Button.Button.Position = UDim2.new(0.89, 0, 0.25, -2)
	Button.Button.TextSize = 12
	Button.Button.Size = UDim2.new(0, 35, 1, -10)
	Button.Button.BorderColor3 = Color3.fromRGB(100, 100, 100)
	Button.Button.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	function Button:connect(callback)
		Button.Button.MouseButton1Click:Connect(callback)
	end

	local hovering = false
	local tweenTime = 0.125
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	Button.Button.MouseEnter:Connect(function()
		hovering = true

		local borderFadeIn =
			TweenService:Create(Button.Button, tweenInfo, { BorderColor3 = Color3.fromRGB(255, 255, 255) })
		borderFadeIn:Play()

		repeat
			wait()
		until not hovering

		local borderFadeOut =
			TweenService:Create(Button.Button, tweenInfo, { BorderColor3 = Color3.fromRGB(100, 100, 100) })
		borderFadeOut:Play()
	end)

	Button.Button.MouseLeave:Connect(function()
		hovering = false
	end)

	if callback then
		Button.Button.MouseButton1Click:Connect(callback)
	end

	return Button
end

function Page:addToggle(title: string, EnableFunction, DisableFunction)
	local Button = self:addButton(title)
	Button.connect = nil
	Button.Button.Text = "Off"

	local Toggel = false

	Button.Button.MouseButton1Click:Connect(function()
		if Toggel then
			Toggel = false
			Button.Button.Text = "Off"
			if DisableFunction ~= nil then
				DisableFunction()
			end
		else
			Toggel = true
			Button.Button.Text = "On"
			if EnableFunction ~= nil then
				EnableFunction()
			end
		end
	end)

	function Button:IsEnabeld()
		return Toggel
	end

	function Button:SetEnableFunction(Function)
		EnableFunction = Function
	end

	function Button:SetDisableFunction(Function)
		DisableFunction = Function
	end

	return Button
end

function Page:addInput(title: string, Function)
	local Button = self:addButton(title)

	Button.TextLabel.Size = UDim2.new(0, 231, 1, 0)

	Button.TextBox = Instance.new("TextBox", Button.Frame)
	Button.TextBox.TextColor3 = Color3.new(1, 1, 1)
	Button.TextBox.Text = ""
	Button.TextBox.Font = Enum.Font.Gotham
	Button.TextBox.Position = UDim2.new(1, -125, 0.25, -2)
	Button.TextBox.Size = UDim2.new(0, 75, 1, -10)
	Button.TextBox.TextSize = 12
	Button.TextBox.BorderColor3 = Color3.fromRGB(100, 100, 100)
	Button.TextBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)

	local hovering = false
	local tweenTime = 0.125
	local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	Button.TextBox.MouseEnter:Connect(function()
		hovering = true

		local borderFadeIn =
			TweenService:Create(Button.TextBox, tweenInfo, { BorderColor3 = Color3.fromRGB(255, 255, 255) })
		borderFadeIn:Play()

		repeat
			wait()
		until not hovering and not Button.TextBox:IsFocused()

		local borderFadeOut =
			TweenService:Create(Button.TextBox, tweenInfo, { BorderColor3 = Color3.fromRGB(100, 100, 100) })
		borderFadeOut:Play()
	end)

	Button.TextBox.MouseLeave:Connect(function()
		hovering = false
	end)

	Button.Button.MouseButton1Click:Connect(function()
		if Function ~= nil then
			Function(Button.TextBox.Text)
		end
	end)

	return Button
end

function MagmaUI:addPage(title: string)
	local page = Page.new(self, title)
	page.Button.MouseButton1Click:Connect(function()
		page:Show()
	end)
	return page
end

function MagmaUI:load()
	UIutil:DraggingEnabled(self.MainFrame)
	self.MainFrame:TweenPosition(UDim2.new(0.5, -250, 0.5, -196), Enum.EasingDirection.In, Enum.EasingStyle.Sine, 1)
end

function MagmaUI:Notify(text: string, mode: number)
	if mode == nil or mode == 0 then
		print("[Magma Hub] " .. text)
	elseif mode == 1 then
		warn("[Magma Hub] " .. text)
	end
	game.StarterGui:SetCore("SendNotification", {
		Title = "Magma Hub",
		Text = text,
		Duration = 2,
	})
end

-- Init
MagmaHub = MagmaUI.new()

-- Local Player Page
local LocalPlayerPage = MagmaHub:addPage("Local Player")
LocalPlayerPage:Show()

-- WalkSpeed
LocalPlayerPage:addInput("WalkSpeed", function(input)
	LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = input
end)

-- JumpPower
LocalPlayerPage:addInput("JumpPower", function(input)
	local Humanoid = LocalPlayer.Character:WaitForChild("Humanoid")
	Humanoid.UseJumpPower = true
	Humanoid.JumpPower = input
end)

-- Teleport To Player
LocalPlayerPage:addInput("Teleport To Player", function(input)
	for _, player in pairs(Players:GetPlayers()) do
		if input == string.sub(player.Name, 1, #input) then
			LocalPlayer.Character.HumanoidRootPart.CFrame = player.Character.HumanoidRootPart.CFrame
				+ Vector3.new(0, 0, -1)
		end
	end
end)

-- Fullbright
LocalPlayerPage:addButton("Fullbright", function()
	local Light = game:GetService("Lighting")

	local function dofullbright()
		Light.Ambient = Color3.new(1, 1, 1)
		Light.ColorShift_Bottom = Color3.new(1, 1, 1)
		Light.ColorShift_Top = Color3.new(1, 1, 1)
		Light.FogEnd = 100000
		Light.FogStart = 0
		Light.ClockTime = 14
		Light.Brightness = 2
		Light.GlobalShadows = true
	end

	dofullbright()
	Light.LightingChanged:Connect(dofullbright)
end)

-- Noclip
local NoclipButton = LocalPlayerPage:addToggle("Noclip")

local function getNoClipParts()
	local parts = {}
	for _, part in next, LocalPlayer.Character:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide then
			table.insert(parts, part)
		end
	end
	return parts
end

local function noclip()
	if not NoclipButton:IsEnabeld() then
		return
	end

	for _, v in next, getNoClipParts() do
		v.CanCollide = false
	end
end

RunService.Stepped:Connect(noclip)

-- Infinity Jump
local InfinityJumpButton = LocalPlayerPage:addToggle("Infinity Jump")

UserInputService.JumpRequest:Connect(function()
	if InfinityJumpButton:IsEnabeld() then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
	end
end)

-- Suicid
LocalPlayerPage:addButton("Suicid", function()
	LocalPlayer.Character:WaitForChild("Humanoid").Health = 0
end)

-- Fly
local FlyButton = LocalPlayerPage:addToggle("Fly")
local ctrl = { f = 0, b = 0, l = 0, r = 0 }
local lastctrl = { f = 0, b = 0, l = 0, r = 0 }
local maxspeed = 50
local speed = 0
local bg = nil
local bv = nil

function Fly()
	local Torso = LocalPlayer.Character:FindFirstChild("Torso")

	if Torso == nil then
		Torso = LocalPlayer.Character:FindFirstChild("LowerTorso")
	end

	if Torso == nil then
		Torso = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	end

	bg = Instance.new("BodyGyro", Torso)
	bg.P = 9e4
	bg.maxTorque = Vector3.new(9e9, 9e9, 9e9)
	bg.cframe = Torso.CFrame

	bv = Instance.new("BodyVelocity", Torso)
	bv.velocity = Vector3.new(0, 0.1, 0)
	bv.maxForce = Vector3.new(9e9, 9e9, 9e9)

	repeat
		wait()
		LocalPlayer.Character.Humanoid.PlatformStand = true
		if ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0 then
			speed = speed + 0.5 + (speed / maxspeed)
			if speed > maxspeed then
				speed = maxspeed
			end
		elseif not (ctrl.l + ctrl.r ~= 0 or ctrl.f + ctrl.b ~= 0) and speed ~= 0 then
			speed = speed - 1
			if speed < 0 then
				speed = 0
			end
		end
		if (ctrl.l + ctrl.r) ~= 0 or (ctrl.f + ctrl.b) ~= 0 then
			bv.velocity = (
				(game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (ctrl.f + ctrl.b))
				+ (
					(
						game.Workspace.CurrentCamera.CoordinateFrame
						* CFrame.new(ctrl.l + ctrl.r, (ctrl.f + ctrl.b) * 0.2, 0).p
					) - game.Workspace.CurrentCamera.CoordinateFrame.p
				)
			) * speed
			lastctrl = { f = ctrl.f, b = ctrl.b, l = ctrl.l, r = ctrl.r }
		elseif (ctrl.l + ctrl.r) == 0 and (ctrl.f + ctrl.b) == 0 and speed ~= 0 then
			bv.velocity = (
				(game.Workspace.CurrentCamera.CoordinateFrame.lookVector * (lastctrl.f + lastctrl.b))
				+ (
					(
						game.Workspace.CurrentCamera.CoordinateFrame
						* CFrame.new(lastctrl.l + lastctrl.r, (lastctrl.f + lastctrl.b) * 0.2, 0).p
					) - game.Workspace.CurrentCamera.CoordinateFrame.p
				)
			) * speed
		else
			bv.velocity = Vector3.new(0, 0.1, 0)
		end
		bg.cframe = game.Workspace.CurrentCamera.CoordinateFrame
			* CFrame.Angles(-math.rad((ctrl.f + ctrl.b) * 50 * speed / maxspeed), 0, 0)
	until not FlyButton:IsEnabeld()
	ctrl = { f = 0, b = 0, l = 0, r = 0 }
	lastctrl = { f = 0, b = 0, l = 0, r = 0 }
	speed = 0
	bg:Destroy()
	bg = nil
	bv:Destroy()
	bv = nil
	LocalPlayer.Character.Humanoid.PlatformStand = false
e
