local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

_G.AnimeLifeSmartAutofarm = false
_G.ActionDelay = 7.0 
local isMinimized = false

local isJobFinishedByGame = false

local sleepRemote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Objects"):WaitForChild("Members"):WaitForChild("Bed"):WaitForChild("Use")
local startJobRemote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Jobs"):WaitForChild("StartJob")

local noclipConnection = nil

local function notify(title, text)
	StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = 3
	})
end

local function setNoClip(state)
	if state then
		if not noclipConnection then
			noclipConnection = RunService.Stepped:Connect(function()
				local char = LocalPlayer.Character
				if char then
					for _, part in ipairs(char:GetDescendants()) do
						if part:IsA("BasePart") and part.CanCollide then
							part.CanCollide = false
						end
					end
				end
			end)
			print("[NoClip] Continuous mode ACTIVATED")
		end
	else
		if noclipConnection then
			noclipConnection:Disconnect()
			noclipConnection = nil
			local char = LocalPlayer.Character
			if char then
				for _, part in ipairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = true
					end
				end
			end
			print("[NoClip] Deactivated")
		end
	end
end

local function physicsTeleport(targetVector)
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local wasNoClip = noclipConnection ~= nil
    if not wasNoClip then
        setNoClip(true)
    end

    local vehicle = hum and hum.SeatPart and hum.SeatPart.Parent
    local targetPos = targetVector + Vector3.new(0, 4, 0)
    local safeCFrame = CFrame.new(targetPos) * CFrame.Angles(0, 0, 0)

    if vehicle then
        for _, part in pairs(vehicle:GetDescendants()) do
            if part:IsA("BasePart") then
                part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
        end
        vehicle:PivotTo(safeCFrame)
        task.wait(0.05)
        if vehicle:FindFirstChild("HumanoidRootPart") then
            vehicle.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
        end
    else
        root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        char:PivotTo(safeCFrame)
        task.wait(0.1)
        if root.Position.Y < targetVector.Y - 0.5 then
            char:PivotTo(CFrame.new(targetVector + Vector3.new(0, 7, 0)))
        end
    end

    if not wasNoClip then
        setNoClip(false)
    end
end

LocalPlayer.Idled:Connect(function()
    if _G.AnimeLifeSmartAutofarm then
        VirtualUser:Button2Down(Vector3.new(0,0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector3.new(0,0,0), workspace.CurrentCamera.CFrame)
    end
end)

local function findMyBed()
	local housingUnits = workspace:FindFirstChild("HousingUnits")
	if not housingUnits then return nil, nil end
	
	for _, zone in ipairs(housingUnits:GetChildren()) do
		local units = zone:FindFirstChild("Units")
		if units then
			for _, unit in ipairs(units:GetChildren()) do
				local home = unit:FindFirstChild("Home")
				local furniture = home and home:FindFirstChild("Furniture")
				if furniture then
					for _, item in ipairs(furniture:GetChildren()) do
						local server = item:FindFirstChild("Server")
						local seat = server and server:FindFirstChild("Seat")
						
						if seat and seat:IsA("Seat") and seat.Occupant == nil then 
							return item, seat 
						end
					end
				end
			end
		end
	end
	return nil, nil
end

local function clickUiButtonByKeywords(keywords)
	local clicked = false
	local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then return false end

	for _, obj in ipairs(playerGui:GetDescendants()) do
		if (obj:IsA("TextButton") or obj:IsA("ImageButton")) then
			local targetText = string.lower(obj:IsA("TextButton") and obj.Text or "")
			local targetName = string.lower(obj.Name)
			
			local matchFound = false
			for _, word in ipairs(keywords) do
				if string.find(targetName, word) or string.find(targetText, word) then
					matchFound = true
					break
				end
			end
			
			if matchFound then
				if obj.Visible and obj.AbsoluteSize.X > 0 and obj.AbsoluteSize.Y > 0 then
					if firesignal then
						firesignal(obj.MouseButton1Click)
						firesignal(obj.Activated)
					elseif getconnections then
						for _, connection in ipairs(getconnections(obj.MouseButton1Click)) do connection:Fire() end
						for _, connection in ipairs(getconnections(obj.Activated)) do connection:Fire() end
					else
						obj:Release()
						obj:Press()
					end
					clicked = true
				end
			end
		end
	end
	return clicked
end

local jobEndedRemote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("Jobs"):WaitForChild("JobEnded")
jobEndedRemote.OnClientEvent:Connect(function(reason)
	if _G.AnimeLifeSmartAutofarm and reason == "Energy" then
		isJobFinishedByGame = true
		print("[Event] Job ended automatically due to low energy.")
	end
end)

local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
	local method = getnamecallmethod()
	
	if method == "FireServer" and self.Name == "QuitJob" then
		if _G.AnimeLifeSmartAutofarm then
			isJobFinishedByGame = true
			print("[Spy] QuitJob signal caught! Manual delivery finish detected.")
		end
	end
	
	return oldNamecall(self, ...)
end)

