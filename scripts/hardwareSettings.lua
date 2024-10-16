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
local ryzenadjPath, rtssCLIPath, powerPlansPath, exePath, modifyXmlCommand

local staticGfxClockValue=0

------------------------------
--function to set the CPU clock in mhz for all power profiles on AC and DC
function hardwareSettings.setCPUClock(clock)
    --add clause to prevent setting extreme values
    if(clock>5100 or clock<1000)then
        toast.showToast("Current value might be unsafe. Setting safe default")
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

    local handle = io.popen(c0.." && "..c1.." && "..c2.." && "..c3)
    if handle then
        handle:close()
    else
        debugStmt.print("hardwareSettings: failed to execute command for setting cpu")
    end

end

-----------------------------

--function to get the current CPU clock reading
function hardwareSettings.getCPUClock()
    local handle=io.popen("powercfg /qh scheme_current SUB_PROCESSOR PROCFREQMAX", "r")
    local output

    --if valid popen handle was available, fetch and parse the output with string matching to pick up CPU clock
    if handle then
        output=handle:read("*a")
        handle:close()
    else
        debugStmt.print("hardwareSettings: failed to execute command for getting cpu clock")
    end

    local cpuClock= output:match("Current DC Power Setting Index: 0x(%x+)")--match pattern for where the clock value appears in the file
    
    --the popen command is successful even when the output was not in expected format and cpuClock could not be read in the string, hence the safeguard:
    if(cpuClock)then
        cpuClock = tonumber(cpuClock, 16) -- convert hexadecimal to decimal
    end
    
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
    local handle=io.popen(ryzenCommand)--though the output of this command isn't really required, it is best to have a handle for it to block asynchronous execution that is typical of io.popen. This wasn't a problem with os.execute
    local output=handle:read("*a")
    handle:close()
end
------------------------------------

function hardwareSettings.getTDP()
    local handle=io.popen('"'..ryzenadjPath..'ryzenadj.exe"'..' --dump-table',"r")
    local output 

    --if handle was available, extract the output and put it into a table as columns and the iterate over the table
    --to fetch the required parameter. Round off that value and return
    if handle then
        output=handle:read("*a")
        handle:close()

        local columns = {}
        for line in output:gmatch("([^\n]+)\n?") do
            for word in string.gmatch(line, "%S+") do
                table.insert(columns, word)
            end
        end

        --find value of tdp identifier and return
        for i=1, #columns do
            if(columns[i]=="0x0010")then--use 0010 instead of 000. This column seems to correspond to PL2/"power limit slow" so it makes more sense to use this as we are aiming for PL1=PL2
                return myMath.round(columns[i+4])
            end
        end
    else
        debugStmt.print("hardwareSettings: failed to execute ryzenAdj info dump")
    end

    return nil
end

-------------------------------
--function to set the static GPU clock. This is undesirable on these new AMD devices because only a restart reverts them to default
function hardwareSettings.setGfxClock(clock)
    --add clause to prevent setting extreme values. NOTE: we don't prevent a zero value from being set as that instructs the clock to be decalred as
    if((clock>2700 or clock<400) and clock~=0)then
        toast.showToast("Current value might be unsafe. Setting safe default")
        hardwareSettings.setGfxClock(800)--NOTE: 800 doesn't correspond to no static clock. That will be indicated by a value of 0. 800 is actually a static clock of 800MHz
        return
    end

    --the clause below is needed because the part of program that deploys a profile might pass a value of 0 if the profile doesn;t
    --have a static gpu clock associated with it. In this case, we don't actually need to apply a clock at all and only change the variable's value
    if(clock==0)then
        staticGfxClockValue=0
        return
    end

    if(clock%200~=0)then
        clock=clock+100
        toast.showToast("Requested value adjusted to maintain multiple of 200MHz")
    end

   --make the command structure:
    local ryzenCommand='"'..ryzenadjPath..'ryzenadj.exe"'..' --gfx-clk='..clock
    local handle=io.popen(ryzenCommand)
    
    local output
    if handle then
        output=handle:read("*a")
        handle:close()

        --the output typically is something like "successfully set gfx clock to 1000" etc we can check if string contained the required clocl value to know
        --if the command executed successfully. 
        if(string.find(output,""..clock))then
            debugStmt.print("hardwareSettings: gfx clock was successfully set and output was "..output)
            staticGfxClockValue=clock--update clock value
        end
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
    io.popen(command)
    

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
    io.popen(command)

    file:close()
    os.exit()--since the display device was reset, rendering will hang on the app so we should exit and then restart if needed
