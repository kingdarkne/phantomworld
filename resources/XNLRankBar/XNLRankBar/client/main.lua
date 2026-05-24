--[[
=====================================================================
                 Script License and Usage V1.2
=====================================================================

This script has been fully written from scratch by VenomXNL
FiveM Account: https://forum.fivem.net/u/VenomXNL/

I've spend a sh*tload of time on research to get it to function like
I wanted (near original game style), spend lots of time on trial 
and errors, and even debugging the original game to be "100% certain"
of the correct parameters. So PLEASE have decency and respect the
small 'requests' in my license :) 


I won't put up all kinds of MIT, CC or what ever licenses etc here for
you to read and/or understand. Just some basic 'rules' which count as
my license and license limitations:

Limitations, You:
 - CAN NOT Claim that this script is yours or that you've made it
 - CAN NOT Make a small adaption and call it an "improved version" or "updated version"
 - CAN NOT EVER sell this script or include it in 'sold bundles'
 - CAN NOT Redistribute it elsewhere (I MYSELF will maintain the latest release version on MY github)
 - CAN NOT Re-upload your 'own version' without WRITTEN permission on my FiveM account!
 - CAN NOT Use it on servers which violate the FiveM ToS about making profits! (Yeah, aint I a bitch? :P)

However:
 - You CAN Implement it in your own game-mode/server
 - You CAN adapt/change it (OBVIOUSLY) to your own needs for your server (just NO re-uploading without permission)
 
=========================================================================================
 Implementations into frameworks (Like ESX, vRP, EssentialMode or whatever is out there)
=========================================================================================
 So we can't redistribute it into our framework without permission?
 Yes you CAN implement AND redistribute it into frameworks, altough I would HIGHLY appreciate
 it that you would send me a message (PM or so) that you are using it in your framework so
 that I know that my script is of good use and being a useful resource
 
 What is MANDATORY though when implementing it in frameworks like ESX, vRP or any other,
 is that you DO PUT THE APPROPRIATE credits in the code at my rankbar scrip section(s)!


=========================================================================================
 Implementations or 'moduled versions' for gamemodes
=========================================================================================
 I'm I for example allowed to "just make an ESX version" as 'addon' for ESX and then
 publish it for ESX users?
 
 NO! You will NEED PERMISSION to do so! 
 WHY? Well simple: Since I want to prevent the forums and releases section from flooding
 with all kinds of 'alternate versions' of my script like for example:
 - XNLRankBar (original)
 - XNLRankBar [ESX Addon]
 - XNLRankBar [vRP Addon]
 - XNLRankBar [EsMode Addon]
 - XNLRankBar [MyFramework Addon]
 
 etc etc etc,
 
 This will just causes a freaking mess on the forum and impossible to decently
 maintain script. So IF there is (ENOUGH!) need/requests for an addon for one of the
 frameworks (and the framework itself doesn't want or refuses to implement it) THEN
 ONE other developer/scripter can get permission to adapt the code to make it compatible
 for that framework, but ONLY ON REQUEST.
 
 
=========================================================================================
 Q&A
=========================================================================================
 Q: Will you (VenomXNL) make 'alternate versions' to support frameworks like ESX, vRP etc?
 A: NO I WILL NOT, I Do NOT use frameworks myself (I'm developing my OWN 100% 
    custom server from scratch with my own (non-released) 'framework'. And thus I have no
	interest in installing other frameworks or scripts to test adaptions.
	When i would do this i would need to either:
	 A: Install a 'massive framework' and run it without knowing what the code's actually do
	 or B: Install the framework and read all code so i know what runs on my server.
	So NOPE, not going to happen, When I write, run or test code I want to know 100% what 
	that code does, or even better: have written it > 99% by myself.

 Q: Why are you so strict on 'the license' and usage?
 A: Well basically i'm not strict, you can use it, adapt it, use it on your server etc etc,
    You just can't 'steal the code' and take credits, profits or any other 'common sense abuse' of it 
	IF you think those 'limitatations' are 'unfair' or 'to strict' then you are proberbly not
	having the 'correct intentions' with code written by others ;)

 Q: Why do you have so much comments in your code?
 A: To make sure it is well documented and explained as clearly as possible, so it's usable for
    "all levels" of scripters (from beginner to advanced). And also in the HOPES to get more 
	beginners interested in coding due to them actually understanding what it does and thus
	them actually learning scripting themselves to :)
	
 Q: You seem to limit 'extra versions' for frameworks, do you have something against frameworks?
 A: Well... euhm.. yes and no... :
    I don't mind frameworks, don't mind basic toolsets to make a basic setup/startup.
	What I DO mind is that so many people install sh*tloads of frameworks and addonds for them
	without understanding the most basic aspect of scripting in games like these.
	
	The issue I have with that is that it often causes issues, people complaining about conflicts
	and script problems and 'admins' running servers without actually knowing what the server and or
	scripts do on their server.. And then the part that AWESOME scripts are made but only are compatible
	with "sh*tloads or requirements" like entire frameworks for just a "simple small extra function".
	
	I would rather see scripts being developed in the style like this one for example, where the script
	has it's own "OnPlayerEvent" functions that are called so that everyone can use them.
	
	So NOPE i don't have anything against frameworks, but DO have something against the way how many people
	use them without knowing a single bit of coding and then complaining at the developers about conflicting scripts
	and due to that lots of scripts flooding the forums with 'alternate versions' to "fix an issue" which isn't even
	an issue when the script would just be made "universally compatible"
	
]]

