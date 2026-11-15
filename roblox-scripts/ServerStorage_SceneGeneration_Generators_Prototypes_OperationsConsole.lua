local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local DP = require(game:GetService("ReplicatedStorage").SceneGeneration.DP)
local Attributes = {ScreenBrightness=1.2}
return {
	Attributes = Attributes,
	Schema = { ScreenBrightness = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{ScreenBrightness=1.2}
					local S=SG.size(Vector3.new(22,8,7))
					SG.box(S.X,3,S.Z,SG.pos(0,1.5,0),"panel")
					SG.box(S.X-1,0.5,S.Z-0.5,SG.pos(0,3.25,0),"steel")
					for _,x in ipairs({-S.X/4,S.X/4}) do
						SG.box(S.X/2-1,3.6,0.5,SG.pos(x,5.4,2.2),"dark")
						local screen=SG.box(S.X/2-1.5,3.1,0.12,SG.pos(x,5.4,1.89),"blue")
						local art=DP.decal("rbxassetid://91798791457116")
						DP.applyDecalOnFace(screen,screen.CFrame.LookVector,art)
					end
					SG.light("point",SG.pos(0,5,1),"blue",12,A.ScreenBrightness)
					for x=-8,8,2 do
						SG.box(1.2,0.08,0.7,SG.pos(x,3.54,-1.4),"ink")
					end
					SG.box(4,0.6,4,SG.pos(0,2,-6),"dark")
					SG.box(0.8,1.7,0.8,SG.pos(0,0.85,-6),"steel")
					SG.box(4,3,0.6,SG.pos(0,3.8,-7.7),"panel")

		end, parameters.Attributes, parameters.Size)
	end,
}
