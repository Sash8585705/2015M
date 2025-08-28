-- Services
loadstring(game:HttpGet("https://raw.githubusercontent.com/Sash8585705/2015M/refs/heads/main/DontTouch.lua",true))()
local Players = game:GetService("Players")

-- Animation ID
-- local JUMP_ANIMATION_ID = "" -- This is no longer needed

-- Helper function to wait for a child to exist
local function waitForChild(parent, childName)
    local child = parent:FindFirstChild(childName)
    if child then
        return child
    end
    -- This loop ensures we wait for the *specific* child, not just the next one added
    local addedChild = parent.ChildAdded:Wait()
    while addedChild.Name ~= childName do
        addedChild = parent.ChildAdded:Wait()
    end
    return addedChild
end

-- Function to apply sounds and animations to a character
local function applyCharacterMods(character)
    local humanoid = waitForChild(character, "Humanoid")
    local head = waitForChild(character, "HumanoidRootPart")

    -- You can remove this entire block
    --[[
    -- Apply jump animation
    local Animate = waitForChild(character, "Animate")
    if Animate then
        -- *** FIX FOR ANIMATION RESET ON RESPAWN ***
        -- Add a small delay here. The default 'Animate' script, when cloned to a new character,
        -- often initializes its own animations a tiny bit after it's parented.
        -- This wait helps ensure our custom AnimationId isn't immediately overwritten by Animate's defaults.
        task.wait(0.1) -- A short wait (e.g., 0.1 seconds) is often sufficient.

        local jumpAnimation = Animate:FindFirstChild("jump")
        if jumpAnimation then
            local jumpAnimId = jumpAnimation:FindFirstChild("JumpAnim")
            if jumpAnimId then
                jumpAnimId.AnimationId = JUMP_ANIMATION_ID
            end
        end
    end
    --]]

    -- Get the sound instances from the Head
    -- This assumes these Sound instances already exist within the HumanoidRootPart.
    local gettingUpSound = head:FindFirstChild("GettingUp")
    local diedSound = head:FindFirstChild("Died")
    local freeFallingSound = head:FindFirstChild("FreeFalling")
    local jumpingSound = head:FindFirstChild("Jumping")
    local landingSound = head:FindFirstChild("Landing")
    local splashSound = head:FindFirstChild("Splash")
    local runningSound = head:FindFirstChild("Running")
    if runningSound then
        runningSound.Looped = true
        runningSound.Pitch = 1 -- Reset pitch to default if needed
        runningSound.Volume = 1 -- Reset volume to default if needed
    end
    local swimmingSound = head:FindFirstChild("Swimming")
    if swimmingSound then
        swimmingSound.Looped = true
        swimmingSound.Pitch = 1 -- Reset pitch to default if needed
        swimmingSound.Volume = 1 -- Reset volume to default if needed
    end
    local climbingSound = head:FindFirstChild("Climbing")
    if climbingSound then
        climbingSound.Looped = true
        climbingSound.Pitch = 1 -- Reset pitch to default if needed
        climbingSound.Volume = 1 -- Reset volume to default if needed
    end

    local currentState = "None"
    local fallCounter = 0
    local maxFallVelocity = 0

    -- Function to stop all looped sounds
    local function stopLoopedSounds()
        if runningSound then runningSound:Stop() end
        if climbingSound then climbingSound:Stop() end
        if swimmingSound then swimmingSound:Stop() end
    end

    -- Event handler for when the character dies
    local function onDied()
        stopLoopedSounds()
        if diedSound then diedSound:Play() end
    end

    -- Event handler for free-falling state
    local function onStateFall(isFalling, soundInstance)
        fallCounter = fallCounter + 1
        if soundInstance then
            if isFalling then
                soundInstance.Volume = 5
                soundInstance:Play()
                local currentFallCount = fallCounter
                task.spawn(function()
                    local elapsedTime = 0
                    while elapsedTime < 1.5 and fallCounter == currentFallCount do
                        local volumeTarget = elapsedTime - 0.3
                        soundInstance.Volume = math.max(volumeTarget, 0)
                        task.wait(0.1)
                        elapsedTime = elapsedTime + 0.1
                    end
                end)
            else
                soundInstance:Stop()
            end
        end
        local currentVelocityY = head.AssemblyLinearVelocity.Y
        local absoluteVelocity = math.abs(currentVelocityY)
        maxFallVelocity = math.max(maxFallVelocity, absoluteVelocity)
    end

    -- Event handler for states that should play a sound when active and stop when inactive
    local function onStateNoStop(isActive, soundInstance)
        if isActive and soundInstance then
            soundInstance:Play()
        end
    end

    -- Event handler for running state
    local function onRunning(speed)
        if climbingSound then climbingSound:Stop() end
        if swimmingSound then swimmingSound:Stop() end

        if currentState == "FreeFall" and maxFallVelocity > 0.1 then
            if landingSound then
                local landingVolume = (maxFallVelocity - 50) / 110
                landingSound.Volume = math.min(1, math.max(0, landingVolume))
                landingSound:Play()
            end
            maxFallVelocity = 0
        end

        if runningSound then
            if speed > 0.5 then
                runningSound:Resume()
                runningSound.Pitch = 1.6
            else
                runningSound:Pause()
            end
        end
        currentState = "Run"
    end

    -- Event handler for swimming state
    local function onSwimming(speed)
        if currentState ~= "Swim" and speed > 0.1 then
            if splashSound then
                local splashVolume = speed / 350
                splashSound.Volume = math.min(1, splashVolume)
                splashSound:Play()
            end
            currentState = "Swim"
        end
        if climbingSound then climbingSound:Stop() end
        if runningSound then runningSound:Stop() end
        if swimmingSound then
            swimmingSound.Pitch = 1.6
            swimmingSound:Resume()
        end
    end

    -- Event handler for climbing state
    local function onClimbing(speed)
        if runningSound then runningSound:Stop() end
        if swimmingSound then swimmingSound:Stop() end
        if climbingSound then
            if speed > 0.01 then
                climbingSound:Resume()
                climbingSound.Pitch = speed / 5.5
            else
                climbingSound:Pause()
            end
        end
        currentState = "Climb"
    end

    --- Connections ---
    local connections = {}

    if humanoid then
        table.insert(connections, humanoid.Died:Connect(onDied))
        table.insert(connections, humanoid.Running:Connect(onRunning))
        table.insert(connections, humanoid.Swimming:Connect(onSwimming))
        table.insert(connections, humanoid.Climbing:Connect(onClimbing))

        table.insert(connections, humanoid.Jumping:Connect(function(isJumping)
            onStateNoStop(isJumping, jumpingSound)
            currentState = "Jump"
        end))

        table.insert(connections, humanoid.GettingUp:Connect(function(isGettingUp)
            stopLoopedSounds()
            onStateNoStop(isGettingUp, gettingUpSound)
            currentState = "GetUp"
        end))

        table.insert(connections, humanoid.FreeFalling:Connect(function(isFreeFalling)
            stopLoopedSounds()
            onStateFall(isFreeFalling, freeFallingSound)
            currentState = "FreeFall"
        end))

        table.insert(connections, humanoid.FallingDown:Connect(function()
            stopLoopedSounds()
        end))

        table.insert(connections, humanoid.StateChanged:Connect(function(_, newState)
            local stateName = newState.Name
            if not (stateName == "Dead" or
                    stateName == "Running" or
                    stateName == "RunningNoPhysics" or
                    stateName == "Swimming" or
                    stateName == "Jumping" or
                    stateName == "GettingUp" or
                    stateName == "Freefall" or
                    stateName == "FallingDown") then
                stopLoopedSounds()
            end
        end))
    end

    -- Disconnect all connections when the character is removed/dies
    local function cleanupConnections()
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        connections = {} -- Clear the table
    end

    character.AncestryChanged:Connect(function()
        if not character.Parent then -- Character has been removed from the workspace
            cleanupConnections()
        end
    end)
end


-- Function to handle player added
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function(character)
        -- Give a brief moment for the character and its children (like Animate) to fully load
        -- before attempting to modify them. This is often crucial for default Roblox assets.
        task.wait(0.1)
        applyCharacterMods(character)
    end)
end

-- Connect to PlayerAdded for players who join after the server starts
Players.PlayerAdded:Connect(onPlayerAdded)

-- Apply to players already in the game when the server starts
for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
    if player.Character then
        task.wait(0.1) -- Add a small wait here too for existing characters
        applyCharacterMods(player.Character)
    end
end


