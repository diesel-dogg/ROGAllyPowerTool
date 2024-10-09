local menu={menuDebug=false}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local buttonMaker=require "scripts.menuHelper.button"
local assetName=require "scripts.helperScripts.assetName"
local deltaTime=require "scripts.helperScripts.deltaTime"
local collisionHandler=require "scripts.helperScripts.collisionHandler"
local toast=require "scripts.helperScripts.toast"
local animationService=require "scripts.helperScripts.animationService"
local timerService=require "scripts.helperScripts.timerService"
local animationSystem=require "scripts.helperScripts.animationSystem"

local menu_mt={__index=menu}-- metatable

local myMath={
  abs=math.abs,
  atan2=math.atan2,
  sin=math.sin,
  cos=math.cos,
}

-------------GUIDE ON EXTRA PARAMS---------Note: params marked with * cannot be passed through constructor and must be defined externally.
-- * addTextDisplay({xRelative,yRelative,font, fontSize,string,colour,align,width, Id})-colour is a table containing the rgb values 
--align is a string that indicates the text alignment(center,left or right ), must be passed along with the width
--width is a parameter that signifies the max horizontal length of the text in pixels 
--* addImage(data={imagePath,xRelative,yRelative, id})
--* addAnimation(data={xRelative,yRelative,sheet,sequence,id})
--*setKeyboardSupport(bool) can be set be passed true to show a pointer image for arrow keys navigation. Enter key will be used for selection.
--*addButtonToScrollpane(button,scrollContentBound): pass a button object along with contentBounds for the scrolling region to this function for the button to participate in calls made to scrollX and scrollY
--*scrollX(distanceToScroll) and scrollY(distanceToScroll) functions can be called with a distance to be scrolled. They will respect the sign of the distance and scroll all buttons added through addButtonToScrollpane as requested. 
-------------------------------------------

local menus={}--all menus that are not currently destroyed and were created. 
local menuInFocus--this will be the menu that currently has focus of the touch listener
local width=display.contentWidth
local height=display.contentHeight
------variables specific to keyboard and mouse controls:
local mouseSetupHelper--fwd reference for function that is INTERNALLY called to init the mouse pointer img and then place it based on a set of conditions
local previouslyFocussedMenu--this will keep track of the menu which was previously focussed. Helps in mouse tracking to determine if the new menu has same name as last menu
local isMouseInputMode--a boolean that is used to identify if the user is using mouse to navigate through menus. This will help in deciding if mouse pointer should be adjusted to a button's locatoin automatically or be allowd to follow the actual mouse input
local focusedButtonIndex=1--indicates the index of the current button that is focused by user input. Value is assigned in key and axis listener based on proximity from mouse pointer
local lastButtonPressed--this keeps track of the last button that was acted on. Helps when a menu is changed and mouse needs to be placed on the button with a same name 
--a reference of previous positions of mouse pointer is stored. This is done since the pointer is created and destroyed along with the menu. 
--tracking previous positions helps in keeping the pointer's position undisturbed when navigating between menus.
local pointerPosition={x=0,y=0}
--whenever a new menu is created, a time needs to be used to prevent the keys from becoming immediately active and to force the user to first be able to see the menu
local keyListenerDelayTimer=0--init the timer to 0. Reset each time a new menu is created otherwise.  
local keyListenerDelayTimeLimit=0.3-- in seconds

-------------------------------------------
--touch listener for buttons
local function moveTouch(event)
	if(menuInFocus==nil)then
		return
	end

	--to avoid ridiculous behaviour in buttons that receive their events from here, return when the menuDebug flag of the script is on
	if(menu.menuDebug)then
		return
	end

	function sendEventToButtons()
		--if a touch up was recevied, release the button graphics irrespective of whether they're touched or not
		if(event.phase=="ended")then
			for i=1,#menuInFocus.buttons do
				menuInFocus.buttons[i]:forceGraphicsRelease()
			end
		end

		for i=1, #menuInFocus.buttons do
			--check which is the first button that is touched by the current touch event and also ensure that this button was not hidden as a result of being
			--on a the scrollableButtons table. Only then pass the event and break the loop.
			if(collisionHandler.buttonCollision(event,menuInFocus.buttons[i]) and menuInFocus.buttons[i].isButtonVisible)then
					menuInFocus.buttons[i]:touchEvent(event)
					lastButtonPressed=menuInFocus.buttons[i]-- store a reference for the button that was acted upon
				break
			end
		end
	end
	
	--addressing of the menuInFocus and its buttons can address nil values as the listener responds on a differnt thread and
	--when menus are being created/destroyed, values may change DURING the listener event and nil values will come up
	pcall(sendEventToButtons)
end	

----------------------------
--some variables that assist in this:
local lastDebugObject=nil

