local composer = require( "composer")
local mainMenuScreen = composer.newScene(  )

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local menuMaker=require "scripts.menuHelper.menu"
local assetName=require "scripts.helperScripts.assetName"
local soundManager=require "scripts.soundManager"
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local deltaTime=require "scripts.helperScripts.deltaTime"
local timerService=require "scripts.helperScripts.timerService"
local animationService= require "scripts.helperScripts.animationService"
local toast=require "scripts.helperScripts.toast"
local textResource= require "scripts.textResources.textResourceEnglish"
local lfs = require( "lfs" )
local profileSelectionMenu=require "scripts.standaloneMenus.profileSelectionMenu"
local advancedOptionsMenu=require "scripts.standaloneMenus.advancedOptionsMenu"
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
local mainMenu, makeProfileSaveMenu,makeFirstLaunchDialog
local changesBlocked=false--this boolean is toggled with help of a 1s timer to prevent rapid input from user

-- level selection menu containing all levels in game.
function makeMainMenu(shouldFadeIn)
    mainMenu=menuMaker.newMenu({name="mainMenu",x=0,y=0,masterImageGroup=menuDisplayGroup, baseImagePath=assetName.mainMenuBase,
    baseImageWidth=540,baseImageHeight=900})
    
    --menu title text
	mainMenu:addTextDisplay({id="title",xRelative=270,yRelative=66,font=assetName.AMB,fontSize=textResource.fontXL,string="QUICK SETTINGS",
        colour={r=90/255,g=103/255,b=121/255}})
    -----------------
    --tdp title
    mainMenu:addTextDisplay({id="tdpTitle",xRelative=270,yRelative=168,font=assetName.AMR,fontSize=textResource.fontM,string="TDP",
        colour={r=90/255,g=103/255,b=121/255}})
	
    --TDP up button 
    mainMenu:addButton({id="tdpUp",xRelative=116,yRelative=228,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --TDP down button 
    mainMenu:addButton({id="tdpDown",xRelative=414,yRelative=228,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})


    --menu TDP text
    local value=hardwareSettings.getTDP()
    if(value==nil)then
        value="?"
    end
    mainMenu:addTextDisplay({id="tdpText", xRelative=270, yRelative=228, font=assetName.AMR, fontSize=textResource.fontL,
    string=""..value.." W", colour={r=132/255,g=82/255,b=82/255}})
    
   
    mainMenu:getItemByID("tdpUp").callbackUp=function()
                                                    --block of code below will be used in all value up/value down options. It returns without proceding if the boolean was raised and otherwise starts a blocking timer to prevent input for the next 1 s
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end

                                                     soundManager.playButtonClickSound()
                                                     hardwareSettings.setTDP(hardwareSettings.getTDP()+1)  
                                                     mainMenu:getItemByID("tdpText").text=""..hardwareSettings.getTDP().." W"
                                                    end

    mainMenu:getItemByID("tdpDown").callbackUp=function()
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end
                                                     soundManager.playButtonClickSound()
                                                     hardwareSettings.setTDP(hardwareSettings.getTDP()-1)
                                                     mainMenu:getItemByID("tdpText").text=""..hardwareSettings.getTDP().." W"
                                                    end
   -----------------
   --cpu title
    mainMenu:addTextDisplay({id="cpuTitle",xRelative=270,yRelative=330,font=assetName.AMR,fontSize=textResource.fontM,string="CPU CLOCK",
        colour={r=90/255,g=103/255,b=121/255}})

    --CPU up button 
    mainMenu:addButton({id="cpuUp",xRelative=116,yRelative=390,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --CPU down button 
    mainMenu:addButton({id="cpuDown",xRelative=414,yRelative=390,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})


    --menu CPU clock text
    local value=hardwareSettings.getCPUClock()
    if(value==nil)then
        value="?"
    end
    mainMenu:addTextDisplay({id="cpuSpeedText", xRelative=270, yRelative=390, font=assetName.AMR, fontSize=textResource.fontL,
    string=""..value.." MHz", colour={r=132/255,g=82/255,b=82/255}})
    
   
    mainMenu:getItemByID("cpuUp").callbackUp=function()
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end 

                                                    soundManager.playButtonClickSound()
                                                     hardwareSettings.setCPUClock(hardwareSettings.getCPUClock()+200) 
                                                     mainMenu:getItemByID("cpuSpeedText").text=""..hardwareSettings.getCPUClock().." MHz"
                                                    end

    mainMenu:getItemByID("cpuDown").callbackUp=function()
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end 

                                                    soundManager.playButtonClickSound()
                                                     hardwareSettings.setCPUClock(hardwareSettings.getCPUClock()-200) 
                                                     mainMenu:getItemByID("cpuSpeedText").text=""..hardwareSettings.getCPUClock().." MHz"
                                                    end  

    -----------------
    --gpu title
    mainMenu:addTextDisplay({id="gpuTitle",xRelative=270,yRelative=500,font=assetName.AMR,fontSize=textResource.fontM,string="GPU STATIC CLOCK",
        colour={r=90/255,g=103/255,b=121/255}})

    --gpu up button 
    mainMenu:addButton({id="gpuUp",xRelative=116,yRelative=560,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --gpu down button 
    mainMenu:addButton({id="gpuDown",xRelative=414,yRelative=560,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})

    --menu gpu clock text
    local value=hardwareSettings.getGfxClock()
    if(value==nil)then
        value="?"
    end
    --we treat a readout of 800mhz as default, non-static clock so adding a clause to print accordingly
    if(value==800)then
        mainMenu:addTextDisplay({id="gpuClockText", xRelative=270, yRelative=560, font=assetName.AMR, fontSize=textResource.fontL,
        string="DEFAULT", colour={r=132/255,g=82/255,b=82/255}})
    else
        mainMenu:addTextDisplay({id="gpuClockText", xRelative=270, yRelative=560, font=assetName.AMR, fontSize=textResource.fontL,
        string=""..value.." MHz", colour={r=132/255,g=82/255,b=82/255}})
    end
    
   
    mainMenu:getItemByID("gpuUp").callbackUp=function()
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end 

                                                    soundManager.playButtonClickSound()
                                                     hardwareSettings.setGfxClock(hardwareSettings.getGfxClock()+200) 
                                                     mainMenu:getItemByID("gpuClockText").text=""..hardwareSettings.getGfxClock().." MHz"
                                                    end

    mainMenu:getItemByID("gpuDown").callbackUp=function()
                                                    if(changesBlocked)then
                                                        return
                                                    else
                                                        changesBlocked=true
                                                        timerService.addTimer(1000,function()
                                                                                    changesBlocked=false
                                                                                end)
                                                    end 

                                                    soundManager.playButtonClickSound()
                                                     hardwareSettings.setGfxClock(hardwareSettings.getGfxClock()-200) 
                                                     mainMenu:getItemByID("gpuClockText").text=""..hardwareSettings.getGfxClock().." MHz"
                                                    end  
    -----------------                                                
    --FPS title
    mainMenu:addTextDisplay({id="fpsTitle",xRelative=270,yRelative=675,font=assetName.AMR,fontSize=textResource.fontM,string="FPS LIMIT",
        colour={r=90/255,g=103/255,b=121/255}})

    --fps up button 
    mainMenu:addButton({id="fpsUp",xRelative=116,yRelative=730,width=90,height=90,imageUpPath=assetName.upButton,doesScaleDown=true})

    --fps down button 
    mainMenu:addButton({id="fpsDown",xRelative=414,yRelative=730,width=90,height=90,imageUpPath=assetName.downButton,doesScaleDown=true})

    
    local value=hardwareSettings.getFPSLimit()
    if(value==nil)then
        value="?"
    end
    local currentFPS=value--fetching a value here since we need to go over multiple cases to set FPS values based on current value in button action so we cannot keep fetching

    if(currentFPS==nil or currentFPS==0)then--if no value is read from file or 0 is read, then declare the limit as NO LIMIT
        mainMenu:addTextDisplay({id="fpsText", xRelative=270, yRelative=730, font=assetName.AMR, fontSize=textResource.fontL,
        string="NO LIMIT", colour={r=132/255,g=82/255,b=82/255}})
    else
         mainMenu:addTextDisplay({id="fpsText", xRelative=270, yRelative=730, font=assetName.AMR, fontSize=textResource.fontL,
        string=""..currentFPS, colour={r=132/255,g=82/255,b=82/255}})
    end
    
   
    mainMenu:getItemByID("fpsUp").callbackUp=function()
                                                    local toSet
                                                    if(currentFPS==nil or currentFPS==0)then
                                                        toSet=30
                                                    elseif(currentFPS==30)then
                                                        toSet=40
                                                    elseif(currentFPS==40)then
                                                        toSet=50
                                                    elseif(currentFPS==50)then
                                                        toSet=60
                                                    elseif(currentFPS==60)then
                                                        toSet=80
                                                    elseif(currentFPS==80)then
                                                        toSet=100
                                                    elseif(currentFPS==100)then
                                                        toSet=117
                                                    elseif(currentFPS==117)then
                                                        toSet=120
                                                    elseif(currentFPS==120)then
                                                        toSet=0
                                                    else
                                                        toSet=0 
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
                                                    hardwareSettings.setFPSLimit(toSet)

                                                    --now fetch fps and readjust string
                                                    currentFPS=hardwareSettings.getFPSLimit()
                                                    if(currentFPS==nil or currentFPS==0)then
                                                        mainMenu:getItemByID("fpsText").text="NO LIMIT"
                                                    else
                                                        mainMenu:getItemByID("fpsText").text=""..currentFPS
                                                    end
                                                end

    mainMenu:getItemByID("fpsDown").callbackUp=function()
                                                    local toSet
                                                    if(currentFPS==nil or currentFPS==0)then
                                                        toSet=120
                                                    elseif(currentFPS==120)then
                                                        toSet=117
                                                    elseif(currentFPS==117)then
                                                        toSet=100
                                                    elseif(currentFPS==100)then
                                                        toSet=80
                                                    elseif(currentFPS==80)then
                                                        toSet=60
                                                    elseif(currentFPS==60)then
                                                        toSet=50
                                                    elseif(currentFPS==50)then
                                                        toSet=40
                                                    elseif(currentFPS==40)then
                                                        toSet=30
                                                    elseif(currentFPS==30)then
                                                        toSet=0
                                                    else
                                                        toSet=0 
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
                                                    hardwareSettings.setFPSLimit(toSet)

                                                    --now fetch fps and readjust string
                                                    currentFPS=hardwareSettings.getFPSLimit()
                                                    if(currentFPS==nil or currentFPS==0)then
                                                        mainMenu:getItemByID("fpsText").text="NO LIMIT"
                                                    else
                                                        mainMenu:getItemByID("fpsText").text=""..currentFPS
                                                    end
                                                end                                                 

    -----------------                                                 
    --profiles button 
    mainMenu:addButton({id="profilesButton",xRelative=88,yRelative=836,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    mainMenu:getItemByID("profilesButton"):addTextDisplay({id="profilesButtonText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="PROFILES", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=100}})

    mainMenu:getItemByID("profilesButton").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        mainMenu:destroy()
                                                        profileSelectionMenu.makeProfileSelectionMenu(function() makeMainMenu(true) end,true)
                                                    end 

    --save profile button 
    mainMenu:addButton({id="saveProfile",xRelative=270,yRelative=836,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    mainMenu:getItemByID("saveProfile"):addTextDisplay({id="profilesButtonText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="CREATE \nPROFILE", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={height=50}, align="center"})

    mainMenu:getItemByID("saveProfile").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        mainMenu:destroy()
                                                        makeProfileSaveMenu()
                                                    end                                                            

    --button to go to the advanced menu
    mainMenu:addButton({id="advanced",xRelative=454,yRelative=836,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    mainMenu:getItemByID("advanced"):addTextDisplay({id="advancedText",xRelative=0,yRelative=0,font=assetName.AMB, fontSize=textResource.fontM,
    string="ADVANCED", colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=100}})

    mainMenu:getItemByID("advanced").callbackUp=function()
                                                        soundManager.playButtonClickSound()
                                                        mainMenu:destroy()
                                                        advancedOptionsMenu.makeAdvancedOptionsMenu(function() makeMainMenu(true) end,true)
                                                    end                                                                                 

    --add a fadeIn effect if indicated in the fn call
	if(shouldFadeIn)then
		mainMenu:fadeIn()  
    end                                                    
end

--------------------------------------------------------------------
--call this function with the string name of a profile and it will capture all the current power settings and write them neatly into a profile file
local function writeDataToProfile(profileName)
    --create variables for current values of tdp, cpu limit, static gpu clock and rtss fps limit and check that they are all valid numbers
    --if there are non numerical values found, set proper defaults:
    local currentTDP=hardwareSettings.getTDP()
    if(tonumber(currentTDP)==nil)then
        currentTDP=15--default
    end

    local currentCPU=hardwareSettings.getCPUClock()
    if(tonumber(currentCPU)==nil)then
        currentCPU=3200--default
    end

    local currentGPU=hardwareSettings.getGfxClock()

    if(tonumber(currentGPU)==nil or myMath.round(tonumber(currentGPU))==800)then
        currentGPU="DEFAULT"--default
    end 

    local currentFPS=hardwareSettings.getFPSLimit()
    if(tonumber(currentFPS)==nil or tonumber(currentFPS)==0)then
        currentFPS="NO LIMIT"--default
    end    

    --notice how we set the canDelete flag to true right at the end when formulating the content for the file. This is because we intend for the user created profiles to be deletable. 
    local stringToWrite="name:"..profileName.."\ntdp:"..currentTDP.."\ncpu:"..currentCPU.."\ngpu:"..currentGPU.."\nfps:"..currentFPS.."\ncanDelete:true"
    --now write the string to file:
    local fileHandle = io.open( "C:/ROGAllyPowerTool/User Profiles/"..profileName..".txt", "w" )

    -- Check if the file was opened successfully
    if fileHandle then
        -- Write the text to the file
        fileHandle:write(stringToWrite)
        -- Close the file handle
        fileHandle:close()
        toast.showToast("Saved profile "..profileName)
    else
        -- Handle the error if the file couldn't be opened
        -- debugStmt.print("mainMenuScreen : Error opening file" )
        toast.showToast("Invalid file name. Do not press ENTER key when inputting the profile name!")
    end
end
-------------------------------------------------------------------

function makeProfileSaveMenu()
    local textBox=native.newTextBox( 270, 500, 400, 100)
    textBox.isEditable = true

    local saveMenu=menuMaker.newMenu({name="saveMenu",x=width*0.5-540*0.5,y=height*0.5-400*0.5,masterImageGroup=nil, baseImagePath=assetName.dialogBase,
    baseImageWidth=540,baseImageHeight=400,overlayAlpha=0.5})

    --title
    saveMenu:addTextDisplay({id="title",xRelative=270,yRelative=50,font=assetName.AMB,fontSize=textResource.fontXL,string="CREATE NEW PROFILE",
        colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})

    --text
    saveMenu:addTextDisplay({id="body",xRelative=270,yRelative=137,font=assetName.AMR,fontSize=textResource.fontS,
            string="Enter a name for the profile by clicking inside the text box below.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

    --apply btn
    saveMenu:addButton({id="saveButton",xRelative=120,yRelative=330,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    saveMenu:getItemByID("saveButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="SAVE",
        colour={r=90/255,g=103/255,b=121/255}})

    --cancel btn
    saveMenu:addButton({id="cancelButton",xRelative=426,yRelative=330,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    saveMenu:getItemByID("cancelButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="CANCEL",
        colour={r=90/255,g=103/255,b=121/255}})

    --callbacks
    saveMenu:getItemByID("saveButton").callbackUp=function()
        soundManager.playButtonClickSound()
        if(textBox.text=="" or textBox.text==nil)then
            toast.showToast("Profile name cannot be empty")
            return
        end
        writeDataToProfile(textBox.text)
        textBox:removeSelf()
        textBox=nil
        saveMenu:destroy()
        makeMainMenu()
    end 

    saveMenu:getItemByID("cancelButton").callbackUp=function()
        soundManager.playButtonClickSound()
        textBox:removeSelf()
        textBox=nil
        saveMenu:destroy()
        makeMainMenu()
    end 
end

----------------------------------
--this function will be called until the necessary option in the dialog shown is selected by the user to install the custom power plans
--once they do so, the preference is toggled and it won't be shown again. This is the first thing anyone will see when they get past the splash screen
function makeFirstLaunchDialog()
    --if the first launch steps were performed, just make the main menu
    if(preferenceHandler.get("firstLaunchStepsPerformed"))then
        makeMainMenu(true)
        return
    end

    local firstLaunchMenu=menuMaker.newMenu({name="firstLaunchMenu",x=width*0.5-540*0.5,y=height*0.5-400*0.5,masterImageGroup=nil, baseImagePath=assetName.dialogBase,
    baseImageWidth=540,baseImageHeight=400,overlayAlpha=0.5})

    --title
    firstLaunchMenu:addTextDisplay({id="title",xRelative=270,yRelative=50,font=assetName.AMB,fontSize=textResource.fontXL,string="SETUP",
        colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})

    --body
    firstLaunchMenu:addTextDisplay({id="body",xRelative=270,yRelative=200,font=assetName.AMR,fontSize=textResource.fontS,
            string="For CPU limit to work, it is necessary to replace the Asus power plans with custom plans of the same name.".. 
            " A command window will open on pressing the ACCEPT button. Please follow the steps there."..
            " You can undo all changes at any time from the ADVANCED menu in-app.",colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

    --accept btn
    firstLaunchMenu:addButton({id="acceptButton",xRelative=120,yRelative=330,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    firstLaunchMenu:getItemByID("acceptButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="ACCEPT",
        colour={r=90/255,g=103/255,b=121/255}})

    --exit btn
    firstLaunchMenu:addButton({id="exitButton",xRelative=426,yRelative=330,width=114,height=65,imageDownPath=nil,
            imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
    firstLaunchMenu:getItemByID("exitButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="EXIT",
        colour={r=90/255,g=103/255,b=121/255}})

    --callbacks
    firstLaunchMenu:getItemByID("acceptButton").callbackUp=function()
        soundManager.playButtonClickSound()
        hardwareSettings.installPowerPlans()
        preferenceHandler.set("firstLaunchStepsPerformed",true)--set the preference to true to prevent showing menu again
        firstLaunchMenu:destroy()
        makeMainMenu()
    end 

    --exit if the user declines. 
    firstLaunchMenu:getItemByID("exitButton").callbackUp=function()
        soundManager.playButtonClickSound()
        toast.showToast("Exiting in 5 seconds")
        timerService.addTimer(5000,function()
                os.exit(  )
            end)
    end 
end
----------------------------------

local function update()
    local dt=deltaTime.getDelta()

end


----------------------------------
function mainMenuScreen:create(event)
    composer.removeScene( event.params.callingScene)--removing the calling scene

    -- debugStmt.print("mainMenuScreen: create is called")
    menuDisplayGroup=display.newGroup()
    local group=self.view
    group:insert(menuDisplayGroup)

    local group=self.view
    local UIDisplayGroup=display.newGroup()
    local blackBarsGroup=display.newGroup() --this group is the last one to be added in the view and contains boundaries used to restrict view to game screen.

    group:insert(UIDisplayGroup)
    group:insert(blackBarsGroup)
    
    --create black rectangles on all the 4 sidess of the game screen to restrict the view to the gameScreen
    local boundaryRectangleTop=display.newRect(blackBarsGroup,width*0.5,-957,width*3,1624)
    local boundaryRectangleBottom=display.newRect(blackBarsGroup,width*0.5,2291,width*3,1624)
    local boundaryRectangleLeft=display.newRect(blackBarsGroup,-width*0.5,height*0.5,width,1624)
    local boundaryRectangleRight=display.newRect(blackBarsGroup,width*1.5,height*0.5,width,1624)
    -- set the colours of the rectangles to black
    boundaryRectangleTop:setFillColor(0,0,0)
    boundaryRectangleBottom:setFillColor(0,0,0)
    boundaryRectangleLeft:setFillColor(0,0,0)
    boundaryRectangleRight:setFillColor(0,0,0)

    --resume timerService and animationService. Had they been paused previously by another screen, this well get them running 
  	timerService.resume()
  	animationService.resume()

    Runtime:addEventListener("enterFrame",update)

    --finally, call the function that checks if the first launch steps were performed and if not, it shows the necessary instructions or otherwise, it proceeds to make the main menu
    --Also,if debug mode is on, we skip this so that we don't get stuck on this locking menu on our testing devices:
    if(not isDebugMode)then
        makeFirstLaunchDialog()
    else
        makeMainMenu()
        toast.showToast("MMS: DEBUG IS ON")
    end
end
-----------------------
function mainMenuScreen:destroy(event)
    debugStmt.print("mainMenuScreen: destroy called")

    --remove all runtime listeners if any.
    Runtime:removeEventListener("enterFrame",update)
    --cancel all timers and remove all animations pertaining to this screen
    timerService.cancelAll()
	animationService.removeAll()
end
-----------------------
-- Listener setup
mainMenuScreen:addEventListener( "create", mainMenuScreen )
mainMenuScreen:addEventListener( "destroy", mainMenuScreen )

return mainMenuScreen