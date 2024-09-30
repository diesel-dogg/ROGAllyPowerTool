local graphicsHelper={}

local debugStmt=require "scripts.helperScripts.printDebugStmt"

--this helper function overrides the newImageSheet function & provides a feature to read 2-d sprite sheets
function graphicsHelper.newImageSheet(assetName,params)
	local frames={}
	local frameWidth=params.width
	local frameHeight=params.height
	local numOfCols=params.sheetContentHeight/frameHeight
	local numOfRows=params.sheetContentWidth/frameWidth

	--assign the values x,y,width and height of the frames as per their locations in the texture
	for i=1,numOfCols do--itereate through the columns
		for j=1,numOfRows do--iterate through the rows
			frames[#frames+1]=
			{
				x=frameWidth*(j-1),
				y=frameHeight*(i-1),
				width=frameWidth,
				height=frameHeight
			}
		end
	end	

	--create image sheet as per the frames created and return it
	local imageSheet

	local fileNameWithoutPath=""

	--identify the first forward slash while moving backwards from the end of the full filename and then extract the string after the "/"
	--That extracted string will be just the name of the actual file along with its extension. 
	for i=string.len(assetName),1,-1 do
		if(assetName:sub(i,i)=="/")then
			fileNameWithoutPath=assetName:sub(i+1)
			break
		end
	end

	--attempt loading the filenameWithoutPath from docs/downloads directory first
	imageSheet=graphics.newImageSheet( "downloads/"..fileNameWithoutPath,system.DocumentsDirectory,{frames=frames})

	--if the attempt to load the imagesheet from the downloads location in the documents directory failed, load it from the standard path that was passed into this function
	if(imageSheet==nil)then
		imageSheet=graphics.newImageSheet(assetName,{frames=frames})--pass the frames to the image sheet
	end
	
	return imageSheet
end
	
return graphicsHelper