-- S8 DOORS loader: loading screen -> key -> loads the main script
-- Fill these 2 in after you create your work.ink link:
local KEY_LINK = "https://work.ink/378s/s8doors" -- the work.ink link people open to get a key
local LINK_ID = 5058683                         -- your link id, so keys from other links don't work

local MAIN_URL = "https://raw.githubusercontent.com/fisalhx9-ops/S8DOORS/refs/heads/main/gamma_gui.lua"
local KEY_API = "https://work.ink/_api/v2/token/isValid/"
local KEY_FILE = "S8Doors_key.txt"
local DOORS_LOBBY = 6516141723

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local genv = (getgenv and getgenv()) or _G

-- ===== DOORS theme =====
local FONT = Enum.Font.Oswald
local TEXT = Color3.fromRGB(255, 222, 189)
local DIM = Color3.fromRGB(150, 122, 98)
local ACCENT = Color3.fromRGB(200, 150, 100)
local BG = Color3.fromRGB(22, 16, 12)
local HOVER = Color3.fromRGB(58, 42, 30)
local GOOD = Color3.fromRGB(110, 220, 130)
local BAD = Color3.fromRGB(255, 90, 80)
local tween = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function corner(o, r) Instance.new("UICorner", o).CornerRadius = UDim.new(0, r or 6) end
local function stroke(o, color, t)
	local s = Instance.new("UIStroke")
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Color = color or ACCENT
	s.Transparency = t or 0.35
	s.Thickness = 1.5
	s.Parent = o
	return s
end
local function text(class, parent, str, size, color)
	local t = Instance.new(class)
	t.BackgroundTransparency = 1
	t.Font = FONT
	t.Text = str
	t.TextSize = size
	t.TextColor3 = color or TEXT
	t.Parent = parent
	if class == "TextButton" then t.AutoButtonColor = false end
	return t
end

-- ===== Screen =====
local gui = Instance.new("ScreenGui")
gui.Name = "S8Loader"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
local parentOk = pcall(function() gui.Parent = gethui and gethui() or game:GetService("CoreGui") end)
if not parentOk or not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

local shade = Instance.new("Frame")
shade.Size = UDim2.fromScale(1, 1)
shade.BackgroundColor3 = Color3.new(0, 0, 0)
shade.BackgroundTransparency = 1
shade.Parent = gui
TweenService:Create(shade, tween, {BackgroundTransparency = 0.35}):Play()

-- free the mouse while the loader is open
local modal = Instance.new("TextButton")
modal.Size = UDim2.fromOffset(0, 0)
modal.BackgroundTransparency = 1
modal.Text = ""
modal.Modal = true
modal.Parent = gui
local mouseConn = RunService.RenderStepped:Connect(function()
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
end)

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(380, 230)
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.BackgroundColor3 = BG
panel.BackgroundTransparency = 0.05
panel.Parent = gui
corner(panel, 8)
stroke(panel)
local pscale = Instance.new("UIScale")
pscale.Scale = 0.85
pscale.Parent = panel
TweenService:Create(pscale, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Scale = 1}):Play()

local title = text("TextLabel", panel, "S8 DOORS", 34)
title.Size = UDim2.new(1, 0, 0, 44)
title.Position = UDim2.fromOffset(0, 14)
local sub = text("TextLabel", panel, "", 14, DIM)
sub.Size = UDim2.new(1, 0, 0, 18)
sub.Position = UDim2.fromOffset(0, 56)

local line = Instance.new("Frame")
line.Size = UDim2.new(1, -40, 0, 1)
line.Position = UDim2.fromOffset(20, 82)
line.BackgroundColor3 = ACCENT
line.BackgroundTransparency = 0.6
line.BorderSizePixel = 0
line.Parent = panel

-- Loading bar
local barBack = Instance.new("Frame")
barBack.Size = UDim2.new(1, -60, 0, 6)
barBack.Position = UDim2.fromOffset(30, 130)
barBack.BackgroundColor3 = HOVER
barBack.BorderSizePixel = 0
barBack.Parent = panel
corner(barBack, 3)
local bar = Instance.new("Frame")
bar.Size = UDim2.fromScale(0, 1)
bar.BackgroundColor3 = TEXT
bar.BorderSizePixel = 0
bar.Parent = barBack
corner(bar, 3)
local status = text("TextLabel", panel, "", 15, DIM)
status.Size = UDim2.new(1, -40, 0, 20)
status.Position = UDim2.fromOffset(20, 146)

local function setProgress(a, msg)
	TweenService:Create(bar, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {Size = UDim2.fromScale(a, 1)}):Play()
	if msg then status.Text = msg end
end

local function close()
	mouseConn:Disconnect()
	TweenService:Create(pscale, tween, {Scale = 0.85}):Play()
	TweenService:Create(shade, tween, {BackgroundTransparency = 1}):Play()
	task.wait(0.25)
	gui:Destroy()
end

local function fail(msg)
	sub.Text = ""
	barBack.Visible = false
	status.Text = msg
	status.TextColor3 = BAD
	status.TextWrapped = true
	status.Size = UDim2.new(1, -40, 0, 60)
	status.Position = UDim2.fromOffset(20, 100)
	task.wait(4)
	close()
