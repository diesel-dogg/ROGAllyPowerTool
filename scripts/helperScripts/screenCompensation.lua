--The script consists of methods that compute the required device-specific compensation that needs to be added to the UI elements
--to reposition them so that they don't leave empty gaps at the edge of the screen and improve the overall presentation of the game
local screenCompensation={}

local debugStmt= require "scripts.helperScripts.printDebugStmt"
local toast=require "scripts.helperScripts.toast"

local xCompensation,yCompensation--compensations to be added to the x and y coordinate of the UI respectively
------------------------------------------------------------

--function responsible for computing the x and y compensations taking into account the orientation of the game
local function computeCompensations()
	--compute x and y compensations as per the screen's orientation
	if(system.orientation=="portrait")then
		--compute x compensation--
	   	local contentAspectRatio=display.contentHeight/display.contentWidth
		local deviceAspectRatio=display.pixelHeight/display.pixelWidth
		--In case of wider devices like iPad/android tablets, an offset(compensation) needs to be added to the position of UI elements. 
		--This is done to push them outwards in order to avoid huge gaps at the edges of the screen
		if(deviceAspectRatio<contentAspectRatio)then
			local widthAsPerContentRatio=display.pixelHeight/contentAspectRatio--what the width should be as per the aspect ratio of the content
			local xCompensationOnDevice=(widthAsPerContentRatio-display.pixelWidth)*0.5--what the compensation will be in pixels on the screen the device(subject to size) 
			
			xCompensation=xCompensationOnDevice/display.pixelWidth*display.contentWidth--what the equivalent compensation will be in the content space
		else--for devices taller than or equal to a standard device(greater than or equal to 16:9), no need for a compensation as it would push the UI elements inwards.  
			xCompensation=0
		end

		--compute y compensation--
		yCompensation=display.safeScreenOriginY
		--for devices that have a smaller screen size than our fixed 1334x750, the API call returns a positive value for yCompensation 
		--which will have the effect of pushing all affected UI elements inwards and cause issues with alignment. Therefore, this compensation
		-- shoudl only be allowed to take up values <0 so that bigger devices can be accommodated and for smaller screens, forcing it to 0 shoudl work IN THEORY.
		if(yCompensation>0)then
			yCompensation=0
		end
	elseif(system.orientation=="landscapeRight" or system.orientation=="landscapeLeft")then
		--compute y compensation--
		local contentAspectRatio=display.contentWidth/display.contentHeight
		local deviceAspectRatio=display.pixelHeight/display.pixelWidth

		if(deviceAspectRatio<contentAspectRatio)then
			local widthAsPerContentRatio=display.pixelHeight/contentAspectRatio--what the width(height for landscape mode) should be as per the aspect ratio of the content
			local yCompensationOnDevice=(widthAsPerContentRatio-display.pixelWidth)*0.5
			
			yCompensation=yCompensationOnDevice/display.pixelWidth*display.contentHeight
		else
			yCompensation=0
		end

		--compute x compensation--
		xCompensation=display.safeScreenOriginX
		--same needs to be done as in the case of portrait mode
		if(xCompensation>0)then
			xCompensation=0
		end
	end
	-- toast.showToast("main: "..display.pixelHeight.." : "..display.pixelWidth.." : "..yCompensation)
end
--for devices without navigation bar, the game does not resize due to which code never reaches the onResize function, In this case, the value of  
--x and y compensation remains uninitialised and a nil error is thrown. To avoid this, call the computeCompensations function manually once when the script runs.
computeCompensations()

-----GLOBAL GETTERS FOR x and y compensations-----
------------------------------------------------------------
function getXCompensation()
	return xCompensation
end

------------------------------------------------------------
function getYCompensation()
	return yCompensation
end

------------------------------------------------------------
--listener that handles a resize event
local function onResize( event )
	--everytime the game is resized update the x and y compensations 
	computeCompensations()
	isScreenCompensationReady=true
end

------------------------------------------------------------
Runtime:addEventListener( "resize", onResize )-- Add the resize event listener, to compute required compensations to be applied on UI elements

return screenCompensation