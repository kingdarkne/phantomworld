/**
 * Extra slash command builders restored from the TRex backup (priority suites).
 */
import { SlashCommandBuilder, PermissionFlagsBits, ChannelType } from 'discord.js';

export const restoredSlashCommands = [
  new SlashCommandBuilder()
    .setName('mod')
    .setDescription('Moderation tools')
    .setDefaultMemberPermissions(PermissionFlagsBits.ModerateMembers)
    .addSubcommand((s) =>
      s
        .setName('ban')
        .setDescription('Ban a member')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true))
        .addStringOption((o) => o.setName('reason').setDescription('Reason'))
        .addIntegerOption((o) =>
          o.setName('days').setDescription('Delete message history days (0-7)').setMinValue(0).setMaxValue(7),
        ),
    )
    .addSubcommand((s) =>
      s
        .setName('unban')
        .setDescription('Unban a user by ID')
        .addStringOption((o) => o.setName('userid').setDescription('Discord user ID').setRequired(true))
        .addStringOption((o) => o.setName('reason').setDescription('Reason')),
    )
    .addSubcommand((s) =>
      s
        .setName('kick')
        .setDescription('Kick a member')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true))
        .addStringOption((o) => o.setName('reason').setDescription('Reason')),
    )
    .addSubcommand((s) =>
      s
        .setName('timeout')
        .setDescription('Timeout a member')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true))
        .addIntegerOption((o) =>
          o.setName('minutes').setDescription('Minutes').setRequired(true).setMinValue(1).setMaxValue(40320),
        )
        .addStringOption((o) => o.setName('reason').setDescription('Reason')),
    )
    .addSubcommand((s) =>
      s
        .setName('untimeout')
        .setDescription('Remove a timeout')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
    )
    .addSubcommand((s) =>
      s
        .setName('warn')
        .setDescription('Warn a member')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true))
        .addStringOption((o) => o.setName('reason').setDescription('Reason')),
    )
    .addSubcommand((s) =>
      s
        .setName('warnings')
        .setDescription('Show warnings for a member')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
    )
    .addSubcommand((s) =>
      s
        .setName('clear')
        .setDescription('Bulk delete messages')
        .addIntegerOption((o) =>
          o.setName('amount').setDescription('1-100').setRequired(true).setMinValue(1).setMaxValue(100),
        )
        .addUserOption((o) => o.setName('user').setDescription('Only delete from this user')),
    )
    .addSubcommand((s) => s.setName('lock').setDescription('Lock this channel'))
    .addSubcommand((s) => s.setName('unlock').setDescription('Unlock this channel')),

  new SlashCommandBuilder()
    .setName('ticket')
    .setDescription('Support tickets')
    .addSubcommand((s) =>
      s
        .setName('setup')
        .setDescription('Configure ticket category + support role (admin)')
        .addChannelOption((o) =>
          o
            .setName('category')
            .setDescription('Category for ticket channels')
            .addChannelTypes(ChannelType.GuildCategory)
            .setRequired(true),
        )
        .addRoleOption((o) => o.setName('role').setDescription('Support role').setRequired(true))
        .addChannelOption((o) =>
          o.setName('logs').setDescription('Optional log channel').addChannelTypes(ChannelType.GuildText),
        ),
    )
    .addSubcommand((s) =>
      s
        .setName('create')
        .setDescription('Open a support ticket')
        .addStringOption((o) => o.setName('reason').setDescription('Why are you opening a ticket?')),
    )
    .addSubcommand((s) => s.setName('close').setDescription('Close this ticket channel'))
    .addSubcommand((s) =>
      s.setName('panel').setDescription('Post an Open Ticket button panel (admin)'),
    )
    .addSubcommand((s) =>
      s
        .setName('add')
        .setDescription('Add a user to this ticket')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
    )
    .addSubcommand((s) =>
      s
        .setName('remove')
        .setDescription('Remove a user from this ticket')
        .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
    ),

  new SlashCommandBuilder().setName('pause').setDescription('Pause music'),
  new SlashCommandBuilder().setName('resume').setDescription('Resume music'),
  new SlashCommandBuilder()
    .setName('volume')
    .setDescription('Set music volume (1-200)')
    .addIntegerOption((o) => o.setName('level').setDescription('Volume').setRequired(true).setMinValue(1).setMaxValue(200)),
  new SlashCommandBuilder()
    .setName('loop')
    .setDescription('Toggle track loop')
    .addStringOption((o) =>
      o
        .setName('mode')
        .setDescription('Loop mode')
        .addChoices(
          { name: 'Toggle', value: 'toggle' },
          { name: 'Track', value: 'track' },
          { name: 'Off', value: 'none' },
        ),
    ),
  new SlashCommandBuilder().setName('nowplaying').setDescription('Show the current track'),
  new SlashCommandBuilder().setName('np').setDescription('Alias of /nowplaying'),

  new SlashCommandBuilder()
    .setName('hug')
    .setDescription('Hug someone')
    .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
  new SlashCommandBuilder()
    .setName('kiss')
    .setDescription('Kiss someone')
    .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
  new SlashCommandBuilder()
    .setName('pat')
    .setDescription('Pat someone')
    .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
  new SlashCommandBuilder()
    .setName('slap')
    .setDescription('Slap someone')
    .addUserOption((o) => o.setName('user').setDescription('User').setRequired(true)),
  new SlashCommandBuilder().setName('meme').setDescription('Random meme'),
  new SlashCommandBuilder()
    .setName('howgay')
    .setDescription('Gay rate meter')
    .addUserOption((o) => o.setName('user').setDescription('User')),
  new SlashCommandBuilder()
    .setName('ship')
    .setDescription('Love meter')
    .addUserOption((o) => o.setName('user1').setDescription('First user').setRequired(true))
    .addUserOption((o) => o.setName('user2').setDescription('Second user').setRequired(true)),
  new SlashCommandBuilder().setName('fact').setDescription('Random useless fact'),
  new SlashCommandBuilder().setName('dog').setDescription('Random dog photo'),
  new SlashCommandBuilder().setName('cat').setDescription('Random cat photo'),
  new SlashCommandBuilder()
    .setName('roast')
    .setDescription('Roast a user')
    .addUserOption((o) => o.setName('user').setDescription('User')),
  new SlashCommandBuilder()
    .setName('ascii')
    .setDescription('ASCII art text')
    .addStringOption((o) => o.setName('text').setDescription('Text').setRequired(true)),
].map((c) => c.toJSON());
