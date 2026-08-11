const Discord = require('discord.js');
const { REST } = require('discord.js');
const { Routes } = require('discord.js');
const chalk = require('chalk');
const fs = require('fs');
const { ApplicationCommand } = require('discord.js');

/**@param {Discord.Client} client */
module.exports = (client) => {
    const interactionLogs = new Discord.WebhookClient({
        id: client.webhooks.interactionLogs.id,
        token: client.webhooks.interactionLogs.token,
    });

    const commands = [];
    console.log(chalk.blue(chalk.bold(`System`)), (chalk.white(`>>`)), (chalk.green(`Loading commands`)), (chalk.white(`...`)))


    fs.readdirSync('./src/interactions').forEach(dirs => {
        const subDir = `./src/interactions/${dirs}`;
        if (!fs.statSync(subDir).isDirectory()) return;
        
        const commandFiles = fs.readdirSync(subDir).filter(files => files.endsWith('.js'));

        console.log(chalk.blue(chalk.bold(`System`)), (chalk.white(`>>`)), chalk.red(`${commandFiles.length}`), (chalk.green(`commands of`)), chalk.red(`${dirs}`), (chalk.green(`loaded`)));

        for (const file of commandFiles) {
            try {
                const command = require(`${process.cwd()}/src/interactions/${dirs}/${file}`);
                console.log(`[COMMAND] Loading command: ${command.data.name} from ${file}`);
                client.commands.set(command.data.name, command);
                commands.push(command.data);
            } catch (err) {
                console.error(`[COMMAND] Failed to load command ${file}:`, err.message);
            }
        };
    });

    const token = process.env.DISCORD_TOKEN || process.env.DISCORD_BOT_TOKEN;
    const rest = new REST({ version: '10' }).setToken(token);
    const guildId = process.env.DISCORD_GUILD_ID;

    (async () => {
        try {
            const embed = new Discord.EmbedBuilder()
                .setDescription(`Started refreshing application (/) commands.`)
                .setColor(client.config.colors.normal)
            interactionLogs.send({
                username: 'Bot Logs',
                embeds: [embed]
            }).catch(() => {});

            if (guildId) {
                await rest.put(
                    Routes.applicationGuildCommands(client.config.discord.id, guildId),
                    { body: commands },
                );
            } else {
                await rest.put(
                    Routes.applicationCommands(client.config.discord.id),
                    { body: commands },
                );
            }

            const embedFinal = new Discord.EmbedBuilder()
                .setDescription(`Successfully reloaded ${commands.length} application (/) commands.`)
                .setColor(client.config.colors.normal)
            interactionLogs.send({
                username: 'Bot Logs',
                embeds: [embedFinal]
            });


        } catch (error) {
            console.log(error);
        }
    })();
}

