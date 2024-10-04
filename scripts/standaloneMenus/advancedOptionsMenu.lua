local advancedOptionsMenu={}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local menuMaker=require "scripts.menuHelper.menu"
local assetName=require "scripts.helperScripts.assetName"
local soundManager=require "scripts.soundManager"
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local timerService=require "scripts.helperScripts.timerService"
local animationService= require "scripts.helperScripts.animationService"
local toast=require "scripts.helperScripts.toast"
local textResource= require "scripts.textResources.textResourceEnglish"
local lfs = require( "lfs" )
local profileSelectionMenu=require "scripts.standaloneMenus.profileSelectionMenu"
local hardwareSettings=require "scripts.hardwareSettings"

-- vars and fwd references
local width=display.contentWidth
local height=display.contentHeight
local makeMainMenu
local menuDisplayGroup
local makeATTMenu

local myMath={
    abs=math.abs,
    deg=math.deg,
    rad=math.rad,
    cos=math.cos,
    sin=math.sin,
    tan=math.tan,
    atan2=math.atan2,
    round=math.round,
    random=math.random,
    pi=math.pi,
    floor=math.floor,
    pow=math.pow,
    min=math.min,
    max=math.max,
}
-----------------------fwd refs:---
local advancedMenu
local callback--this is a reference of the function that called the makeprofileSelectionMenu function of this script. This is our only way of returning control back to where we came here from 
local changesBlocked=false--this boolean is toggled with help of a 1s timer to prevent rapid input from user

