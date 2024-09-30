local objectTypesMap={}

local toast=require "scripts.helperScripts.toast"
local debugStmt=require "scripts.helperScripts.printDebugStmt"
local assetName=require "scripts.helperScripts.assetName"
local graphicsHelper=require "scripts.helperScripts.graphicsHelper"
local fluidManager=require "scripts.helperScripts.fluidManager"

-------------------------------
function objectTypesMap.makeObject(object,objectDisplayGroup,debugDisplayGroup, colour)

    if(object.type=="blockLarge")then
    	-- local assetPath -- path to graphic asset of the object
        object.bodyWidth=300
        object.bodyHeight=100
        object.sprite=display.newRect(objectDisplayGroup,object.x,object.y,object.bodyWidth,object.bodyHeight)

        local physicsBodyParams = { halfWidth=object.bodyWidth*0.5, halfHeight=object.bodyHeight*0.5, x=0, y=0 }
        --add physics body
        physics.addBody( object.sprite, "static", {density=1,friction=1,bounce=0, box=physicsBodyParams} )
        object.sprite.rotation=object.rotation

        object.sprite:setFillColor(1,0,0)--assign a colour for clarity/convenience 

        --shadowMaker(objectDisplayGroup,object,{assetPath=assetName.someImage},object.sprite.width*0.05,object.sprite.height*0.1)
    elseif(object.type=="blockMedium")then
        -- local assetPath -- path to graphic asset of the object
        object.bodyWidth=200
        object.bodyHeight=100
        object.sprite=display.newRect(objectDisplayGroup,object.x,object.y,object.bodyWidth,object.bodyHeight)

        local physicsBodyParams = { halfWidth=object.bodyWidth*0.5, halfHeight=object.bodyHeight*0.5, x=0, y=0 }
        --add physics body
        physics.addBody( object.sprite, "static", {density=1,friction=1,bounce=0, box=physicsBodyParams} )
        object.sprite.rotation=object.rotation

        object.sprite:setFillColor(0,1,0)--assign a colour for clarity/convenience 

        --shadowMaker(objectDisplayGroup,object,{assetPath=assetName.someImage},object.sprite.width*0.05,object.sprite.height*0.1)
    elseif(object.type=="blockSmall")then
        -- local assetPath -- path to graphic asset of the object
        object.bodyWidth=50
        object.bodyHeight=50
        object.sprite=display.newRect(objectDisplayGroup,object.x,object.y,object.bodyWidth,object.bodyHeight)

        local physicsBodyParams = { halfWidth=object.bodyWidth*0.5, halfHeight=object.bodyHeight*0.5, x=0, y=0 }
        --add physics body
        --NOTE: as an example of collision filters, the blockSmall object is configured to not collide with player. See the included collisionFilters document in this project
        physics.addBody( object.sprite, "static", {density=1,friction=1,bounce=0, box=physicsBodyParams,filter={categoryBits=2, maskBits=5}})
        object.sprite.rotation=object.rotation

        object.sprite:setFillColor(0,0,1)--assign a colour for clarity/convenience 

        --shadowMaker(objectDisplayGroup,object,{assetPath=assetName.someImage},object.sprite.width*0.05,object.sprite.height*0.1)
    elseif(object.type=="contentBoundObject")then
        object.bodyWidth=100
        object.bodyHeight=100

        object.sprite=display.newRect( debugDisplayGroup, object.x, object.y, object.bodyWidth, object.bodyHeight )
        object.sprite:setFillColor( 0, 0, 1)
                    
        --add contentBound to detect collision
        object.contentBound.xMin=object.x-object.bodyWidth*0.5
        object.contentBound.xMax=object.x+object.bodyWidth*0.5
        object.contentBound.yMin=object.y-object.bodyHeight*0.5
        object.contentBound.yMax=object.y+object.bodyHeight*0.5  
        object.sprite.rotation=rotation  
    elseif(object.type=="currencyObject")then
        object.sprite=display.newCircle(objectDisplayGroup,object.x, object.y, 40)
        object.sprite:setFillColor( 0.5, 0.5, 1)
        object.sprite.rotation=object.rotation 

        --set content bound
        object.contentBound.x=object.x
        object.contentBound.y=object.y
        object.contentBound.r=object.sprite.width*0.5
    elseif(object.type=="waterDrop")then
        object.sprite=display.newImg(objectDisplayGroup, assetName.waterDrop, object.x, object.y)
        --add physics body
        physics.addBody( object.sprite, "dynamic", {density=0,friction=0,bounce=0, radius=object.sprite.width*0.2})
        
        object.sprite.rotation=object.rotation

        --add this to the fluid system as a demo of how it works
        fluidManager.addFluidParticle(object.sprite,objectDisplayGroup)
    end
    
    return object
end

------------------------------
--function that creates shadow for an object. It accepts the following parameters- 
--1. display group: the display group where shadow is to be placed
--2. object: a reference of object whose shadow is being defined
--3. assetTable is of the format {assetPath, sheet, sequence}. Assetpath shoudl be nil for animation and sheet and sequence should be provided. If assetPath is specified, the code will attempt to load a static image for shadow
--4,5. are offsets to shadow on x,y axis. A universal equation won't work for all objects so we need to pass x,y offsets to this function
function shadowMaker(displayGroup,object,assetTable,xOffset,yOffset)
    --if path for a static image was available, try to load a dedicated shadow and if that wasn't found, just use the image on the given path
    if(assetTable.assetPath)then
        --attempt to load an external dedicated image for the shadow if it is found in the path. 
        local dedicatedShadow=display.newImg( displayGroup, "assets/dedicatedShadows/"..object.type..".png", object.x, object.y,true)--note that the last parameter is true so that the fn in the main script doesn't attempt loading shadows from the documents directory

        --if a dedicated shadow could be picked for this object, remove the previosuly created shadow and set it to nil and then assign the dedicated shadow to object.shadow
        if(dedicatedShadow~=nil)then
            object.shadow=dedicatedShadow
        else
            -- we are giving object's x and y only and not including any offsets here because the offset will be added in object's update routine,
            -- after being calculated below based on shadow's dimensions, this is nescessary because in case of dedicated shadows
            object.shadow=display.newImg(displayGroup, assetTable.assetPath, object.x, object.y,true)--set last param to true as we are not looking to load shadows from the documents directory
        end
    else
        --this is the case there the shadow was an animation so use the sheet and sequence data
        object.shadow=animationService.newSprite(displayGroup,assetTable.sheet,assetTable.sequence)
        object.shadow.x=object.x
        object.shadow.y=object.y
    end

    --set the sprite's colour to black and set a default alpha of 15% in order to make it look like a shadow 
    object.shadow:setFillColor(0,0,0,0.35)

    --dynamic computation of offset based on the angle of the object. This is done in a manner that as the object rotates, the x and y offset values that 
    --were passed into this function are gradually swapped. Eg, an object that is at 45deg, the x and y offsets are both applied in half and so on.
    --note that this is only done once in the typesMap and not in the update functions of the objects so their changing rotations will not affect this. 
    -- The whole values is wrapped inside abs() so that the direction of light can be maintained. 
    object.xOffset=myMath.abs(xOffset*myMath.cos(myMath.rad(object.sprite.rotation))+yOffset*myMath.sin(myMath.rad(object.sprite.rotation)))
    object.yOffset=myMath.abs(yOffset*myMath.cos(myMath.rad(object.sprite.rotation))+xOffset*myMath.sin(myMath.rad(object.sprite.rotation)))
end 

------------------------------
return objectTypesMap