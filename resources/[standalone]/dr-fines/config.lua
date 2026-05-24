Config = {}

-- Fine Categories
Config.Fines = {
    -- Traffic Violations
    ['speeding'] = {
        label = 'Speeding',
        fines = {
            { speed = 10, fine = 500 },
            { speed = 20, fine = 1000 },
            { speed = 30, fine = 2000 },
            { speed = 50, fine = 3500 },
            { speed = 100, fine = 5000 },
        }
    },
    ['red_light'] = {
        label = 'Running Red Light',
        fine = 750
    },
    ['reckless_driving'] = {
        label = 'Reckless Driving',
        fine = 1500
    },
    ['hit_and_run'] = {
        label = 'Hit and Run',
        fine = 5000
    },
    ['dui'] = {
        label = 'Driving Under Influence',
        fine = 3000
    },
    ['driving_without_license'] = {
        label = 'Driving Without License',
        fine = 2000
    },
    ['illegal_parking'] = {
        label = 'Illegal Parking',
        fine = 250
    },
    ['vehicle_impound'] = {
        label = 'Vehicle Impound Fee',
        fine = 1000
    },

    -- Criminal Offenses
    ['public_intoxication'] = {
        label = 'Public Intoxication',
        fine = 500
    },
    ['disorderly_conduct'] = {
        label = 'Disorderly Conduct',
        fine = 750
    },
    ['assault'] = {
        label = 'Assault',
        fine = 2500
    },
    ['battery'] = {
        label = 'Battery',
        fine = 3500
    },
    ['grand_theft'] = {
        label = 'Grand Theft',
        fine = 10000
    },
    ['petty_theft'] = {
        label = 'Petty Theft',
        fine = 1500
    },
    ['burglary'] = {
        label = 'Burglary',
        fine = 5000
    },
    ['robbery'] = {
        label = 'Robbery',
        fine = 7500
    },
    ['armed_robbery'] = {
        label = 'Armed Robbery',
        fine = 15000
    },
    ['murder'] = {
        label = 'Murder',
        fine = 25000
    },
    ['manslaughter'] = {
        label = 'Manslaughter',
        fine = 15000
    },
    ['kidnapping'] = {
        label = 'Kidnapping',
        fine = 20000
    },
    ['attempted_murder'] = {
        label = 'Attempted Murder',
        fine = 20000
    },

    -- Weapon Offenses
    ['illegal_weapon_possession'] = {
        label = 'Illegal Weapon Possession',
        fine = 5000
    },
    ['concealed_weapon_without_permit'] = {
        label = 'Concealed Weapon Without Permit',
        fine = 2500
    },
    ['brandishing_weapon'] = {
        label = 'Brandishing Weapon',
        fine = 1500
    },
    ['discharge_firearm'] = {
        label = 'Discharge Firearm in City Limits',
        fine = 3000
    },

    -- Drug Offenses
    ['drug_possession'] = {
        label = 'Drug Possession',
        fine = 3000
    },
    ['drug_distribution'] = {
        label = 'Drug Distribution',
        fine = 10000
    },
    ['drug_trafficking'] = {
        label = 'Drug Trafficking',
        fine = 25000
    },
    ['manufacturing_drugs'] = {
        label = 'Manufacturing Drugs',
        fine = 20000
    },

    -- Other Offenses
    ['trespassing'] = {
        label = 'Trespassing',
        fine = 1000
    },
    ['vandalism'] = {
        label = 'Vandalism',
        fine = 2000
    },
    ['fraud'] = {
        label = 'Fraud',
        fine = 5000
    },
    ['impersonating_officer'] = {
        label = 'Impersonating an Officer',
        fine = 7500
    },
    ['evading_arrest'] = {
        label = 'Evading Arrest',
        fine = 4000
    },
    ['resisting_arrest'] = {
        label = 'Resisting Arrest',
        fine = 3000
    },
    ['obstruction_of_justice'] = {
        label = 'Obstruction of Justice',
        fine = 3500
    },
    ['harassment'] = {
        label = 'Harassment',
        fine = 1000
    },
    ['stalking'] = {
        label = 'Stalking',
        fine = 2500
    },
}

-- Fine Reduction for paying immediately
Config.ImmediatePaymentDiscount = 0.1 -- 10% discount

-- Fine increase for repeat offenders
Config.RepeatOffenderMultiplier = 1.5 -- 50% increase for repeat offenders

-- Maximum fine amount
Config.MaxFineAmount = 50000

-- Minimum fine amount
Config.MinFineAmount = 100

-- Enable fine notifications
Config.EnableNotifications = true

-- Enable fine payment via bank
Config.EnableBankPayment = true

-- Enable fine payment via cash
Config.EnableCashPayment = true

-- Fine payment deadline (in hours)
Config.PaymentDeadline = 24

-- Interest rate for late payments (per day)
Config.LatePaymentInterest = 0.05 -- 5% per day
