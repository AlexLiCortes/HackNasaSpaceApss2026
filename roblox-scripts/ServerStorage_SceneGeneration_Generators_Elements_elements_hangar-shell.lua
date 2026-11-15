local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local DP = require(game:GetService("ReplicatedStorage").SceneGeneration.DP)
local Attributes = {PanelSpacing=20,DoorWidth=26}
return {
	Attributes = Attributes,
	Schema = { PanelSpacing = { shape = false }, DoorWidth = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{PanelSpacing=20,DoorWidth=26}
					SG.group("Hangar Architecture",nil,function()
						SG.seat("Main Assembly Hangar",700,-200,0,function()
							SG.box(320,2,320,SG.pos(0,-1,0),"concrete")
							SG.boxes{
								3,192,320,-160,96,0,"dark",
								3,192,320,160,96,0,"dark",
								320,192,3,0,96,-160,"dark",
								320,3,320,0,192.5,0,"panel"
							}
							local wing=(320-A.DoorWidth)/2
							SG.box(wing,192,3,SG.pos(-(A.DoorWidth+wing)/2,96,160),"dark")
							SG.box(wing,192,3,SG.pos((A.DoorWidth+wing)/2,96,160),"dark")
							SG.box(A.DoorWidth,172,3,SG.pos(0,106,160),"panel")
							for z=-140,140,A.PanelSpacing do
								for _,x in ipairs({-157,157}) do
									SG.box(0.4,170,0.6,SG.pos(x,99,z),"steel")
								end
							end
							for x=-140,140,20 do
								SG.box(0.6,170,0.4,SG.pos(x,99,-157),"steel")
							end
							for z=-140,140,40 do
								SG.box(314,4,3,SG.pos(0,188,z),"steel")
								SG.segment(-156,182,z,0,190,z,1.2,"steel")
								SG.segment(156,182,z,0,190,z,1.2,"steel")
								for _,x in ipairs({-88,88}) do
									SG.box(22,0.35,2,SG.pos(x,185,z),"white")
									SG.light("point",SG.pos(x,181,z),"white",65,1.6)
								end
							end
							local board=SG.box(58,9,0.5,SG.cframe(0,27,162,0,180,0),"panel")
							local art=DP.decal("rbxassetid://139486740414237")
							DP.applyDecalOnFace(board,board.CFrame.LookVector,art)
						end,{y=-94,pad=true,footprint={320,320}})
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
