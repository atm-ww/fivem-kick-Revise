-- ============================================================================
-- Enhanced FiveM Kick Script v2.0
-- Professional kick system with Discord integration and stylized animations
-- ============================================================================

author 'ilv-scripts (Enhanced by Community)'
version '2.0.0'
description 'Enhanced FiveM kick script with Discord-only permissions, webhook logging, and mass kick functionality - No framework dependencies required'

fx_version 'cerulean'
game 'gta5'

lua54 'yes'

-- Configuration file (shared between client and server)
shared_script 'config.lua'

-- Client scripts (handles animations)
client_scripts {
    'client.lua'
}

-- Server scripts (loaded in dependency order)
server_scripts {
    'modules/utils.lua',       -- Utility functions (loaded first)
    'modules/permissions.lua', -- Permission management
    'modules/discord.lua',     -- Discord webhook integration
    'server.lua'               -- Main server logic (loaded last)
}

-- No framework dependencies required
-- This script now works independently with Discord-only permissions

-- Resource information
repository 'https://github.com/your-repo/fivem-kick-enhanced'
