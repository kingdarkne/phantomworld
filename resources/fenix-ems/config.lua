Config = {}

Config.Debug = false

-- Only dispatch AI EMS when fewer than this many EMS players are on duty.
Config.EmsJobsRequired = 1
Config.EmsJobs = {
    { jobName = 'ambulance', onDutyOnly = true },
    { jobName = 'ems', onDutyOnly = true },
    { jobName = 'lsfd', onDutyOnly = true },
}

-- Seconds before AI EMS is auto-dispatched after death/last stand.
Config.AutoDispatchDelay = 8

-- Cooldown between AI EMS calls for the same player (seconds).
Config.CallCooldown = 120

-- Ambulance model and paramedic ped.
Config.AmbulanceModel = `ambulance`
Config.MedicModel = `s_m_m_paramedic_01`

-- Blip while EMS is responding.
Config.BlipSprite = 153
Config.BlipColor = 1
Config.BlipLabel = 'AI EMS'

-- Revive outcome.
Config.ReviveHealth = 200
Config.ReviveArmor = 0
Config.ChargeFee = 250 -- set 0 to disable

-- How close the ambulance must get before reviving (meters).
Config.ReviveDistance = 12.0

-- Max time before AI EMS gives up (ms).
Config.ResponseTimeout = 120000
