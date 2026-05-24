Upload = Upload or {}

Upload.ServiceUsed = 'discord'   -- discord | fivemanage | fivemerr
Upload.Token = 'YOUR_TOKEN'      --  fivemanage or fivemerr | [*note - for discord webhook is to be changed below not here]

-- FOR DISCORD LOGS
Upload.DiscordLogs = {
    Enabled = true,
    Username = 'Spy Bodycam Records',     -- Bot Username
    Title = 'Bodycam Records',            -- Message Title
}

-- Upload Hooks if Upload.ServiceUsed = discord
Upload.DefaultUploads = {   -- Default Upload of log if job not mentioned in Upload.JobUploads. 
    webhook = 'https://discord.com/api/webhooks/1472836260912431205/O30C_6ZryeUwZ_KDJd_r2XP6gluk1wKW011zxoCBkwrSj-ldHxOnI_i9mdyMCdIhb4wp',
    author = {
        name = "Spy Bodycam",
        icon_url = "https://i.imgur.com/tMyAdkz.png"
    }
}

Upload.JobUploads = {  -- Job Speific Uploads
    ['police'] = {
        webhook = 'https://discord.com/api/webhooks/1472836260912431205/O30C_6ZryeUwZ_KDJd_r2XP6gluk1wKW011zxoCBkwrSj-ldHxOnI_i9mdyMCdIhb4wp',
        author = {
            name = "Police Department",
            icon_url = "https://i.imgur.com/tMyAdkz.png"
        }
    }, -- Add more here
}
