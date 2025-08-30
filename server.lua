-- ============================================================================
-- Enhanced FiveM Kick Script - Main Server File (Discord Only)
-- Discord permissions only, no QBCore dependency for permissions
-- ============================================================================

-- ============================================================================
-- System Initialization
-- ============================================================================

-- Initialize all modules on resource start with comprehensive error handling
CreateThread(function()
    local success, error = pcall(function()
        Utils.LogToConsole("info", "Starting FiveM Kick System v2.0 (Discord Only)...")

        -- Check if all required modules are loaded
        if not Utils then
            error("Utils module not loaded")
        end

        if not Permissions then
            error("Permissions module not loaded")
        end

        if not Discord then
            error("Discord module not loaded")
        end

        -- Initialize permission system
        if not Permissions.Initialize() then
            error("Failed to initialize permission system")
        end

        -- Initialize Discord webhook system
        if not Discord.Initialize() then
            error("Failed to initialize Discord system")
        end

        Utils.LogToConsole("info", "FiveM Kick System initialized successfully!")

        -- Test system functionality
        Utils.LogToConsole("info", "Running system self-test...")

        -- Test timestamp generation
        local timestamp = Utils.GetHongKongTimestamp()
        if not timestamp then
            Utils.LogError("Self-test failed: Timestamp generation")
        else
            Utils.LogToConsole("info", "Self-test passed: Timestamp generation - " .. timestamp)
        end

        -- Test configuration access
        if Config and Config.AllowedDiscordIDs then
            Utils.LogToConsole("info", "Self-test passed: Configuration access")
        else
            Utils.LogError("Self-test failed: Configuration access")
        end

        Utils.LogToConsole("info", "System self-test completed")
    end)

    if not success then
        print("^1[CRITICAL ERROR] FiveM Kick System initialization failed: " .. tostring(error))
        print("^1[CRITICAL ERROR] The kick system will not function properly!")
        print("^1[CRITICAL ERROR] Please check your configuration and module files.")
    end
end)

-- ============================================================================
-- Helper Functions
-- ============================================================================

-- Send error message to player
local function SendErrorMessage(source, message)
    TriggerClientEvent("chat:addMessage", source, {
        args = { "^1[Kick System]", message }
    })
end

-- Send success message to player
local function SendSuccessMessage(source, message)
    TriggerClientEvent("chat:addMessage", source, {
        args = { "^2[Kick System]", message }
    })
end

-- Execute kick with animation
-- This function handles the two-phase kick process:
-- 1. Trigger client-side kidnapping animation
-- 2. Actually kick the player after animation completes
local function ExecuteKickWithAnimation(targetId, reason)
    -- Validate that the target player exists and is connected
    if not Utils.ValidatePlayerId(targetId) then
        Utils.LogError("ExecuteKickWithAnimation: Invalid target ID " .. tostring(targetId))
        return false
    end

    -- Phase 1: Trigger client-side animation
    -- This sends an event to the target player to start the kidnapping scene
    TriggerClientEvent("kick:ilv-scripts:KickKidnapScene", targetId)

    -- Phase 2: Schedule the actual kick after animation duration
    -- The delay allows the animation to play fully before disconnecting the player
    SetTimeout(Config.Commands.kickDelayMs or 10000, function()
        -- Final validation before kick (player might have disconnected during animation)
        if Utils.ValidatePlayerId(targetId) then
            DropPlayer(targetId, reason or "You have been kicked from the server.")
        else
            Utils.LogToConsole("warn", "Player " .. targetId .. " disconnected before kick could be executed")
        end
    end)

    return true
end

-- ============================================================================
-- Enhanced /kicknew Command (Discord Only)
-- ============================================================================

RegisterCommand('kicknew', function(source, args, rawCommand)
    Utils.LogToConsole("info", "Player " .. source .. " attempting /kicknew command")

    -- Get authorization result
    local authResult = Permissions.GetAuthorizationResult(source, "/kicknew")

    -- Check if player is authorized
    if not authResult.isAuthorized then
        Utils.LogToConsole("warn",
            "Unauthorized /kicknew attempt by " .. (authResult.playerData and authResult.playerData.name or "Unknown"))

        -- Send error message to player
        SendErrorMessage(source, "Access denied: " .. authResult.reason)

        -- Log unauthorized attempt to Discord
        if authResult.playerData then
            local targetInfo = args[1] and ("Target ID: " .. args[1]) or "No target specified"
            Discord.SendUnauthorizedAttempt(authResult.playerData, "/kicknew", targetInfo)
        end

        return
    end

    -- Validate target ID
    local targetId = tonumber(args[1])
    if not targetId then
        SendErrorMessage(source, "Usage: /kicknew [player_id]")
        return
    end

    if not Utils.ValidatePlayerId(targetId) then
        SendErrorMessage(source, "Player ID " .. targetId .. " not found or not connected")
        return
    end

    -- Warn about self-kick but allow it (useful for testing)
    if targetId == source then
        SendSuccessMessage(source, "Warning: You are about to kick yourself!")
        Utils.LogToConsole("warn", "Admin " .. authResult.playerData.name .. " is kicking themselves (self-kick)")
    end

    -- Get target player data
    local targetData = Utils.GetPlayerData(targetId)
    if not targetData then
        SendErrorMessage(source, "Could not retrieve target player data")
        return
    end

    -- Execute the kick
    local success = ExecuteKickWithAnimation(targetId, "You have been kicked by an administrator.")

    if success then
        -- Send success message to admin
        SendSuccessMessage(source, "Successfully kicked " .. targetData.name .. " (ID: " .. targetId .. ")")

        -- Log successful action to Discord
        Discord.LogIndividualKick(authResult.playerData, targetData)

        Utils.LogToConsole("info", string.format(
            "Player %s (ID: %d) kicked by admin %s (ID: %d)",
            targetData.name, targetId, authResult.playerData.name, source
        ))
    else
        SendErrorMessage(source, "Failed to kick player")
    end
end, false)

