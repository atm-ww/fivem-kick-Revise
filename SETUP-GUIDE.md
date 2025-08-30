# 🚀 FiveM Kick Script Quick Setup Guide

## 📋 Setup Steps (5 Minutes)

### 1️⃣ Install Script
```bash
# Extract to your resources folder
resources/fivem-kick/
```

### 2️⃣ Add to server.cfg
```cfg
ensure fivem-kick
```

### 3️⃣ Start Server and Find Your Discord ID
```
# In-game command:
/myids

# Check server console output for something like:
discord:123456789012345678
```

### 4️⃣ Configure Permissions
Edit `config.lua` file:
```lua
Config.AllowedDiscordIDs = {
    "discord:123456789012345678",  -- Replace with your actual Discord ID
    -- "discord:another_admin_id",   -- Can add multiple admins
}
```

### 5️⃣ Restart Resource
```
restart fivem-kick
```

### 6️⃣ Test Permissions
```
/kickstatus
```
Should show "✓ AUTHORIZED"

## ✅ Done!

Now you can use:
- `/kicknew [player_id]` - Kick specific player
- `/kicknewall` - Kick all players
- `/kickstatus` - Check permission status

## 🔧 Optional: Setup Discord Webhook

If you want Discord logging:

1. **Create Discord Webhook**
   - Go to your Discord server settings
   - Integrations → Webhooks → New Webhook
   - Copy Webhook URL

2. **Configure Webhook**
   ```lua
   Config.DiscordWebhook = {
       url = "your_webhook_url_here",
       botName = "FiveM Admin Logger",
   }
   ```

3. **Restart**
   ```
   restart fivem-kick
   ```

## ❓ Common Issues

**Q: Shows "Access denied"?**
A: Check if your Discord ID is correctly added to config.lua

**Q: Can't find Discord ID?**
A: Ensure Discord is linked to FiveM, use `/myids` command

**Q: Animation not playing?**
A: Animation is optional, kick functionality still works

**Q: Need QBCore?**
A: No! This script runs independently, no framework dependencies

## 📞 Need Help?

1. Check server console for error messages
2. Use `/kickstatus` to check permission status
3. Ensure Discord is properly linked to FiveM

---

**That's it!** 🎉