if CoreGui:FindFirstChild("AnimeLife_HisokaHub_Pizza") then
	CoreGui:FindFirstChild("AnimeLife_HisokaHub_Pizza"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AnimeLife_HisokaHub_Pizza"
ScreenGui.Parent = CoreGui 

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 255) 
MainFrame.Position = UDim2.new(0.15, 0, 0.4, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui

local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = Color3.fromRGB(230, 126, 34)
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "Anime Life: Auto farm pizza delivery man"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

local MiniBtn = Instance.new("TextButton")
MiniBtn.Size = UDim2.new(0, 35, 1, 0)
MiniBtn.Position = UDim2.new(1, -35, 0, 0)
MiniBtn.BackgroundColor3 = Color3.fromRGB(211, 84, 0)
MiniBtn.BorderSizePixel = 0
MiniBtn.Text = "_"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.Font = Enum.Font.SourceSansBold
MiniBtn.TextSize = 16
MiniBtn.Parent = TitleBar

local ContentFrame = Instance.new("Frame")
ContentFrame.Size = UDim2.new(1, 0, 1, -35)
ContentFrame.Position = UDim2.new(0, 0, 0, 35)
ContentFrame.BackgroundTransparency = 1
ContentFrame.BorderSizePixel = 0
ContentFrame.Parent = MainFrame

local DelayLabel = Instance.new("TextLabel")
DelayLabel.Size = UDim2.new(0, 110, 0, 30)
DelayLabel.Position = UDim2.new(0, 12, 0, 10)
DelayLabel.BackgroundTransparency = 1
DelayLabel.Text = "Set Delay (sec):"
DelayLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
DelayLabel.Font = Enum.Font.SourceSans
DelayLabel.TextSize = 13
DelayLabel.TextXAlignment = Enum.TextXAlignment.Left
DelayLabel.Parent = ContentFrame

local DelayInput = Instance.new("TextBox")
DelayInput.Size = UDim2.new(0, 80, 0, 25)
DelayInput.Position = UDim2.new(0, 145, 0, 12)
DelayInput.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
DelayInput.Text = tostring(_G.ActionDelay)
DelayInput.TextColor3 = Color3.fromRGB(255, 255, 255)
DelayInput.Font = Enum.Font.Code
DelayInput.TextSize = 12
DelayInput.BorderSizePixel = 0
DelayInput.Parent = ContentFrame

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(1, -24, 0, 40)
ToggleBtn.Position = UDim2.new(0, 12, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
ToggleBtn.Text = "START AUTOFARM"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.Font = Enum.Font.SourceSansBold
ToggleBtn.TextSize = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent = ContentFrame

local LogLabel = Instance.new("TextLabel")
LogLabel.Size = UDim2.new(1, -24, 0, 25)
LogLabel.Position = UDim2.new(0, 12, 0, 95)
LogLabel.BackgroundTransparency = 1
LogLabel.Text = "Status: Idle"
LogLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
LogLabel.TextSize = 12
LogLabel.Parent = ContentFrame

local InfoLabel = Instance.new("TextLabel")
InfoLabel.Size = UDim2.new(1, -24, 0, 80)
InfoLabel.Position = UDim2.new(0, 12, 0, 125)
InfoLabel.BackgroundTransparency = 1
InfoLabel.Text = "Notice: The game may pay differently depending on how fast the farm is, and the amount itself fluctuates."
InfoLabel.TextColor3 = Color3.fromRGB(241, 196, 15) 
InfoLabel.Font = Enum.Font.SourceSansItalic
InfoLabel.TextSize = 11
InfoLabel.TextWrapped = true 
InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
InfoLabel.Parent = ContentFrame

local CreditLabel = Instance.new("TextLabel")
CreditLabel.Size = UDim2.new(0, 100, 0, 20)
CreditLabel.Position = UDim2.new(1, -110, 1, -18) 
CreditLabel.BackgroundTransparency = 1
CreditLabel.Text = "by hisoka hub"
CreditLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
CreditLabel.TextTransparency = 0.75 
CreditLabel.Font = Enum.Font.SourceSansItalic
CreditLabel.TextSize = 11
CreditLabel.TextXAlignment = Enum.TextXAlignment.Right
CreditLabel.Parent = ContentFrame

MiniBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        ContentFrame.Visible = false 
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 35), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
        MiniBtn.Text = "+"
    else
        MainFrame:TweenSize(UDim2.new(0, 250, 0, 255), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.2, true)
        task.wait(0.15) 
        ContentFrame.Visible = true 
        MiniBtn.Text = "_"
    end
end)

