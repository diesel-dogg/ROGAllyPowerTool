local sortableGroup={}

local debugStmt=require"scripts.helperScripts.printDebugStmt"

-----------------------------------------------------------
--call this helper function and pass the reference of a group that is to be sorted. At present, the hardcoded value of paramater along
--which sorting will be done is called "zIndex" but a dynamic way of setting the name of this parameter will be eventually needed
function sortableGroup.sort( group )

	--create a duplicate table consisting of all the child display objects in the ascending order of their z-indices 
	local sortedTable = {}
	local totalObjects = group.numChildren

	-- debugStmt.print("SG: group is "..group.name.." and chidren count is "..totalObjects)

	--if there are no objects or only a single child object in the group, do nothing and return
	if(totalObjects==0 or totalObjects==1)then
		return
	end

	for i = 1, totalObjects do
		--only add elements from the main group into the copy that is being made for sorting if they have a valid value for sorting paramter
		if(group[i].zIndex~=nil)then
			sortedTable[ #sortedTable+1 ] = group[ i ]
		end
	end

	--define an ascending sort function based on the sorting parameter, here paramater is hardcoded to be zIndex.
	local sortFunction = function( a, b ) 
							return a.zIndex < b.zIndex
						end
	
	--sort using the sorting function
	table.sort(sortedTable,sortFunction)

	-- Re-arrange the display objects as per the ascending order of the sorting paramater
	for i = 1, #sortedTable do
		sortedTable[i]:toFront()
	end
end

-----------------------------------------------------------
return sortableGroup