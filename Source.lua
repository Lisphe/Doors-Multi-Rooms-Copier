local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

----------------------------------------------------
-- CRITICAL FOLDER CHECK & KICK LOGIC
----------------------------------------------------
local currentRooms = Workspace:FindFirstChild("CurrentRooms")
if not currentRooms then
	LocalPlayer:Kick('Folder "CurrentRooms" Is Missing')
	return
end

local DELAY_TIME = 1
local isRunning = false
local isProcessing = false
local isMinimized = false
local currentVersion = "v1"

local FOLDER_MAP = {
	["A"] = "Archives",
	["B"] = "Backdoors",
	["H"] = "Hotel",
	["G"] = "Greenhouse",
	["M"] = "Mines",
	["W"] = "Sewer",
	["O"] = "Garden",
	["R"] = "Rooms",
	["S"] = "Stairwell",
	["E"] = "Estate",
	["V"] = "Vault",
}

local allowedCategories = {
	["A"] = true,
	["B"] = true,
	["H"] = true,
	["G"] = true,
	["M"] = true,
	["W"] = true,
	["O"] = true,
	["R"] = true,
	["S"] = true,
	["E"] = true,
	["V"] = true,
}

----------------------------------------------------
-- UI CREATION (Optimized: No Export Boxes)
----------------------------------------------------
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LuaRoomExporterGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.new(0, 240, 0, 500)
frame.Position = UDim2.new(0, 20, 0.5, -250)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

-- Top Bar for Dragging and Title
local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 35)
topBar.BackgroundTransparency = 1
topBar.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -40, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Lua Room & Prop Exporter"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 15
title.Font = Enum.Font.SourceSansBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

-- Minimize Button
local minimizeBtn = Instance.new("TextButton")
minimizeBtn.Name = "MinimizeBtn"
minimizeBtn.Size = UDim2.new(0, 30, 0, 30)
minimizeBtn.Position = UDim2.new(1, -35, 0, 2)
minimizeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
minimizeBtn.Text = "-"
minimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minimizeBtn.Font = Enum.Font.SourceSansBold
minimizeBtn.TextSize = 18
minimizeBtn.Parent = topBar

local minCorner = Instance.new("UICorner")
minCorner.CornerRadius = UDim.new(0, 4)
minCorner.Parent = minimizeBtn

-- Container for interactive options
local contentContainer = Instance.new("ScrollingFrame")
contentContainer.Name = "ContentContainer"
contentContainer.Size = UDim2.new(1, 0, 1, -35)
contentContainer.Position = UDim2.new(0, 0, 0, 35)
contentContainer.BackgroundTransparency = 1
contentContainer.BorderSizePixel = 0
contentContainer.CanvasSize = UDim2.new(0, 0, 0, 480)
contentContainer.ScrollBarThickness = 4
contentContainer.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = contentContainer

-- Version Input Box Container
local versionBoxContainer = Instance.new("Frame")
versionBoxContainer.Size = UDim2.new(0.9, 0, 0, 32)
versionBoxContainer.BackgroundTransparency = 1
versionBoxContainer.LayoutOrder = 1
versionBoxContainer.Parent = contentContainer

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(0.4, 0, 1, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "Version:"
versionLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
versionLabel.TextSize = 14
versionLabel.Font = Enum.Font.SourceSansSemibold
versionLabel.TextXAlignment = Enum.TextXAlignment.Left
versionLabel.Parent = versionBoxContainer

local versionInput = Instance.new("TextBox")
versionInput.Size = UDim2.new(0.6, 0, 1, 0)
versionInput.Position = UDim2.new(0.4, 0, 0, 0)
versionInput.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
versionInput.Text = "v1"
versionInput.TextColor3 = Color3.fromRGB(255, 255, 255)
versionInput.TextSize = 14
versionInput.Font = Enum.Font.SourceSans
versionInput.Parent = versionBoxContainer

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 5)
inputCorner.Parent = versionInput