end

-- ===== Key check =====
local function checkKey(key)
	key = (key or ""):gsub("%s", "")
	if #key < 6 then return false end
	local ok, valid = pcall(function()
		local data = HttpService:JSONDecode(game:HttpGet(KEY_API .. key))
		return data.valid == true and (LINK_ID == nil or (data.info and data.info.linkId == LINK_ID))
	end)
	return ok and valid, key
end

local function saveKey(key)
	if writefile then pcall(writefile, KEY_FILE, key) end
end

local function savedKey()
	local key
	pcall(function()
		if isfile and readfile and isfile(KEY_FILE) then key = readfile(KEY_FILE) end
	end)
	return key
end

-- ===== Start =====
local function launch(key)
	genv.S8Key = key
	sub.Text = "LOADING"
	barBack.Visible = true
	status.TextColor3 = DIM
	setProgress(0.75, "Loading S8 Doors...")
	local src
	local ok = pcall(function() src = game:HttpGet(MAIN_URL) end)
	if not ok or not src or #src < 100 then
		fail("Couldn't download the script. Check your internet and try again.")
		return
	end
	setProgress(1, "Done!")
	task.wait(0.3)
	close()
	local fn, compileErr = loadstring(src)
	if fn then
		task.spawn(fn)
	else
		warn("[S8 Doors] " .. tostring(compileErr))
	end
end

local function keyScreen()
	barBack.Visible = false
	sub.Text = "KEY SYSTEM"
	status.Text = ""
	TweenService:Create(panel, tween, {Size = UDim2.fromOffset(380, 270)}):Play()

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -60, 0, 40)
	box.Position = UDim2.fromOffset(30, 98)
	box.BackgroundColor3 = HOVER
	box.BackgroundTransparency = 0.3
	box.Font = FONT
	box.TextSize = 17
	box.TextColor3 = TEXT
	box.PlaceholderText = "Paste your key here"
	box.PlaceholderColor3 = DIM
	box.Text = ""
	box.ClearTextOnFocus = false
	box.Parent = panel
	corner(box, 4)
	local boxStroke = stroke(box, ACCENT, 0.55)

	local function button(str, x, anchor)
		local b = text("TextButton", panel, str, 18)
		b.Size = UDim2.fromOffset(150, 38)
		b.AnchorPoint = Vector2.new(anchor, 0)
		b.Position = UDim2.new(x, anchor == 0 and 30 or -30, 0, 150)
		b.BackgroundColor3 = BG
		b.BackgroundTransparency = 0.25
		corner(b, 4)
		local st = stroke(b, ACCENT, 0.55)
		b.MouseEnter:Connect(function()
			TweenService:Create(b, tween, {BackgroundColor3 = HOVER}):Play()
			TweenService:Create(st, tween, {Transparency = 0}):Play()
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(b, tween, {BackgroundColor3 = BG}):Play()
			TweenService:Create(st, tween, {Transparency = 0.55}):Play()
		end)
		return b
	end

	local getBtn = button("GET KEY", 0, 0)
	local checkBtn = button("CHECK KEY", 1, 1)

	status.Position = UDim2.fromOffset(20, 200)
	status.Size = UDim2.new(1, -40, 0, 40)
	status.TextWrapped = true
	status.Text = "Click GET KEY, finish the link, then paste the key."

	local function say(msg, color)
		status.Text = msg
		status.TextColor3 = color or DIM
	end

	getBtn.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(KEY_LINK)
			say("Link copied! Open it in your browser.", GOOD)
		else
			say(KEY_LINK, TEXT)
		end
	end)

	local busy = false
	checkBtn.MouseButton1Click:Connect(function()
		if busy then return end
		busy = true
		say("Checking key...")
		local valid, key = checkKey(box.Text)
		if valid then
			boxStroke.Color = GOOD
			say("Key accepted!", GOOD)
			saveKey(key)
			box:Destroy()
			getBtn:Destroy()
			checkBtn:Destroy()
			TweenService:Create(panel, tween, {Size = UDim2.fromOffset(380, 230)}):Play()
			status.Position = UDim2.fromOffset(20, 146)
			status.Size = UDim2.new(1, -40, 0, 20)
			launch(key)
		else
			boxStroke.Color = BAD
			say("Invalid or expired key. Get a new one.", BAD)
			busy = false
		end
	end)
end

task.spawn(function()
	sub.Text = "LOADING"
	setProgress(0.2, "Starting...")
	task.wait(0.5)

	if game.PlaceId == DOORS_LOBBY then
		fail("You're in the lobby. Start a DOORS run, then run the script again.")
		return
	end

	setProgress(0.45, "Checking saved key...")
	task.wait(0.4)
	local key = savedKey()
	if key then
		local valid, clean = checkKey(key)
		if valid then
			setProgress(0.6, "Key is valid")
			task.wait(0.3)
			launch(clean)
			return
		end
	end
	setProgress(0.6, "Key needed")
	task.wait(0.4)
	keyScreen()
end)