--=========================================================================================
-- Script information and details
--=========================================================================================
-- These are the original Rockstar XP/RP requirements per level (till level 100), after level 100 i'm using a 'simple formula' to
-- calculate the correct levels and related XP floor and ceilings for those levels since from there on it's just a 'base offset'
-- 28500XP EXTRA which is required per level which will be increased by 50 for each next level.
--
-- Basic Explanation: Going from level 99 to level 100 requires  28550 XP ontop of the XP the player already has.
--                    Going from level 100 to level 101 requires 28600 XP ontop of the XP the player already has.
--
-- So from level 100 and up I can just use a simple "for loop formula" to generate/calculate the correct XP levels
--
-- BUT bellow level 100 there isn't really a 'steady structure', in the XP requirements bellow level 100 rockstar
-- has made several 'strange jumps' in structure (not by adding 50 every time or a 'steady/logical' amount).
-- Changes like +500, +400, +600, +1100 and even -400 difference in the extra XP needed for the next level are seen.
-- Therefor it was easier (and AFAIK the only way) to guarantee correct XP levels/requirements :)
--
-- Ofcourse you are not obligated to stick to these levels and ranks, and you CAN change them, but I have created it this way
-- since i'm making a server with all single player features, all multiplayer features and LOTS more object/location interactions
-- but I/we want to re-create the 'normal gta' experiance with all 'basic game stuff' working like it does normally,
-- therefor I decided to use the original levels/style...
--
-- PLEASE DO KEEP IN MIND: I DO NOT! offer support for using other level styles or XP requirements!
-- I did NOT designed this script to do so, and nor do I have time to make it 'custom' for lots of different servers and people's
-- requirements per server style. However it should not be that hard to change the XP requirements and/or style for calculation :)
--
-- More information about these ranks and their "structure" can be found at:
-- https://gta.fandom.com/wiki/Rank
-- EASIER XP REQUIREMENTS (50% of original Rockstar values)
local RockstarRanks = {
400, 1050, 1900, 3050, 4750, 6250, 8000, 9900, 12000, 14250, 16700, 19350, 22100, 25100, 28200, 31500, 34950, 38550, 42350, 46250,
50350, 54600, 59000, 63550, 68250, 73100, 78100, 83250, 88550, 94000, 99600, 105350, 111200, 117250, 123400, 129700, 136150,
142750, 149500, 156350, 163400, 170500, 177800, 185250, 192800, 200500, 208300, 216300, 224400, 232600, 241000, 249500, 258150, 266900,
275800, 284800, 294000, 303250, 312700, 322250, 331900, 341700, 351650, 361700, 371900, 382250, 392700, 403250, 413950, 424800, 435750,
446800, 458000, 469350, 480800, 492350, 504050, 515900, 527850, 539900, 552100, 564400, 576850, 589400, 602100, 614900, 627800,
640850, 654050, 667300, 680700, 694250, 707900, 721650, 735550, 749550, 763650, 777900, 792175}

local function getPlayerData()
	if GetResourceState('qbx_core') == 'started' then
		return exports.qbx_core:GetPlayerData()
	end
	if GetResourceState('qb-core') == 'started' then
		local QBCore = exports['qb-core']:GetCoreObject()
		return QBCore.Functions.GetPlayerData()
	end
	return nil
end

function tablePrintOut(table)
    if type(table) == 'table' then
       local s = '\n{ '
       for k,v in pairs(table) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. tablePrintOut(v) .. ',\n'
       end
       return s .. '}'
    else
       return tostring(table)
    end
 end

-- example how to trigger it



--===================================================================================
-- "Settings" you can change
--===================================================================================
XNL_UseRedBarWhenLosingXP = true	-- This sets if the bar should turn red when a player is LOSING XP (due to an admin 'punishment' for example!)
XNL_MaxPlayerLevel = 500 			-- Sets the maximum level (Maximum which can be used is 7999!)
									-- This will also prevent the player from getting more XP than possible
									-- IF you use my variable to set/read the player XP
XNL_EnableZKeyForRankbar = true		-- This Enables/Disables (when you set it to false) the Rankbar showing up when the player presses Z on the keyboard							 
							 
--===================================================================================
-- Variable(s) you should NOT be messing with! These are used by the script to make
-- sure everything runs smooth and is calculated well for 'followup' animations 
-- in the Rank Bar
--===================================================================================
XNL_CurrentPlayerXP = 0
XNL_driving = 0
XNL_crafting = 0


RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
	-- Wait for qbx_core server-side to fully register the player before calling the callback
	Wait(2000)
	local pdata = getPlayerData()
	if not pdata or not pdata.citizenid then return end
	local experience = lib.callback.await('xnlrankbar:server:getxpcb', false)
	if experience then
		local dbXP = tonumber(experience.driving) or 0
		-- Never overwrite with lower value: XP may have been added before this callback returned
		XNL_CurrentPlayerXP = math.max(XNL_CurrentPlayerXP, dbXP)
		XNL_crafting = tonumber(experience.crafting) or 0
		-- Initialize the rank bar display so the player sees their rank on spawn
		XNL_SetInitialXPLevels(XNL_CurrentPlayerXP, true, false)
	end
end)

-- Save XP when character unloads (logout/switch) so it persists
RegisterNetEvent('QBCore:Client:OnPlayerUnload')
AddEventHandler('QBCore:Client:OnPlayerUnload', function()
	local pdata = getPlayerData()
	if pdata and pdata.citizenid and XNL_CurrentPlayerXP and XNL_CurrentPlayerXP >= 0 then
		TriggerServerEvent('xnlrankbar:server:setxp', XNL_CurrentPlayerXP, pdata.citizenid)
	end
end)

