Config = {}

Config.Enabled = true
Config.MinIntervalMs = 3 * 60 * 1000
Config.MaxIntervalMs = 7 * 60 * 1000
-- false = everyone can get GTAO-style calls; true = only Underground Contact (Street Hustler)
Config.RequireContractsMeta = false
Config.RingSeconds = 12

Config.Contacts = {
    {
        id = 'lester',
        name = 'Lester',
        title = 'Silent Contract',
        type = 'hitman',
        blurb = 'I need someone removed — quietly. GPS pinged.',
        payout = { min = 1200, max = 2800 },
        pedModel = `a_m_y_hipster_01`,
    },
    {
        id = 'martin',
        name = 'Martin Madrazo',
        title = 'Collection Job',
        type = 'robbery',
        blurb = 'A shop owes us. Hit the register — don\'t get caught.',
        payout = { min = 800, max = 2200 },
    },
    {
        id = 'simeon',
        name = 'Simeon Yetarian',
        title = 'Repo Request',
        type = 'repo',
        blurb = 'Customer skipped payments. Bring me that car.',
        payout = { min = 600, max = 1600 },
    },
    {
        id = 'dispatch',
        name = 'LSPD Tip Line',
        title = 'Citizen Tip',
        type = 'cops',
        blurb = 'Armed suspect spotted. Take them down — freeroam bounty.',
        payout = { min = 900, max = 2000 },
        copsOnly = false,
    },
    {
        id = 'paige',
        name = 'Paige Harris',
        title = 'Quick Hit',
        type = 'hitman',
        blurb = 'One target. No questions. GPS is live.',
        payout = { min = 1500, max = 3200 },
        pedModel = `g_m_y_korean_01`,
    },
    {
        id = 'gerald',
        name = 'Gerald',
        title = 'Corner Store',
        type = 'robbery',
        blurb = 'Register\'s fat tonight. In and out.',
        payout = { min = 700, max = 1800 },
    },
}