end
-----------------------

function hardwareSettings.setFPSLimit(limit)
    local rtssCommand='"'..rtssCLIPath..'rtsscli.exe"'..' limit:set '..limit
    -- debugStmt.print("executing RTSS command "..rtssCommand)

    local handle=io.popen(rtssCommand)--using a handle even though not necessary to block the execution as popen works asynchronously.
    local output=handle:read("*a")
    handle:close()
end

--------------
function hardwareSettings.getFPSLimit()
    local rtssCommand='"'..rtssCLIPath..'rtsscli.exe"'..' limit:get'
    local handle = io.popen(rtssCommand)

    local output
    local fps

    if handle then
        output=handle:read("*a")
        handle:close()
        fps=tonumber(output)
    else
        debugStmt.print("hardwareSettings: failed to execute command for getting fps limit")
    end

    return fps
end
-------------------------

function hardwareSettings.getChargingRate()
     -- Build the command for registry query, using /reg:64 to force querying 64-bit registry view
    local command = 'cmd.exe /c "reg query \"HKLM\\SOFTWARE\\ASUS\\ASUS System Control Interface\\AsusOptimization\\ASUS Keyboard Hotkeys\" /v ChargingRate /reg:64 2>nul"'
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Parse the output to get the value of ChargingRate
    local chargingRateValue = result:match("ChargingRate%s+REG_%w+%s+(%w+)")
    
    if chargingRateValue then
        -- Convert hexadecimal to decimal
        local decimalValue = tonumber(chargingRateValue, 16)
        return myMath.round(decimalValue)
    else
        return nil, "Error: Could not find the ChargingRate key or there was an error executing the command."
    end
end

-------------------------
function hardwareSettings.setChargingRate(newValue)
    -- Convert the new value to hexadecimal if it is given in decimal
    local hexValue = string.format("0x%X", newValue)

    -- Build the command for registry edit, using /reg:64 to force editing 64-bit registry view
    local command = 'cmd.exe /c "reg add \"HKLM\\SOFTWARE\\ASUS\\ASUS System Control Interface\\AsusOptimization\\ASUS Keyboard Hotkeys\" /v ChargingRate /t REG_DWORD /d ' .. hexValue .. ' /f /reg:64"'
    local handle = io.popen(command)
    local result = handle:read("*a")
    handle:close()

    -- Check if the output indicates success
    if result:match("The operation completed successfully") then
        return true, "ChargingRate value successfully updated."
    else
        return false, "Error: Could not update the ChargingRate value. Please check permissions or input."
    end
end

