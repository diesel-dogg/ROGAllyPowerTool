local scrollViewMaker={}


local debugStmt=require "scripts.helperScripts.printDebugStmt"
local widget = require( "widget" )

-----------------------
-- vars and fwd references
local width=display.contentWidth
local height=display.contentHeight

-----------------------
-- call this function from any menu and pass in a params table to make a scrolling view box, scrollTextTable is a table containing all the display.newAutoSizeText objects
-- params table must have x, y, width, height and scrollTextTable, with optional fields i.e. hideBackground which is a bool and backgroundColor.
-- make sure to add all display objects in the scrollTextTable by using table.insert(scrollTextTable, displayObject)
function scrollViewMaker.createScrollView(params)
	
	if (params.hideBackground == nil)then
		params.hideBackground = false
	end

	if (params.backgroundColor == nil)then
		params.backgroundColor = { 226/255,234/255,237/255 }
	end
	
	-- Create the scroll view that will accomodate all the texts pertaining to respective menus
	local scrollView = widget.newScrollView(
	    {
	        x = params.x,
	        y = params.y,
	        width = params.width,
	        height = params.height,
	        hideScrollBar=true,--add this line to prevent app from crashing on Mac.
	        hideBackground = params.hideBackground,
	        backgroundColor = params.backgroundColor
	    }
	)

	if(params.scrollTextTable ~= nil)then
		-- insert all display objects from scrollTextTable into scrollView
		for i=1,#params.scrollTextTable do
			scrollView:insert(params.scrollTextTable[i])
		end
	end

	return scrollView
end

-----------------------
-- call this function from external scripts and pass in a scrollViewObject, when you want to destory it.
function scrollViewMaker.destroy(scrollViewObject)
	scrollViewObject:removeSelf()
	scrollViewObject=nil
end

-----------------------
return scrollViewMaker