-- Periodic save of XP so it persists even if player disconnects without gaining more XP
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(30000)
		local pdata = getPlayerData()
		if pdata and pdata.citizenid and XNL_CurrentPlayerXP and XNL_CurrentPlayerXP >= 0 then
			TriggerServerEvent('xnlrankbar:server:setxp', XNL_CurrentPlayerXP, pdata.citizenid)
		end
	end
end)

--===================================================================================
--   !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!
--===================================================================================
-- These are BASIC EXAMPLE COMMANDS so you can test the script/rankbar INSTANTLY
-- on your game by using these commands:
-- XNLSetBaseXPExample [amountofxp]
-- XNLAddXPExample [amountofxp]
-- XNLRemoveXPExample [amountofxp]
--
-- OBVIOUSLY you enter those WITHOUT the brackets ([ or ])
-- AND... even obvious: REMOVE THESE THREE COMMANDS WHEN YOU ARE GOING TO USE
-- THIS SCRIPT!!!!!
--===================================================================================
--   !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!  !!WARNING!!
--===================================================================================

--[[RegisterCommand("XNLAddXPExample",function(source, args)
	local FirstParam = args[1]
	TestNR = tonumber(FirstParam)
	XNL_AddPlayerXP(TestNR)
end)

RegisterCommand("XNLRemoveXPExample",function(source, args)
	local FirstParam = args[1]
	TestNR = tonumber(FirstParam)
	XNL_RemovePlayerXP(TestNR)
end)

RegisterCommand("XNLSetBaseXPExample",function(source, args)
	local FirstParam = args[1]
	TestNR = tonumber(FirstParam)
	XNL_SetInitialXPLevels(TestNR, true, true)
end)]]  


--===================================================================================
-- This thread will Enable the player to press Z to show the current XP/Rankbar
-- IT IS NOT TESTED WITH CONTROLLERS! please check or implement controller
-- combatability yourself since we don't use controllers and neither allow them
--===================================================================================
Citizen.CreateThread(function()
	if not XNL_EnableZKeyForRankbar then return end
	while true do
	Wait(1)
		if IsControlJustPressed(0, 20) then
			CurLevel = XNL_GetLevelFromXP(XNL_CurrentPlayerXP)
			CreateRankBar(XNL_GetXPFloorForLevel(CurLevel), XNL_GetXPCeilingForLevel(CurLevel), XNL_CurrentPlayerXP, XNL_CurrentPlayerXP, CurLevel, false)

			-- Also show wanted info from dr-wanted, if available
			if GetResourceState('dr-wanted') == 'started' then
				lib.callback('dr-wanted:getSelf', false, function(wanted)
					if wanted and (wanted.level or 0) > 0 then
						local msg = ('Wanted: %d stars (%d pts)'):format(wanted.level or 0, wanted.points or 0)
						TriggerEvent('QBCore:Notify', msg, 'error', 5000)
					end
				end)
			end

			-- ShowHudComponentThisFrame(3) -- Enable this line if you want to display the native player CASH
			--ShowHudComponentThisFrame(4) -- Enable this line if you want to display the native player BANK amount
			-- NOTE ON THE TWO ABOVE: Those are NOT implemented in this script! but just as 'extra info' for a 'complete hud'
			-- print(CurLevel)
		end
	end
end)


--===================================================================================
-- Export Functions so they can more easily be called from external scripts :)
-- as suggested by one of the Elements (oganesson):
-- https://forum.fivem.net/t/release-xnlrankbar-fully-working-original-gta-rankbar-xp-bar-natively-with-original-gta-levels/318839/12?u=venomxnl
--===================================================================================
exports('Exp_XNL_SetInitialXPLevels', function(EXCurrentXP, EXShowRankBar, EXShowRankBarAnimating)
	XNL_SetInitialXPLevels(EXCurrentXP, EXShowRankBar, EXShowRankBarAnimating)
end)

exports('Exp_XNL_AddPlayerXP', function(EXXPAmount)
	XNL_AddPlayerXP(EXXPAmount)
end)

exports('Exp_XNL_RemovePlayerXP', function(EXXPAmount)
	XNL_RemovePlayerXP(EXXPAmount)
end)

exports('Exp_XNL_GetCurrentPlayerXP', function()
	return tonumber(XNL_GetCurrentPlayerXP())
end)

exports('Exp_XNL_GetLevelFromXP', function(EXXPAmount)
	return XNL_GetLevelFromXP(EXXPAmount)
end)

exports('Exp_XNL_GetCurrentPlayerLevel', function()
	return tonumber(XNL_GetCurrentPlayerLevel())
end)

exports('Exp_XNL_GetXPFloorForLevel', function(IntLvl)
	return tonumber(XNL_GetXPFloorForLevel(IntLvl))
end)
exports('Exp_XNL_GetXPCeilingForLevel', function(IntLvl)
	return tonumber(XNL_GetXPCeilingForLevel(IntLvl))
end)

--===================================================================================
-- Client Trigger Events (so it can PARTIALLY be used server  sided :) )
-- as requested by createdbyeric:
-- https://forum.fivem.net/t/release-xnlrankbar-fully-working-original-gta-rankbar-xp-bar-natively-with-original-gta-levels/318839/15?u=venomxnl
--===================================================================================
RegisterNetEvent("XNL_NET:XNL_SetInitialXPLevels")
AddEventHandler("XNL_NET:XNL_SetInitialXPLevels", function(NetCurrentXP, NetShowRankBar, NetShowRankBarAnimating)
	XNL_SetInitialXPLevels(NetCurrentXP, NetShowRankBar, NetShowRankBarAnimating)
end)

