local playerTypesMap={}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local physics =require "physics" 

-------------------------------------------------------------

function playerTypesMap.makePlayer(player,playerDisplayGroup)
	--set the dimensions of the player. 
	player.radius=70

	--set content bound
	player.contentBound.x=player.x
	player.contentBound.y=player.y
	player.contentBound.r=player.radius

	--assign the main sprite image and any other images
	player.sprite=display.newCircle(playerDisplayGroup ,player.x, player.y, player.radius)
	player.sprite:setFillColor(1,1,0)
	--make main sprite
	player.sprite.x=player.x
	player.sprite.y=player.y

	--setup the physics body
	--NOTE: as an example of collision filters, the blockSmall object is configured to not collide with player. See the included collisionFilters document in this project
    physics.addBody(player.sprite,"dynamic",{radius=player.radius,density=1,friction=1, bounce=0, filter={categoryBits=2, maskBits=3}})

	debugStmt.print("playerTypesMap: mass of player : "..player.sprite.mass)

	return player
end

-------------------------------------------------------------

return playerTypesMap