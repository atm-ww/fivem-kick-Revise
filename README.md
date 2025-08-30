# Enhanced FiveM Kick Script v2.0 (Discord Only)

A comprehensive FiveM kick script with Discord-based permissions, webhook logging, and stylized kick animations.

## 🌟 Key Features

### 🎭 Stylized Kick Animation
- Maintains the original kidnapping animation sequence
- Professional animation with guard NPC and van
- Configurable kick delay to ensure animation completion

### 🔐 Discord Permission System (Standalone)
- Discord ID-based authorization system
- **No QBCore or other framework dependencies required**
- Configurable Discord ID allowlist
- Automatic permission validation

### 📊 Discord Webhook Logging
- Real-time logging of all kick actions
- Unauthorized attempt monitoring
- Professional Discord embeds with colors and formatting
- Hong Kong timezone support (UTC+8)
- @mention notifications for involved users

### ⚡ Enhanced Commands
- `/kicknew [id]` - Kick individual player with animation
- `/kicknewall` - Mass kick all players (batch processing)
- `/kickstatus` - Check your permission status
- `/myids` - Display all your identifiers (helps find Discord ID)

## 📦 Installation

### 1. Download and Extract
```
Download the script and extract to your resources folder
```

### 2. Add to server.cfg
```cfg
ensure fivem-kick
```

### 3. Configure Permissions
- Edit `config.lua`
- Add Discord IDs to `Config.AllowedDiscordIDs`
- Configure Discord webhook URL (optional)

### 4. Dependencies
- ✅ Players must have Discord linked to FiveM
- ✅ **No framework dependencies** - runs independently
- ✅ Compatible with any FiveM server

## ⚙️ Configuration

### Discord Permission Setup
```lua
Config.AllowedDiscordIDs = {
    "discord:123456789012345678",  -- Replace with actual Discord IDs
    "discord:987654321098765432",  -- Add more as needed
}
```

### Discord Webhook Setup (Optional)
```lua
Config.DiscordWebhook = {
    url = "https://discord.com/api/webhooks/YOUR_WEBHOOK_URL",
    botName = "FiveM Admin Logger",
    botAvatar = "https://your-avatar-url.png"
}
```

### Command Settings
```lua
Config.Commands = {
    kickDelayMs = 10000,        -- Animation duration before kick
    massKickBatchSize = 5,      -- Players per batch for mass kick
    massKickBatchDelay = 2000   -- Delay between batches
}
```

## 🚀 Usage Guide

### 🔍 Step 1: Find Your Discord ID
```
/myids
```
Check server console output for ID starting with `discord:`

### ⚙️ Step 2: Configure Permissions
Add your Discord ID to `config.lua`:
```lua
Config.AllowedDiscordIDs = {
    "discord:your_discord_numeric_id",
}
```

### 🔄 Step 3: Restart Resource
```
restart fivem-kick
```

### ✅ Step 4: Test Permissions
```
/kickstatus
```

### Individual Kick
```
/kicknew [player_id]
```
- Requires Discord permission
- Plays kidnapping animation
- Logs action to Discord
- Provides execution feedback

### Mass Kick
```
/kicknewall
```
- Kicks all players except executor
- Batch processing prevents server overload
- Each player sees the animation
- Comprehensive Discord logging

## 🔐 Permission Requirements

Users only need:
1. **Discord ID** in `Config.AllowedDiscordIDs`

**Important:** QBCore dependency has been removed. System now runs with Discord permissions only.

## 📋 Discord Logging

### Unauthorized Attempts
- 🚨 Red embed color
- User details and attempted command
- @mention of the user
- Hong Kong timestamp

### Successful Actions
- ✅ Green embed color
- Admin and target details
- Command specifics
- @mention of the admin

### System Events
- 🟢 System startup notifications
- 🔴 System shutdown notifications
- 🚨 Critical error alerts

## 🛠️ Troubleshooting

### Common Issues

1. **"Access denied" messages**
   - Check if Discord ID is in config
   - Use `/kickstatus` to check permissions
   - Use `/myids` to find correct Discord ID

2. **Discord logging not working**
   - Verify webhook URL is correct
   - Check Discord webhook permissions
   - Look for error messages in console

3. **Animation not playing**
   - Check if client.lua is loaded
   - Verify model loading in console
   - Animation continues even if models fail

4. **System initialization failed**
   - Check config.lua syntax
   - Ensure all required files are present
   - Verify Discord ID format: `discord:123456789`

### Console Commands

Check server console for detailed logging:
```
[INFO] FiveM-Kick: System initialized successfully
[WARN] FiveM-Kick: No Discord IDs configured
[ERROR] FiveM-Kick: Permission denied for player
```

## 📁 Technical Details

### File Structure
```
fivem-kick/
├── fxmanifest.lua          # Resource manifest
├── config.lua              # Configuration file
├── config.example.lua      # Configuration example
├── server.lua              # Main server logic
├── client.lua              # Animation handling
├── modules/
│   ├── utils.lua           # Utility functions
│   ├── permissions.lua     # Permission management
│   └── discord.lua         # Discord integration
├── README.md               # This file
└── SETUP-GUIDE.md          # Quick setup guide
```

### System Requirements
- **FiveM Server** - Latest version
- **Discord Integration** - Players must link Discord
- **HTTP Requests** - For Discord webhook functionality
- **No Framework Dependencies** - Runs independently

### Compatibility
- ✅ FiveM latest versions
- ✅ Any framework (QBCore, ESX, etc.)
- ✅ Standalone servers
- ✅ Multi-language support

## 📞 Support

When encountering issues:
1. Check console error messages
2. Verify configuration settings
3. Test with `/kickstatus` command
4. Review Discord webhook setup
5. Use `/myids` to find correct Discord ID

## 📝 Changelog

### v2.0 (Discord Only)
- ✅ Removed QBCore dependency
- ✅ Pure Discord permission system
- ✅ Enhanced error handling
- ✅ Improved configuration validation
- ✅ Complete documentation update
- ✅ Standalone operation capability

### v1.0
- Original kick animation system
- Basic QBCore integration

## 🏆 Credits

- Original animation concept: ilv-scripts
- Enhanced development: FiveM Community
- Discord integration: Community contributions

---

## 🔧 Quick Setup Guide

1. **Install Script** → Extract to resources folder
2. **Add to server.cfg** → `ensure fivem-kick`
3. **Find Discord ID** → Use `/myids` in-game
4. **Configure Permissions** → Edit `config.lua` with your Discord ID
5. **Restart** → `restart fivem-kick`
6. **Test** → Use `/kickstatus` to verify permissions

**Note**: This script requires proper Discord ID configuration. Please follow the installation guide carefully for optimal functionality.