RegisterNetEvent("XNL_NET:AddPlayerXP")
AddEventHandler("XNL_NET:AddPlayerXP", function(NetXPAmmount)
	XNL_AddPlayerXP(NetXPAmmount)
end)

RegisterNetEvent("XNL_NET:RemovePlayerXP")
AddEventHandler("XNL_NET:RemovePlayerXP", function(NetXPAmmount)
	XNL_RemovePlayerXP(NetXPAmmount)
end)


--===================================================================================
-- These are functions you could/can use to make this script 'ready to use' and to
-- (make it ) interface with your own scripts, game modes etc :)
--===================================================================================
function XNL_SetInitialXPLevels(CurrentXP, ShowRankBar, ShowRankBarAnimating)
	-- This function sets the 'inital XP level' (when the player first spawns for example)
	-- When you set ShowRankBar to true, it will show the rankbar on initial setup/spawn
	-- When you set ShowRankBarAnimating it will 'animate' the currentlevel from
	-- the bottom of that rank to the amount of XP the player has for that rank

	
	-- You can ofcourse also use the normal MP0_CHAR_XP_FM stats to set and get the XP
	-- just like I do myself, but for the purpose of releasing this (portion of my)
	-- script I have made sure to use an other 'different variable' to ensure that I would
	-- "not just f*ck up" stats or so on your server :)
	XNL_CurrentPlayerXP = CurrentXP
	
	if ShowRankBar then
		CurLevel = XNL_GetLevelFromXP(CurrentXP)
		AnimateFrom = CurrentXP
		if ShowRankBarAnimating then
			AnimateFrom = XNL_GetXPFloorForLevel(CurLevel)
		end
		CreateRankBar(XNL_GetXPFloorForLevel(CurLevel), XNL_GetXPCeilingForLevel(CurLevel), AnimateFrom, XNL_CurrentPlayerXP, CurLevel, false)
	end
end

function XNL_GetCurrentPlayerXP()
	-- Like the name suggests: This function simply returns the current TOTAL player xp amount
	-- NOTE: Which is set in MY variable in THIS SCRIPT! if you use other variables
	-- like MP0_CHAR_XP_FM for example, you would need to change that ofcourse!
	return XNL_CurrentPlayerXP
end

function XNL_GetCurrentPlayerLevel()
	-- Like the name suggests: This function simply returns the current player level
	-- NOTE: Which is set in MY variable in THIS SCRIPT! if you use other variables
	-- like MP0_CHAR_XP_FM for example, you would need to change that ofcourse!
	return XNL_GetLevelFromXP(XNL_CurrentPlayerXP)
end

function XNL_OnPlayerLevelUp()
	-- This function is called when the played has leveled up while getting the XP
	-- On my server I use this 'XNL Event' to make an 'extra save' to the database
	-- with the (new) player stats, we DO NOT do that on every change to prevent to
	-- much unneeded server traffic.
	
	-- You can for example also use this function to play a sound effect or show a pop up
	-- when a player has leveled up (for example to show which new jobs became availible)
	
	-- NOTE: These are just SUGGESTIONS/IDEA'S for YOU to implement, I have NOT included
	-- these 'features' in this script
end

function XNL_OnPlayerLevelsLost()
	-- This function is called when the played has LOST a level or levels while losing XP
	-- for example by an 'admin punishment'!
	
	-- On my server I use this 'XNL Event' to make an 'extra save' to the database
	-- with the (new) player stats, we DO NOT do that on every change to prevent to
	-- much unneeded server traffic.
	
	-- You can for example also use this function to check if a player has a weapon in his/here
	-- inventory which should be removed due to losing the level required for it, or for example
	-- check if the player needs to be 'kicked' from a vehicle which requires his previously 
	-- higher level to use/drive it
	
	-- NOTE: These are just SUGGESTIONS/IDEA'S for YOU to implement, I have NOT included
	-- these 'features' in this script
end

