local timerService={}

local deltaTime=require "scripts.helperScripts.deltaTime"
local debugStmt=require "scripts.helperScripts.printDebugStmt"

-- fwd references
local timers={}
local timersExempted={} --keeps a reference of timers that are exempted from Timer Services. These timers are updated even if the timerService is paused, they can't be paused or resumed.
local pause=false
local update, delta
local mymath=
{
	round=math.round,
} 

-- Call this function to add a timer from another part of the code and to supply a duration and callback function for the nil
--name is optional and can be used for debugging etc to identify timer
--isExemptedFromService is an optional boolean which is used to make the timers run even if the timerService is paused.
function timerService.addTimer(duration, callback, name, isExemptedFromService)

	-- if the timer is be exempted from service then add it to the timersExempted table
	if(isExemptedFromService)then
		local currentIndex=#timersExempted+1
		timersExempted[currentIndex]={}
		timersExempted[currentIndex].currentTime=0
		timersExempted[currentIndex].duration=duration
		timersExempted[currentIndex].isComplete=false
		timersExempted[currentIndex].callback=callback
		if(name~=nil)then
			timersExempted[currentIndex].name=name
		end
		
		return timersExempted[currentIndex]
	-- if the timer is not to be exempted from service then add it to the timers table
	else
		local currentIndex=#timers+1
		timers[currentIndex]={}
		timers[currentIndex].currentTime=0
		timers[currentIndex].duration=duration
		timers[currentIndex].isComplete=false
		timers[currentIndex].callback=callback
		if(name~=nil)then
			timers[currentIndex].name=name
		end

		return timers[currentIndex]
	end

end

------------------
-- Update the timers stored in the current list of timers. Call this from an update function or tie to an enterFrame listener
function update()
	-- debugStmt.print("timerService: timer count is "..#timers)
	-- debugStmt.print("timerService: exempted timer count is "..#timersExempted)
	
	delta=deltaTime.getDelta()
	--exempt timers from any change in delta time fraction by dividing the fraction part with delta
	-- this is being done so that slowmo effect doesn't affect the running timers.
	delta=delta/deltaTime.fraction 
	delta=delta*1000--convert the delta value to millis as all timers are specified in millis
	

	-- timers exempted from service will update even if timerService is paused
	for i = 1, #timersExempted do
		timersExempted[i].currentTime=timersExempted[i].currentTime+mymath.round(delta)

		--for debug only: print the name, index, currentTime of a timer
		-- if(timersExempted[i].name~=nil)then
		-- 	debugStmt.print("timerService: exempted timer at index "..i.." has name "..timersExempted[i].name.." and current time is "..timersExempted[i].currentTime.."delta was "..delta)
		-- end

		if(timersExempted[i].currentTime>timersExempted[i].duration)then
			timersExempted[i].isComplete=true
			pcall(timersExempted[i].callback)
		end
	end

	--iterate in reverse and remove compelted timersExempted. 
	for i=#timersExempted, 1, -1 do
		if(timersExempted[i].isComplete)then
			local obj=table.remove(timersExempted, i)
			obj=nil
		end
	end
	--------------------

	-- check if the timers that are not exempted from the service, should update or not.
	if(pause)then
		return
	end

	for i = 1, #timers do
		timers[i].currentTime=timers[i].currentTime+mymath.round(delta)

		--for debug only: print the name, index, currentTime of a timer
		-- if(timers[i].name~=nil)then
		-- 	debugStmt.print("timerService: timer at index "..i.." has name "..timers[i].name.." and current time is "..timers[i].currentTime.."delta was "..delta)
		-- end

		if(timers[i].currentTime>timers[i].duration)then
			timers[i].isComplete=true
			pcall(timers[i].callback)
		end
	end

	--iterate in reverse and remove compelted timers. 
	for i=#timers, 1, -1 do
		if(timers[i].isComplete)then
			local obj=table.remove(timers, i)
			obj=nil
		end
	end
end

------------------
-- Call this function when moving from a screen etc. to remove all timer reference. 
function timerService.cancelAll()
	-- iterate in reverse and remove all timers from the standard timers table
	for i=#timers, 1, -1 do
		local obj=table.remove(timers, i)
		obj=nil
	end

	-- iterate in reverse and remove all timers from the exempted timers table
	for i=#timersExempted, 1, -1 do
		local obj=table.remove(timersExempted, i)
		obj=nil
	end
end
----------------

-- Call this function with a reference timer object to release that specific timer
function timerService.cancelTimer(timerToRemove)
	-- iterate in reverse and remove the timer when the reference is encountered. Do this first for standard timers
	for i=#timers, 1, -1 do
		if(timers[i]==timerToRemove)then
			local obj=table.remove(timers, i)
			obj=nil
			break
		end
	end

	-- iterate in reverse and remove the timer when the reference is encountered. Doing this now for exempted timers
	for i=#timersExempted, 1, -1 do
		if(timersExempted[i]==timerToRemove)then
			local obj=table.remove(timersExempted, i)
			obj=nil
			break
		end
	end
end
---------------

--call this function to trigger a boolean that will pause all timers
function timerService.pause()
	pause=true
end

--call this function to resume timers
function timerService.resume()
	pause=false
end

------------------
--persistent listener for the timer service
Runtime:addEventListener ( "enterFrame", update)

return timerService