local button={}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local toast=require "scripts.helperScripts.toast"
local animationService=require "scripts.helperScripts.animationService"
local animationSystem=require "scripts.helperScripts.animationSystem"
local button_mt={__index=button}-- metatable

-------------GUIDE ON EXTRA PARAMS---------Note: params marked with * cannot be passed through constructor and must be defined externally.
-- alphaUp, alphaDown-- setting these values will mean that only "up" image will be used along with corresponding alpha values
--if the button is to be scaled down on press, then imageDown cannot be used
-- * addTextDisplay({xRelative,yRelative,font, fontSize, string, colour,align,width})-colour is a table containing the rgb values 
     --align is a string that indicates the text alignment(center,left or right ), must be passed along with the width
	 --width is a parameter that signifies the max horizontal length of the text in pixels 
--* addImage(data={imagePath,xRelative,yRelative, id})
--* addAnimation(data={xRelative,yRelative,sheet,sequence,id})	
--*activate() and deactivate () are only valid for buttons that have an activatedImagePath. Things like radio buttons can be built this way and these functions can turn on/off their sprite that indicates their state
--activatedImagePath can be provided for buttons like radio buttons. This image's alpha will be zero by default and it can be turned on/ off by using
	-- the activate/ deactivate functions of this script. Image sprite needs to be same size and alignment to the button's base.
--NOTE: the scrollX and scrollY fns must not be called directly but only through the menu. See addButtonToScrollpane in Menu script
-------------------------------------------

-- imageUpPath is a required parameter except for blank buttons(are not visible & have no effects). AlphaDown and up can be specified for buttons that change alpha. 
--doesScaleDown will darken and shrink button on touch and doesGlow will add a bright, flat glow
-- NOTE: certain features when available simultaneously can cause undesired behaviour
function button.newButton(id,x,y,width,height,imageGroup, imageDownPath, imageUpPath, callbackDown, callbackUp, alphaDown, alphaUp, doesScaleDown, doesGlow, activatedImagePath)
	local newButton={
		id=id,
		x=x,
		y=y,
		width=width,
		height=height,
		imageGroup=imageGroup,
		contentBounds={},
		callbackDown=callbackDown,
		callbackUp=callbackUp,
		alphaDown=alphaDown,
		alphaUp=alphaUp,
		doesScaleDown=doesScaleDown,
		doesGlow=doesGlow,
		textDisplays={},
		images={},
		isButtonVisible=true,--this is used when a button is being scrolled and needs to be made unresponsive to touch if it is out of bounds
		lastActivatedState=false,--for buttons like radio buttons that can be activated/ deactivated, a record of their previous state of activation is needed so that the activation indicator image can be properly turned off and back if the button needs to scroll
	}

	--fetch images based on path and group supplied
	if(imageUpPath~=nil)then
		newButton.imageUp=display.newImg(imageGroup,imageUpPath,x,y)
	end
	if(imageDownPath~=nil)then
		newButton.imageDown=display.newImg(imageGroup,imageDownPath,x,y)
	end
	--if activatedImagePath is present, add that image to the button's table and set alpha to 0 as default 
	if(activatedImagePath~=nil)then
		newButton.activatedImage=display.newImg(imageGroup,activatedImagePath,x,y)
		newButton.activatedImage.alpha=0
	end

	--if the button is able to scale down on touch down, add a dark overlay image that will be used to cover it when it shrinks to darken it
	if(newButton.doesScaleDown)then
		newButton.darkOverlay=display.newRect(imageGroup,x,y,newButton.imageUp.width,newButton.imageUp.height)
		--set default colour. notice how alpha is not 0 in the decleration but set to 0 later. The alpha that's set here will be the limiting value which is achieved on setting a=1
		newButton.darkOverlay:setFillColor( 0,0,0,0.3 )
		newButton.darkOverlay.alpha=0
	end

	--if the button is flat-styled and glows in white on touch, add the white panel and set alpha to 0 as default
	if(newButton.doesGlow)then
		newButton.lightOverlay=display.newRect(imageGroup,x,y,newButton.imageUp.width,newButton.imageUp.height)
		newButton.lightOverlay:setFillColor( 1,1,1,0.3 )
		newButton.lightOverlay.alpha=0
	end

	--default image is up:
	if(imageDownPath~=nil)then
		newButton.imageDown.alpha=0
	end
	--in case of a blank button imageUpPath is nil
	if(imageUpPath~=nil)then
		newButton.imageUp.alpha=1
	end

	--default alpha is up:
	if(alphaUp~=nil)then
		newButton.imageUp.alpha=newButton.alphaUp
	end

	--set the bounds of the button
	newButton.contentBounds.xMin=newButton.x-newButton.width*0.5
	newButton.contentBounds.xMax=newButton.x+newButton.width*0.5
	newButton.contentBounds.yMin=newButton.y-newButton.height*0.5
	newButton.contentBounds.yMax=newButton.y+newButton.height*0.5
		
	--debug display for the button(only for debug)
	-- newButton.rect=display.newRect(imageGroup,x,y,width,height)
	-- newButton.rect:setFillColor(0,0,0,0)
	-- newButton.rect.strokeWidth=2
	-- newButton.rect:setStrokeColor(0,0,2)

	return setmetatable(newButton,button_mt)
