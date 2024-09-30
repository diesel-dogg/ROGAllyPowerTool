application =
{

	content =
	{
		width = 550,--these should always be set with portrait orientation. If the app is in landscape, they will automatically be swapped in the code if orientation is changed to landscape in the build.settings
		height = 950, 
		fps = 30,
		shaderPrecision = "lowp",
        scale = "letterbox",
   
		--[[
		imageSuffix =
		{
			    ["@2x"] = 2,
		},
		--]]
	},
	--license table for IAP
	license =
    {
        google =
        {
            key = "enter IAP key",
        },
    },
	-- Push notifications
	notification =
	{
		 google =
        {
            projectNumber = "enter projectNumber"
        },
         iphone =
        {
            types = { "badge", "sound", "alert" }
        },
	},
	  
}