-- ============================================================================
-- New /kicknewall Command (Mass Kick - Discord Only)
-- ============================================================================

RegisterCommand('kicknewall', function(source, args, rawCommand)
    Utils.LogToConsole("info", "Player " .. source .. " attempting /kicknewall command")

    -- Get authorization result
    local authResult = Permissions.GetAuthorizationResult(source, "/kicknewall")

    -- Check if player is authorized
    if not authResult.isAuthorized then
        Utils.LogToConsole("warn",
            "Unauthorized /kicknewall attempt by " .. (authResult.playerData and authResult.playerData.name or "Unknown"))

        -- Send error message to player
        SendErrorMessage(source, "Access denied: " .. authResult.reason)

        -- Log unauthorized attempt to Discord
        if authResult.playerData then
            Discord.SendUnauthorizedAttempt(authResult.playerData, "/kicknewall", "Mass kick attempt")
        end

        return
    end

    -- Check if "self" parameter is provided to include executor
    local includeSelf = args[1] and string.lower(args[1]) == "self"
    
    -- Get all connected players
    local playersToKick
    if includeSelf then
        playersToKick = Utils.GetConnectedPlayers() -- Don't exclude anyone
        Utils.LogToConsole("info", "Found " .. #playersToKick .. " players to kick (including executor)")
    else
        playersToKick = Utils.GetConnectedPlayers(source) -- Exclude executor
        Utils.LogToConsole("info", "Found " .. #playersToKick .. " players to kick (excluding executor)")
    end

    if #playersToKick == 0 then
        if includeSelf then
            SendErrorMessage(source, "No players found to kick")
        else
            SendSuccessMessage(source, "No other players to kick. Use '/kicknewall self' to kick yourself too.")
        end
        Utils.LogToConsole("info", "No players to kick")
        return
    end

    -- Log player list
    for i, playerId in ipairs(playersToKick) do
        local playerName = GetPlayerName(playerId) or "Unknown"
        Utils.LogToConsole("info", "Player to kick: " .. playerId .. " (" .. playerName .. ")")
    end

    -- Confirm the action
    SendSuccessMessage(source, "Starting mass kick of " .. #playersToKick .. " players...")
    Utils.LogToConsole("info", "Starting mass kick process...")

    -- Process kicks in batches to prevent server overload
    local batchSize = Config.Commands.massKickBatchSize or 5
    local batchDelay = Config.Commands.massKickBatchDelay or 2000
    local kickedCount = 0

    CreateThread(function()
        for i = 1, #playersToKick, batchSize do
            local batch = {}

            -- Create batch
            for j = i, math.min(i + batchSize - 1, #playersToKick) do
                table.insert(batch, playersToKick[j])
            end

            -- Process batch
            for _, playerId in ipairs(batch) do
                if Utils.ValidatePlayerId(playerId) then
                    local success = ExecuteKickWithAnimation(playerId, "Server cleared by administrator.")
                    if success then
                        kickedCount = kickedCount + 1
                    end
                end
            end

            -- Wait before next batch (except for last batch)
            if i + batchSize <= #playersToKick then
                Wait(batchDelay)
            end
        end

        -- Send final status message
        SendSuccessMessage(source, "Mass kick completed: " .. kickedCount .. " players kicked")

        Utils.LogToConsole("info", string.format(
            "Mass kick executed by admin %s (ID: %d) - %d players kicked",
            authResult.playerData.name, source, kickedCount
        ))

        -- Log successful mass kick to Discord
        Utils.LogToConsole("info", "Attempting to log mass kick to Discord...")
        Discord.LogMassKick(authResult.playerData, kickedCount)
    end)
end, false)

-- ============================================================================
-- Admin Commands for Testing and Management
-- ============================================================================

-- Command to check permission status
RegisterCommand('kickstatus', function(source, args, rawCommand)
    local authResult = Permissions.GetAuthorizationResult(source, "status check")

    if authResult.playerData then
        local statusMessage = string.format(
            "Permission Status:\n" ..
            "Discord ID: %s\n" ..
            "Discord Permission: %s\n" ..
            "Overall Status: %s\n" ..
            "System: Discord Only (No QBCore dependency)",
            authResult.playerData.discordId or "Not Found",
            authResult.hasDiscordPermission and "✓ Authorized" or "✗ Not Authorized",
            authResult.isAuthorized and "✓ AUTHORIZED" or "✗ NOT AUTHORIZED"
        )

        TriggerClientEvent("chat:addMessage", source, {
            args = { "^3[Kick System Status]", statusMessage }
        })

        -- Also log to console for easy copying
        Utils.LogToConsole("info", "Permission status for " .. authResult.playerData.name .. ":")
        Utils.LogToConsole("info", "Discord ID: " .. (authResult.playerData.discordId or "Not Found"))
        Utils.LogToConsole("info", "All identifiers: " .. table.concat(authResult.playerData.identifiers or {}, ", "))
    else
        SendErrorMessage(source, "Could not retrieve your player data")
    end
end, false)

-- Debug command to show all your identifiers (helps find Discord ID)
RegisterCommand('myids', function(source, args, rawCommand)
    local playerData = Utils.GetPlayerData(source)

    if playerData and playerData.identifiers then
        TriggerClientEvent("chat:addMessage", source, {
            args = { "^2[Your Identifiers]", "Check console for full list" }
        })

        Utils.LogToConsole("info", "=== Identifiers for " .. playerData.name .. " ===")
        for i, identifier in ipairs(playerData.identifiers) do
            Utils.LogToConsole("info", i .. ". " .. identifier)

            -- Highlight Discord ID
            if string.match(identifier, "^discord:") then
                Utils.LogToConsole("info", "   ^^ THIS IS YOUR DISCORD ID - Add this to Config.AllowedDiscordIDs")
            end
        end
        Utils.LogToConsole("info", "=== End of identifiers ===")
    else
        SendErrorMessage(source, "Could not retrieve your identifiers")
    end
end, false)

-- ============================================================================
-- Event Handlers
-- ============================================================================

-- Handle player connecting (for logging purposes)
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local source = source
    Utils.LogToConsole("info", "Player connecting: " .. name .. " (ID: " .. source .. ")")
end)

-- Handle player disconnecting
AddEventHandler('playerDropped', function(reason)
    local source = source
    local playerName = GetPlayerName(source)
    if playerName then
        Utils.LogToConsole("info",
            "Player disconnected: " .. playerName .. " (ID: " .. source .. ") - Reason: " .. reason)
    end
end)

-- ============================================================================
-- Global Error Handling
-- ============================================================================

-- Global error handler for uncaught exceptions
local function HandleGlobalError(errorMessage, stackTrace)
    Utils.LogError("UNCAUGHT ERROR: " .. tostring(errorMessage))
    if stackTrace then
        Utils.LogError("Stack trace: " .. tostring(stackTrace))
    end

    -- Try to send critical error to Discord if possible
    if Discord and Discord.IsWebhookConfigured() then
        local payload = Discord.BuildWebhookPayload(
            "🚨 Critical System Error",
            "The FiveM Kick System encountered an uncaught error:\n```" .. tostring(errorMessage) .. "```",
            16711680 -- Red color
        )

        Discord.SendWebhook(payload, function(success, response)
            if not success then
                Utils.LogError("Failed to send critical error to Discord: " .. tostring(response))
            end
        end)
    end
end

-- ============================================================================
-- System Health Monitoring
-- ============================================================================

-- Periodic health check
CreateThread(function()
    while true do
        Wait(300000) -- Check every 5 minutes

        local success, error = pcall(function()
            -- Check if all modules are still available
            if not Utils or not Permissions or not Discord then
                HandleGlobalError("One or more modules became unavailable during runtime")
                return
            end

            -- Check configuration integrity
            if not Config then
                HandleGlobalError("Configuration became unavailable during runtime")
                return
            end

            -- Test basic functionality
            local timestamp = Utils.GetHongKongTimestamp()
            if not timestamp then
                HandleGlobalError("Timestamp generation failed during health check")
                return
            end

            Utils.LogToConsole("info", "System health check passed - " .. timestamp)
        end)

        if not success then
            HandleGlobalError("Health check failed: " .. tostring(error))
        end
    end
end)

-- ============================================================================
-- Resource Stop Handler
-- ============================================================================

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        Utils.LogToConsole("info", "FiveM Kick System shutting down...")

        -- Send shutdown notification to Discord if configured
        if Discord and Discord.IsWebhookConfigured() then
            local payload = Discord.BuildWebhookPayload(
                "🔴 System Shutdown",
                "The FiveM Kick System is shutting down.\n\n**Time:** " .. Utils.GetHongKongTimestamp(),
                16776960 -- Orange color
            )

            Discord.SendWebhook(payload, function(success, response)
                if success then
                    Utils.LogToConsole("info", "Shutdown notification sent to Discord")
                else
                    Utils.LogError("Failed to send shutdown notification to Discord")
                end
            end)
        end
    end
end)