end
----------------------------------------
--pass in a table accoridng to previously given guidelines to add a text display relative to the button
--data table structure --> {id,xRelative=,yRelative=,font=,fontSize=,string=,color=,align=,width=}
function button:addTextDisplay(data)
	local textParams = 
		{
			parent=self.imageGroup,
		    text = data.string,     
		    x = self.x+data.xRelative,
		    y = self.y+data.yRelative,
		    width = data.width,--for width take the length of the longest possible text
		    font = data.font,   
		    fontSize = data.fontSize,
		    align = data.align,  -- Alignment parameter, works only when the width is specified
		    sizeLimit=data.sizeLimit-- see main script's newAutoSizeText fn
		}
	self.textDisplays[#self.textDisplays+1]=display.newAutoSizeText( textParams)-- see main script's newAutoSizeText fn

	--set id so that this textDisplay obejct can be fetched externall by id for updation etc
	self.textDisplays[#self.textDisplays].id=data.id

	--set the colour of the text 
	self.textDisplays[#self.textDisplays]:setFillColor(data.colour.r,data.colour.g,data.colour.b)
end

--------------------------------------
--pass in a table accoridng to previously given guidelines to add a images relative to the button
--data table structure -> {id=,imagePath=,xRelative=,yRelative=}
function button:addImage(data)
	self.images[#self.images+1]=display.newImg( self.imageGroup,data.imagePath,self.x+data.xRelative,self.y+data.yRelative)

	--set id 
	self.images[#self.images].id=data.id
end

--------------------------------------
--pass data table as per guidelines mentioned at top of script
--data table structure -> {id=, xRelative=,yRelative=, sheet=,sequence=}
--alternative dataTable structure for using multisheet animations ->{id=, xRelative=,yRelative=, path=, frameWidth,= frameHeight=, timePerFrame=, sheetWidth (optional)=, sheetHeight(optional)=}
function button:addAnimation(data)

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

	--play the animation
	self.images[#self.images]:play()

	--set id 
	self.images[#self.images].id=data.id
end

----------------------------------------
--Call this function to turn on the alpha of the activatedImage if it was present
function button:activate()
	if (self.activatedImage~=nil)then
		self.activatedImage.alpha=1
		self.lastActivatedState=true
	end
end

----------------------------------------
--Call this function to turn off the alpha of the activatedImage if it was present
function button:deactivate()
	if (self.activatedImage~=nil)then
		self.activatedImage.alpha=0
		self.lastActivatedState=false
	end
end

---------------------------------------

--Call this function with the distance (+ or -) to be scrolled by this button. The scrollContentBound is structured like all other content bounds
-- and indicates the limit of the scrollpane. If the button's centre exceeds this limit, the button's graphics will not be rendered
--NOTE the scrollY and scrollX functions must never be called direction on a single button but through the menu scripts scroll functions. 
function button:scrollY(distanceToScroll,scrollContentBound)

	--move the contentBounds of the button
	self.contentBounds.yMin=self.contentBounds.yMin+distanceToScroll
	self.contentBounds.yMax=self.contentBounds.yMax+distanceToScroll

	self.y=self.y+distanceToScroll

	--check if the button needs to be still visible in the scrollable area. Observe that visiblity has to be checked for X and Y bounds each time to avoid conflicts. 
	if(self.contentBounds.yMin<scrollContentBound.yMin or self.contentBounds.yMax>scrollContentBound.yMax or
		self.contentBounds.xMin<scrollContentBound.xMin or self.contentBounds.xMax>scrollContentBound.xMax)then
		self.isButtonVisible=false
	else
		self.isButtonVisible=true
	end

	--check if any of the optional/ required images are not nil and first scroll them
	if(self.imageUp~=nil)then
		self.imageUp.y=self.imageUp.y+distanceToScroll
		if(not self.isButtonVisible)then--disable the image up graphic 
			self.imageUp.alpha=0
		else--when the button becomes visible, force the image to up
			self.imageUp.alpha=1
		end
	end
	if(self.imageDown~=nil)then
		self.imageDown.y=self.imageDown.y+distanceToScroll
		--disable the image down graphic regardless of whether button is visible 
		self.imageDown.alpha=0
	end
	if(self.activatedImage~=nil)then
		self.activatedImage.y=self.activatedImage.y+distanceToScroll
		
		if(not self.isButtonVisible)then--disable the activated image graphic 
			self.activatedImage.alpha=0
		else--when the button becomes visible, turn on the activation marker based on the lastActivationState
			if(self.lastActivatedState)then
				self.activatedImage.alpha=1
			else
				self.activatedImage.alpha=0
			end
		end
	end
	if(self.darkOverlay~=nil)then
		self.darkOverlay.y=self.darkOverlay.y+distanceToScroll
		--disable the dark overlay graphic regardless of whether button is visible 
		self.darkOverlay.alpha=0
	end
	if(self.lightOverlay~=nil)then
		--disable the light overlay graphic regardless of whether button is visible 
		self.lightOverlay.alpha=0
	end
	if(self.rect~=nil)then--if the debug box was on
		self.rect.y=self.rect.y+distanceToScroll
	end

	--move all the textDisplays that might be present on the button
	for i=1, #self.textDisplays do
		self.textDisplays[i].y=self.textDisplays[i].y+distanceToScroll
		if(not self.isButtonVisible)then--disable the image if button is not visible
			self.textDisplays[i].alpha=0
		else--when the button becomes visible, show the image again
			self.textDisplays[i].alpha=1
		end
	end

	--move all the images/ animations that might be present on the button
	for i=1, #self.images do
		self.images[i].y=self.images[i].y+distanceToScroll
		if(not self.isButtonVisible)then--disable the image if button is not visible
			self.images[i].alpha=0
		else--when the button becomes visible, show the image again
			self.images[i].alpha=1
		end
	end
end

--------------------------------
--Call this function with the distance (+ or -) to be scrolled by this button. The scrollContentBound is structured like all other content bounds
-- and indicates the limit of the scrollpane. If the button's centre exceeds this limit, the button's graphics will not be rendered
function button:scrollX(distanceToScroll,scrollContentBound)

	--move the contentBounds of the button
	self.contentBounds.xMin=self.contentBounds.xMin+distanceToScroll
	self.contentBounds.xMax=self.contentBounds.xMax+distanceToScroll

	self.x=self.x+distanceToScroll

	--check if the button needs to be still visible in the scrollable area. Observe that visiblity has to be checked for X and Y bounds each time to avoid conflicts. 
	if(self.contentBounds.xMin<scrollContentBound.xMin or self.contentBounds.xMax>scrollContentBound.xMax or
		self.contentBounds.yMin<scrollContentBound.yMin or self.contentBounds.yMax>scrollContentBound.yMax)then
		self.isButtonVisible=false
	else
		self.isButtonVisible=true
	end

	--check if any of the optional/ required images are not nil and first scroll them
	if(self.imageUp~=nil)then
		self.imageUp.x=self.imageUp.x+distanceToScroll
		if(not self.isButtonVisible)then--disable the image up graphic 
			self.imageUp.alpha=0
		else--when the button becomes visible, force the image to up
			self.imageUp.alpha=1
		end
	end
	if(self.imageDown~=nil)then
		self.imageDown.x=self.imageDown.x+distanceToScroll
		--disable the image down graphic regardless of whether button is visible 
		self.imageDown.alpha=0
	end
	if(self.activatedImage~=nil)then
		self.activatedImage.x=self.activatedImage.x+distanceToScroll
		if(not self.isButtonVisible)then--disable the activated image graphic 
			self.activatedImage.alpha=0
		else--when the button becomes visible, turn on the activation marker based on the lastActivationState
			if(self.lastActivatedState)then
				self.activatedImage.alpha=1
			else
				self.activatedImage.alpha=0
			end
		end
	end
	if(self.darkOverlay~=nil)then
		self.darkOverlay.x=self.darkOverlay.x+distanceToScroll
		--disable the dark overlay graphic regardless of whether button is visible 
		self.darkOverlay.alpha=0
	end
	if(self.lightOverlay~=nil)then
		--disable the light overlay graphic regardless of whether button is visible 
		self.lightOverlay.alpha=0
	end
	if(self.rect~=nil)then--if the debug box was on
		self.rect.x=self.rect.x+distanceToScroll
	end

	--move all the textDisplays that might be present on the button
	for i=1, #self.textDisplays do
		self.textDisplays[i].x=self.textDisplays[i].x+distanceToScroll
		if(not self.isButtonVisible)then--disable the image if button is not visible
			self.textDisplays[i].alpha=0
		else--when the button becomes visible, show the image again
			self.textDisplays[i].alpha=1
		end
	end

	--move all the images/ animations that might be present on the button
	for i=1, #self.images do
		self.images[i].x=self.images[i].x+distanceToScroll
		if(not self.isButtonVisible)then--disable the image if button is not visible
			self.images[i].alpha=0
		else--when the button becomes visible, show the image again
			self.images[i].alpha=1
		end
	end
end

----------------------------------------
--function to force reset the graphics of button when released outside its bounds. This is called from the listener in the menu scrip
--and also as part of touch behaviour in the touchEvent function
function button:forceGraphicsRelease()
	--if the image down is currently active, change to imageUp
	if(self.imageDown~=nil)then
		self.imageDown.alpha=0
		self.imageUp.alpha=1
	end

	--if alpha down is currently active set alpha to alphaUp
	if(self.alphaUp~=nil and self.alphaDown~=nil)then
		self.imageUp.alpha=self.alphaUp
	end

	--if the button is scaled down, scae up to its original scale
	if(self.doesScaleDown)then
		if(self.imageUp.xScale<1)then
			self.imageUp.xScale=1
			self.imageUp.yScale=1
			self.darkOverlay.xScale=1
			self.darkOverlay.yScale=1
			self.darkOverlay.alpha=0--disable the visibility of the dark overlay
			--scale up the button texts 
			for i=1,#self.textDisplays do
				self.textDisplays[i].xScale=1
				self.textDisplays[i].yScale=1
			end
			--scale up the button images/animations 
			for i=1,#self.images do
				self.images[i].xScale=1
				self.images[i].yScale=1
			end
			--scale up light for activated buttons
			if(self.activatedImage~=nil)then
				self.activatedImage.xScale=1
				self.activatedImage.yScale=1
			end
		end
	end

	--turn off alpha of white overlay
	if(self.doesGlow)then
		self.lightOverlay.alpha=0
	end
end

----------------------------------------

function button:touchEvent(event)
	--if the button was scrolled out of the scrollpane, touch should not work. 
	if(self.isButtonVisible==false)then
		return
	end

	local eventPhase=event.phase
	
	--handle Images based on different sprites
	if(eventPhase=="began" and self.imageDown~=nil)then
		self.imageDown.alpha=1
		self.imageUp.alpha=0
	elseif(eventPhase=="ended")then
		self:forceGraphicsRelease()	
	end

	--handle alphas if asked to 
	if(self.alphaUp~=nil and self.alphaDown~=nil)then
		if(eventPhase=="began")then
			self.imageUp.alpha=self.alphaDown
		elseif(eventPhase=="ended")then
			self:forceGraphicsRelease()
		end	
	end

	--handle scales if asked to
	if(self.doesScaleDown)then
		if(eventPhase=="began")then
			self.imageUp.xScale=0.95
			self.imageUp.yScale=0.95
			self.darkOverlay.xScale=0.95
			self.darkOverlay.yScale=0.95
			self.darkOverlay.alpha=0--enable the alpha for the dark overlay(currently disabled, set alpha to 1 to enable dark overlay)
			--scale down the button texts 
			for i=1,#self.textDisplays do
				self.textDisplays[i].xScale=0.95
				self.textDisplays[i].yScale=0.95
			end
			--scale down the button's owned/animations
			for i=1,#self.images do
				self.images[i].xScale=0.95
				self.images[i].yScale=0.95
			end
			--scale down light for activated buttons
			if(self.activatedImage~=nil)then
				self.activatedImage.xScale=0.95
				self.activatedImage.yScale=0.95
			end
		elseif(eventPhase=="ended")then
			self:forceGraphicsRelease()
		end	
	end

	--handle the addition of light overlay if doesGlow is activated
	if(self.doesGlow)then
		if(eventPhase=="began")then
			self.lightOverlay.alpha=1--enable the alpha for the light overlay
		elseif(eventPhase=="ended")then
			self:forceGraphicsRelease()
		end	
	end

	--handle callbacks
	if(self.callbackDown~=nil and eventPhase=="began")then
		self.callbackDown()
	end
	if(self.callbackUp~=nil and eventPhase=="ended")then
		self.callbackUp()
	end
end


---------------------------------------
--function will return an element such as text, image or animation that was added using one of the above functions into this button
function button:getItemByID(id)
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


return button