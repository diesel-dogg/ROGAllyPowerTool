local hardwareSettings={}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local menuMaker=require "scripts.menuHelper.menu"
local assetName=require "scripts.helperScripts.assetName"
local soundManager=require "scripts.soundManager"
local preferenceHandler=require "scripts.helperScripts.preferenceHandler"
local timerService=require "scripts.helperScripts.timerService"
local toast=require "scripts.helperScripts.toast"
local lfs = require( "lfs" )

-- vars and fwd references
local width=display.contentWidth
local height=display.contentHeight

local myMath={
    abs=math.abs,
    deg=math.deg,
    rad=math.rad,
    cos=math.cos,
    sin=math.sin,
    tan=math.tan,
    atan2=math.atan2,
    round=math.round,
    random=math.random,
    pi=math.pi,
    floor=math.floor,
    pow=math.pow,
    min=math.min,
    max=math.max,
}

--fwd refs--
local ryzenadjPath, rtssCLIPath, powerPlansPath

local staticGfxClockValue=800

------------------------------
--function to set the CPU clock in mhz for all power profiles on AC and DC
function hardwareSettings.setCPUClock(clock)
    --add clause to prevent setting extreme values
    if(clock>4000 or clock<1000)then
        toast.showToast("Current value  might be unsafe. Setting safe default")
        hardwareSettings.setCPUClock(3200)
        return
    end

    if(clock%200~=0)then
        clock=clock+100
        toast.showToast("Requested value adjusted to maintain multiple of 200MHz")
    end
    
    --before setting clock speed, make sure that our "custom" performance power plan without power slider is activated. Th guid for the plan was taken from the reinstallCustomPlans.bat
    local c0="POWERCFG /SETACTIVE 27fa6203-3987-4dcc-918d-748559d549ec"
    local c1="powercfg -setacvalueindex scheme_all sub_processor PROCFREQMAX".." "..clock
    local c2="powercfg -setdcvalueindex scheme_all sub_processor PROCFREQMAX".." "..clock
    local c3="powercfg -S scheme_current"
    os.execute(c0.." && "..c1.." && "..c2.." && "..c3)--combining commands as when running the os.execute, the cmd prompt window flashes too many times otherwise
end

-----------------------------

--function to get the current CPU clock reading
function hardwareSettings.getCPUClock()
    --start by querying the powercfg and dumping the sub processor data into a file
    local tmpfile = "C:\\ROGAllyPowerTool\\cpu.txt"
    os.execute("powercfg /qh scheme_current SUB_PROCESSOR PROCFREQMAX > "..tmpfile)

    --attempt to open the file
    local file=io.open(tmpfile,"r")

    --while testing on non-windows system, there will not exist such as file, so abort the function and return NA
    if(not file)then
        return "?"
    end

    local content=file:read("*a")

    local cpuClock= content:match("Current DC Power Setting Index: 0x(%x+)")--match pattern for where the clock value appears in the file
    cpuClock = tonumber(cpuClock, 16) -- convert hexadecimal to decimal

    file:close()

    return cpuClock
end
-----------------------------


--function accepts a tdp in watts and converts it into milliwatts and applies stapm, fast and slow TDP using ryzenadj
function hardwareSettings.setTDP(tdp)
    --add clause to prevent setting extreme values
    if(tdp>30 or tdp<7)then
        toast.showToast("Current value  might be unsafe. Setting safe default")
        hardwareSettings.setTDP(15)
        return
    end

    tdp=tdp.."000"

    --make the command structure:
    local ryzenCommand='"'..ryzenadjPath..'ryzenadj.exe"'..' --stapm-limit='..tdp..' --fast-limit='..tdp..' --slow-limit='..tdp..' --apu-slow-limit='..tdp
    os.execute(ryzenCommand)
end
------------------------------------

--before using any of the get functions below, first call this function without fail! It will write all the current setting values
--into a text file located in c/rogallpowertool/temp.txt
function hardwareSettings.writeRyzenadjInfo()
    --make the command structure:
    local ryzenCommand='"'..ryzenadjPath..'ryzenadj.exe"'..' --dump-table'
    local tmpfile = "C:\\ROGAllyPowerTool\\temp.txt"
    local exit = os.execute(ryzenCommand .. ' > ' .. tmpfile)
end
-------------------------

function hardwareSettings.getTDP()
    --start by writing the dump file from ryzenadj with all current values
    hardwareSettings.writeRyzenadjInfo()

    local tmpfile = "C:\\ROGAllyPowerTool\\temp.txt"

    --code below reads in all values into a table
    local file=io.open(tmpfile,"r")

    --while testing on non-windows system, there will not exist such as file, so abort the function and return NA
    if(not file)then
        return "?"
    end

    local value = nil
    local columns ={}
    for line in file:lines() do
        for word in string.gmatch(line, "%S+") do
            table.insert(columns, word)
        end
    end

    --find value of tdp identifier and return
    for i=1, #columns do
        if(columns[i]=="0x0010")then--use 0010 instead of 000. This column seems to correspond to PL2 so it makes more sense to use this as we are aiming for PL1=PL2
            file:close()--IMPORTANT to close before returning
            return myMath.round(columns[i+4])
        end
    end

    file:close()
end

