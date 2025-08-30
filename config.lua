Config = {}
--/kicknewall self
--/kicknewall
--kicknew [id]
-- Discord permission management
-- Add Discord IDs of users who can use kick commands
-- Format: "discord:123456789012345678"
Config.AllowedDiscordIDs = {
    -- 添加你的Discord ID到這裡
    -- 使用 /myids 命令來找到你的Discord ID
    -- Example: "discord:123456789012345678",
}

-- Discord webhook settings for logging
Config.DiscordWebhook = {
    -- Discord webhook URL for logging kick actions
    url = "", -- Replace with your Discord webhook URL

    -- Bot appearance in Discord messages
    botName = "FiveM Admin Logger",
    botAvatar = "https://cdn.discordapp.com/attachments/000000000000000000/000000000000000000/fivem_logo.png"
}

-- Command execution settings
Config.Commands = {
    -- Delay in milliseconds before actually kicking the player (allows animation to play)
    kickDelayMs = 10000,

    -- Mass kick settings to prevent server overload
    massKickBatchSize = 5,    -- Number of players to kick per batch
    massKickBatchDelay = 2000 -- Delay in milliseconds between batches
}

-- Debug and logging settings
Config.Debug = {
    -- Enable console logging for debugging
    enableConsoleLogging = true,

    -- Log level: "info", "warn", "error"
    logLevel = "info"
}