DelayInput.FocusLost:Connect(function(enterPressed)
    local checkNum = tonumber(DelayInput.Text)
    if checkNum and checkNum > 0 then
        _G.ActionDelay = checkNum
    else
        DelayInput.Text = tostring(_G.ActionDelay)
    end
end)

local function runFullComboLoop()
	local compRegion = workspace:FindFirstChild("CompletionRegion")
	local driveZone = compRegion and compRegion:FindFirstChild("DriveZone")

	if driveZone and driveZone:IsA("BasePart") and driveZone.Position.Y > -50 then
		startJobRemote:FireServer("PizzaDelivery")
		task.wait(0.5)

		while not isJobFinishedByGame and _G.AnimeLifeSmartAutofarm do
			LogLabel.Text = "Status: Delivering Pizza..."
			
			local zoneFound = false
			local zoneVector = nil
			
			pcall(function()
				local currentCompRegion = workspace:FindFirstChild("CompletionRegion")
				if currentCompRegion then
					local currentDriveZone = currentCompRegion:FindFirstChild("DriveZone")
					if currentDriveZone and currentDriveZone:IsA("BasePart") then
						if currentDriveZone.Position.Y > -50 then
							zoneVector = currentDriveZone.Position
							zoneFound = true
						end
					end
				end
			end)
			
			if zoneFound and zoneVector then
				LogLabel.Text = "Status: Teleporting to DriveZone"
				physicsTeleport(zoneVector)
			else
				LogLabel.Text = "Status: Target missing. Returning to base..."
				local pizzaBase = nil
				for _, zone in pairs(workspace:GetDescendants()) do
					if zone:IsA("BasePart") and (zone.Name:lower():match("pizza") or zone.Name:lower():match("delivery")) then
						if zone.Size.Magnitude > 4 and not zone:IsDescendantOf(workspace:FindFirstChild("CompletionRegion") or workspace) then
							pizzaBase = zone
							break
						end
					end
				end
				if pizzaBase then 
					physicsTeleport(pizzaBase.Position) 
				end
			end
			
			local startWait = tick()
			while tick() - startWait < _G.ActionDelay do
				if not _G.AnimeLifeSmartAutofarm or isJobFinishedByGame then break end
				local timeLeft = string.format("%.1f", _G.ActionDelay - (tick() - startWait))
				LogLabel.Text = "Next Delivery In: " .. timeLeft .. "s"
				task.wait(0.1)
			end
		end

		if not _G.AnimeLifeSmartAutofarm then return end

		task.wait(0.5) 
		LogLabel.Text = "Status: Claiming Money..."
		
		clickUiButtonByKeywords({"claim", "bank"})
		task.wait(0.3) 
		clickUiButtonByKeywords({"claim", "bank"})
		task.wait(0.5) 
		
		clickUiButtonByKeywords({"close", "exit", "close"})
		task.wait(1.5)

		if not _G.AnimeLifeSmartAutofarm then return end
		
		local sleepSuccess = false
		while not sleepSuccess and _G.AnimeLifeSmartAutofarm do
			character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			humanoid = character:WaitForChild("Humanoid")
			rootPart = character:WaitForChild("HumanoidRootPart")

			LogLabel.Text = "Status: Finding Free Bed..."
			local bedFrame, bedSeat = findMyBed()
			if bedFrame and bedSeat then
				physicsTeleport(bedSeat.Position)
				task.wait(0.5)

				local sitAttempts = 0
				local satDown = false
				while sitAttempts < 4 and not satDown and _G.AnimeLifeSmartAutofarm do
					bedSeat:Sit(humanoid)
					task.wait(0.3)
					if humanoid and humanoid.SeatPart == bedSeat then
						satDown = true
					else
						sitAttempts = sitAttempts + 1
					end
				end

				if satDown then
					sleepRemote:FireServer(bedFrame, bedSeat)
					local fullSleepInterrupted = false
					for i = 20, 1, -1 do
						if not _G.AnimeLifeSmartAutofarm then break end
						if humanoid and not humanoid.SeatPart then
							bedSeat:Sit(humanoid)
							task.wait(0.2)
							if humanoid and not humanoid.SeatPart then
								fullSleepInterrupted = true
								break
							end
						end
						LogLabel.Text = "Energy Regeneration: " .. i .. "s"
						task.wait(1)
					end
					
					if not fullSleepInterrupted and _G.AnimeLifeSmartAutofarm then
						sleepSuccess = true
						if humanoid and humanoid.Parent then
							humanoid.Sit = false 
							humanoid.PlatformStand = false
							rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
							humanoid.Jump = true 
						end
						task.wait(0.5) 
					else
						LogLabel.Text = "Status: Sleep pre-empted! Retrying..."
						task.wait(1)
					end
				else
					LogLabel.Text = "Status: Failed to sit on bed. Retrying..."
					task.wait(1)
				end
			else
				LogLabel.Text = "Status: No free beds. Waiting..."
				task.wait(3)
			end
		end

	else
		local sleepSuccess = false
		while not sleepSuccess and _G.AnimeLifeSmartAutofarm do
			character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			humanoid = character:WaitForChild("Humanoid")
			rootPart = character:WaitForChild("HumanoidRootPart")

			LogLabel.Text = "Status: Finding Free Bed..."
			local bedFrame, bedSeat = findMyBed()
			if bedFrame and bedSeat then
				physicsTeleport(bedSeat.Position)
				task.wait(0.5)

				local sitAttempts = 0
				local satDown = false
				while sitAttempts < 4 and not satDown and _G.AnimeLifeSmartAutofarm do
					bedSeat:Sit(humanoid)
					task.wait(0.3)
					if humanoid and humanoid.SeatPart == bedSeat then
						satDown = true
					else
						sitAttempts = sitAttempts + 1
					end
				end

				if satDown then
					sleepRemote:FireServer(bedFrame, bedSeat)
					local fullSleepInterrupted = false
					for i = 20, 1, -1 do
						if not _G.AnimeLifeSmartAutofarm then break end
						if humanoid and not humanoid.SeatPart then
							bedSeat:Sit(humanoid)
							task.wait(0.2)
							if humanoid and not humanoid.SeatPart then
								fullSleepInterrupted = true
								break
							end
						end
						LogLabel.Text = "Energy Regeneration: " .. i .. "s"
						task.wait(1)
					end
					
					if not fullSleepInterrupted and _G.AnimeLifeSmartAutofarm then
						sleepSuccess = true
						if humanoid and humanoid.Parent then
							humanoid.Sit = false 
							humanoid.PlatformStand = false
							rootPart.CFrame = rootPart.CFrame + Vector3.new(0, 5, 0)
							humanoid.Jump = true 
						end
						task.wait(0.5) 
					else
						LogLabel.Text = "Status: Sleep pre-empted! Retrying..."
						task.wait(1)
					end
				else
					LogLabel.Text = "Status: Failed to sit on bed. Retrying..."
					task.wait(1)
				end
			else
				LogLabel.Text = "Status: No free beds. Waiting..."
				task.wait(3)
			end
		end

		if not _G.AnimeLifeSmartAutofarm then return end

		isJobFinishedByGame = false

		LogLabel.Text = "Status: Starting Job..."
		startJobRemote:FireServer("PizzaDelivery")
		task.wait(0.5)

		while not isJobFinishedByGame and _G.AnimeLifeSmartAutofarm do
			LogLabel.Text = "Status: Delivering Pizza..."
			
			local zoneFound = false
			local zoneVector = nil
			
			pcall(function()
				local currentCompRegion = workspace:FindFirstChild("CompletionRegion")
				if currentCompRegion then
					local currentDriveZone = currentCompRegion:FindFirstChild("DriveZone")
					if currentDriveZone and currentDriveZone:IsA("BasePart") then
						if currentDriveZone.Position.Y > -50 then
							zoneVector = currentDriveZone.Position
							zoneFound = true
						end
					end
				end
			end)
			
			if zoneFound and zoneVector then
				LogLabel.Text = "Status: Teleporting to DriveZone"
				physicsTeleport(zoneVector)
			else
				LogLabel.Text = "Status: Target missing. Returning to base..."
				local pizzaBase = nil
				for _, zone in pairs(workspace:GetDescendants()) do
					if zone:IsA("BasePart") and (zone.Name:lower():match("pizza") or zone.Name:lower():match("delivery")) then
						if zone.Size.Magnitude > 4 and not zone:IsDescendantOf(workspace:FindFirstChild("CompletionRegion") or workspace) then
							pizzaBase = zone
							break
						end
					end
				end
				if pizzaBase then 
					physicsTeleport(pizzaBase.Position) 
				end
			end
			
			local startWait = tick()
			while tick() - startWait < _G.ActionDelay do
				if not _G.AnimeLifeSmartAutofarm or isJobFinishedByGame then break end
				local timeLeft = string.format("%.1f", _G.ActionDelay - (tick() - startWait))
				LogLabel.Text = "Next Delivery In: " .. timeLeft .. "s"
				task.wait(0.1)
			end
		end

		if not _G.AnimeLifeSmartAutofarm then return end

		task.wait(0.5) 
		LogLabel.Text = "Status: Claiming Money..."
		
		clickUiButtonByKeywords({"claim", "bank"})
		task.wait(0.3) 
		clickUiButtonByKeywords({"claim", "bank"})
		task.wait(0.5) 
		
		clickUiButtonByKeywords({"close", "exit", "close"})
		task.wait(1.5)
	end
end

ToggleBtn.MouseButton1Click:Connect(function()
    _G.AnimeLifeSmartAutofarm = not _G.AnimeLifeSmartAutofarm
    if _G.AnimeLifeSmartAutofarm then
        local checkNum = tonumber(DelayInput.Text)
        if checkNum and checkNum > 0 then _G.ActionDelay = checkNum end
        
        setNoClip(true)
        
        ToggleBtn.Text = "AUTOFARM: ON"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(46, 204, 113)
        
        task.spawn(function()
			while _G.AnimeLifeSmartAutofarm do
				local success, err = pcall(function()
					runFullComboLoop()
				end)
				if not success then
					warn("Critical farm loop error: ", err)
					task.wait(2)
				end
			end
        end)
    else
        setNoClip(false)
        ToggleBtn.Text = "START AUTOFARM"
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(150, 30, 30)
        LogLabel.Text = "Status: Stopped"
    end
end)
