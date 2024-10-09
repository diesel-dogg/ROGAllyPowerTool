local profileSelectionMenu={}

--This is a template script that can add items to a scrollable set of buttons, handles their availability with assistance from 
--preferences that are set in the unlockSystem and also by using details from the Attributes script. Buying of items, checking for currency, unlock state, last selected item etc is also all available

local debugStmt= require "scripts.helperScripts.printDebugStmt"
local assetName=require "scripts.helperScripts.assetName"
local menuMaker=require "scripts.menuHelper.menu"
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local toast=require "scripts.helperScripts.toast"
local soundManager=require "scripts.soundManager"
local animationService= require "scripts.helperScripts.animationService"
local animationSystem= require "scripts.helperScripts.animationSystem"
local lfs = require("lfs")
local hardwareSettings=require "scripts.hardwareSettings"

local width=display.contentWidth
local height=display.contentHeight

local myMath={
    atan2=math.atan2,
    abs=math.abs,
    deg=math.deg,
    rad=math.rad,
    random=math.random,
    pi=math.pi,
    floor=math.floor,
    pow=math.pow,
    cos=math.cos,
    sin=math.sin,
    sqrt=math.sqrt,
    round=math.round,
}

local showProfileOptions, showConfirmationDialog
local profile
local callback--this is a reference of the function that called the makeprofileSelectionMenu function of this script. This is our only way of returning control back to where we came here from 
local stringToKeyValue,readProfileTableFromFile, getAlphabeticalTableOfProfilesFromPath

