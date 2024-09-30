local deltaTime={fraction=1}--fraction defines a value that will be multiplied to the deltaTime value that is returned to other parts of the programme. This is manipulated via a tween in the GW to add a slowMotion effect
--script's only purpose to listen for the next frame and compute the deltaTime value which will be used throughout the programme. 
local debugStmt= require "scripts.helperScripts.printDebugStmt"
local getTimer=system.getTimer
local dt
local rt=0

-------------------
local function update()
	local temp = getTimer()
    dt = (temp-rt) * 0.001
    rt = temp  -- Store game time
end

-------------------
function deltaTime.getDelta()
	return dt*deltaTime.fraction--multiply the fraction value and return 
end

-------------------
Runtime:addEventListener ( "enterFrame", update)

return deltaTime