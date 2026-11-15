local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local DP = require(game:GetService("ReplicatedStorage").SceneGeneration.DP)
local Attributes = {GlassTransparency=0.78}
return {
	Attributes = Attributes,
	Schema = { GlassTransparency = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{GlassTransparency=0.78}
					SG.group("Elevated Flight Control Room",nil,function()
						SG.group("Observation Room Envelope",SG.pos(700,18,-62),function()
							SG.box(112,1,36,SG.pos(0,-0.5,0),"floor")
							SG.box(114,2,38,SG.pos(0,26,0),"panel")
							SG.box(112,24,1,SG.pos(0,12,18),"dark")
							SG.box(112,4,1,SG.pos(0,2,-18),"panel")
							SG.box(112,4,1,SG.pos(0,22,-18),"panel")
							SG.style("glass","Glass",A.GlassTransparency,true)
							for x=-48,48,16 do
								SG.box(15.5,16,0.35,SG.pos(x,12,-18),"glass")
								SG.box(0.5,20,0.8,SG.pos(x-8,12,-18),"steel")
							end
							for _,x in ipairs({-56,56}) do
								SG.box(1,24,12,SG.pos(x,12,-12),"panel")
								SG.box(1,24,12,SG.pos(x,12,12),"panel")
								SG.box(1,14,12,SG.pos(x,17,0),"panel")
							end
							for _,x in ipairs({-36,0,36}) do
								SG.box(18,0.3,1.2,SG.pos(x,24,0),"white")
								SG.light("point",SG.pos(x,22,0),"white",28,1.3)
							end
							local fascia=SG.box(48,5,0.4,SG.pos(0,22,-18.7),"ink")
							local art=DP.decal("rbxassetid://109796298680222")
							DP.applyDecalOnFace(fascia,fascia.CFrame.LookVector,art)
						end)
						for _,x in ipairs({652,748}) do
							SG.group("Control Room Support "..x,nil,function()
								SG.box(4,111,4,SG.pos(x,-38.5,-48),"steel")
								SG.segment(x,-14,-48,x,16,-76,2,"steel")
							end)
						end
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