-------------------------------
--function to set the static GPU clock. This is undesirable on these new AMD devices because only a restart reverts them to default
function hardwareSettings.setGfxClock(clock)
    --add clause to prevent setting extreme values
    if(clock>2700 or clock<400)then
        toast.showToast("Current value  might be unsafe. Setting safe default")
        hardwareSettings.setGfxClock(800)
        return
    end

    if(clock%200~=0)then
        clock=clock+100
        toast.showToast("Requested value adjusted to maintain multiple of 200MHz")
    end

   --make the command structure:
    local ryzenCommand='"'..ryzenadjPath..'ryzenadj.exe"'..' --gfx-clk='..clock
    local result=os.execute(ryzenCommand)

    --if ryzenAdj command indicates that it was successful, update our local variable that we are using to track the current static clock value
    if(result==0)then--0 means no error and success
        staticGfxClockValue=clock
    end
end

---------------------------

--simply return the local variable that we are using in this script to track the value of the static clock. 
function hardwareSettings.getGfxClock()
    return staticGfxClockValue
end
------------------------

function hardwareSettings.resetGfx()
    local tmpfile = "C:\\ROGAllyPowerTool\\display.txt"
    --notice how we need to use an envionrment variable to obtain the correct path of the pnputil since solar2d is 32 bit and there is no pnputil in 32 bit
    local command = "%windir%\\sysnative\\pnputil.exe /enum-devices /class DISPLAY > "..tmpfile
    os.execute(command)
    

    --now attempt to open the file
    local file=io.open(tmpfile,"r")

    --while testing on non-windows system, there will not exist such as file, so abort the function and return NA
    if(not file)then
        toast.showToast("Restarting display failed")
    end

    local content=file:read("*a")

    local displayDeviceID
    for line in content:gmatch("([^\n]+)") do
        displayDeviceID = line:match("^%s*Instance ID:%s*(.*)$")
        if displayDeviceID then
            debugStmt.print("display id is : "..displayDeviceID)
            break
        end
    end

    local command = '%windir%\\sysnative\\pnputil.exe /restart-device '..'"'..(displayDeviceID)..'"'
    debugStmt.print("command is : "..command)
    os.execute(command)

    file:close()
    os.exit()--since the display device was reset, rendering will hang on the app so we should exit and then restart if needed
end
-----------------------

function hardwareSettings.setFPSLimit(limit)
    local rtssCommand='"'..rtssCLIPath..'rtsscli.exe"'..' limit:set '..limit
    -- debugStmt.print("executing RTSS command "..rtssCommand)

    os.execute(rtssCommand)
end

--------------
function hardwareSettings.getFPSLimit()
    --run the get command and dump the output in a text file
    local rtssCommand='"'..rtssCLIPath..'rtsscli.exe"'..' limit:get'
    local tmpfile = "C:\\ROGAllyPowerTool\\rtss.txt"
    local exit = os.execute(rtssCommand .. ' > ' .. tmpfile)

    --read the number from file
    local file=io.open(tmpfile,"r")

    if(not file)then
        return nil
    end

    -- debugStmt.print("file with name was successfully opened "..tmpfile)

    local fps=tonumber(file:read("*a"))

    file:close()
   
    return fps
end

-------------------------
--install/reinstall custom power plans button. The Asus armoury crate power plans are non compliant with cpu settings and other powercfg commands so 
--this batch file creates power plans with the same IDs and names but standard windows power saver settings so that we can apply our changes to them. 
--by duplicating the windows power saving setting, we remove the battery slider and prevent windows from overriding cpu settings.
--these settings are sometimes lost when the device is plugged in so we need a button to reapply the batch file. 
function hardwareSettings.installPowerPlans()
    local powerPlansCommand='"'..powerPlansPath..'reinstallCustomPlans.bat"'

    os.execute(powerPlansCommand)
end

-------------------------
--This will reinstall the default asus power plans
function hardwareSettings.restoreAsusPlans()
    local powerPlansCommand='"'..powerPlansPath..'restoreAsusPlans.bat"'

    local output=os.execute(powerPlansCommand)
end

---------------------beyond this point is only the code that needs to be executed exactly once for init---------------
--create the path variable for where we store ryzenadj.exe
ryzenadjPath=system.pathForFile( "ryzenadj/ryzenadj.exe" ,system.ResourceDirectory )
ryzenadjPath=ryzenadjPath:gsub("/","\\")
ryzenadjPath=ryzenadjPath:gsub("ryzenadj.exe","")--since we need to use this path for other purposes as well, we remove the ryzenadj.exe part from it

--create the path variable for where we store rtss-CLI.exe
rtssCLIPath=system.pathForFile( "RTSS/rtsscli.exe" ,system.ResourceDirectory )
rtssCLIPath=rtssCLIPath:gsub("/","\\")
rtssCLIPath=rtssCLIPath:gsub("rtsscli.exe","")

--create the path variable for where we store the batch file that reinstalls and replaces asus power plans
powerPlansPath=system.pathForFile( "powerPlans/reinstallCustomPlans.bat" ,system.ResourceDirectory )
powerPlansPath=powerPlansPath:gsub("/","\\")
powerPlansPath=powerPlansPath:gsub("reinstallCustomPlans.bat","")

--use lfs to make a directory in C drive where we will store the temp file with values of all ryzenadj parameters each time we use that program
local success = lfs.chdir( "C:/" )
if success then
    lfs.mkdir( "ROGAllyPowerTool" )
    lfs.mkdir( "ROGAllyPowerTool/User Profiles" )
end

return hardwareSettings