local animationService={}

local debugStmt = require( "scripts.helperScripts.printDebugStmt" )
local graphicsHelper=require"scripts.helperScripts.graphicsHelper"
local animations={}

-- add a new sprite animation using group, sheet and sequence name references. This is added to the local record of all anims.
-- This fn also performs basic housekeeping by removing records that do not exist any longer.
--See inside function for details on the isExemptedFromService flag. This is basically useful for animations that are not part of the GW and need to be used in menus etc.
function animationService.newSprite(group, sheet, sequence, isExemptedFromService)
	--if the isExemptFromService flag was raised, it means that this animation needs to be created directly in Corona's display library and not be 
	--entered into our service's records. I.e, it cannot be paused or resumed univarsally through the service
	if(isExemptedFromService)then
		return display.newSprite(group,sheet,sequence)
	else
		for i=#animations, 1, -1 do
			if(animations[i].frame==nil)then
				obj=table.remove( animations,i )
				obj=nil
			end
		end

		local currentIndex=#animations+1
		animations[currentIndex]=display.newSprite(group,sheet,sequence)

		return animations[currentIndex]
	end
end

------------------------------------------------------------------------
--This function is useful for a quick automated animation which fits one or multiple of the following criteria:
--* No special sequence of frames is necessary and all frames are followed linearly
--* It's acceptable to play animation as an endless loop with no reversal of frames
--* Particularly useful for large sprite sheets or animations with up to n sprite sheets. For first sprite sheet, append _1.png to file name and for second append _2.png and so on
--All that is needed is the path without the extension, dimensions of a single frame and the time to be spent per frame. 
--NOTE: if an animation is required that is exempted from the pause, resume, cancel functionality of our animationService, use the isExemptedFromService flag
function animationService.newMultiSheetAnimation(group,path, frameWidth, frameHeight, timePerFrame, isExemptedFromService)
	local pathWithoutFileExtenstion=""

	--identify the first forward . while moving backwards from the end of the full filename and then extract the string before the "."
	--That extracted string will be just the path of the actual file along with its extension. 
	for i=string.len(path),1,-1 do
		if(path:sub(i,i)==".")then
			pathWithoutFileExtenstion=path:sub(1,i-1)
			debugStmt.print("animationService: pathWithoutFileExtenstion is "..pathWithoutFileExtenstion)
			break
		end
	end


	local sheets={}
	local numberOfFramesInSheet={}

	local index=1

	--conttinue to test-load sheets until nil and make sprite sheets intot he sheets table and store their number of frames at corresponding index of numberOfFramesInSheet table
	while true do
		--create a dummy image of the entire sprite sheet to get the sheet's dimensions and store them locally
		local dummy=display.newImg(group,pathWithoutFileExtenstion.."_"..index..".png",-5000,-5000)
		
		if(dummy~=nil)then
			local sheetHeight=dummy.height
			local sheetWidth=dummy.width
			--remove the dummy sheet after dimensions were procured
			display.remove(dummy)
			dummy=nil

			numberOfFramesInSheet[#numberOfFramesInSheet+1]=(sheetWidth/frameWidth)*(sheetHeight/frameHeight)

			sheets[#sheets+1]= graphicsHelper.newImageSheet(pathWithoutFileExtenstion.."_"..index..".png", {width=frameWidth, height=frameHeight, numFrames=numberOfFramesInSheet[#numberOfFramesInSheet], sheetContentWidth=sheetWidth, sheetContentHeight=sheetHeight})
		
			index=index+1
		else
			break
		end
	end

	-------------

	local mainSequence={}--make a table that will store all sequences by picking them up from the table of sheets and using the number of frames in each sheet as stored earlier

	for i=1, #sheets do
		mainSequence[#mainSequence+1]={ name="seq"..i, sheet=sheets[i], start=1, count=numberOfFramesInSheet[i], time=timePerFrame*numberOfFramesInSheet[i], loopCount=1 }
	end

    --generate the animation that will be returned. Use the isExemptedFromService flag as usual
    local animation=animationService.newSprite(group,sheets[1],mainSequence,isExemptedFromService)

    --a sprite listener is necessary to manually be able to set the animation object to the next seq if the seq that just ended. Special behaviour of
    --animation such as distinct frame ordering and reversal of play order etc is not possible 
    local function spriteListener(event)
    	if(event.phase=="ended")then
    		--get the integer appended to the name of the sequence that ended
    		local index=tonumber(string.sub(animation.sequence, 4, 4))

    		--checl if next index is present in the mainSequence and play it
    		if(mainSequence[index+1]~=nil)then
    			animation:setSequence( "seq"..index+1 )
    			animation:play()
    		else--if there was only one sequence or the last sequence was already played, force play the first sequence by hardcoding sequence name
    			animation:setSequence( "seq1")
    			animation:play()
    		end
	    end
    end

    animation:addEventListener( "sprite", spriteListener )--add listener

    return animation
end


---------GENERAL HELPER FUNCTIONS TO BE CALLED EXTERNALLY----------
--function will pause all animations that are presently playing and will raise a "paused" flag to their object so that they can be later resumed
function animationService.pause()
	for i=1, #animations do
		if(animations[i].isPlaying)then
			animations[i]:pause()
			animations[i].isPaused=true
		end
	end
end

--function will resume all previously paused animations
function animationService.resume()
	for i=1, #animations do
		if(animations[i].isPaused)then
			animations[i]:play()
			--pull the flag back down after playing to prevent animation from playing endlessly!
			animations[i].isPaused=false
		end
	end
end

--call this fucntion when transitioning screens etc to remove all animations since these will become null when the view changes
function animationService.removeAll()
	for i=#animations, 1, -1 do
		obj=table.remove( animations,i )
		obj=nil
	end
end


return animationService