Config = {}

-- Tips configuration
Config.Tips = {
    -- Gun Permit Tips
    {
        category = 'gun_permit',
        title = 'Gun Permit Information',
        tips = {
            'You need a weapon license to purchase firearms legally from Ammunation',
            'Apply for your weapon license at City Hall',
            'Weapon licenses can be revoked for criminal activity',
            'Keep your firearms registered to avoid legal trouble',
            'Concealed carry permits require additional background checks',
            'Never point a firearm at anyone unless in self-defense',
            'Store your weapons safely when not in use',
            'Report lost or stolen weapons immediately to police',
            'Illegal weapon possession can result in heavy fines and jail time',
            'Practice proper firearm safety at all times',
        },
        cooldown = 300 -- Show every 5 minutes
    },
    -- Vehicle Tips
    {
        category = 'vehicles',
        title = 'Vehicle Tips',
        tips = {
            'Always park your vehicle in designated parking areas to avoid fines',
            'Vehicle insurance can help cover repair costs',
            'Regular maintenance at customs shops keeps your car running smoothly',
            'Speeding tickets can add up quickly - drive safely',
            'Call a tow truck if your vehicle breaks down',
            'Vehicle impound fees can be expensive - avoid parking violations',
            'Keep your fuel tank filled to avoid running out',
            'Use your turn signals when changing lanes',
            'Watch for pedestrians in busy areas',
            'Customize your vehicle at Benny\'s for unique upgrades',
        },
        cooldown = 300
    },
    -- Job Tips
    {
        category = 'jobs',
        title = 'Job Tips',
        tips = {
            'Check your job duties at your workplace',
            'Higher job ranks unlock better pay and responsibilities',
            'You can change jobs at City Hall',
            'Some jobs require specific licenses or certifications',
            'Work with your team for better efficiency',
            'Follow workplace safety guidelines',
            'Report workplace incidents to your supervisor',
            'Keep track of your work hours',
            'Professional conduct can lead to promotions',
            'Learn all aspects of your job for advancement',
        },
        cooldown = 300
    },
    -- Money Tips
    {
        category = 'money',
        title = 'Money Management Tips',
        tips = {
            'Save money for emergencies and unexpected expenses',
            'Invest in skills that can increase your earning potential',
            'Avoid unnecessary purchases to build savings',
            'Use bank accounts for secure money storage',
            'Keep track of your income and expenses',
            'Look for legal ways to earn extra income',
            'Avoid get-rich-quick schemes that may be illegal',
            'Budget your spending to avoid financial trouble',
            'Consider long-term financial goals',
            'Seek financial advice when needed',
        },
        cooldown = 300
    },
    -- Legal Tips
    {
        category = 'legal',
        title = 'Legal Tips',
        tips = {
            'Know your rights when interacting with law enforcement',
            'Cooperate with police during investigations',
            'Request a lawyer if you\'re arrested',
            'Keep important documents like ID and licenses on hand',
            'Report crimes to help keep the city safe',
            'Avoid associating with known criminals',
            'Understand the consequences of criminal activity',
            'Stay informed about city laws and regulations',
            'Respect other citizens and their property',
            'Legal troubles can affect your job and reputation',
        },
        cooldown = 300
    },
    -- Health Tips
    {
        category = 'health',
        title = 'Health Tips',
        tips = {
            'Visit the hospital for serious injuries',
            'Keep medical supplies handy for emergencies',
            'Stay hydrated and eat regularly',
            'Rest when you\'re injured to recover faster',
            'Exercise regularly to maintain good health',
            'Avoid dangerous situations when possible',
            'Call EMS for medical emergencies',
            'Health insurance can cover medical costs',
            'Mental health is just as important as physical health',
            'Take breaks to avoid burnout',
        },
        cooldown = 300
    },
    -- Social Tips
    {
        category = 'social',
        title = 'Social Tips',
        tips = {
            'Be respectful to other players in the city',
            'Help new players learn the ropes',
            'Join community events to meet people',
            'Communication is key to good relationships',
            'Avoid toxic behavior - it ruins the experience',
            'Report rule violations to staff',
            'Make friends and build connections',
            'Participate in city activities',
            'Be a positive influence in the community',
            'Remember it\'s just a game - have fun responsibly',
        },
        cooldown = 300
    },
    -- Housing Tips
    {
        category = 'housing',
        title = 'Housing Tips',
        tips = {
            'Choose a location that fits your lifestyle',
            'Consider proximity to your workplace',
            'Secure your property with locks and alarms',
            'Pay rent on time to avoid eviction',
            'Decorate your home to make it comfortable',
            'Know your tenant rights and responsibilities',
            'Report maintenance issues to your landlord',
            'Keep your living space clean and organized',
            'Get to know your neighbors',
            'Home ownership requires ongoing maintenance',
        },
        cooldown = 300
    },
    -- Business Tips
    {
        category = 'business',
        title = 'Business Tips',
        tips = {
            'Research before starting a business',
            'Create a business plan for success',
            'Hire reliable employees',
            'Provide good customer service',
            'Keep accurate financial records',
            'Market your business effectively',
            'Adapt to changing market conditions',
            'Network with other business owners',
            'Comply with all business regulations',
            'Reinvest profits for growth',
        },
        cooldown = 300
    },
    -- Emergency Tips
    {
        category = 'emergency',
        title = 'Emergency Tips',
        tips = {
            'Call 911 for police emergencies',
            'Call EMS for medical emergencies',
            'Stay calm during emergency situations',
            'Follow emergency responder instructions',
            'Know emergency exits in buildings',
            'Keep emergency contacts accessible',
            'Learn basic first aid',
            'Have an emergency plan',
            'Stay informed during emergencies',
            'Help others when safe to do so',
        },
        cooldown = 300
    },
}

-- Display settings
Config.DisplayInterval = 600 -- Show a tip every 10 minutes (in seconds)
Config.DisplayDuration = 10 -- How long to display the tip (in seconds)
Config.EnableOnJoin = true -- Show a tip when player joins
Config.EnableRandomTips = true -- Show random tips periodically

-- UI settings
Config.Position = 'top' -- top, bottom, left, right
Config.BackgroundColor = 'rgba(0, 0, 0, 0.8)'
Config.TextColor = '#ffffff'
Config.TitleColor = '#f1e542'
Config.FontSize = 18
