--Function returns a string when supplied with a table. That string contains text representation of all tables and nested tables
function dumpTableToConsole(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dumpTableToConsole(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--WHAT THIS FUNCTION DOES:
--extracts the actual filename without the path from the supplied filename and looks for just this file in a pre-defined path in the DocumentsDirectory
--If the file is not found in this path, it uses the full filename that was supplied (along with the path) and attempts to load up the img from that path in the resource directory. 
--Basically, it allows for images in the doc directory to conveniently and automatically override those in the resource directory. 
--Option parameter at end: for certain in-game assets, attempting to constantly load images from the docs directory can be quite expensive. In these cases, 
--the bypassDocDirectory clause can be raised and image will be loaded directly from res directory
function display.newImg(parent,filename, x, y, bypassDocDirectory)

	--to avoid issues arising from the different range or arguments that the engine accepts for the new Image function, we check 
	--if the second paramater is not of type string, that means the call is not compatiable with our rigid strucutre of passing
	--arguments to this function and we instead pass all arguments into the engine's default function. 
	if(type(filename)~="string")then
		-- debugStmt.print("main: type of filename parameter is "..type(filename)..". Hence, calling newImage function")
		return display.newImage(parent,filename,x,y,bypassDocDirectory)
	end

	local img

	--for certain in-game assets, attempting to constantly load images from the docs directory can be quite expensive. In these cases, 
	--the bypassDocDirectory clause can be raised and image will be loaded directly from res directory
	-- if(not bypassDocDirectory)then
	-- 	local fileNameWithoutPath=""

	-- 	--identify the first forward slash while moving backwards from the end of the full filename and then extract the string after the "/"
	-- 	--That extracted string will be just the name of the actual file along with its extension. 
	-- 	for i=string.len(filename),1,-1 do
	-- 		if(filename:sub(i,i)=="/")then
	-- 			fileNameWithoutPath=filename:sub(i+1)
	-- 			break
	-- 		end
	-- 	end

	-- 	--first try loading the image from the downloads folder in the documents directory
	-- 	img=display.newImage(parent,"downloads/"..fileNameWithoutPath,system.DocumentsDirectory,x,y)
	-- end

	--if the image was not found, check for the image in the resource directory
	if(img==nil)then
		img=display.newImage(parent,filename,x,y, bypassDocDirectory)
	end

	return img
end

------------------------------
--This function will only work to replace calls for display.newtext that use the modern API's tabular system. The data table passed will
--be the same format as Corona's API but can optionally specify a sizeLimit{width=,height=} table. The function will iteratively reduce the sizes of the text
--until they fit within the prescribed dimensions on both axes and it will automatically apply compensation by adding spaces to x, y pos to achieve left, right or center alignment as requested
--RULES:
--1. DO NOT supply corona's native WIDTH parameter if sizeLimit is specified. 
--2. Alignment will not work with sizeLimit for text that is changed during runtime. For such text objects, use Corona's WIDTH parameter instead of sizeLimit and specify the alignment
--3. When a width was supplied in the dataTable with the aim of wrapping, DO NOT constrain the width with sizeLimit. In this case, rely on a height constrain alone. 
function display.newAutoSizeText(data)
	if(data.sizeLimit==nil)then--simply add a new text using the standard API if no sizeLimit specified. 
		return display.newText(data)
	else
		local object=display.newText(data)
		if(data.sizeLimit.width~=nil)then--first handle the width
			while(object.width>data.sizeLimit.width)do
				-- debugStmt.print("main: current width of display object is "..object.width.." required was "..data.sizeLimit.width.." font size is "..data.fontSize)
				display.remove(object)
				object=nil
				data.fontSize=data.fontSize-2--reduce font size
				--if the dataTable contained a width parameter, show a warning as our sizeLimit system cannot work with Solar2D's specification of width and height
				if(data.width~=nil)then
					toast.showToast( "newAutoSizeText", "do not specify width if sizeLimit was specified")
				end
				--add new displ object
				object=display.newText(data)
			end
			--if alignment was specified, use spaces before or after the text until correct alignment w.r.t. specified with is achieved:
			if(data.align~=nil )then
				if(data.align=="left")then
					while(data.sizeLimit.width-object.width>2)do--until the difference of available width and actual width is small enough, append spaces at the end of text to help push it leftward to achieve alignment
						object.text=object.text.." "
					end
				elseif(data.align=="center")then
					object.x=object.x--automatically aligned since text appears to be anchored at centre
				elseif(data.align=="right")then
					while(data.sizeLimit.width-object.width>2)do--until the difference of available width and actual width is small enough, add spaces at the start of text to help push it rightward to achieve alignment
						object.text=" "..object.text
					end
				end
			end
			return object
		end
		if(data.sizeLimit.height~=nil)then--handle the height similar to width but no alignment considerations here..
			while(object.height>data.sizeLimit.height)do
				-- debugStmt.print("main: current height of display object is "..object.height.." required was "..data.sizeLimit.height.." font size is "..data.fontSize)
				display.remove(object)
				object=nil
				data.fontSize=data.fontSize-2
				object=display.newText(data)
			end
			return object
		end
	end
end

-------------------------
--global table that will copy a passed table and return that copy. This is often necessary since tables are all passed by reference in lua
function copyTable(orig)
   local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[copyTable(orig_key)] = copyTable(orig_value)
        end
        setmetatable(copy, copyTable(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

----------------------------

--GLOBAL function that can be called from anywhere in the programme to return a time value in seconds after formatting it as mm:ss
function formatTime(timeInSeconds)
	local minutes=math.floor(timeInSeconds/60)
	local seconds=math.floor(timeInSeconds%60)
	local milliseconds=math.floor((timeInSeconds%60-seconds)*100)

	if minutes<10 then
		minutes="0"..minutes
	end
	if seconds<10 then
		seconds="0"..seconds
	end
	if milliseconds<10 then
		milliseconds="0"..milliseconds
	end
	return minutes..":"..seconds.."."..milliseconds
end

--------------------------
--helper function to format string so that the content can be shrinked. For eg. 10000 will be displayed as 10K. 
function formatNumberString(input)
	local text=""

	--if score is thousand or greater divide by 1000 and append the letter K
	if(input>9999)then
		text=string.format( "%.1f",input/1000).."K"--maximum
	else
		text=input
	end

	return text
end

--------------------------

local composer = require( "composer" )
local deltaTime=require "scripts.helperScripts.deltaTime"
local debugStmt= require "scripts.helperScripts.printDebugStmt"
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local toast=require "scripts.helperScripts.toast"
local menuMaker=require "scripts.menuHelper.menu"
-- local steamManager=require "scripts.externalServices.steamManager"
local screenCompensation=require "scripts.helperScripts.screenCompensation"
local soundManager=require "scripts.soundManager"
-- local crossPromotionPopup=require "scripts.crossPromotionPopup"
local timerService=require "scripts.helperScripts.timerService"

--------------------------

local width=display.contentWidth
local height=display.contentHeight
local makeUpdateMenu

--init prefs 
preferenceHandler.init()
--init soundManager
soundManager.init()
--init app42 

--the text resource needs to be a global table so that scripts with textResources in different languages can be assigned to this table when necessary. 
--To start, the main script will initialise this table to the english language script. A preference can later be chcked below (after Prefs are inited) to revise the table with the user's previosuly selected language.
if(preferenceHandler.get("language")=="russian")then
	textResource=require "scripts.textResources.textResourceRussian"
elseif(preferenceHandler.get("language")=="spanish")then
	textResource=require "scripts.textResources.textResourceSpanish"
elseif(preferenceHandler.get("language")=="chinese")then
	textResource=require "scripts.textResources.textResourceChinese"
else
	textResource=require "scripts.textResources.textResourceEnglish"
end

--Also set the global variable that is used in other scripts (eg, inGameUI) to enable/disable developer-specific debugging fatures.
--NOTE: this boolean, when turned on, will also force turn on printdebugstmt feature regardless of the build environment
isDebugMode=false
levelCount=10
isPlacementModeOn=false--global boolean that would tell if placement mode should be on or off. This is toggled by Q in the gameworld is used for pausing physics when setting up levels, placing objects etc. 

local backButtonTimer=0-- timer to define window of time within which user can press back a second time to exit
local backButtonTimeLimit=3

--remove the top panel
display.setStatusBar( display.HiddenStatusBar )

--multitouch below is turned off by default but can be turned on if the project requires
-- system.activate( "multitouch" )
-- toast.showToast("MAIN: multitouch disabled")

------------------------------

local function update()
	local delta=deltaTime.getDelta()

	-- call sound manager's update
	soundManager.update(delta)

	
	--update back button timer
	if (backButtonTimer>0)then
		backButtonTimer=backButtonTimer+delta
		if(backButtonTimer>backButtonTimeLimit)then
			backButtonTimer=0
		end
	end
end

-------------------------------
function onSystemEvent( event )
   	if(event.type=="applicationSuspend" or event.type=="applicationExit")then
		-- call functions that we need to call on app suspension or exit.

	elseif(event.type=="applicationResume")then
		-- call functions that are needed to be evaluated on resumption of the app. after the suspension
		
		--first cancel all notifications and clear ios badge count
		notifications.cancelNotificationAndResetBadge()

		--hides status and navigation bar in android devices
		if ( system.getInfo("platform") == "android" ) then
		    native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
		end

	elseif(event.type=="applicationStart")then
		-- call functions that are needed to be evaluated on start of the app.



		--hides status and navigation bar in android devices
		if ( system.getInfo("platform") == "android" ) then
		    native.setProperty( "androidSystemUiVisibility", "immersiveSticky" )
		end

		-- composer.gotoScene ("scripts.screens.mainMenuScreen", {params={callingScene="nil"}})
		composer.gotoScene ("scripts.screens.splashScreen", {params={callingScene="nil"}})
	end
end

------------------------------

--funtion to create the update menu that will force the users to update the app to latest version
function makeUpdateMenu()
	local updateMenu=menuMaker.newMenu({name="updateMenu",x=0,y=0})
	
	--add update Menu Base
	
	-- add title text
	
	--add message text
	
	--add update button
	
	-- add callback on updateButton

end

-------------------------
--definte the behaviour of the Android HW back button:
local function backButtonAction(event)
	
	if(event.keyName=="back" and event.phase=="up")then
		debugStmt.print("main:back pressed ")
		if(backButtonTimer==0)then
			toast.showToast(textResource.backButtonExitToast)
			backButtonTimer=0.1 --trigger the timer
		else 
			os.exit(  )
		end
		return true
	end
end

---------------------------

Runtime:addEventListener ( "enterFrame", update)
Runtime:addEventListener( "system", onSystemEvent )
Runtime:addEventListener("key", backButtonAction )