--this function only listens for the M key to toggle the debugging flag of the menu script. This function also allows scaling of objects in the menu
--that were last moved. NOTE: This may not work for all objects. 
local function moveKeyDebug(event)
	if(event.phase=="up" and isDebugMode)then
		if(event.descriptor=="m") then--this is a universal key for toggling the mouse-drag debugging of menu objects. See menu helper script
			menu.menuDebug=not menu.menuDebug
			toast.showToast("MENU: mouse-drag debugging is "..tostring(menu.menuDebug)..". Use < > to scale objects")
		end

		if(event.descriptor==".") then--using the > key to scale up the last debug object that was selected and printing its scale
			if(lastDebugObject~=nil)then
				lastDebugObject:scale(1.05,1.05)
				debugStmt.print("menu: x and y scale of  "..lastDebugObject.id.." are "..lastDebugObject.xScale..", "..lastDebugObject.yScale)
			end
		end
		if(event.descriptor==",") then--using the < key to scale don the last debug object that was selected and printing its scale
			if(lastDebugObject~=nil)then
				lastDebugObject:scale(0.95,0.95)
				debugStmt.print("menu: x and y scale of  "..lastDebugObject.id.." are "..lastDebugObject.xScale..", "..lastDebugObject.yScale)
			end
		end
	end
end
-------------------------

--This function is the listner that is added to all textDisplays of a menu, all images/animations and some basic images of buttons
--It uses a special menuDebug flag that is part of this script's table and that can be toggled with M key. Moving around these elements disables 
--all clicks on buttons to avoid confusion and it prints the relative x,y positions of the objects to console. 
-- NOTE: this is just for debugging. Scrolling elements and other button-related features won't work with this. 

local function moveTouchDebug(event)
	if(not menu.menuDebug)then
		return
	end

	--call this function in pcall to avoid crashes
	local function handleTouch()
		if(event.phase=="began")then
			lastDebugObject=nil--reset the last object when touch starts
			lastDebugObject=event.target.owner--store reference to the object first touched so that this is the only object moved unless control is lifted from mouse
		elseif(event.phase=="moved")then

			--when moving the sub-elements of buttons, we'll need to know the relative movement of the lastDebugObject display object
			local dX=event.x-lastDebugObject.x
			local dY=event.y-lastDebugObject.y

			--simply move the lastDebugObject. This will either be a text display, or an image/animation 
			lastDebugObject.x=event.x
			lastDebugObject.y=event.y

			debugStmt.print("menu: RELATIVE x and y of  "..lastDebugObject.id.." are "..lastDebugObject.x-menuInFocus.x..", "..lastDebugObject.y-menuInFocus.y
				.."| Absolute x,y are "..lastDebugObject.x..","..lastDebugObject.y.." | If yComp was used, add to y Coord: "..-getYCompensation()..", If xCompe was used then add to x: "..-getXCompensation())

			--attempt checking for image up/down in buttons and move them
			if(lastDebugObject.imageUp~=nil)then
				lastDebugObject.imageUp.x=lastDebugObject.imageUp.x+dX
				lastDebugObject.imageUp.y=lastDebugObject.imageUp.y+dY
			end
			if(lastDebugObject.imageDown~=nil)then
				lastDebugObject.imageDown.x=lastDebugObject.imageDown.x+dX
				lastDebugObject.imageDown.y=lastDebugObject.imageDown.y+dY
			end

			--buttons might have images, textDisplays etc, move those too
			if(lastDebugObject.textDisplays~=nil)then
				for i=1, #lastDebugObject.textDisplays do
					lastDebugObject.textDisplays[i].x=lastDebugObject.textDisplays[i].x+dX
					lastDebugObject.textDisplays[i].y=lastDebugObject.textDisplays[i].y+dY
				end
			end

			if(lastDebugObject.images~=nil)then
				for i=1, #lastDebugObject.images do
					lastDebugObject.images[i].x=lastDebugObject.images[i].x+dX
					lastDebugObject.images[i].y=lastDebugObject.images[i].y+dY
				end
			end

			--handling the contentBound of buttons
			if(lastDebugObject.contentBounds~=nil)then
				lastDebugObject.contentBounds.xMin=lastDebugObject.contentBounds.xMin+dX
				lastDebugObject.contentBounds.xMax=lastDebugObject.contentBounds.xMax+dX
				lastDebugObject.contentBounds.yMin=lastDebugObject.contentBounds.yMin+dY
				lastDebugObject.contentBounds.yMax=lastDebugObject.contentBounds.yMax+dY
			end
			--handling the optional contentBoundImage of buttons
			if(lastDebugObject.rect~=nil)then
				lastDebugObject.rect.x=lastDebugObject.rect.x+dX
				lastDebugObject.rect.y=lastDebugObject.rect.y+dY
			end
		end
	end

	pcall(handleTouch)