versionInput.FocusLost:Connect(function()
	if versionInput.Text ~= "" then
		currentVersion = versionInput.Text
	else
		versionInput.Text = currentVersion
	end
end)

-- Main Start / Stop Button
local startBtn = Instance.new("TextButton")
startBtn.Name = "StartBtn"
startBtn.Size = UDim2.new(0.9, 0, 0, 35)
startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
startBtn.Text = "START COPYING"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.Font = Enum.Font.SourceSansBold
startBtn.TextSize = 15
startBtn.LayoutOrder = 2
startBtn.Parent = contentContainer

local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 6)
startCorner.Parent = startBtn

-- Category Buttons List
local categories = {
	{Key = "A", Name = "Archives"},
	{Key = "B", Name = "Backdoors"},
	{Key = "H", Name = "Hotel"},
	{Key = "G", Name = "Greenhouse"},
	{Key = "M", Name = "Mines"},
	{Key = "W", Name = "Sewer"},
	{Key = "O", Name = "Garden"},
	{Key = "R", Name = "Rooms"},
	{Key = "S", Name = "Stairwell"},
	{Key = "E", Name = "Estate"},
	{Key = "V", Name = "Vault"},
}

for order, cat in ipairs(categories) do
	local btn = Instance.new("TextButton")
	btn.Name = cat.Name .. "Btn"
	btn.Size = UDim2.new(0.9, 0, 0, 28)
	btn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
	btn.Text = cat.Name .. " (" .. cat.Key .. "): ON"
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansSemibold
	btn.TextSize = 13
	btn.LayoutOrder = order + 2
	btn.Parent = contentContainer

	btn.MouseButton1Click:Connect(function()
		allowedCategories[cat.Key] = not allowedCategories[cat.Key]
		if allowedCategories[cat.Key] then
			btn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
			btn.Text = cat.Name .. " (" .. cat.Key .. "): ON"
		else
			btn.BackgroundColor3 = Color3.fromRGB(178, 34, 34)
			btn.Text = cat.Name .. " (" .. cat.Key .. "): OFF"
		end
	end)
end

----------------------------------------------------
-- DRAGGABLE LOGIC
----------------------------------------------------
local dragging, dragStart, startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

----------------------------------------------------
-- MINIMIZE LOGIC
----------------------------------------------------
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		contentContainer.Visible = false
		frame.Size = UDim2.new(0, 240, 0, 35)
		minimizeBtn.Text = "+"
	else
		contentContainer.Visible = true
		frame.Size = UDim2.new(0, 240, 0, 500)
		minimizeBtn.Text = "-"
	end
end)

----------------------------------------------------
-- ROOM, PROP & SIDEROOM CLONING LOGIC WITH ANTI-DUPLICATION
----------------------------------------------------
local function getDestinationFolders(categoryName, versionName)
	local mainFolder = ServerStorage:FindFirstChild(categoryName)
	if not mainFolder then
		mainFolder = Instance.new("Folder")
		mainFolder.Name = categoryName
		mainFolder.Parent = ServerStorage
	end

	local versionFolder = mainFolder:FindFirstChild(versionName)
	if not versionFolder then
		versionFolder = Instance.new("Folder")
		versionFolder.Name = versionName
		versionFolder.Parent = mainFolder
	end

	local roomsFolder = versionFolder:FindFirstChild("Rooms")
	if not roomsFolder then
		roomsFolder = Instance.new("Folder")
		roomsFolder.Name = "Rooms"
		roomsFolder.Parent = versionFolder
	end

	local propsFolder = versionFolder:FindFirstChild("Props")
	if not propsFolder then
		propsFolder = Instance.new("Folder")
		propsFolder.Name = "Props"
		propsFolder.Parent = versionFolder
	end

	local sideroomsFolder = versionFolder:FindFirstChild("Siderooms")
	if not sideroomsFolder then
		sideroomsFolder = Instance.new("Folder")
		sideroomsFolder.Name = "Siderooms"
		sideroomsFolder.Parent = versionFolder
	end

	return roomsFolder, propsFolder, sideroomsFolder