-------------------------
--this function will ideally return a table that has decimal values of the EnableUlps and StutterMode registry keys which are
--to be used in an appropriate UI function to check and decide if the values were default or modified and give user correct options accordingly. 
function hardwareSettings.getStutterModeAndULPS()
   -- Query for ULPS (EnableUlps) value
    local ulpsCommand = 'cmd.exe /c "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v EnableUlps /reg:64 2>nul"'
    local ulpsHandle = io.popen(ulpsCommand)
    local ulpsResult = ulpsHandle:read("*a")
    ulpsHandle:close()

    -- Query for Stutter Mode (StutterMode) value
    local stutterCommand = 'cmd.exe /c "reg query \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v StutterMode /reg:64 2>nul"'
    local stutterHandle = io.popen(stutterCommand)
    local stutterResult = stutterHandle:read("*a")
    stutterHandle:close()

    -- Debugging: Print raw results for troubleshooting
    debugStmt.print("hardwareSettings: ULPS Registry Query Result:\n" .. ulpsResult)
    debugStmt.print("hardwareSettings: StutterMode Registry Query Result:\n" .. stutterResult)

    -- Parse the output to get the EnableUlps value
    local ulpsValue = ulpsResult:match("EnableUlps%s+REG_DWORD%s+0x(%x+)")
    
    -- Parse the output to get the StutterMode value
    local stutterModeValue = stutterResult:match("StutterMode%s+REG_DWORD%s+0x(%x+)")

    -- Check if both values were successfully retrieved
    if ulpsValue and stutterModeValue then
        -- Convert hexadecimal to decimal
        local ulpsDecimalValue = tonumber(ulpsValue, 16)
        local stutterModeDecimalValue = tonumber(stutterModeValue, 16)

        return {
            ulps = ulpsDecimalValue,
            stutterMode = stutterModeDecimalValue
        }
    else
        -- Return error details if one or both values weren't found
        if not ulpsValue then
            debugStmt.print("hardwareSettings: Error- Could not find 'EnableUlps' key.")
        end
        if not stutterModeValue then
            debugStmt.print("hardwareSettings: Error- Could not find 'StutterMode' key.")
        end

        return nil, "Error: Could not find one or both registry values (EnableUlps or StutterMode)."
    end
end
-------------------------

--this function disables both ulps and stutter mode
function hardwareSettings.disableStutterModeAndULPS()
    -- Command to set ULPS (EnableUlps) to 0
    local setULPSCommand = 'cmd.exe /c "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v EnableUlps /t REG_DWORD /d 0 /f /reg:64"'
    
    -- Command to set Stutter Mode (StutterMode) to 0
    local setStutterModeCommand = 'cmd.exe /c "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v StutterMode /t REG_DWORD /d 0 /f /reg:64"'

    -- Execute the commands
    local ulpsHandle = io.popen(setULPSCommand)
    local ulpsResult = ulpsHandle:read("*a")
    ulpsHandle:close()

    local stutterHandle = io.popen(setStutterModeCommand)
    local stutterResult = stutterHandle:read("*a")
    stutterHandle:close()

    -- Check if both operations were successful
    if ulpsResult:find("The operation completed successfully") and stutterResult:find("The operation completed successfully") then
        return true, "ULPS and Stutter Mode have been successfully set to 0."
    else
        return false, "Error: Could not set ULPS and/or Stutter Mode to 0."
    end
end
-------------------------

--this function sets 2 for stutter mode and 1 for ulps thereby restoring defaults
function hardwareSettings.restoreDefaultsStutterModeAndULPS()
    -- Command to set ULPS (EnableUlps) to 1
    local setULPSCommand = 'cmd.exe /c "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v EnableUlps /t REG_DWORD /d 1 /f /reg:64"'
    
    -- Command to set Stutter Mode (StutterMode) to 2
    local setStutterModeCommand = 'cmd.exe /c "reg add \"HKLM\\SYSTEM\\CurrentControlSet\\Control\\Class\\{4d36e968-e325-11ce-bfc1-08002be10318}\\0000\" /v StutterMode /t REG_DWORD /d 2 /f /reg:64"'

    -- Execute the commands
    local ulpsHandle = io.popen(setULPSCommand)
    local ulpsResult = ulpsHandle:read("*a")
    ulpsHandle:close()

    local stutterHandle = io.popen(setStutterModeCommand)
    local stutterResult = stutterHandle:read("*a")
    stutterHandle:close()

    -- Check if both operations were successful
    if ulpsResult:find("The operation completed successfully") and stutterResult:find("The operation completed successfully") then
        return true, "ULPS and Stutter Mode have been successfully set to defaults"
    else
        return false, "Error: Could not set ULPS and/or Stutter Mode to defaults"
    end
end
-------------------------

