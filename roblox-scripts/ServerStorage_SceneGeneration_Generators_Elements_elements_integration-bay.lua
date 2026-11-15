local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local DP = require(game:GetService("ReplicatedStorage").SceneGeneration.DP)
local Attributes = {SafetyRadius=35}
return {
	Attributes = Attributes,
	Schema = { SafetyRadius = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{SafetyRadius=35}
					SG.group("Central Integration Bay",nil,function()
						SG.group("Engine Envelope Markings",nil,function()
							local surface=SG.box(A.SafetyRadius*2,0.08,A.SafetyRadius*2,SG.pos(700,-93.85,-200),"floor")
							local art=DP.decal("rbxassetid://110940185889712")
							DP.applyDecalOnFace(surface,Vector3.new(0,1,0),art)
						end)
						for _,x in ipairs({667,733}) do
							for _,z in ipairs({-233,-167}) do
								SG.group("Integration Safety Bollard "..x.." "..z,nil,function()
									SG.box(1.2,4,1.2,SG.pos(x,-92,z),"steel")
									SG.box(1.25,0.4,1.25,SG.pos(x,-90,z),"blue")
									SG.light("point",SG.pos(x,-89.7,z),"blue",12,0.8)
								end)
							end
						end
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