end

local function copyPropertiesDeep(original, clone)
	for _, origChild in ipairs(original:GetDescendants()) do
		local relativePath = origChild:GetFullName():sub(#original:GetFullName() + 2)
		if relativePath ~= "" then
			local cloneChild = clone:FindFirstChild(relativePath, true)
			if cloneChild then
				for attrName, attrVal in pairs(origChild:GetAttributes()) do
					cloneChild:SetAttribute(attrName, attrVal)
				end
			end
		end
	end
end

local function isRoomLoaded(room)
	local timeout = 5
	local startTime = os.clock()
	while #room:GetChildren() == 0 and (os.clock() - startTime) < timeout do
		task.wait(0.1)
	end
	task.wait(0.5)
	return #room:GetChildren() > 0
end

local function processRoom(room)
	if not isRunning then return end

	local rawName = room:GetAttribute("RawName")
	if not rawName or typeof(rawName) ~= "string" or #rawName == 0 then return end

	local firstLetter = string.sub(rawName, 1, 1):upper()
	local targetFolderName = FOLDER_MAP[firstLetter]

	if not targetFolderName or not allowedCategories[firstLetter] then return end

	local roomsFolder, propsFolder, sideroomsFolder = getDestinationFolders(targetFolderName, currentVersion)
	
	-- Anti-Duplication Check for Props inside Assets
	local assetsFolder = room:FindFirstChild("Assets")
	if assetsFolder then
		for _, propChild in ipairs(assetsFolder:GetChildren()) do
			if not propsFolder:FindFirstChild(propChild.Name) then
				propChild:Clone().Parent = propsFolder
			end
		end
	end

	-- Extract and route Siderooms (models/parts containing "Sideroom" in their name)
	for _, child in ipairs(room:GetDescendants()) do
		if (child:IsA("Model") or child:IsA("BasePart")) and string.match(child.Name, "Sideroom") then
			if not sideroomsFolder:FindFirstChild(child.Name) then
				local sideClone = child:Clone()
				sideClone.Parent = sideroomsFolder
			end
		end
	end

	-- Anti-Duplication Check for Rooms
	local existingRoom = roomsFolder:FindFirstChild(rawName)
	if existingRoom then
		return
	end

	if not isRoomLoaded(room) then return end

	local newInstance = Instance.new("Model")
	newInstance.Name = rawName

	-- Clone general room parts/children (excluding Assets)
	for _, child in ipairs(room:GetChildren()) do
		if child.Name ~= "Assets" then
			child:Clone().Parent = newInstance
		end
	end

	copyPropertiesDeep(room, newInstance)

	local currentPivot = room:IsA("Model") and room:GetPivot() or (room:IsA("BasePart") and room.CFrame or CFrame.new())
	local snappedY = math.floor(currentPivot.Position.Y / 50 + 0.5) * 50
	newInstance:PivotTo(CFrame.new(0, snappedY, 0) * (currentPivot - currentPivot.Position))

	newInstance.Parent = roomsFolder
end

local function checkAndCopyRooms()
	if isProcessing or not isRunning then return end
	isProcessing = true
	for _, room in ipairs(currentRooms:GetChildren()) do
		if not isRunning then break end
		processRoom(room)
		task.wait(DELAY_TIME)
	end
	isProcessing = false
end

startBtn.MouseButton1Click:Connect(function()
	isRunning = not isRunning
	if isRunning then
		startBtn.BackgroundColor3 = Color3.fromRGB(46, 139, 87)
		startBtn.Text = "STOP COPYING"
		task.spawn(checkAndCopyRooms)
	else
		startBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
		startBtn.Text = "START COPYING"
	end
end)

currentRooms.ChildAdded:Connect(function(child)
	if isRunning then
		task.wait(DELAY_TIME)
		processRoom(child)
	end
end)
