-- ============================================================================
-- Discord Webhook Integration Module
-- Handles Discord webhook logging for kick command actions
-- ============================================================================

local Discord = {}

-- ============================================================================
-- Webhook Configuration and Validation
-- ============================================================================

-- Check if Discord webhook is properly configured
-- @return boolean: true if configured, false otherwise
function Discord.IsWebhookConfigured()
    if not Config.DiscordWebhook then
        return false
    end
    
    if not Config.DiscordWebhook.url or Config.DiscordWebhook.url == "" then
        return false
    end
    
    -- Basic URL validation
    if not string.match(Config.DiscordWebhook.url, "^https://discord%.com/api/webhooks/") then
        Utils.LogError("Invalid Discord webhook URL format")
        return false
    end
    
    return true
end

-- ============================================================================
-- Webhook Payload Building
-- ============================================================================

-- Build base webhook payload structure
-- @param title: Embed title
-- @param description: Embed description
-- @param color: Embed color (decimal)
-- @return table: Webhook payload
function Discord.BuildWebhookPayload(title, description, color)
    local payload = {
        username = Config.DiscordWebhook.botName or "FiveM Admin Logger",
        avatar_url = Config.DiscordWebhook.botAvatar or "",
        embeds = {
            {
                title = title,
                description = description,
                color = color or 16711680, -- Default red color
                timestamp = Utils.GetISOTimestamp(),
                footer = {
                    text = "FiveM Kick System",
                    icon_url = "https://cdn.discordapp.com/attachments/000000000000000000/000000000000000000/fivem_logo.png"
                }
            }
        }
    }
    
    return payload
end

-- Add field to webhook embed
-- @param payload: Webhook payload to modify
-- @param name: Field name
-- @param value: Field value
-- @param inline: Whether field should be inline (optional)
function Discord.AddEmbedField(payload, name, value, inline)
    if not payload.embeds or not payload.embeds[1] then
        return
    end
    
    if not payload.embeds[1].fields then
        payload.embeds[1].fields = {}
    end
    
    table.insert(payload.embeds[1].fields, {
        name = name,
        value = Utils.SanitizeString(value),
        inline = inline or false
    })
end

-- ============================================================================
-- HTTP Request Handling
-- ============================================================================

-- Send webhook payload to Discord with comprehensive error handling
-- @param payload: Webhook payload to send
-- @param callback: Optional callback function
function Discord.SendWebhook(payload, callback)
    local success, error = pcall(function()
        if not Discord.IsWebhookConfigured() then
            Utils.LogToConsole("warn", "Discord webhook not configured, logging to console instead")
            if payload and payload.embeds and payload.embeds[1] then
                Utils.LogToConsole("info", "Webhook would have sent: " .. tostring(payload.embeds[1].title))
            end
            if callback then callback(false, "Webhook not configured") end
            return
        end
        
        if not payload then
            Utils.LogError("SendWebhook: No payload provided")
            if callback then callback(false, "No payload provided") end
            return
        end
        
        local jsonPayload
        local jsonSuccess, jsonError = pcall(function()
            jsonPayload = json.encode(payload)
        end)
        
        if not jsonSuccess then
            Utils.LogError("SendWebhook: Failed to encode JSON payload - " .. tostring(jsonError))
            if callback then callback(false, "JSON encoding failed") end
            return
        end
        
        -- Add timeout and retry logic
        local requestTimeout = 10000 -- 10 seconds
        local maxRetries = 2
        local currentRetry = 0
        
        local function attemptRequest()
            currentRetry = currentRetry + 1
            
            PerformHttpRequest(Config.DiscordWebhook.url, function(statusCode, responseText, headers)
                local requestSuccess = statusCode >= 200 and statusCode < 300
                
                if requestSuccess then
                    Utils.LogToConsole("info", "Discord webhook sent successfully (attempt " .. currentRetry .. ")")
                    if callback then callback(true, responseText) end
                else
                    Utils.LogError("Discord webhook failed with status " .. statusCode .. ": " .. tostring(responseText))
                    
                    -- Retry on certain error codes
                    if currentRetry < maxRetries and (statusCode == 429 or statusCode >= 500) then
                        Utils.LogToConsole("warn", "Retrying webhook request in 2 seconds... (attempt " .. (currentRetry + 1) .. "/" .. maxRetries .. ")")
                        SetTimeout(2000, attemptRequest)
                    else
                        if callback then callback(false, responseText) end
                    end
                end
            end, 'POST', jsonPayload, {
                ['Content-Type'] = 'application/json',
                ['User-Agent'] = 'FiveM-Kick-System/2.0'
            })
        end
        
        attemptRequest()
    end)
    
    if not success then
        Utils.LogError("SendWebhook: Critical error - " .. tostring(error))
        if callback then callback(false, "Critical error: " .. tostring(error)) end
    end
