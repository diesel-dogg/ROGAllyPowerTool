local vibrationHelper={}

--NOTE: This script contains all the functions responsible for the ios taptic engine and android vibrator   
local vibrator = require 'plugin.vibrator'
local debugStmt = require "scripts.helperScripts.printDebugStmt" 
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local toast=require "scripts.helperScripts.toast"

--FWD References
local getIsHaptic
local vibrationDurationHeavy=100--these are the durations in ms for vibration (non-taptic devices)
local vibrationDurationMedium=60
local vibrationDurationLight=30
local bufferDuration=30--this is the duration of the shortest interval necessary for two consecutive vibrations (non taptic) to be perceivable

--function to call taptic/vibrator depending on the availability. The function accepts a string to specify the strength(intensity) of the effect.
function vibrationHelper.vibrateOnce(strength)
	--if vibration was disabled, return
	if(not preferenceHandler.get("isVibrationOn"))then
		return
	end

	--first check if the current device supports haptic feedback and call the taptic engine, other wise call the vibrator
	if(getIsHaptic())then
		local haptic = vibrator.newHaptic('impact',strength)
		haptic:invoke()
	else
		if(strength=="heavy")then--heavy
			vibrator.vibrate(vibrationDurationHeavy)
		elseif(strength=="medium")then--medium 
			vibrator.vibrate(vibrationDurationMedium)
		elseif(strength=="light")then--medium 
			vibrator.vibrate(vibrationDurationLight)	
		end
	end
end
-------------------------------------------------
--function to call taptic/vibrator depending on the availability. It accepts 2 parameters- a string to specify the strength(intensity) of the effect, 
--a table containing time in milliseconds defining a pattern of vibration. Structure example for pattern table-> {{delay=0,strength="light"},{delay=100,strength="heavy"}}
function vibrationHelper.vibrateWithPattern(pattern)

	--start by checking that there is no pair in the pattern where the delay of the current index (computed from the time of last vibration)
	--is less than the necessary time that the last vibration will need for completion. In such a case, display a toast warning.
	-- First index doesn;t have this constraint and is hence not checked
	for i=2, #pattern do
		if(pattern[i-1].strength=="heavy" and pattern[i].delay<(vibrationDurationHeavy+bufferDuration))then
			toast.showToast("vibration helper- not enough delay allow for previous HEAVY vibration")
		elseif(pattern[i-1].strength=="medium" and pattern[i].delay<(vibrationDurationMedium+bufferDuration))then
			toast.showToast("vibration helper- not enough delay allow for previous MEDIUM vibration")
		elseif(pattern[i-1].strength=="light" and pattern[i].delay<(vibrationDurationLight+bufferDuration))then
			toast.showToast("vibration helper- not enough delay allow for previous LIGHT vibration")
		end
	end	

	--if vibration was disabled, return
	if(not preferenceHandler.get("isVibrationOn"))then
		return
	end

	local index=1
	
	--function called recursively to complete the vibration pattern
	--NOTE: in order to handle the vibration with delays corona's own timer API is used instead of self made timerService, 
	--this is done to make it function universally throughout the lifetime of the game independent of game's state
	local function vibrateWithDelay()
		timer.performWithDelay( pattern[index].delay,
			function()
				vibrationHelper.vibrateOnce(pattern[index].strength)
				index=index+1--increment the index
				--if index has exceeded the size of the pattern table, break the recurssion and return
				if(index>#pattern)then
					return
				end
				vibrateWithDelay()--call this function recursively until the end of the pattern is reached
			end)
	end

	vibrateWithDelay()
end
-------------------------------------------------
--function that returns true if haptic engine is available in the current device and returns false if otherwise
function getIsHaptic()
	local deviceInfo=system.getInfo("architectureInfo")
	--check if the device is an iPhone, if not return false(only iphones support haptic engine)
	if(deviceInfo:sub(1,6)=="iPhone")then
		local version=""
		for i=7,deviceInfo:len() do
			local char=deviceInfo:sub(i,i)
			if(char==",")then
				break
			else
				version=version..char
			end
		end

		--for iphone 7 and later device(version code 9 onwards), return true
		if(tonumber(version)>=9)then
			return true
		end
	end
	
	return false
end
-------------------------------------------------

return vibrationHelper