function XNL_AddPlayerXP(XPAmount)
	local pdata = getPlayerData()
	if not pdata or not pdata.citizenid then return end
	xplayer = pdata.citizenid
	--======================================================================================
	-- "The Command" to give the player new XP (Well documented/commented)
	--======================================================================================
	if not is_int(XPAmount) then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_AddPlayerXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return
	end

	if XPAmount < 0 then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_AddPlayerXP'")
		print("XNL WARNING: is trying to TAKE XP from a player, use 'XNL_RemovePlayerXP' instead!")
		print("=====================================================================================================")
		return
	end
	
	

	local CurrentLevel = XNL_GetLevelFromXP(XNL_CurrentPlayerXP)	-- Remembers the CURRENT level of the player BEFORE adding the new XP
	local CurrentXPWithAddedXP = XNL_CurrentPlayerXP + XPAmount		-- Remembers the NEW XP amount (with the new xp added to the already 'owned XP')
	local NewLevel =  XNL_GetLevelFromXP(CurrentXPWithAddedXP)		-- Remembers the NEW level which the player will get after adding the new XP (IF there would be a new level)
	local LevelDifference = 0			
								-- This variable will 'later on' remember how many levels the player has leveled up (at once)
	TriggerServerEvent('xnlrankbar:server:setxp', CurrentXPWithAddedXP,xplayer)
	-- This section is 'my build in level cap' which can be set in the variables at the top of the script
	if NewLevel > XNL_MaxPlayerLevel - 1 then
		NewLevel = XNL_MaxPlayerLevel -1
		CurrentXPWithAddedXP = XNL_GetXPCeilingForLevel(XNL_MaxPlayerLevel - 1)
	end
	
	-- This section detects if there is a difference in level due to player gaining XP
	if NewLevel > CurrentLevel then
		LevelDifference = NewLevel - CurrentLevel
	end
	
	if LevelDifference > 0 then
		-- If we detect that the player has reached a new level we will need to make sure it also
		-- shows this progress in the rank bar. This function/section even supports leveling up multiple
		-- levels at once :)
		StartAtLevel = CurrentLevel
		CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_CurrentPlayerXP, XNL_GetXPCeilingForLevel(StartAtLevel), StartAtLevel, false)
		
		-- Make a loop to go through all the levels the player has received from this xp gain (if he/she received (multiple) new level(s))
		for i = 1, LevelDifference ,1 
		do 
			StartAtLevel = StartAtLevel + 1
			
			if i == LevelDifference then
				-- If we have reached the 'final new level' in the loop we'll make sure it the actual current XP Total (including the newly added amount)
				CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_GetXPFloorForLevel(StartAtLevel), CurrentXPWithAddedXP, StartAtLevel, false)
			else
				-- If we to do 'multiple bar animations' we will need to make sure that it will only 'animate' to the maximum amount of XP per bar for the level it is showing,
				-- in MOST cases we don't even need this section since most of the time players will only level up one level at a time, but I wanted it to be '100% compatible' with
				-- situations where it would happen that a player skips one or multiple levels at once by gaining new XP
				CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), StartAtLevel, false)
			end
		end
	else
		-- Here we just create the normal rankbar without the need to make it 're-appear' with the 'level up animation'
		CreateRankBar(XNL_GetXPFloorForLevel(NewLevel), XNL_GetXPCeilingForLevel(NewLevel), XNL_CurrentPlayerXP, CurrentXPWithAddedXP, NewLevel, false)
	end
	
	-- Update the variable to make it work properly the next time XP update is requested
	XNL_CurrentPlayerXP = CurrentXPWithAddedXP
	
	-- This function is called when the played has leveled up while getting the XP
	-- this is only called ONCE even when receiving enough XP to level up multiple levels at once :)
	if LevelDifference > 0 then
		XNL_OnPlayerLevelUp()
	end
end

function XNL_RemovePlayerXP(XPAmount)
	--======================================================================================
	-- "The Command" to give the player new XP (Well documented/commented)
	--======================================================================================
	if not is_int(XPAmount) then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_RemovePlayerXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return
	end

	if XPAmount < 0 then
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_RemovePlayerXP'")
		print("XNL WARNING: is trying to give 'negative' XP by passing a negative value, If you for example  ")
		print("XNL WARNING: want to remove 100XP just use: 'XNL_RemovePlayerXP(100)' to remove 100XP from the player")
		print("=====================================================================================================")
		return
	end

	local CurrentLevel = XNL_GetLevelFromXP(XNL_CurrentPlayerXP)	-- Remembers the CURRENT level of the player BEFORE adding the new XP
	local CurrentXPWithRemovedXP = XNL_CurrentPlayerXP - XPAmount	-- Remembers the NEW XP amount (with the xp removed to the already 'owned XP')
	local NewLevel =  XNL_GetLevelFromXP(CurrentXPWithRemovedXP)	-- Remembers the NEW level which the player will get after adding the new XP (IF there would be a new level)
	local LevelDifference = 0										-- This variable will 'later on' remember how many levels the player has leveled up (at once)
	
	-- This section makes sure that the player doesn't get bellow level 1 (to prevent game crashes or weird sh*t from happening (I DID NOT tested what happens if you try to set it bellow 1!)
	if NewLevel < 1 then
		NewLevel = 1
	end

	if CurrentXPWithRemovedXP < 0 then
		CurrentXPWithRemovedXP = 0
	end

	
	-- This section detects if there is a difference in level due to player losing XP
	if NewLevel < CurrentLevel then
		LevelDifference = math.abs(NewLevel - CurrentLevel)	-- Math(ematical) function gets the absolute difference between the Current and new level (counting the 'level loss')
	end
	
	if LevelDifference > 0 then
		-- If we detect that the player has reached a new level we will need to make sure it also
		-- shows this progress in the rank bar. This function/section even supports leveling up multiple
		-- levels at once :)
		StartAtLevel = CurrentLevel
		CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_CurrentPlayerXP, XNL_GetXPFloorForLevel(StartAtLevel), StartAtLevel, true)
		
		-- Make a loop to go through all the levels the player has received from this xp gain (if he/she received (multiple) new level(s))
		for i = 1, LevelDifference ,1
		do 
			StartAtLevel = StartAtLevel - 1
			
			if i == LevelDifference then
				-- If we have reached the 'final new level' in the loop we'll make sure it the actual current XP Total (including the newly added amount)
				CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), CurrentXPWithRemovedXP, StartAtLevel, true)
			else
				-- If we to do 'multiple bar animations' we will need to make sure that it will only 'animate' to the maximum amount of XP per bar for the level it is showing,
				-- in MOST cases we don't even need this section since most of the time players will only level up one level at a time, but I wanted it to be '100% compatible' with
				-- situations where it would happen that a player skips one or multiple levels at once by gaining new XP
				CreateRankBar(XNL_GetXPFloorForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_GetXPCeilingForLevel(StartAtLevel), XNL_GetXPFloorForLevel(StartAtLevel), StartAtLevel, true)
			end
		end
	else
		-- Here we just create the normal rankbar without the need to make it 're-appear' with the 'level animation'
		CreateRankBar(XNL_GetXPFloorForLevel(NewLevel), XNL_GetXPCeilingForLevel(NewLevel), XNL_CurrentPlayerXP, CurrentXPWithRemovedXP , NewLevel, true)
	end
	
	-- Update the variable to make it work properly the next time XP update is requested
	XNL_CurrentPlayerXP = CurrentXPWithRemovedXP
	
	-- This function is called when the played has leveled up while getting the XP
	-- this is only called ONCE even when receiving enough XP to level up multiple levels at once :)
	if LevelDifference > 0 then
		XNL_OnPlayerLevelsLost()
	end