end

-- ============================================================================
-- Unauthorized Attempt Logging
-- ============================================================================

-- Log unauthorized command attempt to Discord
-- @param playerData: Player data structure
-- @param command: Command that was attempted
-- @param targetInfo: Additional target information (optional)
function Discord.SendUnauthorizedAttempt(playerData, command, targetInfo)
    if not playerData then
        Utils.LogError("SendUnauthorizedAttempt: No player data provided")
        return
    end
    
    local timestamp = Utils.GetHongKongTimestamp()
    local discordMention = Utils.FormatDiscordMention(playerData.discordId)
    
    -- Build description with mention
    local description = string.format(
        "🚨 **UNAUTHORIZED ACCESS ATTEMPT** 🚨\n\n" ..
        "User %s attempted to use a restricted command without proper permissions.\n\n" ..
        "**Time:** %s",
        discordMention,
        timestamp
    )
    
    -- Create webhook payload with red color for unauthorized attempts
    local payload = Discord.BuildWebhookPayload(
        "🚫 Unauthorized Command Attempt",
        description,
        16711680 -- Red color
    )
    
    -- Add detailed fields
    Discord.AddEmbedField(payload, "👤 Player", playerData.name, true)
    Discord.AddEmbedField(payload, "🆔 Discord ID", playerData.discordId or "Not Found", true)
    Discord.AddEmbedField(payload, "⚡ Command", command, true)
    
    if targetInfo then
        Discord.AddEmbedField(payload, "🎯 Target", targetInfo, true)
    end
    
    Discord.AddEmbedField(payload, "🔗 Player Source", tostring(playerData.source), true)
    
    -- Send webhook
    Discord.SendWebhook(payload, function(success, response)
        if success then
            Utils.LogToConsole("info", "Unauthorized attempt logged to Discord for player: " .. playerData.name)
        else
            Utils.LogError("Failed to log unauthorized attempt to Discord: " .. tostring(response))
        end
    end)
end

-- ============================================================================
-- Successful Action Logging
-- ============================================================================

