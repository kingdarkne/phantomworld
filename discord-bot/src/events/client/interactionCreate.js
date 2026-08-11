const Discord = require('discord.js');

function loadCaptchaGenerator() {
    try {
        return require("@haileybot/captcha-generator");
    } catch (err) {
        console.warn('[verify] captcha-generator unavailable:', err.message);
        return null;
    }
}

const reactionSchema = require("../../database/models/reactionRoles");
const banSchema = require("../../database/models/userBans");
const verify = require("../../database/models/verify");
const Commands = require("../../database/models/customCommand");
const CommandsSchema = require("../../database/models/customCommandAdvanced");

module.exports = async (client, interaction) => {
    // Commands
    if (interaction.isChatInputCommand() || interaction.isUserContextMenuCommand()) {
        // GUARANTEE Discord gets a response within the 3s window
        if (!interaction.deferred && !interaction.replied) {
            try {
                await interaction.deferReply();
            } catch (deferErr) {
                console.error("[INTERACTION] Failed to defer:", deferErr.message);
            }
        }

        const cmd = client.commands.get(interaction.commandName);
        
        try {
            const data = await banSchema.findOne({ User: interaction.user.id }).maxTimeMS(5000);
            if (data) {
                return client.errNormal({
                    error: "You have been banned by the developers of this bot",
                    type: interaction.deferred ? 'editreply' : 'ephemeral'
                }, interaction);
            }
        } catch (dbErr) {
            console.error("Database check failed:", dbErr.message);
        }

        if (!cmd) {
            try {
                const cmdd = await Commands.findOne({
                    Guild: interaction.guild.id,
                    Name: interaction.commandName,
                }).maxTimeMS(5000);
                if (cmdd) {
                    if (interaction.deferred) return interaction.editReply({ content: cmdd.Responce });
                    return interaction.reply({ content: cmdd.Responce });
                }

                const cmdx = await CommandsSchema.findOne({
                    Guild: interaction.guild.id,
                    Name: interaction.commandName,
                }).maxTimeMS(5000);
                if (cmdx) {
                    if (cmdx.Action == "Normal") {
                        if (interaction.deferred) return interaction.editReply({ content: cmdx.Responce });
                        return interaction.reply({ content: cmdx.Responce });
                    } else if (cmdx.Action == "Embed") {
                        return client.embed({
                            desc: `${cmdx.Responce}`,
                            type: interaction.deferred ? 'editreply' : 'reply'
                        }, interaction);
                    } else if (cmdx.Action == "DM") {
                        if (!interaction.deferred) await interaction.deferReply({ ephemeral: true });
                        interaction.editReply({ content: "I have sent you something in your DMs" });
                        return interaction.user.send({ content: cmdx.Responce }).catch((e) => {
                            client.errNormal({
                                error: "I can't DM you, maybe you have DM turned off!",
                                type: 'editreply'
                            }, interaction);
                        });
                    }
                }
            } catch (cmdErr) {
                console.error("Custom command check failed:", cmdErr.message);
            }
        }

        if (
            interaction.options &&
            typeof interaction.options.getSubcommand === 'function' &&
            interaction.options.getSubcommand(false) === 'help'
        ) {
            const getMentions = (name) => {
                if (typeof client.getSlashMentions !== 'function') return `Use \`/${name}\``;
                try {
                    const info = client.getSlashMentions(name);
                    return info.map((m) => `${m[0]} - \`${m[1]}\``).join("\n");
                } catch { return `Use \`/${name}\``; }
            };

            return client.embed({
                title: `❓・Help panel`,
                desc: `Get help with the commands in \`${interaction.commandName}\` \n\n${getMentions(interaction.commandName)}`,
                type: 'editreply'
            }, interaction)
        }

        if (cmd) {
            try {
                await cmd.run(client, interaction, interaction.options);
            } catch (err) {
                client.emit("errorCreate", err, interaction.commandName, interaction);
            }
        }
    }

    // Verify system
    if (interaction.isButton() && interaction.customId == "Bot_verify") {
        try {
            const data = await verify.findOne({ Guild: interaction.guild.id, Channel: interaction.channel.id }).maxTimeMS(5000);
            if (data) {
                const Captcha = loadCaptchaGenerator();
                if (!Captcha) {
                    return client.errNormal({
                        error: "Verify captcha is unavailable (canvas/Node mismatch). Set Node 18 in KataBump and reinstall node_modules.",
                        type: 'ephemeral'
                    }, interaction);
                }
                let captcha = new Captcha();

                const image = new Discord.AttachmentBuilder(captcha.JPEGStream, { name: "captcha.jpeg" });

                interaction.reply({ files: [image], fetchReply: true }).then(function (msg) {
                    const filter = s => s.author.id == interaction.user.id;

                    interaction.channel.awaitMessages({ filter, max: 1, time: 60000 }).then(response => {
                        if (response.first().content === captcha.value) {
                            response.first().delete().catch(() => {});
                            msg.delete().catch(() => {});

                            client.succNormal({
                                text: "You have been successfully verified!"
                            }, interaction.user).catch(error => { })

                            var verifyUser = interaction.guild.members.cache.get(interaction.user.id);
                            if (verifyUser) verifyUser.roles.add(data.Role).catch(() => {});
                        }
                        else {
                            response.first().delete().catch(() => {});
                            msg.delete().catch(() => {});

                            client.errNormal({
                                error: "You have answered the captcha incorrectly!",
                                type: 'editreply'
                            }, interaction).then(msgError => {
                                setTimeout(() => {
                                    msgError.delete().catch(() => {});
                                }, 2000)
                            })
                        }
                    }).catch(() => {
                        msg.delete().catch(() => {});
                    });
                })
            } else {
                client.errNormal({
                    error: "Verify is disabled in this server! Or you are using the wrong channel!",
                    type: 'ephemeral'
                }, interaction);
            }
        } catch (err) {
            console.error(err);
        }
    }

    // Reaction roles button
    if (interaction.isButton()) {
        var buttonID = interaction.customId.split("-");
        if (buttonID[0] == "reaction_button") {
            try {
                const data = await reactionSchema.findOne({ Message: interaction.message.id }).maxTimeMS(5000);
                if (!data) return;

                const [roleid] = data.Roles[buttonID[1]];

                if (interaction.member.roles.cache.get(roleid)) {
                    interaction.member.roles.remove(roleid).catch(error => { })
                    interaction.reply({ content: `<@&${roleid}> was removed!`, ephemeral: true });
                }
                else {
                    interaction.member.roles.add(roleid).catch(error => { })
                    interaction.reply({ content: `<@&${roleid}> was added!`, ephemeral: true });
                }
            } catch (err) {
                console.error(err);
            }
        }
    }

    // Reaction roles select
    if (interaction.isStringSelectMenu()) {
        // Phantom dropdown help (slim-bot menu merged back)
        if (interaction.customId === 'phantom-help-category') {
            try {
                const { handleHelpSelect } = require('../../lib/helpMenu');
                const payload = handleHelpSelect(interaction);
                await interaction.update(payload);
            } catch (err) {
                console.error('[help] select update failed:', err.message);
                try {
                    await interaction.reply({ content: 'Failed to update help menu.', ephemeral: true });
                } catch (_) {}
            }
            return;
        }
        if (interaction.customId == "reaction_select") {
            try {
                const data = await reactionSchema.findOne({ Message: interaction.message.id }).maxTimeMS(5000);
                if (!data) return;

                let roles = "";
                for (let i = 0; i < interaction.values.length; i++) {
                    const [roleid] = data.Roles[interaction.values[i]];
                    roles += `<@&${roleid}> `;

                    if (interaction.member.roles.cache.get(roleid)) {
                        interaction.member.roles.remove(roleid).catch((error) => { });
                    } else {
                        interaction.member.roles.add(roleid).catch((error) => { });
                    }

                    if ((i + 1) === interaction.values.length) {
                        interaction.reply({ 
                            content: `I have updated the following roles for you: ${roles}`,
                            ephemeral: true,
                        });
                    }
                }
            } catch (err) {
                console.error(err);
            }
        }
    }

    // Tickets
    if (interaction.customId == "Bot_openticket") {
        return require(`${process.cwd()}/src/commands/tickets/create.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_closeticket") {
        return require(`${process.cwd()}/src/commands/tickets/close.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_claimTicket") {
        return require(`${process.cwd()}/src/commands/tickets/claim.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_transcriptTicket") {
        return require(`${process.cwd()}/src/commands/tickets/transcript.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_openTicket") {
        return require(`${process.cwd()}/src/commands/tickets/open.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_deleteTicket") {
        return require(`${process.cwd()}/src/commands/tickets/delete.js`)(client, interaction);
    }
    if (interaction.customId == "Bot_noticeTicket") {
        return require(`${process.cwd()}/src/commands/tickets/notice.js`)(client, interaction);
    }
}
