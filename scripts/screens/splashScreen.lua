local composer = require( "composer" )

local splashScreen = composer.newScene()

local deltaTime=require "scripts.helperScripts.deltaTime"
local debugStmt=require "scripts.helperScripts.printDebugStmt"
local assetName=require "scripts.helperScripts.assetName"
local graphicsHelper=require "scripts.helperScripts.graphicsHelper"
local animationService= require "scripts.helperScripts.animationService"
local timerService=require "scripts.helperScripts.timerService"
local textResource=require "scripts.textResources.textResourceEnglish"

local splashScreenTimer,splashScreenTimeLimit--duration for which the splash screen will be shown

local width=display.contentWidth
local height=display.contentHeight

-----------------------
--update function for splash screen
local function update()
	local dt=deltaTime.getDelta()

	--increment timer
	splashScreenTimer=splashScreenTimer+dt
	if(splashScreenTimer>splashScreenTimeLimit)then
		-- enter a correct scene path and uncomment this function call.
		composer.gotoScene ("scripts.screens.mainMenuScreen", { effect="crossFade" ,params={callingScene="scripts.screens.splashScreen"}}) 
	end
end
-----------------------

--create function of splash screen to init timers etc.
function splashScreen:create(event)
	composer.removeScene( event.params.callingScene)--removing the calling scene

	debugStmt.print("splashScreen: create is called")

	--resume timerService and animationService. Had they been paused previously by another screen, this well get them running 
  	timerService.resume()
  	animationService.resume()
  	
	local group=self.view

	--init timers
	splashScreenTimer=0
	splashScreenTimeLimit=5

	--init splash screen gfx
	local FDLogo=display.newImg(group,assetName.FDLogo,width*0.5,height*0.5-200)

	local blingAnimationSheet = graphicsHelper.newImageSheet(assetName.blingAnimation, {width=338, height=407, numFrames=10, sheetContentWidth=1690, sheetContentHeight=814})
	local blingAnimationSequence = 
		{
			name = "cloud",
			start=1,
			count=10,
			delay=3,
			time=1500,
			loopCount = 1,
			loopDirection = "forward"
		}
	local blingAnimation=animationService.newSprite(group,blingAnimationSheet,blingAnimationSequence)
	blingAnimation.x=width*0.5
	blingAnimation.y=height*0.5-200
	timerService.addTimer(2500, 
				function()
					blingAnimation:play()
				end )
  
  --add run as admin message
  display.newAutoSizeText({parent=group,text="PLEASE ENSURE TO RUN AS ADMINISTRATOR", x=width/2, y=height-100-getYCompensation()-300, font=assetName.AMR, fontSize=textResource.fontL
  	,width=500, align="center"})	

  --add copyright notice
  display.newAutoSizeText({parent=group,text=textResource.copyrightText, x=width/2, y=height-50-getYCompensation(), font=assetName.AMR, fontSize=textResource.fontXS})	

  --add update Listener 
  Runtime:addEventListener("enterFrame",update)	
end

-----------------------
function splashScreen:destroy(event)
	debugStmt.print("splashScreen: destroy is called")

	--cancel all timers pertaining to this screen
	timerService.cancelAll()
	animationService.removeAll()

	--remove update Listener
 	Runtime:removeEventListener("enterFrame",update)
end
-----------------------

-- Listener setup
splashScreen:addEventListener( "create", splashScreen )
splashScreen:addEventListener( "destroy", splashScreen )

return splashScreen