-- Log successful command execution to Discord
-- @param playerData: Player data structure
-- @param command: Command that was executed
-- @param details: Command execution details
function Discord.SendSuccessfulAction(playerData, command, details)
    if not playerData then
        Utils.LogError("SendSuccessfulAction: No player data provided")
        return
    end
    
    local timestamp = Utils.GetHongKongTimestamp()
    local discordMention = Utils.FormatDiscordMention(playerData.discordId)
    
    -- Build description with mention
    local description = string.format(
        "✅ **ADMIN ACTION EXECUTED** ✅\n\n" ..
        "Administrator %s successfully executed a kick command.\n\n" ..
        "**Time:** %s",
        discordMention,
        timestamp
    )
    
    -- Create webhook payload with green color for successful actions
    local payload = Discord.BuildWebhookPayload(
        "✅ Successful Admin Action",
        description,
        65280 -- Green color
    )
    
    -- Add detailed fields
    Discord.AddEmbedField(payload, "👤 Administrator", playerData.name, true)
    Discord.AddEmbedField(payload, "🆔 Discord ID", playerData.discordId or "Not Found", true)
    Discord.AddEmbedField(payload, "⚡ Command", command, true)
    
    -- Add command-specific details
    if details then
        if details.targetPlayer then
            Discord.AddEmbedField(payload, "🎯 Target Player", details.targetPlayer, true)
        end
        
        if details.targetId then
            Discord.AddEmbedField(payload, "🔢 Target ID", tostring(details.targetId), true)
        end
        
        if details.playersKicked then
            Discord.AddEmbedField(payload, "👥 Players Kicked", tostring(details.playersKicked), true)
        end
        
        if details.reason then
            Discord.AddEmbedField(payload, "📝 Reason", details.reason, false)
        end
    end
    
    Discord.AddEmbedField(payload, "🔗 Admin Source", tostring(playerData.source), true)
    
    -- Send webhook
    Discord.SendWebhook(payload, function(success, response)
        if success then
            Utils.LogToConsole("info", "Successful action logged to Discord for admin: " .. playerData.name)
        else
            Utils.LogError("Failed to log successful action to Discord: " .. tostring(response))
        end
    end)
end

-- ============================================================================
-- Specialized Logging Functions
-- ============================================================================

-- Log individual kick action
-- @param adminData: Administrator player data
-- @param targetData: Target player data
function Discord.LogIndividualKick(adminData, targetData)
    local details = {
        targetPlayer = targetData.name,
        targetId = targetData.source,
        reason = "Administrative kick with animation"
    }
    
    Discord.SendSuccessfulAction(adminData, "/kicknew", details)
end

-- Log mass kick action
-- @param adminData: Administrator player data
-- @param kickedCount: Number of players kicked
function Discord.LogMassKick(adminData, kickedCount)
    local details = {
        playersKicked = kickedCount,
        reason = "Mass kick - all players removed from server"
    }
    
    Discord.SendSuccessfulAction(adminData, "/kicknewall", details)
end

-- ============================================================================
-- System Status Logging
-- ============================================================================

-- Log system startup/configuration status
function Discord.LogSystemStatus()
    if not Discord.IsWebhookConfigured() then
        Utils.LogToConsole("warn", "Discord webhook logging is disabled - webhook not configured")
        return
    end
    
    local description = string.format(
        "🔧 **KICK SYSTEM STATUS** 🔧\n\n" ..
        "The FiveM kick system has been initialized and is ready for use.\n\n" ..
        "**Time:** %s\n" ..
        "**Authorized Users:** %d",
        Utils.GetHongKongTimestamp(),
        Utils.TableLength(Config.AllowedDiscordIDs)
    )
    
    local payload = Discord.BuildWebhookPayload(
        "🟢 System Initialized",
        description,
        3447003 -- Blue color
    )
    
    Discord.AddEmbedField(payload, "📊 Status", "Online and Ready", true)
    Discord.AddEmbedField(payload, "🔐 Security", "Discord Permission System Active", true)
    
    Discord.SendWebhook(payload, function(success, response)
        if success then
            Utils.LogToConsole("info", "System status logged to Discord")
        else
            Utils.LogError("Failed to log system status to Discord: " .. tostring(response))
        end
    end)
end

-- ============================================================================
-- Module Initialization
-- ============================================================================

-- Initialize Discord module
function Discord.Initialize()
    Utils.LogToConsole("info", "Initializing Discord webhook system...")
    
    if Discord.IsWebhookConfigured() then
        Utils.LogToConsole("info", "Discord webhook configured and ready")
        -- Log system startup
        Discord.LogSystemStatus()
    else
        Utils.LogToConsole("warn", "Discord webhook not configured - logging will be console-only")
    end
    
    return true
end

-- ============================================================================
-- Export Discord for use in other modules
-- ============================================================================

-- Make Discord available globally for other modules
_G.Discord = Discord

-- Also return for require() usage if needed
return Discord