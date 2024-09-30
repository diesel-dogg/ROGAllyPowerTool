local fps={}

local deltaTime=require "scripts.helperScripts.deltaTime"
local debugStmt=require "scripts.helperScripts.printDebugStmt"

local samples={}
local sampleCount=625*0.5--this can be adjusted (current value of 625*0.5 is set to achieve around 5 seconds sampling at 60fps)
local avgFps=0
local smoothing=0.99--this can be adjusted (lower value will mean more focus on instantaneous value and higher value will focus more on past avg)
local fpsDisplay

local myMath={round=math.round}
local width=display.contentWidth
local height=display.contentHeight

---------------------------------
function fps.init(displayGroup)
	fpsDisplay=display.newAutoSizeText({parent=displayGroup,text="FPS: ", x=65+getXCompensation(), y=30, font=native.systemFont, fontSize=20, align="left"})--set display position here
end

---------------------------------
--This is a more basic method of computing fps based on a fixed set of smaples stored in a table
function fps.method1()
	if(#samples>sampleCount)then
		for i=1, #samples-1 do
			samples[i]=samples[i+1]
		end
		samples[#samples]=nil
	end
	samples[#samples+1]=deltaTime.getDelta()

	local sum=0
	for i=1, #samples do
		sum=sum+samples[i]
	end

	local avgFrame=sum/#samples
	avgFps=myMath.round(1/avgFrame)

	--set the text of fps display object only if debug mode is turned on
	if(isDebugMode)then
		fpsDisplay.text="FPS: "..avgFps
	end

	return avgFps
end

---------------------------------
--this method attaches more weight to the previous average and smooths out the displayed average value
function fps.method2()
	local dt=deltaTime.getDelta()
	local newFps=1/dt

	avgFps=avgFps*smoothing + newFps*(1-smoothing)

	fpsDisplay.text="FPS: "..myMath.round(avgFps)

	return avgFps
end

return fps