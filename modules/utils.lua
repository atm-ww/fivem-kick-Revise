-- ============================================================================
-- Utility Functions Module
-- Provides common utility functions for the FiveM kick script
-- ============================================================================

local Utils = {}

-- ============================================================================
-- Hong Kong Time Functions
-- ============================================================================

-- Get current timestamp in Hong Kong time (UTC+8)
-- Returns formatted string: "YYYY-MM-DD HH:MM:SS HKT"
function Utils.GetHongKongTimestamp()
    local utcTime = os.time()
    local hkTime = utcTime + (8 * 3600) -- Add 8 hours for UTC+8
    return os.date("%Y-%m-%d %H:%M:%S", hkTime) .. " HKT"
end

-- Get ISO timestamp for Discord webhook (UTC format)
function Utils.GetISOTimestamp()
    return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

-- ============================================================================
-- Player Validation Functions
-- ============================================================================

-- Validate if a player ID is valid and player exists
-- @param id: Player ID to validate
-- @return boolean: true if valid, false otherwise
function Utils.ValidatePlayerId(id)
    if not id then
        return false
    end
    
    local playerId = tonumber(id)
    if not playerId then
        return false
    end
    
    -- Check if player exists and is connected
    local playerName = GetPlayerName(playerId)
    return playerName ~= nil and playerName ~= ""
end

-- Get all connected players (excluding a specific source if provided)
-- @param excludeSource: Source ID to exclude from the list (optional)
-- @return table: Array of player source IDs
function Utils.GetConnectedPlayers(excludeSource)
    local players = {}
    local playerList = GetPlayers()
    
    for _, playerId in ipairs(playerList) do
        local sourceId = tonumber(playerId)
        if sourceId and (not excludeSource or sourceId ~= excludeSource) then
            table.insert(players, sourceId)
        end
    end
    
    return players
end

-- Get player data structure with all relevant information
-- @param source: Player source ID
-- @return table: Player data structure or nil if player not found
function Utils.GetPlayerData(source)
    local playerName = GetPlayerName(source)
    if not playerName then
        return nil
    end
    
    local identifiers = GetPlayerIdentifiers(source)
    local discordId = nil
    
    -- Extract Discord ID from identifiers
    for _, identifier in ipairs(identifiers) do
        if string.match(identifier, "discord:") then
            discordId = identifier
            break
        end
    end
    
    return {
        source = source,
        name = playerName,
        discordId = discordId,
        identifiers = identifiers
    }
end

-- ============================================================================
-- Logging Functions
-- ============================================================================

-- Log message to console with different levels
-- @param level: Log level ("info", "warn", "error")
-- @param message: Message to log
function Utils.LogToConsole(level, message)
    if not Config.Debug.enableConsoleLogging then
        return
    end
    
    local timestamp = Utils.GetHongKongTimestamp()
    local prefix = ""
    
    if level == "error" then
        prefix = "^1[ERROR]^7"
    elseif level == "warn" then
        prefix = "^3[WARN]^7"
    else
        prefix = "^2[INFO]^7"
    end
    
    print(string.format("%s [%s] FiveM-Kick: %s", prefix, timestamp, message))
end

-- Log error with stack trace if available
-- @param message: Error message
-- @param err: Error object (optional)
function Utils.LogError(message, err)
    local fullMessage = message
    if err then
        fullMessage = fullMessage .. " | Error: " .. tostring(err)
    end
    Utils.LogToConsole("error", fullMessage)
end

-- ============================================================================
-- String Utility Functions
-- ============================================================================

-- Extract numeric Discord ID from Discord identifier for mentions
-- @param discordId: Discord identifier (e.g., "discord:123456789")
-- @return string: Formatted Discord mention or "Unknown User"
function Utils.FormatDiscordMention(discordId)
    if not discordId then
        return "Unknown User"
    end
    
    local numericId = discordId:match("discord:(%d+)")
    return numericId and "<@" .. numericId .. ">" or "Unknown User"
end

-- Sanitize string for safe logging (remove potential injection attempts)
-- @param str: String to sanitize
-- @return string: Sanitized string
function Utils.SanitizeString(str)
    if not str then
        return "nil"
    end
    
    -- Remove potential harmful characters and limit length
    local sanitized = tostring(str):gsub("[<>@&]", ""):sub(1, 100)
    return sanitized
end

-- ============================================================================
-- Table Utility Functions
-- ============================================================================

-- Check if a value exists in a table
-- @param table: Table to search
-- @param value: Value to find
-- @return boolean: true if found, false otherwise
function Utils.TableContains(table, value)
    if not table or not value then
        return false
    end
    
    for _, v in ipairs(table) do
        if v == value then
            return true
        end
    end
    return false
end

-- Get table length (works for both arrays and hash tables)
-- @param table: Table to count
-- @return number: Number of elements
function Utils.TableLength(table)
    if not table then
        return 0
    end
    
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    return count
end

-- ============================================================================
-- Export Utils for use in other modules
-- ============================================================================

-- Make Utils available globally for other modules
_G.Utils = Utils

-- Also return for require() usage if needed
return Utils