-- Function to toggle startup registration for the app
function hardwareSettings.toggleStartup(shouldEnable)
    -- Define task name and the path to the XML file
    local taskName = "ROG Ally Power Tool"
    local xmlPath = system.pathForFile( "taskScheduler/TaskConfig.xml" ,system.ResourceDirectory )

     -- Modify the <Command> tag in the XML file
    if not modifyXmlCommand(xmlPath, '"'..exePath..'ROG Ally Power Tool.exe"') then
        return
    end

    local command
    if shouldEnable then
        -- Command to import the task from the XML file into Task Scheduler
        command = 'schtasks /create /tn "' .. taskName .. '" /xml "' .. xmlPath .. '" /f'
    else
        -- Command to remove the task from Task Scheduler
        command = 'schtasks /delete /tn "' .. taskName .. '" /f'
    end

    -- Print the command being executed for debugging
    debugStmt.print("hardwareSettings: Executing Command: " .. command)

    -- Execute the command using os.execute and print the result directly
    local result = os.execute(command)

    -- Check if the task was added/removed successfully (0 indicates success)
    if result == 0 then
        if shouldEnable then
            toast.showToast("Startup task added successfully!")
            debugStmt.print("hardwareSettings: Task successfully added to Task Scheduler with battery support.")
        else
            toast.showToast("Startup task removed")
            debugStmt.print("hardwareSettings: Task successfully removed from Task Scheduler.")
        end
    else
        debugStmt.print("hardwareSettings: Error- Could not modify the task. Exit code: " .. tostring(result) .. ". Please check permissions or syntax.")
    end
end

---------------------------
-- Function to check if the application is configured to start at Windows launch through win task scheduling service
function hardwareSettings.isTaskPresent()
    local taskName= "ROG Ally Power Tool"
    -- Command to query the task in Task Scheduler
    local command = 'schtasks /query /tn "' .. taskName .. '" 2>nul'

    -- Execute the command using os.execute
    local result = os.execute(command)

    -- Check if the exit code is 0, indicating the task is found
    if result == 0 then
        debugStmt.print("hardwareSettings: Task '" .. taskName .. "' is present.")
        return true
    else
        debugStmt.print("hardwareSettings: Task '" .. taskName .. "' is not present.")
        return false
    end
end

---------------------------
--attempt to run net session to work out if admin elevation available
function hardwareSettings.isRunAsAdmin()
    -- We use 'net session' because it requires admin privileges to run
    local result = os.execute('net session >nul 2>nul')

    if result == 0 then
        -- Command succeeded, meaning the application is running as admin
        debugStmt.print("hardwareSettings: Application is running with administrator privileges.")
        return true
    else
        -- Command failed, meaning the application is NOT running as admin
        debugStmt.print("hardwareSettings: Application is NOT running with administrator privileges.")
        return false
    end
end
--------------------------
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

------------------------HELPERS------------------
--this function will be called by toggleStartup function to modify the path of the command that points to the app's executable
--during runtime as there's no way to ensure that it will be at the exact same path on all users' systems.
function modifyXmlCommand(xmlFilePath,newCommandPath)
    -- Open the XML file for reading
    local file = io.open(xmlFilePath, "r")
    if not file then
        return false
    end

    -- Read the content of the XML file
    local xmlContent = file:read("*all")
    file:close()

    -- Replace the existing <Command> path with the new command path
    local modifiedXmlContent = xmlContent:gsub("<Command>.-</Command>", "<Command>" .. newCommandPath .. "</Command>")

    -- Open the XML file for writing and save the modified content
    file = io.open(xmlFilePath, "w")
    if not file then
        return false
    end
    file:write(modifiedXmlContent)
    file:close()

    debugStmt.print("hardwareSettings: Successfully modified the <Command> section of the XML.")
    return true
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

--executable path. This will be used to add the exe to start up registry
exePath=powerPlansPath:gsub("Resources\\powerPlans\\","")

debugStmt.print("hardwareSettings: path of exe is "..exePath)

--use lfs to make a directory in C drive where we will store the temp file with values of all ryzenadj parameters each time we use that program
local success = lfs.chdir( "C:/" )
if success then
    lfs.mkdir( "ROGAllyPowerTool" )
    lfs.mkdir( "ROGAllyPowerTool/User Profiles" )
end

return hardwareSettings