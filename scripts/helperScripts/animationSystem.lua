local animationSystem={}

-----NOTE: DO NOT USE WITH PHYSICS---------

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local toast=require "scripts.helperScripts.toast"
local assetName=require "scripts.helperScripts.assetName"
local deltaTime=require "scripts.helperScripts.deltaTime"
local timerService=require "scripts.helperScripts.timerService"

----fwd refs-----
local reverseTable
local setSequence
local listOfAnimations={}
local myMath=
{
	round=math.round,
	random=math.random,
} 
-------------------

local animationSystem_mt={__index=animationSystem}--animationSystem metatable

-------This is the universal update function for all animations currently in place--------

local function update()
	local dt=deltaTime.getDelta()

	-- debugStmt.print("AnimationSystem: current animation count is "..#listOfAnimations)

	--iterate in reverse and remove all animation objects that have a removeMe flag raised
	for i=#listOfAnimations, 1, -1 do
		if(listOfAnimations[i].removeMe)then
			local dummy=table.remove( listOfAnimations,i )
			dummy=nil
		end
	end

	--iterate over all animations
	for i=1, #listOfAnimations do
		--if any object somewhere in the code claimed to be owner of the animation object, it must automatically be assigned as owner of the 
		--display group of this animation object. This is because touch listeners etc are always added on the display group so addressing the owner of the display group in a touch 
		--listener should automatically point us to the owner of the animation object itself
		if(listOfAnimations[i].owner)then
			listOfAnimations[i].displayGroup.owner=listOfAnimations[i].owner
		end

		--ensure that the x and y parameters of the display group  are synced with the actual x and y params of the animation object. 
		if(listOfAnimations[i].x~=listOfAnimations[i].displayGroup.x or listOfAnimations[i].y~=listOfAnimations[i].displayGroup.y)then
			listOfAnimations[i].displayGroup.x=listOfAnimations[i].x
			listOfAnimations[i].displayGroup.y=listOfAnimations[i].y
		end

		--sync the rotation
		if(listOfAnimations[i].rotation~=listOfAnimations[i].displayGroup.rotation)then
			listOfAnimations[i].displayGroup.rotation=listOfAnimations[i].rotation
		end

		--sync the x and y scales. It is usually recommended to use the availabe Scale function but settings scales directly is also possible
		if(listOfAnimations[i].xScale~=listOfAnimations[i].displayGroup.xScale)then
			listOfAnimations[i].displayGroup.xScale=listOfAnimations[i].xScale
		end
		if(listOfAnimations[i].yScale~=listOfAnimations[i].displayGroup.yScale)then
			listOfAnimations[i].displayGroup.yScale=listOfAnimations[i].yScale
		end

		--synce the group's visibility using the alpha parameter
		listOfAnimations[i].displayGroup.alpha=listOfAnimations[i].alpha

		--to make it possible to directly set w,h params and not always have to rely on Scale fn, we can check if the width and height values set in the animation
		--object are consistent with the dimensions of the first frame and if they're not, we can iterate over all frames and resize them individually
		if(listOfAnimations[i].width~=listOfAnimations[i].frames[1].width or listOfAnimations[i].height~=listOfAnimations[i].frames[1].height)then
			for j=1,#listOfAnimations[i].frames do
				listOfAnimations[i].frames[j].width=listOfAnimations[i].width
				listOfAnimations[i].frames[j].height=listOfAnimations[i].height
			end
		end

		--IMP: usually if a display group is destroyed for an animation object through the composer system or our menu system, fetching its width/height will return nil.
		--this can be easily used to identify when the animation is no longer needed and then call our actual removeSelf function on this animation to release memory
		if(listOfAnimations[i].displayGroup.width==nil)then
			listOfAnimations[i]:removeSelf()
		else

		--to handle syncing of fill.effect, check if a string value was set for the animation object and then check if there's a variable called currentFillEffectName
		--that has the same effect name as the anim object on the first frame. If not, iterate over all frames and use Solar2D API to apply the fill and add a name for the fill to each frame
		--so that the next time, a fill effect is only applied to frames if the one assigned to the animation object was changed to another type
		if(listOfAnimations[i].fill.effect~=nil and listOfAnimations[i].frames[1].currentFillEffectName~=listOfAnimations[i].fill.effect)then
			for j=1,#listOfAnimations[i].frames do
				listOfAnimations[i].frames[j].fill.effect=listOfAnimations[i].fill.effect
				listOfAnimations[i].frames[j].currentFillEffectName=listOfAnimations[i].fill.effect
			end
		end	
			-- debugStmt.print("AnimationSystem: x and y of group "..listOfAnimations[i].displayGroup.x..", "..listOfAnimations[i].displayGroup.y)
		end
	end
end

------------------
--DATA table must be passed as follows:
------------------
--path- path to the imageSheet(s). Multiple sheets should be named with _1, _2 etc
--group (optional)- display group in which this animation is added
--x,y- coordinates
--timePerFrame- this is the timePerFrame that will ONLY be used for the default sequence. All other sequences must specify their own timeperframe as explained below
--playStyle- String value that can be forward,loop (infinite looping), random, bounce. This governs how the animation is played. NOTE: playstyle for multiple seqs cannot be independently specified and this parameter will directly need changing when playstyle is to be changed
--sequences (optional)- contains subtables like this-> {name=, frameOrder={order in which frames are played}, timePerFrame=}
--frameWidth, frameHeight are required parameters
--frameCount- total number of frames in a SINGLE sheet. In case of multiple sheets, it is expected that EACH sheet will have this number of frames
--imageSheetCount (optional)- if an animation has multiple image sheets, it is necessary to inidicate how many. NOTE: the frameCount supplied in the dataTable should be the same no of frames in each of the imageSheets

--List of animation features working-> multisheet,test-loading from documents directory,x,y,width,height,scale,alpha,setFillColor,isPlaying,frame(replaced with currentFrame),setSequence,setFrame
--play,pause,addEventListener(touch and spriteListener only),fill.effect(dodgy),
--timeScale-> this is 1 by default and a value can be set to this which will be UNIVERSALLY applied as a multiplier to the timePerFrame value of EVERY SEQUENCE. To reset values of timePerFrame for ANY seq, set this back to 1 externally
function animationSystem.new(data)
	--create some basic variables in the new animation object and store values as required that were passed in from the data table
	local newAnimation={
		path=data.path,
		frames={},--this is the table where the actual frame images are loaded in. All images in the supplied older are loaded
		displayGroup=display.newGroup(),
		x=data.x,
		y=data.y, 
		rotation=0,
		xScale=1,--init the scale values to 1. See the :scale function later in script
		yScale=1,
		width=nil,
		height=nil,-- the w,h are initialised after the frames are loaded in below and set based on the first frame. It is possilbe to enforce these by directly setting values externally. The update function will sync the requested value across all frames
		alpha=1,--this is the alpha of the local dusplay group since we use this parameter a lot to control visibility of an animation. This can be set directly externally and the universal update function will sync it
		timePerFrame=data.timePerFrame,--this is only used as timePerFrame for the default sequence. All other sequences must specify their own value
		timeScale=1,--see comment above for why it is used. This is multiplied to the timePerFrame values in the animation behaviour's timer calls
		playStyle=data.playStyle,
		currentFrameIndex=1,--init the current frame iterator index to 1. This points to the INDEX of the frame being represented presently from the currently activated sequence
		sequences=data.sequences,
		currentSequenceIndex=nil,--this refers to the index of the current sequence amongst the entire table of sequences, which is currently active. It is assigned below after the default sequence is populated
		currentSequence="default",--set the current sequence as default
		lastDisplayedFrame=nil,--this will store the reference to the frame (not index but actual frame/image) which was set to alpha=1 so that the next time a frame or sequence etc are changed, the previous frame's visibility can be toggled
		spriteListenerCallback=nil,--if the addEventListener was called on this animation object to add a callback function for the spriteListener type event, it will be stored in this 
		currentTimerReference=nil,--stores the reference to an active timerService timer that is presently controlling the animation. This is required when attmepting to remove the animation or stop/resume etc
		isPlaying=false,--flag that indicates if animation is playing or paused. See play, pause functions
		removeMe=false,--flag is raised in the removeSelf override function. It allows universal update routine to remove the animation from the list of animations
		fill={},--this can be used to assign post-process effects via fill.effect. LIMITATION- unlikely to respect anything beyond a standard effect without values and parameters
	}

	--if an imageSheetCount wasn't provided, assume there's a single sheet to this animation and set this value
	local imageSheets={}
	if(data.imageSheetCount==nil)then
		data.imageSheetCount=1
	end

	--we need the path of the sheet(s) without the path and without the _1 _2 suffixes in order to be able to check if
	--some sheet of this name was pushed into the documents directory from the server which needs to override the default asset in the resourceDirectory
	local fileNameWithoutPath=""
	--identify the first forward slash while moving backwards from the end of the full filename and then extract the string after the "/"
	--That extracted string will be just the name of the actual file along with its extension. 
	for i=string.len(newAnimation.path),1,-1 do
		if(newAnimation.path:sub(i,i)=="/")then
			fileNameWithoutPath=newAnimation.path:sub(i+1)
			break
		end
	end

	--populate a table of image sheets that are available. Start by looking for the sheet without the full path in the documentsDirectory/downloads
	--if it is not found there, load the sheet from its full path in the resource directory
	for i=1,data.imageSheetCount do
		local dummySheet
		dummySheet=graphics.newImageSheet("downloads/"..fileNameWithoutPath.."_"..i..".png",system.DocumentsDirectory,{width=data.frameWidth,height=data.frameHeight,numFrames=data.frameCount})
		
		if(dummySheet==nil)then
			dummySheet=graphics.newImageSheet(newAnimation.path.."_"..i..".png",{width=data.frameWidth,height=data.frameHeight,numFrames=data.frameCount})
		end

		if(dummySheet~=nil)then
			imageSheets[#imageSheets+1]=dummySheet
		end
	end

	--an important assumption is that the frameCount that is supplied will be the exact number of frames in EACH sheet even when there are multiple sheets. 
	--Based on this, iterate over each available image sheet and then pull each available frame out of the sheets and slap all frames into combined table of frames
	for i=1,data.imageSheetCount do
		for j=1,data.frameCount do
			newAnimation.frames[#newAnimation.frames+1]=display.newImage(newAnimation.displayGroup, imageSheets[i], j )
			newAnimation.frames[#newAnimation.frames].alpha=0--by default, a frame is not visible
		end
	end

	--now use the dimensions of the first frame to initialise width and height values
	newAnimation.width=newAnimation.frames[1].width
	newAnimation.height=newAnimation.frames[1].height

	--since sequence table might not be necessarily passed into the data table, create an empty one if it was nil
	if(newAnimation.sequences==nil)then
		newAnimation.sequences={}
	end

	--to the existing table of sequences, add a "default" sequence which will include all the frames that were loaded:
	newAnimation.sequences[#newAnimation.sequences+1]={}
	newAnimation.sequences[#newAnimation.sequences].name="default"--add name to sequence
	newAnimation.sequences[#newAnimation.sequences].timePerFrame=data.timePerFrame
	newAnimation.sequences[#newAnimation.sequences].frameOrder={}--add and then populate the frameOrder subtable for the default seq
	for j=1,#newAnimation.frames do
		newAnimation.sequences[#newAnimation.sequences].frameOrder[#newAnimation.sequences[#newAnimation.sequences].frameOrder+1]=j
	end

	--call the setSequence function now that all sequences are populated and let it take care of all the housekeeping to set up the default seq
	animationSystem.setSequence( newAnimation,"default" )

	newAnimation.displayGroup.bypassPostProcess=true
	--add the local group into the group passed in through data table
	if(data.group~=nil)then
		data.group:insert(newAnimation.displayGroup)
	end

	newAnimation.displayGroup.x=newAnimation.x--set the required coordinates directly on the local display group
	newAnimation.displayGroup.y=newAnimation.y

	--once the animation is full ready, only then add it to the list of animations currently in operation
	listOfAnimations[#listOfAnimations+1]=newAnimation

	return setmetatable(newAnimation,animationSystem_mt)
end

----------------------------------------
local function animationBehaviourHandler(self,interval)

	--pull out the order of the frames required for hte sequence that is currently being played. This can be done with the help of currentSequenceIndex
	local frameOrder=copyTable(self.sequences[self.currentSequenceIndex].frameOrder)

	--if the isPlayingInReverse flag was high, reverse the above order of frames
	if(self.isPlayingInReverse)then
		reverseTable(frameOrder)
	end

	self.currentTimerReference=timerService.addTimer(interval,function()
										--if the animation's playStyle wasn't random and the currentframe index hadn't reached the final frame of the sequence, activate next frame and turn off current frame.
										--Then call the timer again to handle future frames. NOTE that for random play style, these clauses are not needed and it is handled quite separately below
										if(self.playStyle~="random" and self.currentFrameIndex<=#frameOrder)then
											-- if(self.path==assetName.xxxxxxx)then
											-- 	debugStmt.print("animationSystem: path is "..self.path.." currentFrameIndex is "..self.currentFrameIndex.." and size of frameOrder is "..tostring(#frameOrder))
											-- end
											
											--if the lastDisplayedFrame wasn't nil, turn off its visibility
											if(self.lastDisplayedFrame)then
												self.lastDisplayedFrame.alpha=0
											end

											self.frames[frameOrder[self.currentFrameIndex]].alpha=1

											--now, assign the frame whose alpha was set to 1 as the last displayed frame
											self.lastDisplayedFrame=self.frames[frameOrder[self.currentFrameIndex]]

											-- debugStmt.print("animationSystem: timePerFrame is "..self.sequences[self.currentSequenceIndex].timePerFrame)

											animationBehaviourHandler(self,self.sequences[self.currentSequenceIndex].timePerFrame*(1/self.timeScale))--notice how timeScale is multiplied to allow similarity to solar2d's timeScale feature

											--make a dummy event table with phase "next" and call the spriteListener callback if one was present
											if(self.spriteListenerCallback)then
												local event={phase="next"}
												self.spriteListenerCallback(event)
											end

											--increment the frame index of the current sequence 
											self.currentFrameIndex=self.currentFrameIndex+1

										--if the animation sequence had come to an end and the style was to loop, return to the first frame and call the timer again
										elseif(self.playStyle=="loop")then
											--make a dummy event table with phase ended and call the spriteListener callback if one was present
											if(self.spriteListenerCallback)then
												local event={phase="ended"}
												self.spriteListenerCallback(event)
											end

											--set the currentFrameIndex to 1 and re-call the function with 0 interval to allow animation to proceed
											self.currentFrameIndex=1
											animationBehaviourHandler(self,0)

										--if the animation sequence had come to an end and the style was to bounce, call a helper function to reverse the sequence table and then start from 2nd frame (not first to avoid redundant frame being displayed)
										elseif(self.playStyle=="bounce")then
											--toggle the isPlayingInReverse boolean so that the local frameOrder table that was loaded in this function can be reversed the next time
											self.isPlayingInReverse=not self.isPlayingInReverse

											--make a dummy event table with phase ended and call the spriteListener callback if one was present
											if(self.spriteListenerCallback)then
												local event={phase="ended"}
												self.spriteListenerCallback(event)
											end

											--set the currentFrameIndex to 2 and not 1 because we don't want to repeat a frame when playing in reverse and re-call the function with 0 interval to allow animation to proceed
											self.currentFrameIndex=2
											animationBehaviourHandler(self,0)

										--if play style was forward, we don't do anything other than simply call the spriteListner callback if one was present
										elseif(self.playStyle=="forward")then
											if(self.spriteListenerCallback)then
												local event={phase="ended"}
												self.spriteListenerCallback(event)
											end
										

										--for random play, there is no end for the animation and a randomised currentFrameIndex in the selected frameOrder is selected and played
										elseif(self.playStyle=="random")then
											--if the lastDisplayedFrame wasn't nil, turn off its visibility
											if(self.lastDisplayedFrame)then
												self.lastDisplayedFrame.alpha=0
											end

											--now proceed by getting a random value for currentFrameIndex within the size of the current frameOrder
											self.currentFrameIndex=myMath.random(1,#frameOrder)

											-- debugStmt.print("AnimationSystem: here "..self.currentFrameIndex)
											self.frames[frameOrder[self.currentFrameIndex]].alpha=1
											
											--now, assign the frame whose alpha was set to 1 as the last displayed frame
											self.lastDisplayedFrame=self.frames[frameOrder[self.currentFrameIndex]]

											animationBehaviourHandler(self,self.sequences[self.currentSequenceIndex].timePerFrame*(1/self.timeScale))
										end
										
									end,nil,true)
end

----------------------------------------OVERRIDE FUNCTIONS BELOW------------
--These override standard Solar2d functions to handle functionality for play, stop, setsequence, scale etc. 

--OVERRIDE FUNCTION:the play function will simply call the animationBehaviourHandler with a reference to self and the required timer interval
function animationSystem:play()
	if(self.isPlaying==false)then--prevent playing repeatedly as that will just add more and more timers and speed up the aniamtion!
		animationBehaviourHandler(self,self.sequences[self.currentSequenceIndex].timePerFrame*(1/self.timeScale))
		self.isPlaying=true
	end
end

----------------------------
--OVERRIDE FUNCTION:the puase function only needs to cancel the current timer's reference without resetting any other iterators etc so that when play is called again, things can continue from the previous state
function animationSystem:pause()
	if(self.isPlaying==true)then
		timerService.cancelTimer(self.currentTimerReference)
		self.isPlaying=false
	end
end

------------------------------
--OVERRIDE FUNCTION: sets the current sequence from the pre-existing sequences table of the animation object by accepting the name of the seqeunce
function animationSystem:setSequence( sequenceName )
	self.currentSequence=sequenceName

	--store the index that points to the sequence in the sequences table that matches the current sequence that was specified
	local index
	for i=1,#self.sequences do
		if (self.currentSequence==self.sequences[i].name)then
			self.currentSequenceIndex=i
			break
		end
	end

	--whenever a new sequence is selected, we need to start the sequence from ITS first frame so reset the currentFrameIndex
	self.currentFrameIndex=1

	--set the alpha as 1 for the currentFrameIndex of the currentSequenceIndex
	local frameOrder=self.sequences[self.currentSequenceIndex].frameOrder
	self.frames[frameOrder[self.currentFrameIndex]].alpha=1

	--if the lastDisplayedFrame wasn't nil, turn off its visibility. IMP: Alpha of lastdisplayedframe must not be set to 0 if this frame also happened to be the first frame of the new sequence!!
	if(self.lastDisplayedFrame and self.lastDisplayedFrame~=self.frames[frameOrder[self.currentFrameIndex]])then
		self.lastDisplayedFrame.alpha=0
	end

	--set the lastDisplayedFrame as the frame whose alpha was just set to 1
	self.lastDisplayedFrame=self.frames[frameOrder[self.currentFrameIndex]]

	--Now, if the animation was already playing, call pause and play in succession to reset the timer so that previous sequence's frames don't interfere
	if(self.isPlaying)then
		self:pause()
		self:play()
	end
end
------------------------------

--OVERRIDE FUNCTION. Sets the frame at the supplied index from the CURRENT FRAME ORDER (i.e. currently active sequence)
function animationSystem:setFrame(index)
	--set current frame index to the one supplied
	self.currentFrameIndex=index

	--set the alpha as 1 to force visibility of the current frame
	local frameOrder=self.sequences[self.currentSequenceIndex].frameOrder
	self.frames[frameOrder[self.currentFrameIndex]].alpha=1

	--if the lastDisplayedFrame wasn't nil, turn off its visibility. Also, do not turn of the visibility if the requested index
	--was the same as the actual frame being displayed. This is because sometimes, a part of the code might repeatedly call this function with the same frameindex and we won't want it to be hidden in that case. 
	if(self.lastDisplayedFrame and self.frames[frameOrder[self.currentFrameIndex]]~=self.lastDisplayedFrame)then
		self.lastDisplayedFrame.alpha=0
	end

	--set the lastDisplayedFrame as the frame whose alpha was just set to 1
	self.lastDisplayedFrame=self.frames[frameOrder[self.currentFrameIndex]]
end
---------------------------

--OVERRIDE FUNCTION:removeSelf function override will remove the entire set of frames (through removal of the local display group) and raise the removeMe flag which will allow
--the update rountine to check and remove record of this animation. Also cancel timer that handles frame management. 
function animationSystem:removeSelf()
	--remove and set the local display group to nil if it wasn't already nil
	if(self.displayGroup.removeSelf~=nil)then
		self.displayGroup:removeSelf( )
		self.displayGroup=nil
	end

	self.removeMe=true--raise the flag so that the universal update function of this script can remove this from the list of animations
	--explicitly call the cancelTimer function of the timerService on the current timer reference to release the timer
	timerService.cancelTimer(self.currentTimerReference)
end

------------------------------
--OVERRIDE FUNCTION:The scale function will attempt to scale the local display group that contains all the sequence-table frames and set xScale and yScale values on the animation object
function animationSystem:scale(xScale,yScale)
	self.displayGroup:scale(xScale,yScale)
	self.xScale=self.displayGroup.xScale
	self.yScale=self.displayGroup.yScale
end

---------------------------
--OVERRIDE FUNCTION: this is used to assign the basic RGB colour and reference alpha for each available frame in the animation. All 4 values are to be passed
function animationSystem:setFillColor( r,g,b,a )
	for i=1, #self.frames do
		self.frames[i]:setFillColor( r,g,b,a )
	end
end

----------------------------
--OVERRIDE FUNCTION:LIMITATIONS:currently only touch listener is supported by directly adding it to the display group and spriteListener which will make
--callbacks to the passed in callback function with only the "ended" phase (called whenever a seauence is over, bounces or loops) or "next" phase. See the Play function (and possibly the stop/pause) function in this script to see how this works

function animationSystem:addEventListener(type,callback)
	if(type=="touch")then
		self.displayGroup:addEventListener( "touch", callback )--the movement will be automatically handled by the universal update function on the top of script
	elseif(type=="spriteListener")then
		self.spriteListenerCallback=callback
	end
end

---------------------------------HELPER FUNCTIONS--------------------

function reverseTable(t)
  local n = #t
  local i = 1
  while i < n do
    t[i],t[n] = t[n],t[i]
    i = i + 1
    n = n - 1
  end
end

--------------------------------
Runtime:addEventListener ( "enterFrame", update )


return animationSystem