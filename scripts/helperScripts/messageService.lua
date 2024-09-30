local messageService={	width=display.contentWidth,
								height=display.contentHeight,
							}
local timerService=require "scripts.helperScripts.timerService"							
local assetName=require "scripts.helperScripts.assetName"
local debugStmt=require "scripts.helperScripts.printDebugStmt"
local toast=require "scripts.helperScripts.toast"
local obj--the text display object
local image-- some calls may supply an optional imagePath to be displayed
local q--a queue that stores the data 
local textTransition,imageTransition

obj=nil
image=nil
q={}

--------------------------------------------------------------

--function to remove the current data and show the next data in the queue
local function remove()
	if obj~= nil then
		--trigger a tween out of the obj and image and remove the display object at the end of the transition
		if(image~=nil)then
			imageTransition=transition.to(image, {alpha=0,y=image.y-100, time = 500, onComplete=
			function (  )
				display.remove(image)
				image=nil
			end})
		end

		textTransition=transition.to(obj, {alpha=0,y=obj.y-100, time = 500, onComplete=
			function (  )
				display.remove(obj)
				obj=nil
				--if queue is not empty, show next data
				if(#q~=0) then
					messageService.showMessage(q[1].displayGroup,q[1].data)
					table.remove( q, 1)
				end
			end})
	end
end

--------------------------------------------------------------
-- Data  table format {text="....",x=....,y=.....,fontName=, size=..,sizeLimit={}, color={r,g,b}, time=, imagePath, imageX, imageY,imageWidth,imageHeight,isExemptedFromService}
--Time,fontName ,color, imagePath, imageX, imageY,imageWidth,imageHeight,isExemptedFromService are optional
--SizeLimit is an optional table in line with our autoSizeText feature. See the main script for guidance.
-- isExemptedFromService is a variable that's passed straight to timerService. If msg should continue to work during suspension of services, set this to true. 
function messageService.showMessage(displayGroup,data)
	-- if the display object is occupied, don't override but add the data to queue for later.
	if(obj~=nil) then
		q[#q+1]={}
		q[#q].displayGroup=displayGroup
		q[#q].data=data
		return
	end

	local fontName
	if(data.fontName==nil)then
		fontName=assetName.AMB
	else
		fontName=data.fontName
	end

	--if object is nil then set the object and its background
	local textData=
	{
		parent=displayGroup,
		text=data.text,
		x=data.x,
		y=data.y,
		font=fontName,
		fontSize=data.size,
		align=data.align,
		width=data.width,
		sizeLimit=data.sizeLimit-- see main script's newAutoSizeText fn
	}
	--if object is nil then set the object and its background
	obj=display.newAutoSizeText(textData)
	if(data.color~=nil)then
		obj:setFillColor(data.color.r,data.color.g,data.color.b,1)
	else
		obj:setFillColor(1,1,1,1)
	end

	--check if an image path was specified and then add that image at the supplied coordinates
	if(data.imagePath~=nil)then
		image=display.newImg(displayGroup,data.imagePath,data.imageX,data.imageY)
		--further, if width and height were specified for the image, apply those else the image will be rendered as above in default size
		if(data.imageWidth~=nil and data.imageHeight~=nil)then
			image.width=data.imageWidth
			image.height=data.imageHeight
		end
	end

	local duration
	
	if(data.time~=nil)then
		duration=data.time
	else
		duration=3000
	end

	--bring the message to the rear of the display group to make sure it remains behind the menus
	obj:toBack()
	if(image~=nil)then
		image:toBack()
	end
	--remove a data after 3 seconds 
	timerService.addTimer( duration, remove,nil, data.isExemptedFromService)
end

--------------------------------------------------------------
--a variation of show message function where messages will be independent of the waiting queue. This can allow for multiple messages to be shown on the screen at the same time
function messageService.showMessageWithoutQueue(displayGroup,data)
	local fontName
	if(data.fontName==nil)then
		fontName=assetName.AMB
	else
		fontName=data.fontName
	end
	
	--if object is nil then set the object and its background
	local textData=
	{
		parent=displayGroup,
		text=data.text,
		x=data.x,
		y=data.y,
		font=fontName,
		fontSize=data.size,
		align=data.align,
		width=data.width,
		sizeLimit=data.sizeLimit-- see main script's newAutoSizeText fn
	}
	--if object is nil then set the object and its background
	local obj=display.newAutoSizeText(textData)
	if(data.color~=nil)then
		obj:setFillColor(data.color.r,data.color.g,data.color.b,1)
	else
		obj:setFillColor(1,1,1,1)
	end

	local image 
	--check if an image path was specified and then add that image at the supplied coordinates
	if(data.imagePath~=nil)then
		image=display.newImg(displayGroup,data.imagePath,data.imageX,data.imageY)
	end

	local duration
	
	if(data.time~=nil)then
		duration=data.time
	else
		duration=3000
	end

	-- --bring the message to the rear of the display group to make sure it remains behind the menus
	-- obj:toBack()
	-- if(image~=nil)then
	-- 	image:toBack()
	-- end
	
	--remove a data after supplied time limit
	local function remove()
		--trigger a tween out of the obj and image and remove the display object at the end of the transition
		if(image~=nil)then
			transition.to(image, {alpha=0,y=image.y-100, time = 500, onComplete=
			function (  )
				display.remove(image)
				image=nil
			end})
		end

		transition.to( obj, {alpha=0,y=obj.y-100, time = 500, onComplete=
		function (  )
			display.remove(obj)
			obj=nil
		end})
	end

	timerService.addTimer( duration, remove, nil, data.isExemptedFromService)
end

--------------------------------------------------------------
--resets the message service, must be called from the destroy of every script to erase any message lingering from the previous screen
function messageService.cancelAll()
	if(textTransition~=nil)then
		transition.cancel(textTransition)
	end
	if(imageTransition~=nil)then
		transition.cancel(imageTransition)
	end
	obj=nil
	image=nil
	q={}
end
--------------------------------------------------------------

return messageService