(function(global){
    // Centralized hover help texts for Oxo Admin UI.
    // Keep this file text-only so designers can tweak wording without touching app.js or index.html.

    const self = {
        heal: 'Restore your own health to full and clear visible damage.',
        revive: 'Revive yourself from a downed state using the configured medical system.',
        noclip: 'Toggle staff noclip fly mode. Use movement keys + mouse to move freely without collision.',
        invincible: 'Toggle god mode so you cannot take damage.',
        invisible: 'Hide your player model from normal view while keeping admin control.',
        ammo: 'Give yourself unlimited ammunition for your current weapons.',
        armor: 'Refill your armor to 100 using the configured armor backend.',
        stress: 'Clear your stress using the configured status/stress system.',
        wanted: 'Reduce your current wanted level using the Advanced Wanted system.',
        superjump: 'Jump higher than normal. Useful for cinematic moves and quick navigation.',
        skin: 'Open the configured skin/appearance menu to change your character.'
    };

    const miniSelf = {
        heal: 'Quick-heal yourself from the mini panel.',
        revive: 'Quick-revive yourself from the mini panel.',
        noclip: 'Toggle noclip fly mode from the mini panel.',
        invincible: 'Toggle god mode from the mini panel.',
        invisible: 'Hide your player model from the mini panel.',
        duty: 'Toggle your staff duty state without opening the full menu.',
        ammo: 'Give yourself unlimited ammo from the mini panel.',
        superjump: 'Toggle super jump from the mini panel.',
        armor: 'Refill your armor from the mini panel.',
        stress: 'Remove your stress from the mini panel.',
        tpMarkedNoVehicle: 'Teleport to waypoint without vehicle from the mini panel.'
    };

    const player = {
        kick: 'Disconnect the selected player from the server with a reason.',
        ban: 'Ban the selected player for a set duration or permanently.',
        prisonBan: 'Issue a prison ban based on selected offences and server rules.',
        heal: 'Heal the selected player to full health.',
        revive: 'Revive the selected player from a downed state.',
        kill: 'Force-kill the selected player.',
        stress: 'Clear the selected player\'s stress using the configured system.',
        wanted: 'Reduce the selected player\'s wanted level using the Advanced Wanted system.',
        bring: 'Teleport the selected player to your current position.',
        goto: 'Teleport yourself to the selected player.',
        spectate: 'Start spectating the selected player in free camera.',
        spectateStop: 'Stop spectating and return control to your character.',
        freeze: 'Freeze the selected player in place.',
        unfreeze: 'Unfreeze the selected player.',
        noclip: 'Toggle noclip for the selected player.',
        invincible: 'Toggle god mode for the selected player.',
        invisible: 'Toggle invisibility for the selected player.',
        giveMoney: 'Give money to the selected player from the chosen account.',
        removeMoney: 'Remove money from the selected player.',
        clearinv: 'Clear the selected player\'s inventory. Use with care.',
        checkinv: 'Check the selected player\'s inventory in view-only mode when supported by the configured inventory backend.',
        openinv: 'Open the selected player\'s inventory with admin access so you can move items in and out.',
        confiscateillegal: 'Confiscate illegal items from the selected player without wiping the rest of their inventory.',
        giveItem: 'Give a specific item and count to the selected player.',
        skin: 'Open the skin/appearance menu for the selected player.',
        message: 'Send a private message to the selected player.',
        warn: 'Send an official warning message to the selected player.',
        setJob: 'Set the job and grade for the selected player through your framework bridge.',
        troll_slap: 'Playfully slap the player with a physics knock.',
        troll_launch: 'Launch the player high into the air. Very visible.',
        troll_screen: 'Apply a temporary screen and camera effect to the player.',
        troll_fire: 'Briefly set the player on fire for troll purposes.',
        troll_ufo: 'Trigger the UFO kidnap troll sequence on the player.',
        troll_animal: 'Spawn animals to attack the player.',
        troll_npcs: 'Send nearby NPCs to attack the player.',
        troll_clone: 'Spawn a clone that follows the player.',
        troll_flipveh: 'Flip the player\'s vehicle.',
        troll_slowwalk: 'Force the player into a slow walking style.',
        troll_cam2d: 'Enable a 2D side-camera style for the player.',
        troll_camflip: 'Flip the player\'s camera upside-down.'
    };

    const miniPlayer = {
        bring: 'Bring the ID from the mini panel to your position.',
        goto: 'Teleport to the ID from the mini panel.',
        freeze: 'Freeze the ID from the mini panel.',
        unfreeze: 'Unfreeze the ID from the mini panel.',
        spectate: 'Start spectating the ID set in the mini panel.',
        spectateStop: 'Stop spectating the current mini-panel target.'
    };

    const serverClean = {
        veh: 'Delete all non-essential vehicles on the map.',
        peds: 'Delete non-player NPCs on the map.',
        objs: 'Delete world props and objects.',
        all: 'Run a full cleanup of vehicles, peds and objects.'
    };

    const veh = {
        repair: 'Repair your current or nearest vehicle.',
        deleteClosest: 'Delete the closest vehicle to you.',
        maxmods: 'Apply max performance and visual mods to your vehicle.',
        maxfuel: 'Fill the vehicle\'s fuel to maximum.',
        plate: 'Set a new license plate text on your current vehicle.',
        color: 'Set primary and secondary paint colors by ID.',
        lock: 'Lock your current or nearest vehicle doors.',
        unlock: 'Unlock your current or nearest vehicle doors.',
        torque: 'Multiply the vehicle\'s torque by the given factor.'
    };

    const devMini = {
        toggle: 'Toggle developer raycast debug mode for entity selection.',
        del: 'Delete the last entity hit by the dev raycast.',
        copy3: 'Copy the last hit position as a vec3 to your clipboard.',
        copy4: 'Copy the last hit position as a vec4 to your clipboard.',
        lightning: 'Trigger a lightning strike at the raycast hit position.',
        godshand: 'Use the dev hand to delete or move entities you target.'
    };

    const byId = {
        'self-duty-btn': 'Toggle your staff duty state. Off duty hides most tools; on duty unlocks your permissions.',
        'self-noclip-btn': 'Toggle noclip fly mode. Combine with the speed slider for cinematic movement.',
        'self-superjump-btn': 'Toggle super jump for your own character.',
        'self-invis-btn': 'Toggle your own invisibility (staff only).',
        'self-nametag-btn': 'Toggle your overhead name tag visibility.',
        'self-inv-btn': 'Toggle god mode so you cannot take damage.',
        'self-armor-btn': 'Refill your armor to 100 using the configured armor system.',
        'self-ammo-btn': 'Toggle unlimited ammo for your weapons.',
        'self-stress-btn': 'Clear your current stress/panic level using the configured system.',
        'self-wanted-btn': 'Reduce your current wanted level by one star, ignoring normal cooldowns.',
        'self-onepunch-btn': 'Enable one-punch knockouts in melee combat.',
        'self-job-btn': 'Set your own job/grade when permitted for specific grades (0-6).',
        'staff-name-btn': 'Save a custom staff display name shown on duty.',
        'rp-name-btn': 'Set an RP first/last name for the staff member.',
        'rp-name-reset-btn': 'Clear and reset the stored RP name.',

        'players-refresh': 'Refresh the online player list and ping information.',
        'bans-refresh': 'Refresh the list of current bans from the database.',

        'cleanup-auto-toggle': 'Toggle automatic cleanup of entities on a fixed interval.',
        'notify-btn': 'Send a short notification popup to all players.',
        'announce-btn': 'Broadcast a longer announcement message to all players.',

        'veh-spawn': 'Spawn a vehicle by model at your position, optionally with a custom plate.',
        'veh-owned-load': 'Load owned vehicles for the selected player.',
        'veh-gift-btn': 'Gift a vehicle to the selected player and register it to them.',

        'zone-create': 'Create or update the admin zone at your current position.',
        'zone-reset': 'Reset the zone form to create a new zone from scratch.',

        'staff-refresh': 'Refresh staff overview, duty state and statistics.',

        'roles-refresh': 'Reload roles, permissions and staff assignments from the server.',
        'role-create': 'Create a new staff role with the given name.',
        'role-save': 'Save permissions and assignments for the currently selected role.',
        'role-delete': 'Delete the selected staff role.',

        'dev-toggle': 'Toggle in-world developer raycast debug overlay.',
        'dev-del': 'Delete the entity currently highlighted by the dev raycast.',
        'dev-v3': 'Copy last raycast coordinates as vec3 to clipboard.',
        'dev-v4': 'Copy last raycast coordinates as vec4 to clipboard.',
        'dev-lightning': 'Strike lightning where the dev ray hits.',
        'dev-godshand': 'Toggle God\'s Hand mode for powerful entity manipulation.',

        'console-run': 'Execute a raw command on the server console. Use with care.',
        'console-scan': 'Run an automated exploit scan against the current server state.',
        'console-monitor': 'Toggle live exploit/health monitor for selected players.',
        'console-monitor-settings-btn': 'Open monitor filter and interval settings.',
        'console-scan-one': 'Run a deep exploit/cheat scan on a single player ID.',
        'monitor-add-btn': 'Add a player ID to the exploit/health monitor list.',
        'monitor-clear-btn': 'Clear the exploit/health monitor list.'
    };

    global.OxoHelpTexts = {
        self,
        miniSelf,
        player,
        miniPlayer,
        serverClean,
        veh,
        devMini,
        byId
    };

})(window);
