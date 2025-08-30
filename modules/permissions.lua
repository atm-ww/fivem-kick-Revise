-- ============================================================================
-- Permission Management Module - Discord Only
-- Handles Discord-based permission checking for kick commands
-- ============================================================================

local Permissions = {}

-- ============================================================================
-- Core Permission Functions
-- ============================================================================

-- Get Discord ID from player identifiers
-- @param source: Player source ID
-- @return string|nil: Discord identifier or nil if not found
function Permissions.GetPlayerDiscordId(source)
    if not source then
        Utils.LogError("GetPlayerDiscordId: Invalid source provided")
        return nil
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then
        Utils.LogToConsole("warn", "No identifiers found for player " .. tostring(source))
        return nil
    end
    
    -- Search for Discord identifier
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "^discord:") then
            Utils.LogToConsole("info", "Found Discord ID for player " .. tostring(source) .. ": " .. identifier)
            return identifier
        end
    end
    
    Utils.LogToConsole("warn", "No Discord identifier found for player " .. tostring(source))
    return nil
end

-- Check if a Discord ID is in the allowed list
-- @param discordId: Discord identifier to check
-- @return boolean: true if authorized, false otherwise
function Permissions.CheckDiscordPermission(discordId)
    if not discordId then
        Utils.LogToConsole("warn", "CheckDiscordPermission: No Discord ID provided")
        return false
    end
    
    if not Config.AllowedDiscordIDs then
        Utils.LogError("CheckDiscordPermission: Config.AllowedDiscordIDs is not defined")
        return false
    end
    
    -- Check if Discord ID is in allowed list
    for _, allowedId in ipairs(Config.AllowedDiscordIDs) do
        if allowedId == discordId then
            Utils.LogToConsole("info", "Discord ID authorized: " .. discordId)
            return true
        end
    end
    
    Utils.LogToConsole("warn", "Discord ID not authorized: " .. discordId)
    return false
end

-- Main authorization check for a player and command (Discord only)
-- @param source: Player source ID
-- @param command: Command being executed (for logging purposes)
-- @return boolean: true if authorized, false otherwise
function Permissions.IsAuthorized(source, command)
    if not source then
        Utils.LogError("IsAuthorized: Invalid source provided")
        return false
    end
    
    -- Get player's Discord ID
    local discordId = Permissions.GetPlayerDiscordId(source)
    if not discordId then
        Utils.LogToConsole("warn", "Authorization failed for player " .. tostring(source) .. ": No Discord ID")
        return false
    end
    
    -- Check if Discord ID is authorized
    local isAuthorized = Permissions.CheckDiscordPermission(discordId)
    
    if isAuthorized then
        Utils.LogToConsole("info", "Player " .. tostring(source) .. " authorized for command: " .. tostring(command))
    else
        Utils.LogToConsole("warn", "Player " .. tostring(source) .. " NOT authorized for command: " .. tostring(command))
    end
    
    return isAuthorized
end

-- ============================================================================
-- Enhanced Permission Functions
-- ============================================================================

-- Get comprehensive player permission data
-- @param source: Player source ID
-- @return table|nil: Permission data structure or nil if error
function Permissions.GetPlayerPermissionData(source)
    local playerData = Utils.GetPlayerData(source)
    if not playerData then
        Utils.LogError("GetPlayerPermissionData: Could not get player data for source " .. tostring(source))
        return nil
    end
    
    local discordId = playerData.discordId
    local isAuthorized = discordId and Permissions.CheckDiscordPermission(discordId) or false
    
    return {
        source = source,
        name = playerData.name,
        discordId = discordId,
        isAuthorized = isAuthorized,
        hasDiscordId = discordId ~= nil
    }
end

