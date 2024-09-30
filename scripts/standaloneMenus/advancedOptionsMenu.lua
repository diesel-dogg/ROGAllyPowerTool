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
	advancedMenu:addTextDisplay({id="installPlansText",xRelative=270,yRelative=215,font=assetName.AMR,fontSize=textResource.fontS,
			string="For CPU limit to work, it is necessary to replace the Asus power plans with custom plans of the same name".. 
			" that have the Windows battery slider disabled. A command window will open on pressing this button. Please follow the steps there.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--install/reinstall custom power plans button. The Asus armoury crate power plans are non compliant with cpu settings and other powercfg commands so 
    --this batch file creates power plans with the same IDs and names but standard windows power saver settings so that we can apply our changes to them. 
    --by duplicating the windows power saving setting, we remove the battery slider and prevent windows from overriding cpu settings.
    --these settings are sometimes lost when the device is plugged in so we need a button to reapply the batch file. 
    advancedMenu:addButton({id="installPlans",xRelative=270,yRelative=328,width=228,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButtonLarge,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("installPlans"):addTextDisplay({id="installPlansBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Reinstall Custom Plans", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=200}})

    advancedMenu:getItemByID("installPlans").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.installPowerPlans()
                                                    end
    --------                                                
    --text for restore asus plans:
	advancedMenu:addTextDisplay({id="restorePlansText",xRelative=270,yRelative=421,font=assetName.AMR,fontSize=textResource.fontS,
			string="The default Asus power plans can be restored at any time with the button below.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--this button will restore the default asus power plans
    advancedMenu:addButton({id="restorePlans",xRelative=270,yRelative=490,width=228,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButtonLarge,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("restorePlans"):addTextDisplay({id="restorePlansBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Restore Default Plans", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=200}})

    advancedMenu:getItemByID("restorePlans").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.restoreAsusPlans()
                                                    end                                                            
    --------
    --gfx reset button 
    --text for display device reset:
	advancedMenu:addTextDisplay({id="gfxResetText",xRelative=270,yRelative=598,font=assetName.AMR,fontSize=textResource.fontS,
			string="This option, even though present, is not expected to work, and as such, it is recommended to restart the device to release a static GPU clock,",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

    advancedMenu:addButton({id="gfxReset",xRelative=270,yRelative=682,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    advancedMenu:getItemByID("gfxReset"):addTextDisplay({id="gfxResetBtnText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="Gfx Reset", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=100}})

    advancedMenu:getItemByID("gfxReset").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        hardwareSettings.resetGfx()
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

	--add text display credit to ciphray
	advancedMenu:addTextDisplay({id="notice",xRelative=272,yRelative=770,font=assetName.AMR,fontSize=textResource.fontXS,
		string="Scripts to set custom profiles and restore default profiles are courtesy of Ciphray on the GPD Discord",
		colour={r=90/255,g=103/255,b=121/255}, width=500, align="left"})

	--add a fadeIn effect if indicated in the fn call
	if(shouldFadeIn)then
		advancedMenu:fadeIn()  
	end
end

return advancedOptionsMenu
