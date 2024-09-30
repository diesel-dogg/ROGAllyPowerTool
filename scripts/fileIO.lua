local fileIO={}

local json = require( "json" )
local debugStmt=require "scripts.helperScripts.printDebugStmt"

--function to read a given file containing the data tables and return them
--the second variable can be passed as true if the file is to be searched in the documents director. This feature was added in Novemeber 2020 
--to allow us to read in the setups from downloaded txt files for the purpose of livewire. All other setups are typically stored in resource dir. 
function fileIO.getTableFromFile(filename,isDocumentsDirectory) 
	local tableToRead={}
	local path 
	-- Path for the file to read(for devices), 
	if(not isDocumentsDirectory)then
		path = system.pathForFile(filename, system.ResourceDirectory)
	else
		path = system.pathForFile(filename, system.DocumentsDirectory)
	end

	-- Path for the file to read(for PC), 
	-- local path = system.pathForFile(filename:sub(7,#filename), system.DocumentsDirectory)
	
	-- Open the file handle
	local file, errorString = io.open( path, "r" )
	if not file then
	    -- Error occurred; output the cause
        debugStmt.print("FileIO:Error- "..errorString)
		return nil--if the file wasn't found in the specified location return nil
	else
		-- Read data from file
        local contents = file:read( "*a" )
        -- Decode JSON data into Lua table
        tableToRead = json.decode( contents )
	    -- Close the file handle
	    io.close( file )
	    file = nil
		return tableToRead
	end 
end

------------------------------------
--function to sava a given table in a given file
function fileIO.writeTableToFile(table,filename)

    --Path for the file to write
 	local path = system.pathForFile( filename, system.DocumentsDirectory )

    -- Open the file handle
    local file, errorString = io.open( path, "w" )

    if not file then
        -- Error occurred; output the cause
        debugStmt.print( "fileIO: " .. errorString )
        return false
    else
        -- Write encoded JSON data to file
        file:write( json.encode( table ) )
        -- Close the file handle
        io.close( file )
        return true
    end
end

------------------------------------
-- function that takes the series folder path and returns the number of events present in it 
function fileIO.getEventCount(seriesPath)
	local index=1

	while true do
		local path= system.pathForFile(seriesPath.."/level"..index..".txt", system.ResourceDirectory )
		-- Open the file handle
		local file = io.open( path,"r")
		debugStmt.print("fileIO"..tostring(file))
		if not file then
            index=index-1  
            return index
		else
			index=index+1
            io.close( file )
		end
	end
end
    
------------------------------------

return fileIO