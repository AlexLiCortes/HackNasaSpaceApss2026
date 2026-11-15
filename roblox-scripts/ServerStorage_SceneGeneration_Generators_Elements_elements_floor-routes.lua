local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local Attributes = {LaneWidth=12}
return {
	Attributes = Attributes,
	Schema = { LaneWidth = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{LaneWidth=12}
					SG.group("Hangar Circulation",nil,function()
						for _,x in ipairs({640,760}) do
							SG.group("Integration Aisle "..x,nil,function()
								SG.road({x,-94,-40,x,-94,-330},A.LaneWidth,"floor",{shoulder=2,depth=2,base="concrete"})
							end)
						end
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