end

--======================================================================================
--======================================================================================
-- Basicaly if you're a 'standard user/implementor' of my script, you would not need
-- to use, change or 'worry about' the functions bellow and they should have no
-- (direct) use to you, the functions bellow just ensure proper functioning of the
-- script and rankbar :)
--======================================================================================
--======================================================================================

--======================================================================================
-- This function calculates (or gets while still bellow level 100!)
-- the 'floor level' XP amount for the level you're asking it for
-- this is required to set the 'start position' of the rankbar to animate
--
-- NOTE: Technically you DO NOT NEED to interface or 'mess' with this function!
--       This function is CRUCIAL for proper rank bar animations and has NOTHING
--       todo with setting user ranks, levels, rp or whatever you want to call it!
--		 You do NOT need to change this function or so to set level limits or so,
--		 you would only need to if you want to make different XP levels than the
--		 original game has!
--======================================================================================
function XNL_GetXPFloorForLevel(intLevelNr)
	if is_int(intLevelNr) then
		
		-- This is some 'basic build in security' JUST IN CASE people DO think it'scaleform
		-- a good idea to mess with these functions!
		if intLevelNr > 7999 then
			intLevelNr = 7999
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the floor level XP for")
			print("XNL WARNING: an player level beyond level 7999, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' to 7999!")
			print("=====================================================================================================")
		end
		
		-- If the level is set bellow 2 (so basically level 1 since level 0 doesn't exist!)
		-- we will automatically return that the 'floor' of this level is 0XP (since it's not in the list)
		if intLevelNr < 2 then
			return 0
		end
		
		if intLevelNr > 100 then
			BaseXP = RockstarRanks[99]	-- Get the 'base XP' from the last known original rockstar level (100) in my table
			ExtraAddPerLevel = 25		-- REDUCED: was 50 (now 50% easier)
			MainAddPerLevel = 14275 	-- REDUCED: was 28550 (now 50% easier)
			                            -- NOTE: With reduced values, leveling is now 50% easier than original Rockstar requirements
			
			BaseLevel = intLevelNr - 100 -- Here we make sure that the first 100 levels are 'excluded' from the loop since we already have a base offset.
			CurXPNeeded = 0				 -- This variable will remember the total XP for the level (and adds to it during the loop below)
			for i = 1, BaseLevel ,1 
			do 
				MainAddPerLevel = MainAddPerLevel + 25		-- REDUCED: was 50 (now 50% easier)
				CurXPNeeded = CurXPNeeded + MainAddPerLevel	-- Adding the total + XP for the current passed Level in the loop
			end
			
			return BaseXP + CurXPNeeded	 -- Returning the Base XP from the last known 'rockstar rank' and adding the new extra rank(s) XP to it
		end
		
		-- IF the level we're requesting the "floor xp" from is level 100 or bellow we'll take the amount of XP
		-- required from the table I've put in this script which uses the original rockstar XP levels
		return RockstarRanks[intLevelNr - 1]
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_GetXPFloorForLevel'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 0 -- YES this MIGHT cause an XP bar which will not show xp drawing for a moment IF there is an error in the script, but it will prevent crashing!
	end
end

--======================================================================================
-- This function calculates (or gets while still bellow level 99!)
-- the 'ceiling level' XP amount for the level you're asking it for
-- this is required to set the 'end position' of the rankbar to animate AND it's used
-- to show the second part of the progress: the "1500/2000" bellow the rankbar
--
-- NOTE: Technically you DO NOT NEED to interface or 'mess' with this function!
--       This function is CRUCIAL for proper rank bar animations and has NOTHING
--       todo with setting user ranks, levels, rp or whatever you want to call it!
--		 You do NOT need to change this function or so to set level limits or so,
--		 you would only need to if you want to make different XP levels than the
--		 original game has!
--======================================================================================
function XNL_GetXPCeilingForLevel(intLevelNr)
	if is_int(intLevelNr) then
		
		-- This is some 'basic build in security' JUST IN CASE people DO think it'scaleform
		-- a good idea to mess with these functions!
		if intLevelNr > 7999 then
			intLevelNr = 7999
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the ceiling level XP")
			print("XNL WARNING: for an player level beyond level 7999, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' to 7999!")
			print("=====================================================================================================")
		end
		
		-- If the level is set bellow 2 (so basically level 1 since level 0 doesn't exist!)
		-- we will automatically return that the 'floor' of this level is 0XP (since it's not in the list)
		if intLevelNr < 1 then
			print("=====================================================================================================")
			print("XNL WARNING: You have an error in one of your scripts which is trying to get the ceiling level XP")
			print("XNL WARNING: for an player level BELLOW level 1, which is the game limit!")
			print("XNL WARNING: Script has prevented this and set the 'limit' back to 1!")
			print("=====================================================================================================")
			return 800	-- NOTE: If you have changed the "original Rockstar Level Table" you will need to change this one to!
		end
		
		if intLevelNr > 99 then
			BaseXP = RockstarRanks[99]
			ExtraAddPerLevel = 25		-- REDUCED: was 50 (now 50% easier)
			MainAddPerLevel = 14275 	-- REDUCED: was 28550 (now 50% easier)
			-- NOTE: With reduced values, going from level 100 to 101 now requires 14300XP instead of 28600XP
			
			-- NOTE: This section bellow is 'well documented' in the function XNL_GetXPFloorForLevel above, so no need to comment it all twice :)
			BaseLevel = intLevelNr - 99
			CurXPNeeded = 0
			for i = 1, BaseLevel ,1 
			do 
				MainAddPerLevel = MainAddPerLevel + 25  -- REDUCED: was 50 (now 50% easier)
				CurXPNeeded = CurXPNeeded + MainAddPerLevel
			end
			
			return BaseXP + CurXPNeeded
		end
		
		-- IF the level we're requesting the "ceiling xp" for is level 99 or bellow we'll take the amount of XP
		-- required from the table I've put in this script which uses the original rockstar XP levels
		return RockstarRanks[intLevelNr]
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_GetXPCeilingForLevel'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 0 -- YES this MIGHT cause an XP bar which will not show xp drawing for a moment IF there is an error in the script, but it will prevent crashing!
	end
end

function XNL_GetLevelFromXP(intXPAmount)
	--======================================================================================
	-- This function 'converts' the XP amount you 'put in' to the level belongs to/in
	-- NOTE: This function does NOT have an 'upper limit' or 'error handling' on entering
	-- INSANE amounts since it should NOT happen if the scripts using these features
	-- are scripted normally! Especially not when considering that the maximum level
	-- "supported" is 7999! ;)
	--======================================================================================	
	if is_int(intXPAmount) then
		local SearchingFor = intXPAmount
		
		if SearchingFor < 0 then return 1 end				-- Just return level 1 if an XP level BELLOW 0 is given
		
		if SearchingFor < RockstarRanks[99] then			-- Check if the XP amount is smaller than the last item (level 100) in my 'Rockstar XP Requirements level list'
			local CurLevelFound = -1
		
			local CurrentLevelScan = 0
			for k,v in pairs(RockstarRanks)do			-- And if it's bellow the 'maximum known rockstar XP requirement' scan the table here
				CurrentLevelScan = CurrentLevelScan + 1	-- Just keep counting +1 for each level that doesn't match the xp level
				if SearchingFor < v then break end		-- when we found it, break the loop and report the level we've found :)
			end
			
			return CurrentLevelScan
		else
			-- If the amount of XP you're trying to get the level from is above the maximum XP amount in the rockstar XP requirements list (level 100)
			-- then we'll make our own loop to find the correct level here :)
			BaseXP = RockstarRanks[99]
			ExtraAddPerLevel = 25		-- REDUCED: was 50 (now 50% easier)
			MainAddPerLevel = 14275 	-- REDUCED: was 28550 (now 50% easier)
			-- NOTE: With reduced values, leveling is now 50% easier than original Rockstar requirements
			
			CurXPNeeded = 0
			local CurLevelFound = -1
			for i = 1, XNL_MaxPlayerLevel - 99 ,1 			-- The - 99 in this loop ensures that the for loop result excludes the first 99 levels which are 
			do 												-- already 'covered by' the table at the top
				MainAddPerLevel = MainAddPerLevel + 25  -- REDUCED: was 50 (now 50% easier)
				CurXPNeeded = CurXPNeeded + MainAddPerLevel
				CurLevelFound = i
				if SearchingFor < (BaseXP + CurXPNeeded) then break end
			end
		
			return CurLevelFound + 99
		end
	else
		print("=====================================================================================================")
		print("XNL WARNING: You have an error in one of your scripts calling the function 'XNL_GetLevelFromXP'")
		print("XNL WARNING: The script which is calling this function is not passing an integer!")
		print("=====================================================================================================")
		return 1 -- YES this MIGHT return the incorrect level... BUT will prevent possible crashes!
	end
end

--===================================================================================
-- This is the function that actually 'generates' the Rankbar and sets the variables
-- for it to make it function like it should
--===================================================================================
function CreateRankBar(XP_StartLimit_RankBar, XP_EndLimit_RankBar, playersPreviousXP, playersCurrentXP, CurrentPlayerLevel, TakingAwayXP)
	RankBarColor = 116 -- The Normal Online Ranbar color (IS NOT used for the globes!)
	if TakingAwayXP and XNL_UseRedBarWhenLosingXP then
		RankBarColor = 6 -- Dark Red
	end
	
	
	-- Although some sites note that the RankBar is hud ID 40, this does not work when we want to 
	-- call it for drawing, we actually need to call id 19 (which is the WeaponWheel)
	--[[
		I have also located AND CONFIRMED (instead of just assuming internet data!) the following other components:
			WANTED_STARS 			= 1
			WEAPON_ICON 			= 2
			CASH 					= 3
			MP_CASH 				= 4
			MP_MESSAGE 				= 5
			VEHICLE_NAME 			= 6
			AREA_NAME 				= 7
			VEHICLE_CLASS 			= 8
			STREET_NAME 			= 9
			HELP_TEXT 				= 10
			FLOATING_HELP_TEXT_1 	= 11
			FLOATING_HELP_TEXT_2 	= 12
			CASH_CHANGE 			= 13
			RETICLE 				= 14
			SUBTITLE_TEXT 			= 15
			RADIO_STATIONS 			= 16
			SAVING_GAME 			= 17
			GAME_STREAM				= 18
			WEAPON_WHEEL 			= 19   <-- This sameone is also used to call the rankbar!
			WEAPON_WHEEL_STATS 		= 20
			HUD_COMPONENTS 			= 21
			HUD_WEAPONS 			= 22
	]]
	if not HasHudScaleformLoaded(19) then							-- Here we check if the scaleform has been loaded or not
        RequestHudScaleform(19)										-- If it's not loaded we will request (load) it
		while not HasHudScaleformLoaded(19) do						-- here we will wait until it has loaded
			Wait(1)													-- you will HAVE to put this wait here to prevent script hang and game freezing!
		end
    end
	
	-- Currently i can't find any links to change the colors of the rank logo's (the globes on both sides) effectively
	-- i have tried setting component color id's with functions like ApplyHudColour, Colourise and other functions like that,
	-- (NOPE! those where NOT just 'guesses' but actual functions found in the data files regarding the HUD/Rankbar)
	-- tried addressing thm at HUD item 19, 40 (since some websites state that this is the rankbar ID, however! i could/can
	-- not find any logical evidence for this in hud.gfx! (or i might have overlooked it) 
	--
	-- Also tried using loading and preparing scale forms etc with for loops etc, but for now I will just leave it at what it is
	-- I'm eventually planning on using the "Rank Globe Color's" for prestige players in my server so I MIGHT come back to it and
	-- do more research but for now this rather 'unimportant feature' is holding back to much other development to keep researching.
	-- IF someone else finds or knows the solution them please don't hesitate to notify me so I can add it to my functionality and update
	-- this 'public release' script to :)
	--
	-- But what i DID notice is that the rankbar somewhat has ID 140! This can be seen/found in:
	-- sprite652(_Packages.com.rockstargames.gtav.hud.NEW_HUD)
	--
	-- HOWERVER: My appologies but I WILL NOT copy/publish these lines since I'm not taking any risks on publishing
	-- copyrighted lines/decompiled code ;) People whom would actually need this data are also well aware on how
	-- they can obtain or view that data ;) .... IF you don't know it, then you don't need that data either ;)

	-- This function sets the color of the rankBAR (NOT the globes)
	-- This function is called inside hud.gfx and only takes ONE parameter
	-- The globe color needs to be set differently
	BeginScaleformMovieMethodHudComponent(19, "SET_COLOUR")
		PushScaleformMovieFunctionParameterInt(RankBarColor) -- 116 is the "normal multiplayer rankbar color"
    EndScaleformMovieMethodReturn()

	
	--[[
	    PURE_WHITE 	= 0
		WHITE 		= 1
		BLACK 		= 2
		GREY 		= 3
		GREYLIGHT 	= 4
		GREYDARK 	= 5
		RED 		= 6
		REDLIGHT 	= 7
		REDDARK 	= 8
		BLUE 		= 9
		BLUELIGHT 	= 10
		BLUEDARK 	= 11
		YELLOW 		= 12
		YELLOWLIGHT = 13
		YELLOWDARK 	= 14
		ORANGE 		= 15
		ORANGELIGHT = 16
		ORANGEDARK 	= 17
		GREEN 		= 18
		GREENLIGHT 	= 19
		GREENDARK 	= 20
		PURPLE 		= 21
		PURPLELIGHT	= 22
		PURPLEDARK 	= 23
		PINK 		= 24
		BRONZE 		= 107
		SILVER 		= 108
		GOLD 		= 109
		PLATINUM 	= 110
		FREEMODE 	= 116	-- This is the 'normal blue color' for the Rankbar
	]]
	
	-- This function calls the function SET_RANK_SCORES inside HUD GFX (MP_RANK_BAR)
	-- and takes a maximum of 7 parameters which I have described bellow
    BeginScaleformMovieMethodHudComponent(19, "SET_RANK_SCORES")		-- The HUD/Movie Component we want to use to draw the Rankbar
		PushScaleformMovieFunctionParameterInt(XP_StartLimit_RankBar)	-- This sets the 'absolute begin limit' for the bar where it can start drawing from (includes the blue "you already had this XP" bar)
		PushScaleformMovieFunctionParameterInt(XP_EndLimit_RankBar)		-- This sets the 'end limit' for the current level bar AND the 'top value' of the displayed XP text beneath the bar
		PushScaleformMovieFunctionParameterInt(playersPreviousXP)		-- This sets where the previous XP 'was located' at the bar and thus from where to start drawing the 'white/new xp bar'
		PushScaleformMovieFunctionParameterInt(playersCurrentXP)		-- This sets the current players XP (to 'where' the bar has to move!)
		PushScaleformMovieFunctionParameterInt(CurrentPlayerLevel)		-- This one Determines the LEFT 'globe', so the CURRENT player's level!
		PushScaleformMovieFunctionParameterInt(100)						-- This one sets the opacity (visibility %) from 0 (invisible) to 100 (fully visible)
		--PushScaleformMovieFunctionParameterInt(8)					 	-- This CAN be used to set the 'end level' when making ONE bar to level up multiple levels
																		-- This can then make it look like this for example (5)==========----------(8)
																		-- when leveling up from level 5 to level 8 at once. BUT we CHOOSE to make it like i did now
																		-- (making multiple bars fill), so IF you want to change it you can just adapt the code and 
																		-- set this 'extra' pushscale parameter :)
    EndScaleformMovieMethodReturn()										-- "Ends" the current command/function handler
end

--===================================================================================
-- This is a 'small function' which is basically not needed (IF there are no errors 
-- made when using my script!) BUT i've put it in here anyway since I have added some
-- 'extra error handling' to some functions to make it a bit easier and 'less crash 
-- prone' when new users/scripters try to use it or adapt it.
--===================================================================================
function is_int(n)
	if type(n) == "number" then
		if math.floor(n) == n then
			return true
		end
	end
	return false
end