end

----------------------------
--Key listener is used for the situation when the doesSupportKeyboard flag of a menu object is raised. Arrow keys can be used for navigation and enter key to perform button action
local function moveKey(event)
	if(menuInFocus==nil )then
		return
	end
	--if the menu in focus doesn't support keyboard, abort
	if(menuInFocus.doesSupportKeyboard==false )then
		return
	end
	--if the timer that blocks key action on creation of a new menu is still running (i.e. block is needed), return
	if(keyListenerDelayTimer<=keyListenerDelayTimeLimit)then
		return
	end

	local function performKeyActions()
		--whenever a key is pressed, start by determining the closest button index to the current mouse pointer
		local minDist=100000000000
		for i=1,#menuInFocus.buttons do
			local squaredDist=((menuInFocus.buttons[i].y-menuInFocus.pointerImage.y)^2)+((menuInFocus.buttons[i].x-menuInFocus.pointerImage.x)^2)
			if(squaredDist<minDist)then
				focusedButtonIndex=i
				minDist=squaredDist
			end
		end
		if(event.phase=="down")then
			if(event.keyName=="left" or event.keyName=="up" or event.keyName=="leftShoulderButton1") then
				isMouseInputMode=false--if user is using keyboard to navigate through the menus, set mouse inpute mode to false
				--first check if the mouse is already aligned with its nearest button by using collisionHandler and also check if the button in focus is visible. 
				--If it is not, don't change the focusedButtonIndex in order to force an alignment
				if(not collisionHandler.buttonCollision(menuInFocus.pointerImage,menuInFocus.buttons[focusedButtonIndex]) and menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					focusedButtonIndex=focusedButtonIndex
				else
					--use an infinite loop to determine the nearest visible button-- in backward order
					while(true)do
					   	focusedButtonIndex=focusedButtonIndex-1
					   	if(focusedButtonIndex<1)then
							focusedButtonIndex=#menuInFocus.buttons
						end
						--if the button currently in focus is visible break the loop
					   	if(menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					   		break	
					  	end
					end
				end
				--set position of the pointer image and enable make it visible
				menuInFocus.pointerImage.x=menuInFocus.buttons[focusedButtonIndex].x+menuInFocus.buttons[focusedButtonIndex].width*0.25
				menuInFocus.pointerImage.y=menuInFocus.buttons[focusedButtonIndex].y+menuInFocus.buttons[focusedButtonIndex].height*0.25
				menuInFocus.pointerImage.alpha=1
			elseif(event.keyName=="right" or event.keyName=="down" or event.keyName=="rightShoulderButton1") then
				isMouseInputMode=false--set the mouseInput mode to false
				--first check if the mouse is already aligned with its nearest button by using collisionHandler and also check if the button in focus is visible. 
				--If it is not, don't change the focusedButtonIndex in order to force an alignment
				if(not collisionHandler.buttonCollision(menuInFocus.pointerImage,menuInFocus.buttons[focusedButtonIndex]) and menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					focusedButtonIndex=focusedButtonIndex
				else
					--use an infinite loop to determine the nearest visible button-- in forward order
					while(true)do
					   	focusedButtonIndex=focusedButtonIndex+1
					   	if(focusedButtonIndex>#menuInFocus.buttons)then
					   		focusedButtonIndex=1
					   	end
					   	--if the button currently in focus is visible break the loop
					   	if(menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					   		break	
					   	end
					end
				end
				menuInFocus.pointerImage.x=menuInFocus.buttons[focusedButtonIndex].x+menuInFocus.buttons[focusedButtonIndex].width*0.25
				menuInFocus.pointerImage.y=menuInFocus.buttons[focusedButtonIndex].y+menuInFocus.buttons[focusedButtonIndex].height*0.25
				menuInFocus.pointerImage.alpha=1
			--check for a list of keys that are generally used in keyboards/controllers to perform action pertaining to the button selected.   
			elseif(event.keyName=="enter" or event.keyName=="buttonX" or event.keyName=="buttonA" or event.keyName=="button3" or 
				event.keyName=="buttonStart") then
				--first check if the mouse is already aligned with the button in focus and then check if the button is visible, if yes perform action
				if(collisionHandler.buttonCollision(menuInFocus.pointerImage,menuInFocus.buttons[focusedButtonIndex]) and menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					event.phase="began"--hack the event phase before calling the touchEvent  on the down stroke of the enter key. This is because the button script recognises "began" phase
					lastButtonPressed=menuInFocus.buttons[focusedButtonIndex]--set the reference for the last button pressed, 
					menuInFocus.buttons[focusedButtonIndex]:touchEvent(event)
				end
			end
		elseif(event.phase=="up")then
			if(event.keyName=="enter" or event.keyName=="buttonX" or event.keyName=="buttonA" or event.keyName=="button3" or event.keyName=="buttonStart")then
				--first check if the mouse is already aligned with the button in focus and then check if the button is visible, if yes perform action
				if(collisionHandler.buttonCollision(menuInFocus.pointerImage,menuInFocus.buttons[focusedButtonIndex]) and menuInFocus.buttons[focusedButtonIndex].isButtonVisible)then
					event.phase="ended"--hack the event phase before calling the forceGraphicsRelease on the release of the enter key. This is because the button script recognises "ended" phase
					lastButtonPressed=menuInFocus.buttons[focusedButtonIndex]--set the reference for the last button pressed
					menuInFocus.buttons[focusedButtonIndex]:touchEvent(event)
					menuInFocus.buttons[focusedButtonIndex]:forceGraphicsRelease()
				else--if the up event detected is outside the current button call force release graphics 
					menuInFocus.buttons[focusedButtonIndex]:forceGraphicsRelease()
				end
			end
		end
	end

	--addressing of the menuInFocus and its buttons can address nil values as the listener responds on a differnt thread and
	--when menus are being created/destroyed, values may change DURING the listener event and nil values will come up
	pcall(performKeyActions)
end

-----------------------------
local currentAxisLocation={x=0, y=0}
--joystick movement is tracked by the moveAxis listener if the doesSupportKeyboard bool is activated. Joystick keys can be used for navigation between buttons
local function moveAxis(event)
	if(menuInFocus==nil )then
		return
	end
	--if the menu in focus doesn't support keyboard, abort
	if(menuInFocus.doesSupportKeyboard==false )then
		return
	end
	--Firstly, check if the position of controller is outside the deadzone, otherwise bring the pointer to a halt.
	if(event.normalizedValue>0.5 or event.normalizedValue<-0.5)then
		if(event.axis.type=="leftX" or event.axis.type=="x") then
			currentAxisLocation.x=event.normalizedValue
			--if user is using controller to navigate through the menus, set mouse inpute mode to true. NOTE: Some controls tend to fire axis events even if the user
			--is not moving the joystick. To prevent it from affecting the pointer system, set isMouseInputMode only when a relevant event is detected.  
			isMouseInputMode=true
		elseif(event.axis.type=="leftY" or event.axis.type=="y") then
			currentAxisLocation.y=event.normalizedValue	
			isMouseInputMode=true
		end
	else
		--if the movement is on x axis, set the x variable of axis location
		if(event.axis.type=="leftX" or event.axis.type=="x")then
			currentAxisLocation.x=0
		--if the movement is on y axis, set the y variable of axis location
		elseif(event.axis.type=="leftY" or event.axis.type=="y")then
			currentAxisLocation.y=0
		end
	end
end
-----------------------------
--mouse movement is only tracked if the doesSupportKeyboard bool is activated. Moving the mouse over a button will override the actions performed using keyboard and will make the pointer follow the mouse cursor
local function moveMouse(event)
	if(menuInFocus==nil )then
		return
	end
	--set mouse input mode to true if the mouse is moved. For menus like controls menu in GW, the keyboard support is disabled and a duplicate pointer image is used instead.
	--Hence this rule is not aplicable for menus that don't have keyboard support
	if(menuInFocus.doesSupportKeyboard)then
		isMouseInputMode=true
		--make the pointer image follow the mouse as a mouse cursor would do
		menuInFocus.pointerImage.x=event.x
		menuInFocus.pointerImage.y=event.y
	end
end

-----------------------------
local function update()		
	dt=deltaTime.getDelta()
    local function updateMenuInFocus()
    	--update the alpha value for fadeIn if alpha was <1
    	if (menuInFocus.imageGroup.alpha<1) then
    		menuInFocus.imageGroup.alpha=menuInFocus.imageGroup.alpha+(4*dt)
    	end
    end

    local function updateJoystickMouse()
	    --compute angle that the current axis location makes with the origin(0,0) to determine the angle of movement and move the mouse pointer image
	    local angle=myMath.atan2(currentAxisLocation.y-0, currentAxisLocation.x-0)
	    local mouseV=700
	    --to make the speed of mouse proportional to the axes' tilt, multiply the magnitude of current axis location 
	    local mouseVx=myMath.abs(currentAxisLocation.x)*mouseV*myMath.cos(angle)
	    local mouseVy=myMath.abs(currentAxisLocation.y)*mouseV*myMath.sin(angle)
	    --if the analog stick was restored back to 0, force the x and y components of mouse velocity to 0
	    if(currentAxisLocation.x==0 and currentAxisLocation.y==0)then
	    	mouseVx=0
	    	mouseVy=0
	    end
	    --compute the leftmost and rightmost points on the screen from 0,0 of the content area 
	    local leftEdge=-(display.pixelWidth*0.5-width*0.25)
	    local rightEdge=display.pixelWidth*0.5+width*0.75
	    --make sure the pointer doesn't move out of the screen, confine the pointer's movement within the bounds of the screen
	    if(menuInFocus.pointerImage.x+mouseVx*dt<leftEdge or menuInFocus.pointerImage.x+mouseVx*dt>rightEdge or
	    menuInFocus.pointerImage.y+mouseVy*dt<0 or menuInFocus.pointerImage.y+mouseVy*dt>height)then
			return
		end
	    --add distances along x and y to the pointer image owned by the current menu based on velocity components computed above
	    menuInFocus.pointerImage.x=menuInFocus.pointerImage.x+mouseVx*dt
	    menuInFocus.pointerImage.y=menuInFocus.pointerImage.y+mouseVy*dt
	end
	--update the keyListenerDelayTimer only if it is less the limiting value
	if(keyListenerDelayTimer<=keyListenerDelayTimeLimit)then
		keyListenerDelayTimer=keyListenerDelayTimer+dt
	end

    pcall(updateMenuInFocus)
    pcall(updateJoystickMouse)
end	

----------Constructor--------
--NOTE that the width and height of base image are passed to the function and its compulsory. This is to ensure that the placement and dimensions of the base image
--is precise even in devices of lower resolutions.
--data table structure -> {name=,x=,y=,masterImageGroup=, baseImagePath=,baseImageWidth=,baseImageHeight=,overlayAlpha=}
function menu.newMenu(data)
	local newMenu={
		name=data.name,
		x=data.x,
		y=data.y,
		buttons={},
		textDisplays={},
		images={},
		doesSupportKeyboard=false,-- disable keyboard support as default. This is an OPTIONAL value to be set externally only
		scrollableButtons={},--table that can only contain objects of button type. Function later in the script will facilitate scrolling of table
		scrollContentBound={}--this is the table of the scrollPane that will be used for culling effect of the scrollableButtons. It should be passed from the addButtonToScrollpane function
	}

	--create a sub group for self and then add to the supplied master group
	newMenu.imageGroup=display.newGroup()
	
	if(data.masterImageGroup~=nil)then
		data.masterImageGroup:insert(newMenu.imageGroup)
	end

	--if a value for overlayAlpha was provided, use that and create a dark overlay underneath other menu items
	if(data.overlayAlpha)then
		local overlay=display.newRect(newMenu.imageGroup,width*0.5,height*0.5,width*2,height*2)
		
		overlay:setFillColor(0,0,0,data.overlayAlpha)
	end

	--draw the base image only when all 3 of the variables are passed.
	if(data.baseImagePath~=nil and data.baseImageWidth~=nil and data.baseImageHeight~=nil)then
		newMenu.baseImage=display.newImg(newMenu.imageGroup,data.baseImagePath)
		newMenu.baseImage.x=newMenu.x+data.baseImageWidth*0.5
		newMenu.baseImage.y=newMenu.y+data.baseImageHeight*0.5
		newMenu.baseImage.width=data.baseImageWidth
		newMenu.baseImage.height=data.baseImageHeight
	end

	--by default, a newly created menu should have touch focus. 
	--NOTE: This is done after a few seconds of creation of menu so that buttons and actions through listeners are not immediately available to avoid mixups with previous menus
	timerService.addTimer(100,function()
								menuInFocus=newMenu
							  end, nil, true)

	--reset the keyListenerDelayTimer and set the time limit
	keyListenerDelayTimer=0

	--add the newly created menu to the list of menus currently available
	menus[#menus]=newMenu

	return setmetatable(newMenu,menu_mt)
end

--------------------------------------
--pass in a table accoridng to previously given guidelines to add a text display relative to the menu
--data table structure --> {id,xRelative=,yRelative=,font=,fontSize=,string=,color=,align=,width=}
function menu:addTextDisplay(data)
	local textParams = 
		{
			parent=self.imageGroup,
		    text = data.string,     
		    x = self.x+data.xRelative,
		    y = self.y+data.yRelative,
		    width = data.width,
		    font = data.font,   
		    fontSize = data.fontSize,
		    align = data.align, -- Alignment parameter, works only when the width is specified
		    sizeLimit=data.sizeLimit-- see main script's newAutoSizeText fn
		}
	self.textDisplays[#self.textDisplays+1]=display.newAutoSizeText(textParams)--this function is defined in main

	--set id so that this textDisplay obejct can be fetched externally by id for updation etc
	self.textDisplays[#self.textDisplays].id=data.id

	--set the colour of the text 
	self.textDisplays[#self.textDisplays]:setFillColor(data.colour.r,data.colour.g,data.colour.b)

	-- add the debug movement listener to allow for this text display to be moved
	self.textDisplays[#self.textDisplays]:addEventListener( "touch", moveTouchDebug )
	--define this text as its own owner. This convention needs to be maintained mainly for buttons later on
	self.textDisplays[#self.textDisplays].owner=self.textDisplays[#self.textDisplays]
end

--------------------------------------
--pass in a table accoridng to previously given guidelines to add images relative to the menu
--data table structure -> {id=,imagePath=,xRelative=,yRelative=}
function menu:addImage(data)
	self.images[#self.images+1]=display.newImg( self.imageGroup,data.imagePath,self.x+data.xRelative,self.y+data.yRelative)

	--set id so that this image obejct can be fetched externally by id for updation etc
	self.images[#self.images].id=data.id

	--add the debug movement listener to allow for this text display to be moved
	self.images[#self.images]:addEventListener( "touch", moveTouchDebug )
	--define this image as its own owner. This convention needs to be maintained mainly for buttons later on
	self.images[#self.images].owner=self.images[#self.images]
end

--------------------------------------
--pass data table as per guidelines mentioned at top of script to add animations to the menus
--data table structure -> {id=,xRelative=,yRelative=, sheet=,sequence=}
--alternative dataTable structure for using multisheet animations ->See the constructor of the AnimationSystem script. Everything that is accepted there is also accepted here EXCEPT GROUP
function menu:addAnimation(data)
	--use standard approach to make animations when sequence and sheet are supplied otherwise look for params to make multisheet anim
	if(data.sheet~=nil and data.sequence~=nil)then
		--for menus and buttons avoid the use of animation service as in states like gameLose/gameWin, the animation service won't update
		self.images[#self.images+1]=display.newSprite(self.imageGroup,data.sheet,data.sequence)
	-- elseif(data.path~=nil and data.frameWidth~=nil and data.frameHeight~=nil and data.timePerFrame~=nil)then
	-- 	self.images[#self.images+1]=animationService.newMultiSheetAnimation(self.imageGroup,data.path,data.frameWidth,data.frameHeight,data.timePerFrame,true,data.sheetWidth, data.sheetHeight)--notice how true is passed in for isExemptFromService since this is a UI element and likely exempted
	elseif(data.frameCount~=nil)then--this is for the new experimental animationSystem. 
		self.images[#self.images+1]=animationSystem.new({group=self.imageGroup,path=data.path,timePerFrame=data.timePerFrame,playStyle=data.playStyle,x=0,y=0,sequences=data.sequences,frameWidth=data.frameWidth,frameHeight=data.frameHeight,frameCount=data.frameCount,imageSheetCount=data.imageSheetCount})
	end

	--set the position of animation
	self.images[#self.images].x=self.x+data.xRelative
	self.images[#self.images].y=self.y+data.yRelative

	--set id so that this animation obejct can be fetched externally by id for updation etc
	self.images[#self.images].id=data.id
	--play the animation
	self.images[#self.images]:play()

	 -- add the debug movement listener to allow for this text display to be moved
	self.images[#self.images]:addEventListener( "touch", moveTouchDebug )
	--define this image as its own owner. This convention needs to be maintained mainly for buttons later on
	self.images[#self.images].owner=self.images[#self.images]
end

--------------------------------------
--pass data table as per guidelines mentioned at top of script to add buttons to the menus(uses button helper script)
--data table structure -> {id=,xRelative=,yRelative=, width=,height=,imageDownPath=,imageUpPath=callbackDown=,callbackUp=,alphaDown=,alphaUp=,doesScaleDown=,doesGlow=,activatedImagePath=}
function menu:addButton(data)
	
	self.buttons[#self.buttons+1]=buttonMaker.newButton(data.id,self.x+data.xRelative,self.y+data.yRelative,data.width,data.height,self.imageGroup, data.imageDownPath, data.imageUpPath, 
		data.callbackDown, data.callbackUp,data.alphaDown, data.alphaUp,data.doesScaleDown, data.doesGlow,data.activatedImagePath)

	--for allowing buttons to be moveable during debug, try adding a listener to either their up or down image assuming that any serious button in a menu
	--will have at least one of these two.
	local button=self.buttons[#self.buttons]

	if(button.imageUp~=nil)then
		button.imageUp:addEventListener( "touch", moveTouchDebug )
		button.imageUp.owner=button
	elseif(button.imageDown~=nil)then
		button.imageDown:addEventListener( "touch", moveTouchDebug )
		button.imageDown.owner=button
	end
end

---------------------------------------
local count=0
--For guidelines, see top of script. The forceSkipBoundCheck function is only to be used when called by the scrollToButtonAtIndex fn. It serves to
--skip checking if a button is already present in the contentBound of the scrollableArea and is used when trying to autoscroll to a button index. It must not be called externally
function menu:scrollY(distanceToScroll, forceSkipBoundCheck)
	--first check if the first button in the list is visible on the scrollPane. If it is and the user requested scrolling in the +ve y direction, do nothing
	if(self.scrollableButtons[1].contentBounds.yMin>self.scrollContentBound.yMin and distanceToScroll>0 and forceSkipBoundCheck==false)then
		return
	end
	--simlilarly, if the last button is visible and scrolling was requested in the -ve y direction, reject
	if(self.scrollableButtons[#self.scrollableButtons].contentBounds.yMax<self.scrollContentBound.yMax and distanceToScroll<0 and forceSkipBoundCheck==false)then
		return
	end

	--if scrolling request is deemed valid and code arrives here, Scroll!!
	for i=1, #self.scrollableButtons do
		self.scrollableButtons[i]:scrollY(distanceToScroll,self.scrollContentBound)
	end
end

---------------------------------------
--For guidelines, see top of script. The forceSkipBoundCheck function is only to be used when called by the scrollToButtonAtIndex fn. It serves to
--skip checking if a button is already present in the contentBound of the scrollableArea and is used when trying to autoscroll to a button index. It must not be called externally
function menu:scrollX(distanceToScroll, forceSkipBoundCheck)
	--first check if the first button in the list is visible on the scrollPane. If it is and the user requested scrolling in the +ve x direction, do nothing
	if(self.scrollableButtons[1].contentBounds.xMin>self.scrollContentBound.xMin and distanceToScroll>0 and forceSkipBoundCheck==false)then
		return
	end
	--simlilarly, if the last button is visible and scrolling was requested in the -ve x direction, reject
	if(self.scrollableButtons[#self.scrollableButtons].contentBounds.xMax<self.scrollContentBound.xMax and distanceToScroll<0 and forceSkipBoundCheck==false)then
		return
	end

	--if scrolling request is deemed valid and code arrives here, Scroll!!
	for i=1, #self.scrollableButtons do
		self.scrollableButtons[i]:scrollX(distanceToScroll,self.scrollContentBound)
	end
end

---------------------------------------
--pass the index of a button to this function and the menu will automatically scroll until this button is visible.
--The padding (yPadding and xPadding) is the distance to be allowed on all edges of the scrollpane to ensure a neat setup of buttons. The sytem will ensure that the button at given index has this minimum padding from the edges of the menu's contentBounds
--NOTE: this must only be done after all objects are added to the menu and the buttons are all present in the table of scrollableButtons
--NOTE2: It is best to use a mac device and take a screenshot of the menu with button debugging turned on to get a proper idea for contentBound coordinates, xPadding, yPadding etc
function menu:scrollToButtonAtIndex(index, xPadding, yPadding)
	--start be checking the centre of the button at given index to determine where its default position is:
	local button=self.scrollableButtons[index]

	while(button.contentBounds.yMin<self.scrollContentBound.yMin+yPadding)do
		self:scrollY(1, true)
	end

	while(button.contentBounds.yMax>self.scrollContentBound.yMax-yPadding)do
		self:scrollY(-1, true)
	end

	while(button.contentBounds.xMin<self.scrollContentBound.xMin+xPadding)do
		self:scrollX(1, true)
	end

	while(button.contentBounds.xMax>self.scrollContentBound.xMax-xPadding)do
		self:scrollX(-1, true)
	end
end

------------------------------------
--NOTE: if a button (preexisting) has to be added to the scrollPane, DO NOT do it directly but only through this function.
--Also note that this function should only add in a button on which all necessary actions such as addition of text and graphic have been performed. 
function menu:addButtonToScrollpane(button,scrollContentBound)
	self.scrollContentBound=scrollContentBound

	self.scrollableButtons[#self.scrollableButtons+1]=button

	--force a 0 scroll on x and y axis so that the button scripts can perform the basic visibility related work for the graphics of the button that was just added
	--otherwise this button will be visible even if it is outside the scrollpane
	self.scrollableButtons[#self.scrollableButtons]:scrollY(0,scrollContentBound)
	self.scrollableButtons[#self.scrollableButtons]:scrollX(0,scrollContentBound)
end

---------------------------------------
function menu:getItemByID(id)
	--check if button matches id
	for i=1, #self.buttons do
		if(self.buttons[i].id==id)then
			return self.buttons[i]
		end
	end

	--check if text matches id
	for i=1, #self.textDisplays do
		if(self.textDisplays[i].id==id)then
			return self.textDisplays[i]
		end
	end

	--check if image matches id
	for i=1, #self.images do
		if(self.images[i].id==id)then
			return self.images[i]
		end
	end
	return nil
end

----------------------------------------
--call this function externally to toggle the support for keyboard access on this menu object. DO NOT handle the doesSupportKeyboard boolean directly
--NOTE: this function assumes that all the buttons pertaining to the menu(in focus) have already been created. Hence it must be called at the end.
function menu:setKeyboardSupport(doesSupportKeyboard)
	self.doesSupportKeyboard=doesSupportKeyboard
	mouseSetupHelper(self)
end
--------------------------------------
-- This is a local helper function that is called from the setKeyboardSupport function. Note that if keyboard support is enable for a menu, mouse support is automatically added. 
-- Rule1: if the new menu doesn't have the same name as previous menu and the last input was made using a mouse, the pointer is placed where it was last placed in the previous menu
-- Rule2: if the new menu doesn't have the same name as previous menu but mouse was NOT used as the input device for last menu, the pointer is placed at button index 1 in new menu
-- Rule3: if the new menu has the same name as the previous menu, the system will look for a button with the same name as the last button pressed in previous menu and place the pointer there. 
function mouseSetupHelper(self)
	--start by creating an image for the mouse pointer
	self.pointerImage=display.newImg(assetName.pointer,pointerPosition.x,pointerPosition.y)--NOTE- pointer should be at the top most layer in z-order, so no group is assigned
	self.pointerImage.width=100
	self.pointerImage.height=100
	--bring the pointer image on the first button of the menu, if the menu created is different from the previous one or the first menu of the game
	--it is also checked if the user had last used the mouse or not. If the last input was from a mouse, do not set the pointerImage to the first button of the menu
	if((previouslyFocussedMenu==nil or previouslyFocussedMenu.name~=self.name) and not isMouseInputMode)then
		self.pointerImage.x=self.buttons[1].x+self.buttons[1].width*0.25
		self.pointerImage.y=self.buttons[1].y+self.buttons[1].height*0.25
	end
	--if the previously focused menu is the same as the current menu's name, look at the reference for the last buttont that was clicked on the previous menu
	--and set the mouse pointer to that button. This is necessary to maintain coherence in scenarious where new menus are created for a scrolling effect or in the case of level-cards etc.
	if(previouslyFocussedMenu~=nil and previouslyFocussedMenu.name==self.name and not isMouseInputMode)then
		--search through all the buttons of the current menu to get the button that was last selected in the previouslyFocusedMenu.
		for i=1, #self.buttons do
			if(lastButtonPressed.id==self.buttons[i].id)then--place the pointer at the location of this button and break the loop
				self.pointerImage.x=self.buttons[i].x+self.buttons[i].width*0.25
				self.pointerImage.y=self.buttons[i].y+self.buttons[i].height*0.25
				break
			end
		end
	end
end

----------------------------------------
--function that returns the menu currently in focus
function menu.getMenuInFocus()
	return menuInFocus
end

---------------------------------------
--this is a function that can be called to set the current menu in focus to nil so that listeners will stop functoining. Can be used when input is to be disabled for a few moments while retaining graphics
function menu.setMenuInFocusToNil()
	menuInFocus=nil
end
----------------------------------------
--call this function to fade the menu in. This can technically be called at any time but should be done as soon as all buttons, texts are added
--WARNING: The fading seems to work correctly even for buttons that rely on changing alpha values but it is not advised to use this feature in such menus
--NOTE: option of setting fadeTime was removed since lua cannot handle small floating points correctly. Fixed approx speed is used.
function menu:fadeIn()
	self.imageGroup.alpha=0
end

-------------------------------------
--remove all display objects associated with menu, remove focus from this menu if it was in focus and then set to nil
function menu:destroy()
	if(menuInFocus==self)then	
		previouslyFocussedMenu=menuInFocus	
		menuInFocus=nil
	end
	--update the values of pointer positions to keep track of the pointer's positions to determine the placement of next menu's pointer
	if(self.doesSupportKeyboard)then--check if pointer is enabled
		pointerPosition.x=self.pointerImage.x
		pointerPosition.y=self.pointerImage.y
		self.pointerImage:removeSelf()
	end
	self.imageGroup:removeSelf()
	self=nil
end
----------------------------------------
--add a universal action listener for menus as well as frame listener to update menus independently
Runtime:addEventListener ( "touch", moveTouch)
Runtime:addEventListener ( "enterFrame", update)
Runtime:addEventListener("key", moveKey )
Runtime:addEventListener("key", moveKeyDebug )
Runtime:addEventListener("axis", moveAxis )
Runtime:addEventListener("mouse", moveMouse)
----------------------------------------
return menu