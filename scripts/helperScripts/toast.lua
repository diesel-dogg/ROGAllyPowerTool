local toast={width=display.contentWidth,
			height=display.contentHeight}

--TOAST SCRIPT-- this script will show Android style toasts and will use its own timer. Toast are independent of displayGroup and will persist
--from one screen to the next. Stopping, cancelling, pausing operations are not available. 

local bg=nil
local obj=nil
local q={}
local debugStmt=require "scripts.helperScripts.printDebugStmt"
local deltaTime=require "scripts.helperScripts.deltaTime"
local textResource=require "scripts.textResources.textResourceEnglish"
local assetName=require "scripts.helperScripts.assetName"

local remove

qLimit=5-- max number of toasts to be queued
local timer=0
local timeLimit=4--duration of the toast

------------------------------
local function update()
	dt=deltaTime.getDelta()

	--increment the timer only if had been triggered
	if(timer>0)then
		timer=timer+dt
		--if timer exceeds the duration of the toast, call the remove function and reset the timer
		if(timer>timeLimit)then
			timer=0
			remove()
		end
	end
end

------------------------------
function remove()
	if obj~= nil and bg~=nil then
		display.remove(bg)
		display.remove(obj)
		obj=nil
		bg=nil
		--if queue is not empty, show next toast
		if(#q~=0) then
			toast.showToast(q[1])
			table.remove( q, 1)
		end
	end
end

------------------------------
function toast.showToast(msg)
	--if the display object is occupied, don't override but add the msg to queue for later.
	if(obj~=nil) then
		if(#q<qLimit)then
			q[#q+1]=msg
		end
		return
	end

	obj=display.newAutoSizeText({text=msg, x=toast.width/2, y=toast.height-300, font=assetName.AMR, fontSize=textResource.fontM,
	width=toast.width,align="center" })
	obj:setFillColor(1,1,1,1)
	bg=display.newRoundedRect(toast.width/2, toast.height-300, obj.width+20, obj.height+20,10 )
	bg:setFillColor( 0,0,0,1 )

	bg:toFront( )
	obj:toFront( )

	timer=0.1--trigger the timer
end
------------------------------

Runtime:addEventListener ( "enterFrame", update)

return toast