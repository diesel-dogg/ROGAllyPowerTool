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
local showRestartDialog
-----------------------------------
function advancedOptionsMenu.makeAdvancedOptionsMenu(callback1,shouldFadeIn)
	callback=callback1

	advancedMenu=menuMaker.newMenu({name="advancedMenu",x=0,y=0,masterImageGroup=nil, baseImagePath=assetName.advancedMenuBase,
		baseImageWidth=810,baseImageHeight=900,overlayAlpha=0.5})

	--menu title text
	advancedMenu:addTextDisplay({id="title",xRelative=405,yRelative=66,font=assetName.AMB,fontSize=textResource.fontXL,string="ADVANCED OPTIONS",
		colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})
	
	--------
	--text for installPlans (now updated to include text for restoring power plans):
	advancedMenu:addTextDisplay({id="installPlansText",xRelative=418,yRelative=664,font=assetName.AMR,fontSize=textResource.fontS,
			string="For CPU limit to work, the Asus power plans must be replaced with custom power plans of the same name.".. 
			" A command window will open on pressing this button- please follow the steps there. Alternatively, you also have the options of restoring the default Asus power plans.",
            colour={r=132/255,g=82/255,b=82/255},width=700,align="left"})

	--install/reinstall custom power plans button. The Asus armoury crate power plans are non compliant with cpu settings and other powercfg commands so 
    --this batch file creates power plans with the same IDs and names but standard windows power saver settings so that we can apply our changes to them. 
    --by duplicating the windows power saving setting, we remove the battery slider and prevent windows from overriding cpu settings.
    --these settings are sometimes lost when the device is plugged in so we need a button to reapply the batch file. 
    advancedMenu:addButton({id="installPlans",xRelative=230,yRelative=764,width=228,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButtonLarge,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("installPlans"):addTextDisplay({id="installPlansBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Reinstall Custom Plans", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=200}})

    advancedMenu:getItemByID("installPlans").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.installPowerPlans()
                                                    end
    --------                                                
    --text for restore asus plans:
	-- advancedMenu:addTextDisplay({id="restorePlansText",xRelative=270,yRelative=684,font=assetName.AMR,fontSize=textResource.fontS,
	-- 		string="The default Asus power plans can be restored at any time with the button below.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--this button will restore the default asus power plans
    advancedMenu:addButton({id="restorePlans",xRelative=586,yRelative=764,width=228,height=65,imageDownPath=nil,
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
    advancedMenu:addTextDisplay({id="chargingRateTitle",xRelative=244,yRelative=202,font=assetName.AMR,fontSize=textResource.fontM,string="BATTERY CHARGE LIMIT \n (Please restart device after changing this setting)",
        colour={r=90/255,g=103/255,b=121/255}, align="left", width=400})
    
    --charging limit  up button 
    advancedMenu:addButton({id="chargingRateUp",xRelative=70,yRelative=302,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --charging limit  down button 
    advancedMenu:addButton({id="chargingRateDown",xRelative=338,yRelative=302,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})
   
    local currentChargingRate=hardwareSettings.getChargingRate()
    if(currentChargingRate==nil)then
        currentChargingRate="?"
        advancedMenu:addTextDisplay({id="chargingRateText", xRelative=202, yRelative=302, font=assetName.AMR, fontSize=textResource.fontL,
            string=""..currentChargingRate, colour={r=132/255,g=82/255,b=82/255}})
    else
        advancedMenu:addTextDisplay({id="chargingRateText", xRelative=202, yRelative=302, font=assetName.AMR, fontSize=textResource.fontL,
            string=""..currentChargingRate.."%", colour={r=132/255,g=82/255,b=82/255}})
    end

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
                                                        advancedMenu:getItemByID("chargingRateText").text=""..currentChargingRate.."%"
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
                                                        advancedMenu:getItemByID("chargingRateText").text=""..currentChargingRate.."%"
                                                    end
                                                end                                            
    --------
    --startup launch title
    advancedMenu:addTextDisplay({id="startupLaunchTitle",xRelative=550,yRelative=246,font=assetName.AMR,fontSize=textResource.fontM,string="LAUNCH TOOL ON WINDOWS START",
        colour={r=90/255,g=103/255,b=121/255}, align="left",width=250})
   
    --set the text on the button to enabled or disabled based on whether the app is currently configured to run on windows launch or not:
    local isTaskPresent=hardwareSettings.isTaskPresent()
    if(isTaskPresent)then
        advancedMenu:addButton({id="startupLaunchButton",xRelative=696,yRelative=246,width=86,height=50,imageUpPath=assetName.sliderEnabled})
    else
        advancedMenu:addButton({id="startupLaunchButton",xRelative=696,yRelative=246,width=86,height=50,imageUpPath=assetName.sliderDisabled})
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

        --once the actions are complete, make the menu again so that button can be revised:
        advancedMenu:destroy()
        advancedOptionsMenu.makeAdvancedOptionsMenu(callback, false)
    end
    --------

    --stutter mode and ulps title
    advancedMenu:addTextDisplay({id="stutterModeAndUlpsTitle",xRelative=418,yRelative=410,font=assetName.AMR,fontSize=textResource.fontM,string="DISABLE STUTTER MODE AND ULPS",
        colour={r=90/255,g=103/255,b=121/255}, align="left",width=700})

    --checking the registry values for stutter mode and ULPS:
    local currentValueTable=hardwareSettings.getStutterModeAndULPS()

    --We need to show the switch as being enabled when both stutterMode and ulps are disabled (i.e. set to 0). For any other values or even if either key is not present, we show the slider toggle in disabled state
    if(currentValueTable and currentValueTable.stutterMode==0 and currentValueTable.ulps==0)then
        advancedMenu:addButton({id="stutterModeAndUlpsButton",xRelative=554,yRelative=410,width=86,height=50,imageUpPath=assetName.sliderEnabled})
    else
        advancedMenu:addButton({id="stutterModeAndUlpsButton",xRelative=554,yRelative=410,width=86,height=50,imageUpPath=assetName.sliderDisabled})
    end

    --callback
    advancedMenu:getItemByID("stutterModeAndUlpsButton").callbackUp=function()
        --no real reason to not prevent rapid inputs toggling this switch:
        if(changesBlocked)then
            return
        else
            changesBlocked=true
            timerService.addTimer(1000,function()
                                        changesBlocked=false
                                    end)
        end
        soundManager.playButtonClickSound()

        local outcome=false
        local msg=nil
        --this is the case where the switch was already enabled and stutter mode and ulps were both set to 0. 
        --In this case, we need to set sutter mode to its typical default value of 2 and ulps to 1 as a way to restore the defaults
        if(currentValueTable and currentValueTable.stutterMode==0 and currentValueTable.ulps==0)then
            outcome,msg=hardwareSettings.restoreDefaultsStutterModeAndULPS()
        else
            --in any other case, including if either of these keys were missing in registry, we can safely create entries for both and set values to 0
            outcome,msg=hardwareSettings.disableStutterModeAndULPS()
        end

        --if the actions were successfully carried out (i.e. both keys were set to 0 or restored to default), show a dialog requesting a system restart
        if(outcome==true)then
            advancedMenu:destroy()
            showRestartDialog()--this menu will automatically make the advancedOptionsMenu when user clicks OK
        end
    end

    --stutter mode and ulps body
    advancedMenu:addTextDisplay({id="stutterModeAndUlpsBody",xRelative=418,yRelative=508,font=assetName.AMR,fontSize=textResource.fontS,
            string="Stutter Mode is understood to be a technique to smoothen the FPS during high workloads by adjusting frame delivery at the driver level."..
            " This can often be at the cost of increased input latency and responsiveness. Disabling this along with the GPU's Ultra Low Power State can possibly improve gaming experience.",
            colour={r=132/255,g=82/255,b=82/255},width=700,align="left"})
    --------

	--exit button
	advancedMenu:addButton({id="exitButton",xRelative=405,yRelative=836,width=114,height=65,imageDownPath=nil,
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

-----------------------------------------------

function showRestartDialog()
    local restartMenu=menuMaker.newMenu({name="restartMenu",x=width*0.5-540*0.5,y=height*0.5-400*0.5,masterImageGroup=nil, baseImagePath=assetName.dialogBase,
    baseImageWidth=540,baseImageHeight=400,overlayAlpha=0.8})

    --title
    restartMenu:addTextDisplay({id="title",xRelative=270,yRelative=50,font=assetName.AMB,fontSize=textResource.fontXL,string="RESTART REQUIRED!",
        colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})

    local text= "Please restart device for changes made to the registry to take effect."
    --text
    restartMenu:addTextDisplay({id="body",xRelative=270,yRelative=198,font=assetName.AMR,fontSize=textResource.fontL,
            string=""..text,colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

    --ok btn
    restartMenu:addButton({id="okButton",xRelative=270,yRelative=333,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    restartMenu:getItemByID("okButton"):addTextDisplay({xRelative=0,yRelative=0,font=assetName.AMB,fontSize=textResource.fontM,string="OK",
        colour={r=90/255,g=103/255,b=121/255}})

    restartMenu:getItemByID("okButton").callbackUp=function()
        soundManager.playButtonClickSound()
        restartMenu:destroy()
        advancedOptionsMenu.makeAdvancedOptionsMenu(callback,true)
    end 

    restartMenu:fadeIn()
end

return advancedOptionsMenu
