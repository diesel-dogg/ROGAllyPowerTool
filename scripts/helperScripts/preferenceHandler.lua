local preferenceHandler={}
local GGData= require "scripts.helperScripts.GGData"
local debugStmt=require "scripts.helperScripts.printDebugStmt"
local box= GGData:new ("userdata")
local crypto = require( "crypto" )

box:enableIntegrityControl( crypto.sha512, "Famousdogg8190!" )

--perform verification on all entries
local corruptEntries = box:verifyIntegrity()
box:save()

--Init the required fields and their corresponding start values if they are presently nil
function preferenceHandler.init()
	
	if box:get("launchCount")== nil then
		debugStmt.print("preferenceHandler: initing launchCount to 0")
		box:set("launchCount",0)
	end

	if box:get("adSkipTimeLimit")== nil then
		debugStmt.print("preferenceHandler: initing adSkipTimeLimit to 120 ")
		box:set("adSkipTimeLimit",120)
	end

	if box:get("didUserRate")== nil then
		debugStmt.print("preferenceHandler: initing didUserRate to false")
		box:set("didUserRate","false")
	end

	if box:get("isNoAdsPurchased")== nil then
		debugStmt.print("preferenceHandler: initing isNoAdsPurchased to false")
		box:set("isNoAdsPurchased","false")
	end

	if box:get("prohibitedApps")== nil then
		debugStmt.print("preferenceHandler: initing prohibitedApps to nil")
		box:set("prohibitedApps","nil")
	end

	if box:get("iosVersionLink")== nil then
		debugStmt.print("preferenceHandler: initing iosVersionLink to nil ")
		box:set("iosVersionLink","nil")
	end

	if box:get("androidVersionLink")== nil then
		debugStmt.print("preferenceHandler: initing androidVersionLink to nil ")
		box:set("androidVersionLink","nil")
	end

	if box:get("minimumIosVersion")== nil then
		debugStmt.print("preferenceHandler: initing minimumIosVersion to 0 ")
		box:set("minimumIosVersion",0)
	end
	
	if box:get("minimumAndroidVersion")== nil then
		debugStmt.print("preferenceHandler: initing minimumAndroidVersion to 0 ")
		box:set("minimumAndroidVersion",0)
	end

	if box:get("language")== nil then
		debugStmt.print("preferenceHandler: initing language to english ")
		box:set("language","english")
	end
	
	if box:get("volumeLevelMusic")== nil then
		debugStmt.print("preferenceHandler: initing volumeLevelMusic to 1 ")
		box:set("volumeLevelMusic",1)
	end

	if box:get("volumeLevelSFX")== nil then
		debugStmt.print("preferenceHandler: initing volumeLevelSFX to 1 ")
		box:set("volumeLevelSFX",1)
	end

	if box:get("currency")== nil then
		debugStmt.print("preferenceHandler: initing currency to 0")
		box:set("currency",0)
	end

	if box:get("highestLevelCleared")== nil then
		debugStmt.print("preferenceHandler: initing highestLevelCleared to 0")
		box:set("highestLevelCleared",0)
	end

	if box:get("rewardedAdCurrency")== nil then
		debugStmt.print("preferenceHandler: initing rewardedAdCurrency to 200")
		box:set("rewardedAdCurrency",200)
	end

	if box:get("lastItemSelected")== nil then
		debugStmt.print("preferenceHandler: initing lastItemSelected to 1")
		box:set("lastItemSelected",1)
	end

	--set preferences as true for the unlock and purchase state of the default item so that it's always available to user
	if box:get("item1Unlocked")== nil then
		debugStmt.print("preferenceHandler: initing item1Unlocked to true")
		box:set("item1Unlocked",true)
	end
	if box:get("item1Purchased")== nil then
		debugStmt.print("preferenceHandler: initing item1Purchased to true")
		box:set("item1Purchased",true)
	end

	if box:get("didShowATTPopup")== nil then
		debugStmt.print("preferenceHandler: initing didShowATTPopup to false")
		box:set("didShowATTPopup","false")
	end

	if box:get("didFireATTEvent")== nil then--indicate if an event was fired to indicate the status of att permission on this device
		debugStmt.print("preferenceHandler: initing didFireATTEvent to false")
		box:set("didFireATTEvent","false")
	end

	-- this pref. is specifically for android and checks if user has already rated the app. 
	-- we are now using custom popups on Android instead of native popups. This will not be used for IOS as that is being handled natively.
	if box:get("didUserRateAndroid")== nil then
		debugStmt.print("preferenceHandler: initing didUserRateAndroid to false")
		box:set("didUserRateAndroid","false")
	end
	
	if box:get("blockAnalytics")== nil then
		debugStmt.print("preferenceHandler: initing blockAnalytics to false")
		box:set("blockAnalytics","false")
	end

	----PREFERENCES FOR ROG ALLY POWER MANAGEMENT----
	if box:get("firstLaunchStepsPerformed")== nil then
		debugStmt.print("preferenceHandler: initing firstLaunchStepsPerformed to false")
		box:set("firstLaunchStepsPerformed",false)
	end
	
	--rig prefs
	-- box:set("lastItemSelected",1) 
	-- box:set("currency",300) 
	-- box:set("item2Unlocked",false)--uncomment to test unlock menu
	-- box:set("item2Purchased",false)--uncomment to test unlock menu

	box:save()
end

---------------------------------------
--mount the box into the preferenceHandler table for external use
preferenceHandler.box=box

--Used the getter ans setter methods rather than directly accessing box
function preferenceHandler.get(field)
	local toReturn= box:get(field)
	if toReturn=="true" then
		return true
	elseif toReturn=="false" then
		return false
	else
		return toReturn
	end
end

------------------------

function preferenceHandler.set(field, value)
	local val=nil
	if value==true then
		val="true"
	elseif value==false then
		val="false"
	else
		val=value
	end
	box:set(field,val)
	box:save()
end

------------------------
--clear the list and reset preferences
function preferenceHandler.clearPreferences()
	box:clear()
	preferenceHandler.init()
end

return preferenceHandler