-------------------------------
function profileSelectionMenu.makeProfileSelectionMenu(callback1,shouldFadeIn)
	callback=callback1

	local profileMenu=menuMaker.newMenu({name="profileMenu",x=135,y=0,masterImageGroup=nil, baseImagePath=assetName.mainMenuBase,
		baseImageWidth=540,baseImageHeight=950,overlayAlpha=0.5})

	--menu title text
	profileMenu:addTextDisplay({id="title",xRelative=270,yRelative=66,font=assetName.AMB,fontSize=textResource.fontXL,string="PRESETS & PROFILES",
		colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})
	
	----------------------
	--exit button
	profileMenu:addButton({id="exitButton",xRelative=270,yRelative=880,width=114,height=65,imageDownPath=nil,
			imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
	profileMenu:getItemByID("exitButton"):addTextDisplay({xRelative=0,yRelative=0,font=assetName.AMB,fontSize=textResource.fontM,string="EXIT",
		colour={r=90/255,g=103/255,b=121/255}})
	--scroll down button
	profileMenu:addButton({id="scrollDownButton",xRelative=422,yRelative=880,width=60,height=60,imageDownPath=nil,
			imageUpPath=assetName.downButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
	--scroll up button
	profileMenu:addButton({id="scrollUpButton",xRelative=112,yRelative=880,width=60,height=60,imageDownPath=nil,
			imageUpPath=assetName.upButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})

	---profile buttons--------
	--use these variables to adjust the placement of buttons
	local startX,startY,xSeparation,ySeparation,buttonsPerRow
	startX=270
	startY=210
	xSeparation=145
	ySeparation=140
	buttonsPerRow=1
	--NOTE: It is best to use a mac device and take a screenshot of the menu with button debugging turned on to get a proper idea for contentBound coordinates, xPadding, yPadding etc
	local scrollContentBound={xMin=135,xMax=600+135, yMin=100, yMax=850}

	--Before creating the buttons for user-created profiles, we need to determine the path in the internal resources where preset profiles are stored and then
	--extract the profile tables for each preset profile and populate the preset buttons so that they appear on top always
	local presetPath=system.pathForFile( "presets/preset1.txt" ,system.ResourceDirectory )
    presetPath=presetPath:gsub("/preset1.txt","")

    --get all alphabetically organised paths of preset profiles
	local tableOfPresetPaths=getAlphabeticalTableOfProfilesFromPath(presetPath)    

	--iterate over the preset profiles and create their buttons
    for i=1, #tableOfPresetPaths do
	    local presetTable=readProfileTableFromFile(tableOfPresetPaths[i])
		local x=startX+xSeparation*((i-1)%buttonsPerRow)
		local y=startY+ySeparation*(myMath.floor((i-1)/buttonsPerRow))

		--add the base image of the button 
		profileMenu:addButton({id="profileButton"..i,xRelative=x,yRelative=y,width=540,height=120,imageDownPath=nil,imageUpPath=assetName.profileButton,
		callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true,doesGlow=nil})
		
		--preset name:
		profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetName",xRelative=0,yRelative=-40,font=assetName.AMB,fontSize=textResource.fontXS,
			string=""..presetTable.name,colour={r=132/255,g=82/255,b=82/255},sizeLimit={width=300},align="centre"})
		
		--preset TDP:
		profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetTDP",xRelative=-100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
			string="TDP: "..presetTable.tdp.." W",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		--preset cpu:
		profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetCPU",xRelative=-100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
			string="CPU CLK: "..presetTable.cpu.." MHz",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		--preset gpu:
		if(presetTable.gpu=="DEFAULT")then--if string detected is default, then omit the MHz unit
			profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetGPU",xRelative=100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
				string="GPU STATIC CLK: "..presetTable.gpu,colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		else
			profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetGPU",xRelative=100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
				string="GPU STATIC CLK: "..presetTable.gpu.." MHz",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		end

		--preset fps:
		if(presetTable.fps=="NO LIMIT")then
			profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetGPU",xRelative=100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
			string="FPS LIMIT: NO LIMIT",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		else
			profileMenu:getItemByID("profileButton"..i):addTextDisplay({id="presetGPU",xRelative=100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
				string="FPS LIMIT: "..presetTable.fps.."",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
		end

		--add buttons to scroll pane
		profileMenu:addButtonToScrollpane(profileMenu:getItemByID("profileButton"..i),scrollContentBound)

		--callback for the buttons created above. 
		profileMenu:getItemByID("profileButton"..i).callbackUp=function() 
			profileMenu:destroy()
			showProfileOptions(presetTable)
		end	
	end

	--Next, iterate over the user created profiles and create their buttons
	local tableOfUserProfilePaths=getAlphabeticalTableOfProfilesFromPath("C:/ROGAllyPowerTool/User Profiles")
	
	if(#tableOfUserProfilePaths>0)then   
	    for i=1, #tableOfUserProfilePaths do
	    	local iterator=#tableOfPresetPaths+i
		    local presetTable=readProfileTableFromFile(tableOfUserProfilePaths[i])
			local x=startX+xSeparation*((iterator-1)%buttonsPerRow)
			local y=startY+ySeparation*(myMath.floor((iterator-1)/buttonsPerRow))
			--add the base image of the button 
			profileMenu:addButton({id="profileButton"..iterator,xRelative=x,yRelative=y,width=540,height=120,imageDownPath=nil,imageUpPath=assetName.profileButton,
			callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true,doesGlow=nil})
			
			--preset name:
			profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetName",xRelative=0,yRelative=-40,font=assetName.AMB,fontSize=textResource.fontXS,
				string="USER PROFILE- "..presetTable.name,colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=300},align="centre"})
			--preset TDP:
			profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetTDP",xRelative=-100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
				string="TDP: "..presetTable.tdp.." W",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			--preset cpu:
			profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetCPU",xRelative=-100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
				string="CPU CLK: "..presetTable.cpu.." MHz",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			--preset gpu:
			if(presetTable.gpu=="DEFAULT")then--if string detected is default, then omit the MHz unit
				profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetGPU",xRelative=100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
					string="GPU STATIC CLK: "..presetTable.gpu,colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			else
				profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetGPU",xRelative=100,yRelative=-10,font=assetName.AMR,fontSize=textResource.fontXS,
					string="GPU STATIC CLK: "..presetTable.gpu.." MHz",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			end

			--preset fps:
			if(presetTable.fps=="NO LIMIT")then
				profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetGPU",xRelative=100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
				string="FPS LIMIT: NO LIMIT",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			else
				profileMenu:getItemByID("profileButton"..iterator):addTextDisplay({id="presetGPU",xRelative=100,yRelative=30,font=assetName.AMR,fontSize=textResource.fontXS,
					string="FPS LIMIT: "..presetTable.fps.."",colour={r=90/255,g=103/255,b=121/255},sizeLimit={width=200},align="left"})
			end

			--add buttons to scroll pane
			profileMenu:addButtonToScrollpane(profileMenu:getItemByID("profileButton"..iterator),scrollContentBound)

			--callback for the buttons created above. 
			profileMenu:getItemByID("profileButton"..iterator).callbackUp=function() 
				profileMenu:destroy()
				showProfileOptions(presetTable)
			end	
		end
	else
		debugStmt.print("profileSelectionMenu: no user profiles found")
	end

	--callbacks
	profileMenu:getItemByID("exitButton").callbackUp=function()
		soundManager.playButtonClickSound()
		profileMenu:destroy()
		callback()
	end	

	profileMenu:getItemByID("scrollUpButton").callbackUp=function()
		soundManager.playButtonClickSound()
		profileMenu:scrollY(ySeparation,false)
	end

	profileMenu:getItemByID("scrollDownButton").callbackUp=function()
		soundManager.playButtonClickSound()
		profileMenu:scrollY(-ySeparation,false)
	end

	--add a fadeIn effect if indicated in the fn call
	if(shouldFadeIn)then
		profileMenu:fadeIn()  
	end

	--autoscroll the menu to the button of the currently selected ball
	-- profileMenu:scrollToButtonAtIndex(lastSelectedItemIndex,0,25)	
end

-------------------------------

function showProfileOptions(profileTable)
	debugStmt.print("profileSelectionMenu: absolute path of the profile is "..profileTable.absolutePath)

	soundManager.playButtonClickSound()	

	local optionsMenu=menuMaker.newMenu({name="optionsMenu",x=width*0.5-540*0.5,y=height*0.5-400*0.5,masterImageGroup=nil, baseImagePath=assetName.dialogBase,
	baseImageWidth=540,baseImageHeight=400,overlayAlpha=0.5})

	--title
	optionsMenu:addTextDisplay({id="title",xRelative=270,yRelative=50,font=assetName.AMB,fontSize=textResource.fontXL,string="PROFILE OPTIONS",
		colour={r=90/255,g=103/255,b=121/255}, sizeLimit={width=500}})

	local text= 'You selected profile '..'"'..profileTable.name..'"'..'. You can apply the profile or cancel and abort. User-created profiles can also be deleted'
	--text
	optionsMenu:addTextDisplay({id="body",xRelative=270,yRelative=200,font=assetName.AMR,fontSize=textResource.fontS,
			string=""..text,colour={r=132/255,g=82/255,b=82/255},width=500,align="center"})

	--apply btn
	optionsMenu:addButton({id="applyButton",xRelative=120,yRelative=330,width=114,height=65,imageDownPath=nil,
			imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
	optionsMenu:getItemByID("applyButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="APPLY",
		colour={r=90/255,g=103/255,b=121/255}})

	--cancel btn
	optionsMenu:addButton({id="cancelButton",xRelative=426,yRelative=330,width=114,height=65,imageDownPath=nil,
			imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
	optionsMenu:getItemByID("cancelButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="CANCEL",
		colour={r=90/255,g=103/255,b=121/255}})

	--check the profiletable's canDelete flag. This will usually be false for presets and true for user profiles. When true, add a delete option in the middle:
	if(profileTable.canDelete=="true")then
		optionsMenu:addButton({id="deleteButton",xRelative=270,yRelative=330,width=114,height=65,imageDownPath=nil,
			imageUpPath=assetName.greyButton,callbackDown=nil,callbackUp=nil,alphaDown=nil,alphaUp=nil,doesScaleDown=true})
		optionsMenu:getItemByID("deleteButton"):addTextDisplay({xRelative=0,yRelative=-5,font=assetName.AMB,fontSize=textResource.fontM,string="DELETE",
			colour={r=90/255,g=103/255,b=121/255}})

		optionsMenu:getItemByID("deleteButton").callbackUp=function()
																--attempt to delete the profile and show toast based on outcome. 
																local result=os.remove( profileTable.absolutePath )

																soundManager.playButtonClickSound()
																optionsMenu:destroy()
																profileSelectionMenu.makeProfileSelectionMenu(callback,false)
																
																if(result)then
																	toast.showToast("Profile successfully deleted.")
																else
																	toast.showToast("ERROR- Unable to delete profile.")
																end
															end	
	end

	--optionsMenu
	optionsMenu:getItemByID("applyButton").callbackUp=function()
		soundManager.playButtonClickSound()
		optionsMenu:destroy()

		--Start checking all parameters from the profile table and then make calls to the hardwareSettings script to apply them:
		--IMPORTANT- ALL VALUES THAT ARE TAKEN FROM FILE ARE STRINGS. CONVERT TO NUMBER WHERE NEEDED BEFORE PASSING
		hardwareSettings.setTDP(tonumber(profileTable.tdp))--apply tdp

		hardwareSettings.setCPUClock(tonumber(profileTable.cpu))--apply cpu


		if(profileTable.gpu~="DEFAULT")then--apply gpu unless default value was found
			hardwareSettings.setGfxClock(tonumber(profileTable.gpu))
		end

		if(profileTable.fps=="NO LIMIT")then--apply specified fps limit unless NO LIMIT was specified in which case, apply 0
			hardwareSettings.setFPSLimit(0)
		else 
			hardwareSettings.setFPSLimit(tonumber(profileTable.fps))
		end

		callback()
	end	

	optionsMenu:getItemByID("cancelButton").callbackUp=function()
		soundManager.playButtonClickSound()
		optionsMenu:destroy()
		profileSelectionMenu.makeProfileSelectionMenu(callback,false)
	end	
end
-----------------------------

---------HELPERS-------------
--helper function to take in a string value (raw file data) and convert it to JSON. KV pairs have to be organised
--in a very specific manner. See the superLoader.txt file for reference
function stringToKeyValue(str)
    local t = {}
    for line in str:gmatch"[^\n]+" do
        local k, v = line:match"^([^:]+):([^:]+)$"
        if k then -- line is k:v pair?
           t[k] = v
        end
    end
    return t
end
----------------------

function readProfileTableFromFile(path)
	--start reading process for json table in the init file
	local file, errorString = io.open(path, "r" )

	if(file)then
		local contents = file:read( "*a" )
		local tableToReturn={}
		tableToReturn = stringToKeyValue(contents)
	    -- Close the file handle
	    io.close( file )

	    --a little sly trick here: we quietly add an "absolutePath" variable inside the table before returning it. 
	    --Making and fetching paths for preset profiles, user profiles etc on different system is not straightforward and this function is the one place that already has access to this information. 
	    --By adding the absolute path to the table, we can later access the exact path of a profile in case we need to add a feature to delete it or whatnot. 
	    tableToReturn.absolutePath=path

	    return tableToReturn
	end
	return nil
end

---------------
--given a path, this function will PROPERLY identify all profiles whilst ignoring other random files in the path and then add their path into a table, sort the table alphabetically and return
function getAlphabeticalTableOfProfilesFromPath(path)
	local tableOfPaths={}

    for file in lfs.dir(path) do
	    if file ~= "." and file ~= ".." then
	        local filePath = path .. "/" .. file
	        local attr = lfs.attributes(filePath)
	        if attr and attr.mode == "file" then
	        	local presetTable=readProfileTableFromFile(filePath)
	        	if(presetTable.name~=nil)then--it is inside this IF clause that we finally will have data from the preset table which is not a bullshit random file but a proper profile preset. So we start placing buttons here
	        		tableOfPaths[#tableOfPaths+1]=filePath
	        	end
	        end
	    end
	end

	--modified sort function for table.sort that uses lower case conversion before sorting to make alphabetical sorting case-insensitive
	table.sort(tableOfPaths, function(a, b)
	    return string.lower(a) < string.lower(b)
	end)

	return tableOfPaths
end


return profileSelectionMenu