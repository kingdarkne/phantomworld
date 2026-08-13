const chalk = require('chalk');
const fs = require('fs');
const Discord = require('discord.js');
const path = require('path');

module.exports = (client) => {
    if (client._phantomEventsLoaded) {
        console.warn('[events] already loaded — skipping duplicate registration');
        return;
    }
    client._phantomEventsLoaded = true;
    client._phantomRegisteredEvents = client._phantomRegisteredEvents || new Set();

    console.log(chalk.blue(chalk.bold(`System`)), (chalk.white(`>>`)), (chalk.green(`Loading events`)), (chalk.white(`...`)));

    const eventsDir = path.join(__dirname, '../../events');
    
    if (!fs.existsSync(eventsDir)) {
        console.error(chalk.red(`[ERROR] Events directory not found: ${eventsDir}`));
        return;
    }

    fs.readdirSync(eventsDir).forEach(dirs => {
        const subDir = path.join(eventsDir, dirs);
        if (!fs.statSync(subDir).isDirectory()) return;

        const events = fs.readdirSync(subDir).filter(files => files.endsWith('.js'));

        console.log(chalk.blue(chalk.bold(`System`)), (chalk.white(`>>`)), chalk.red(`${events.length}`), (chalk.green(`events of`)), chalk.red(`${dirs}`), (chalk.green(`loaded`)));

        for (const file of events) {
            try {
                const eventPath = path.join(subDir, file);
                const event = require(eventPath);
                const eventName = file.split(".")[0];
                
                let discordEvent = eventName;
                
                const mappings = {
                    'clientReady': 'ready',
                    'messageCreate': 'messageCreate',
                    'interactionCreate': 'interactionCreate',
                    'guildMemberAdd': 'guildMemberAdd',
                    'guildMemberRemove': 'guildMemberRemove'
                };

                if (mappings[eventName]) {
                    discordEvent = mappings[eventName];
                } else {
                    const eventKey = Object.keys(Discord.Events).find(key => key.toLowerCase() === eventName.toLowerCase());
                    if (eventKey) discordEvent = Discord.Events[eventKey];
                }

                const key = `${dirs}/${file}:${discordEvent}`;
                if (client._phantomRegisteredEvents.has(key)) {
                    console.warn(`[EVENT] Skip duplicate ${key}`);
                    continue;
                }
                client._phantomRegisteredEvents.add(key);

                console.log(`[EVENT] Registering event: ${discordEvent} (original: ${eventName}) from ${file}`);
                client.on(discordEvent, (...args) => {
                    Promise.resolve()
                        .then(() => event(client, ...args))
                        .catch((err) => {
                            console.error(`[EVENT ERROR] Error in event ${discordEvent}:`, err?.message || err);
                        });
                });
            } catch (err) {
                console.error(chalk.red(`[ERROR] Failed to load event ${file} in ${dirs}:`), err.message);
            }
        }
    });

    try { client.setMaxListeners(0); } catch (_) {}
};