-----------------------------------
function advancedOptionsMenu.makeAdvancedOptionsMenu(callback1,shouldFadeIn)
	callback=callback1

	advancedMenu=menuMaker.newMenu({name="advancedMenu",x=0,y=0,masterImageGroup=nil, baseImagePath=assetName.mainMenuBase,
		baseImageWidth=540,baseImageHeight=900,overlayAlpha=0.5})

	--menu title text
	advancedMenu:addTextDisplay({id="title",xRelative=270,yRelative=66,font=assetName.AMB,fontSize=textResource.fontXL,string="ADVANCED OPTIONS",
		colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})
	
	--------
	--text for installPlans:
	advancedMenu:addTextDisplay({id="installPlansText",xRelative=270,yRelative=490,font=assetName.AMR,fontSize=textResource.fontS,
			string="For CPU limit to work, the Asus power plans must be replaced with custom power plans of the same name.".. 
			" A command window will open on pressing this button- please follow the steps there.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--install/reinstall custom power plans button. The Asus armoury crate power plans are non compliant with cpu settings and other powercfg commands so 
    --this batch file creates power plans with the same IDs and names but standard windows power saver settings so that we can apply our changes to them. 
    --by duplicating the windows power saving setting, we remove the battery slider and prevent windows from overriding cpu settings.
    --these settings are sometimes lost when the device is plugged in so we need a button to reapply the batch file. 
    advancedMenu:addButton({id="installPlans",xRelative=270,yRelative=592,width=228,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButtonLarge,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("installPlans"):addTextDisplay({id="installPlansBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Reinstall Custom Plans", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=200}})

    advancedMenu:getItemByID("installPlans").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.installPowerPlans()
                                                    end
    --------                                                
    --text for restore asus plans:
	advancedMenu:addTextDisplay({id="restorePlansText",xRelative=270,yRelative=684,font=assetName.AMR,fontSize=textResource.fontS,
			string="The default Asus power plans can be restored at any time with the button below.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--this button will restore the default asus power plans
    advancedMenu:addButton({id="restorePlans",xRelative=270,yRelative=756,width=228,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButtonLarge,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("restorePlans"):addTextDisplay({id="restorePlansBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Restore Default Plans", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=200}})

    advancedMenu:getItemByID("restorePlans").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.restoreAsusPlans()
                                                    end                                                            
    --------
 --    --gfx reset button 
 --    --text for display device reset:
	-- advancedMenu:addTextDisplay({id="gfxResetText",xRelative=270,yRelative=598,font=assetName.AMR,fontSize=textResource.fontS,
	-- 		string="This option, even though present, is not expected to work, and as such, it is recommended to restart the device to release a static GPU clock,",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

 --    advancedMenu:addButton({id="gfxReset",xRelative=270,yRelative=682,width=114,height=65,imageDownPath=nil,
 --            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
 --    advancedMenu:getItemByID("gfxReset"):addTextDisplay({id="gfxResetBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
 --    string="Gfx Reset", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=100}})

 --    advancedMenu:getItemByID("gfxReset").callbackUp=function()
 --                                                        soundManager.playButtonClickSound()
 --                                                        hardwareSettings.resetGfx()
 --                                                    end 
    --------

    --chargingRate registry parameter that controls max charging limit of batter:
    --charging rate title
    advancedMenu:addTextDisplay({id="chargingRateTitle",xRelative=270,yRelative=168,font=assetName.AMR,fontSize=textResource.fontM,string="BATTERY CHARGE LIMIT \n (Please restart device after changing this setting)",
        colour={r=90/255,g=103/255,b=121/255}, align="center", sizeLimit={width=500}})
    
    --charging limit  up button 
    advancedMenu:addButton({id="chargingRateUp",xRelative=116,yRelative=238,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --charging limit  down button 
    advancedMenu:addButton({id="chargingRateDown",xRelative=414,yRelative=238,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})
   
    local value=hardwareSettings.getChargingRate()
    if(value==nil)then
        value="?"
    end
    local currentChargingRate=value--fetching a value here since we need to go over multiple cases to set charging rate values based on current value in button action so we cannot keep fetching

    advancedMenu:addTextDisplay({id="chargingRateText", xRelative=270, yRelative=238, font=assetName.AMR, fontSize=textResource.fontL,
    string=""..currentChargingRate, colour={r=132/255,g=82/255,b=82/255}})

    advancedMenu:getItemByID("chargingRateUp").callbackUp=function()
                                                    local toSet
                                                    if(currentChargingRate==60)then
                                                        toSet=65
                                                    elseif(currentChargingRate==65)then
                                                        toSet=70
                                                    elseif(currentChargingRate==70)then
                                                        toSet=75
                                                    elseif(currentChargingRate==75)then
                                                        toSet=80
                                                    elseif(currentChargingRate==80)then
                                                        toSet=85
                                                    elseif(currentChargingRate==85)then
                                                        toSet=90
                                                    elseif(currentChargingRate==90)then
                                                        toSet=95
                                                    elseif(currentChargingRate==95)then
                                                        toSet=100
                                                    elseif(currentChargingRate==100)then
                                                        toSet=60
                                                    else
                                                        toSet=100
                                                    end                            

                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end

                                                    soundManager.playButtonClickSound()
                                                    hardwareSettings.setChargingRate(toSet)

                                                    --now fetch charging rate and readjust string
                                                    currentChargingRate=hardwareSettings.getChargingRate()
                                                    if(currentChargingRate==nil)then
                                                        advancedMenu:getItemByID("chargingRateText").text="?"
                                                    else
                                                        advancedMenu:getItemByID("chargingRateText").text=""..currentChargingRate
                                                    end
                                                end

    advancedMenu:getItemByID("chargingRateDown").callbackUp=function()
                                                    local toSet
                                                    if(currentChargingRate==100)then
                                                        toSet=95
                                                    elseif(currentChargingRate==95)then
                                                        toSet=90
                                                    elseif(currentChargingRate==90)then
                                                        toSet=85
                                                    elseif(currentChargingRate==85)then
                                                        toSet=80
                                                    elseif(currentChargingRate==80)then
                                                        toSet=75
                                                    elseif(currentChargingRate==75)then
                                                        toSet=70
                                                    elseif(currentChargingRate==70)then
                                                        toSet=65
                                                    elseif(currentChargingRate==65)then
                                                        toSet=60
                                                    elseif(currentChargingRate==60)then
                                                        toSet=100
                                                    else
                                                        toSet=100
                                                    end                            

                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end

                                                    soundManager.playButtonClickSound()
                                                    hardwareSettings.setChargingRate(toSet)

                                                    --now fetch charging rate and readjust string
                                                    currentChargingRate=hardwareSettings.getChargingRate()
                                                    if(currentChargingRate==nil)then
                                                        advancedMenu:getItemByID("chargingRateText").text="?"
                                                    else
                                                        advancedMenu:getItemByID("chargingRateText").text=""..currentChargingRate
                                                    end
                                                end                                            
    --------
    --startup launch title
    advancedMenu:addTextDisplay({id="startupLaunchTitle",xRelative=270,yRelative=316,font=assetName.AMR,fontSize=textResource.fontM,string="LAUNCH TOOL ON WINDOWS START",
        colour={r=90/255,g=103/255,b=121/255}, align="center", sizeLimit={width=500}})

    advancedMenu:addButton({id="startupLaunchButton",xRelative=270,yRelative=372,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
   
    --set the text on the button to enabled or disabled based on whether the app is currently configured to run on windows launch or not:
    local isTaskPresent=hardwareSettings.isTaskPresent()
    if(isTaskPresent)then
        advancedMenu:getItemByID("startupLaunchButton"):addTextDisplay({id="startupLaunchButtonText",xRelative=0,yRelative=0,font=assetName.AMB,fontSize=textResource.fontM,string="ENABLED",
            colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=100}})
    else
        advancedMenu:getItemByID("startupLaunchButton"):addTextDisplay({id="startupLaunchButtonText",xRelative=0,yRelative=0,font=assetName.AMB,fontSize=textResource.fontM,string="DISABLED",
            colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=100}})
    end

    --callback
    advancedMenu:getItemByID("startupLaunchButton").callbackUp=function()
        --Setting up a scheduled task involves a slightly long process where an xml file is also edited and I want to show a toast confirmation at the end, so using the blokcking timer here as well:
        if(changesBlocked)then
            return
        else
            changesBlocked=true
            timerService.addTimer(1000,function()
                                        changesBlocked=false
                                    end)
        end
        soundManager.playButtonClickSound()
        
        if(isTaskPresent)then
            local success, message =hardwareSettings.toggleStartup(false)
        else
            local success, message =hardwareSettings.toggleStartup(true)
        end

        --once the actions are complete, check the status once again and update the button text
        isTaskPresent=hardwareSettings.isTaskPresent()
        if(isTaskPresent)then
            advancedMenu:getItemByID("startupLaunchButton"):getItemByID("startupLaunchButtonText").text="ENABLED"
        else
            advancedMenu:getItemByID("startupLaunchButton"):getItemByID("startupLaunchButtonText").text="DISABLED"
        end
        
    end
    --------

	--exit button
	advancedMenu:addButton({id="exitButton",xRelative=270,yRelative=836,width=114,height=65,imageDownPath=nil,
			imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
	advancedMenu:getItemByID("exitButton"):addTextDisplay({xRelative=0,yRelative=0,font=assetName.AMB,fontSize=textResource.fontM,string="EXIT",
		colour={r=90/255,g=103/255,b=121/255}})

	--callbacks
	advancedMenu:getItemByID("exitButton").callbackUp=function()
		soundManager.playButtonClickSound()
		advancedMenu:destroy()
		callback()
	end	

	-- --flowers to ciphray:
	-- advancedMenu:addTextDisplay({id="notice",xRelative=272,yRelative=770,font=assetName.AMR,fontSize=textResource.fontXS,
	-- 	string="Scripts to set custom profiles and restore default profiles are courtesy of Ciphray on the GPD Discord",
	-- 	colour={r=90/255,g=103/255,b=121/255}, width=500, align="left"})

	--add a fadeIn effect if indicated in the fn call
	if(shouldFadeIn)then
		advancedMenu:fadeIn()  
	end
end

return advancedOptionsMenu
