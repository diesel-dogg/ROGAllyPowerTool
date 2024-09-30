local soundManager = {isBossLevelMusic=false}--the flag will be controlled by the GW to indicate if the music to be played is for the boss level or not

local debugStmt = require("scripts.helperScripts.printDebugStmt")
local toast = require("scripts.helperScripts.toast")
local preferenceHandler=require("scripts.helperScripts.preferenceHandler")

----vars and fwd references--------
local myMath={
	atan2=math.atan2,
	abs=math.abs,
	deg=math.deg,
	rad=math.rad,
	random=math.random,
	pi=math.pi,
	floor=math.floor,
	ceil=math.ceil,
	round=math.round,
	pow=math.pow
}
local runtime
local gainPercentMusic=0 local gainPercentSFX=0 --can be positive or negative
local setMusicVolume -- function to set volume of a particular channel
local setSFXVolume
local setPitch -- set pitch of an audio source
local currentMusicIndex -- current backGround music index
local lastMusicIndex -- no. of backGround music clips


--audio handles
local backgroundMusic -- reference of current playing bgMusic
local buttonClickSound

--audio time and timeGap
local buttonClickSoundTime, buttonClickSoundTimeGap, currencyDeductionSoundTimer, currencyDeductionSoundTimeGap
-------------------

function soundManager.init()
	runtime = 0	
	
	-- init gainPercent for Music and SFX based on Music and SFX volumeLevel
	-- soundManager.setGainPercentMusic()
	-- soundManager.setGainPercentSFX()

	-- loading all sounds
	buttonClickSound=audio.loadSound("assets/sounds/".."buttonClickSound.mp3")
	currencyDeductionSound=audio.loadSound("assets/sounds/currencyDeductionSound.mp3")

	-- init all timers
	soundManager.initTimers()
	
	-- backGroundMusic vars init
	currentMusicIndex=0
	lastMusicIndex=1 -- current we have 3 audio clips of bg musics that are played in the non-final levels
	
	-- reserved channels : 1. bg music 2. UI 3. water sound 4. special rock sounds
	audio.reserveChannels(2);
end

-------------------
--setting values of soundTime and soundTimeGap of each audio handle
function soundManager.initTimers()
	buttonClickSoundTimeGap=0.1 buttonClickSoundTime=-buttonClickSoundTimeGap currencyDeductionSoundTimeGap=1 currencyDeductionSoundTimer=-currencyDeductionSoundTimeGap
end

-------------------
-- called from main script
function soundManager.update( dt )
	runtime = runtime + dt -- in seconds
end

-------------------
-- whenever we want to play bgMusic
function soundManager.playBackgroundMusic( )

	-- don't play any sound when volumeLevel is 0
	if preferenceHandler.get("volumeLevelMusic") == 0 then
		return
	end

	-- removing previously buffered music
	audio.dispose(backgroundMusic)			
	backgroundMusic=nil		
	
	local volume=nil
	local seekPoint=nil
	
	--increment the current music index
	currentMusicIndex=currentMusicIndex+1
	if (currentMusicIndex > lastMusicIndex) then
		currentMusicIndex=1		
	end

	--set the volume and the seek point of the music (needs to be hardcoded based on the music)
	if (currentMusicIndex==0) then--zero is the index reserved for the specific music that will be played for the boss levels
		volume=0.2
		seekPoint=0
	elseif (currentMusicIndex==1) then
		volume=0.2
		seekPoint=0
	elseif (currentMusicIndex==2) then
		volume=0.2
		seekPoint=0
	elseif (currentMusicIndex==3) then
		volume=0.3
		seekPoint=0
	end	

	-- load music with the currentMusicIndex
	backgroundMusic=audio.loadStream("assets/sounds/backgroundMusic"..currentMusicIndex..".mp3")
	
	audio.seek(seekPoint*1000, backgroundMusic)

	-- play and callback's the function
	local channel,src=audio.play(backgroundMusic,{channel=1, loop=0,
		onComplete=function(event) 
		if (event.completed) then
			soundManager.playBackgroundMusic() -- call recursively
		end
	end})
	setMusicVolume(volume, {channel=1})	-- sets volume of currentChannel