-- Discord-only authorization check
-- @param source: Player source ID
-- @param command: Command being executed
-- @return table: Authorization result with details
function Permissions.GetAuthorizationResult(source, command)
    local result = {
        isAuthorized = false,
        reason = "Unknown error",
        playerData = nil,
        hasDiscordPermission = false
    }
    
    -- Get player data
    result.playerData = Utils.GetPlayerData(source)
    if not result.playerData then
        result.reason = "Player data not found"
        return result
    end
    
    -- Check if Discord IDs are configured
    if not Config.AllowedDiscordIDs or #Config.AllowedDiscordIDs == 0 then
        result.reason = "No Discord IDs configured in config.lua"
        Utils.LogError("Authorization failed: No Discord IDs configured in Config.AllowedDiscordIDs")
        return result
    end
    
    -- Check Discord permission
    if result.playerData.discordId then
        result.hasDiscordPermission = Permissions.CheckDiscordPermission(result.playerData.discordId)
        
        if result.hasDiscordPermission then
            result.isAuthorized = true
            result.reason = "Authorized via Discord ID"
        else
            result.reason = "Discord ID not in allowed list"
        end
    else
        result.reason = "No Discord ID found - ensure Discord is linked to FiveM"
    end
    
    Utils.LogToConsole("info", string.format(
        "Authorization check for %s (command: %s): %s - %s",
        result.playerData.name,
        command,
        result.isAuthorized and "AUTHORIZED" or "DENIED",
        result.reason
    ))
    
    return result
end

-- ============================================================================
-- Configuration Validation
-- ============================================================================

-- Validate permission configuration on startup
-- @return boolean: true if configuration is valid, false otherwise
function Permissions.ValidateConfiguration()
    local isValid = true
    
    -- Check if Config exists
    if not Config then
        Utils.LogError("ValidateConfiguration: Config table not found")
        return false
    end
    
    -- Check AllowedDiscordIDs
    if not Config.AllowedDiscordIDs then
        Utils.LogToConsole("warn", "Config.AllowedDiscordIDs not defined - creating empty table")
        Config.AllowedDiscordIDs = {}
    elseif type(Config.AllowedDiscordIDs) ~= "table" then
        Utils.LogError("ValidateConfiguration: Config.AllowedDiscordIDs must be a table")
        isValid = false
    else
        -- Validate Discord ID format
        for i, discordId in ipairs(Config.AllowedDiscordIDs) do
            if type(discordId) ~= "string" then
                Utils.LogError("ValidateConfiguration: Discord ID at index " .. i .. " must be a string")
                isValid = false
            elseif not string.match(discordId, "^discord:%d+$") then
                Utils.LogError("ValidateConfiguration: Invalid Discord ID format at index " .. i .. ": " .. discordId)
                isValid = false
            end
        end
        
        if #Config.AllowedDiscordIDs == 0 then
            Utils.LogToConsole("warn", "No Discord IDs configured - use /myids to find your Discord ID")
            Utils.LogToConsole("info", "System will start but no one will have permissions until Discord IDs are added")
        else
            Utils.LogToConsole("info", "Loaded " .. #Config.AllowedDiscordIDs .. " allowed Discord IDs")
        end
    end
    
    -- Validate other config sections (non-critical)
    if not Config.DiscordWebhook then
        Utils.LogToConsole("info", "Discord webhook not configured - logging will be console-only")
    end
    
    if not Config.Commands then
        Utils.LogToConsole("info", "Command settings not configured - using defaults")
    end
    
    if not Config.Debug then
        Utils.LogToConsole("info", "Debug settings not configured - using defaults")
    end
    
    return isValid
end

-- Initialize permission system (Discord only)
function Permissions.Initialize()
    Utils.LogToConsole("info", "Initializing Discord-only permission system...")
    
    -- Validate configuration
    local isValid = Permissions.ValidateConfiguration()
    if not isValid then
        Utils.LogError("Permission system initialization failed due to configuration errors")
        return false
    end
    
    -- Log configuration summary
    local configSummary = string.format(
        "Discord Permission System Summary:\n" ..
        "- Authorized Discord IDs: %d\n" ..
        "- QBCore Dependency: REMOVED\n" ..
        "- Authorization Method: Discord ID Only",
        #Config.AllowedDiscordIDs
    )
    
    Utils.LogToConsole("info", configSummary)
    Utils.LogToConsole("info", "Discord-only permission system initialized successfully")
    return true
end

-- ============================================================================
-- Export Permissions for use in other modules
-- ============================================================================

-- Make Permissions available globally for other modules
_G.Permissions = Permissions

-- Also return for require() usage if needed
return Permissions