const fetch = require("node-fetch");
const generator = require('generate-password');

module.exports = async (client, interaction, args) => {

    const password = generator.generate({
        length: 10,
        symbols: true,
        numbers: true
    });

    const user = interaction.options.getUser('user');

    if (!user) return client.errUsage({ usage: "hack [mention user]", type: 'editreply' }, interaction)

    const wait = (ms) => new Promise(resolve => setTimeout(resolve, ms));

    let msg = await client.embed({
        title: '💻・Hacking',
        desc: `The hack on ${user} started...`,
        type: 'editreply'
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `Searching for user information..`,
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `Searching for IP address...`,
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `The users ip address was found!`,
        fields: [
            {
                name: '🔗┆IP Adress',
                value: `\`\`\`127.0.0.1\`\`\``,
                inline: true,
            }
        ],
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `Searching for Discord login...`,
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `The users discord login was found!`,
        fields: [
            {
                name: '📨┆Email',
                value: `\`\`\`${user.username}onDiscord@gmail.com\`\`\``
            },
            {
                name: '🔑┆Password',
                value: `\`\`\`${password}\`\`\``
            }
        ],
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `Search for Discord token...`,
        type: 'editreply'
    }, interaction);

    await wait(1000);
    try {
        const res = await fetch(`https://some-random-api.com/bottoken?${user.id}`);
        const json = await res.json();
        
        await client.embed({
            title: '💻・Hacking',
            desc: `The users discord account token was found!`,
            fields: [
                {
                    name: '🔧┆Token',
                    value: `\`\`\`${json.token}\`\`\``,
                    inline: true
                }
            ],
            type: 'editreply',
        }, interaction);
    } catch (e) {
        await client.embed({
            title: '💻・Hacking',
            desc: `The users discord account token was found!`,
            fields: [
                {
                    name: '🔧┆Token',
                    value: `\`\`\`Unavailable\`\`\``,
                    inline: true
                }
            ],
            type: 'editreply',
        }, interaction);
    }

    await wait(1000);
    await client.embed({
        title: '💻・Hacking',
        desc: `Reporting account to Discord for breaking TOS...`,
        type: 'editreply',
    }, interaction);

    await wait(1000);
    await client.succNormal({ text: `${user} is succesfully hacked. All the user's information was send to your dm`, type: 'editreply' }, interaction);
    
    client.embed({
        title: '😂・Pranked',
        image: "https://media1.tenor.com/images/05006ed09075a0d6965383797c3cea00/tenor.gif?itemid=17987788",
    }, interaction.user).catch(() => {});
}
