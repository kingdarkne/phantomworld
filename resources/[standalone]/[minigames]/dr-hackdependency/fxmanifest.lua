fx_version "adamant"

game "gta5"

files {
    "html/index.html",
    -- audio assets are not present in this package;
    -- removing stale declarations avoids mount/load errors
}

ui_page "html/index.html"

client_script "client.lua"