end

---------------------UI and HUD related sound effects------------------------
--plays the button click sound when a button is pressed and released (reserved channel 2)
function soundManager.playButtonClickSound(buttonID)
	if(preferenceHandler.get("volumeLevelSFX")==0) then
		return
	end

	if(runtime-buttonClickSoundTime > buttonClickSoundTimeGap)then
		if(audio.isChannelActive(2))then
			return
		end
		
		debugStmt.print("SM: playing button click sound")
		audio.play( buttonClickSound, {channel=2})
		setSFXVolume(0.4, {channel=2})
		buttonClickSoundTime=runtime
	end
end

------------------------------------------------
--sound played when a user makes a purchase with in game currency and their currency is deducted
function soundManager.playCurrencyDeductionSound()
	if(preferenceHandler.get("volumeLevelSFX")==0) then
		return
	end

	if(runtime- currencyDeductionSoundTimer > currencyDeductionSoundTimeGap)then
		local ch,src = audio.play(currencyDeductionSound)
		setSFXVolume(0.4, {channel=ch})
		currencyDeductionSoundTimer=runtime
	end
end

-------------------NO Sound functions beyond this point-----
-- sets gain percentage based on volume level
function soundManager.setGainPercentMusic()
	local volumeLevel=preferenceHandler.get("volumeLevelMusic") --we want the actual value of volume and then apply the gainPercentMusic to it
	local previousgainPercentMusic=gainPercentMusic

	if (volumeLevel==1) then
		gainPercentMusic=0
	end

	local currentVolume=audio.getVolume({channel=1})
	local volume=currentVolume/(1+previousgainPercentMusic)
	volume=myMath.round(volume*100)*0.01--round the value of actual volume to 2 decimal places for precision
	setMusicVolume(volume, {channel=1})	-- sets volume of 1st Channel
end

--------------------------------------
--function to set the gain percent for channels pertaining to sfx, called when volume is changed or at the time of init
function soundManager.setGainPercentSFX()

	local previousgainPercentSFX=gainPercentSFX
	local volumeLvl=preferenceHandler.get("volumeLevelSFX")
	if(volumeLvl==1)then
	   gainPercentSFX=0 
	end	

	local currentVolume=audio.getVolume({channel=2})
	local volume=currentVolume/(1+previousgainPercentSFX)
	volume=myMath.round(volume*100)*0.01--round the value of actual volume to 2 decimal places for precision
	setSFXVolume(volume, {channel=2})	-- sets volume of 2nd Channel (water sound)
end

---------------------------------------
-- Method to stop all sound effect. i.e audio that is playing on channels other than 1 and 2
function soundManager.stopAllEffects()
	for i=3,32 do 
		audio.stop(i)
	end
	--reinitialise the timers so that sounds can be resumed without gap
	soundManager.initTimers()
end

------------------
--call fn to stop audio on the bgMusic Channel
function soundManager.stopBackgroundMusic()
	if(audio.isChannelPlaying(1))then
		audio.stop(1)
	end
end

-----------------------------------

-- sets volume at a channel
function setMusicVolume( volume, params )
	local vol=volume+volume*gainPercentMusic -- increases or decreases the volume
	if (vol>1) then -- if adding gainPercentMusic increases the volume above 100% then set volume to 100% i.e. 1
		vol=1
	end
	audio.setVolume(vol,{channel=params.channel})
end

-------------------
--Same as the function above specific to SFX
function setSFXVolume(volume, params)
	volume=volume+volume*gainPercentSFX
	if(volume>1)then
		volume=1
	end
	-- debugStmt.print("soundManager: volume after gain is calculated as "..volume)
	audio.setVolume(volume,{channel=params.channel})
end

-------------------
-- sets pitch of an audio source
function setPitch(src, pitch)
	al.Source(src,al.PITCH,pitch)
end
-------------------

return soundManager