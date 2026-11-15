local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local Attributes = {RailHeight=4,DeckWidth=12}
return {
	Attributes = Attributes,
	Schema = { RailHeight = { shape = false }, DeckWidth = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{RailHeight=4,DeckWidth=12}
					SG.group("Multi Level Service Catwalks",nil,function()
						for _,y in ipairs({-54,-18,18,54}) do
							SG.group("Service Level "..y,nil,function()
								for _,x in ipairs({558,842}) do
									SG.group("Wall Catwalk "..x,nil,function()
										SG.box(A.DeckWidth,1,278,SG.pos(x,y-0.5,-201),"panel")
										local edge=x+6
										if x>700 then edge=x-6 end
										SG.box(0.25,0.25,278,SG.pos(edge,y+A.RailHeight,-201),"steel")
										SG.box(0.2,0.2,278,SG.pos(edge,y+2,-201),"steel")
										for z=-336,-66,18 do
											SG.box(0.3,A.RailHeight,0.3,SG.pos(edge,y+A.RailHeight/2,z),"steel")
											SG.box(1.8,0.3,0.6,SG.pos(x,y+0.3,z),"blue")
										end
										for z=-320,-80,60 do
											SG.group("Blue Service Luminaire "..z,nil,function()
												SG.box(0.6,1.8,3,SG.pos(x,y+6,z),"dark")
												SG.box(0.65,0.8,2.5,SG.pos(x,y+6,z),"blue")
												SG.light("point",SG.pos(x,y+6,z),"blue",24,1.4)
											end)
										end
									end)
								end
								SG.group("Rear Crosswalk",nil,function()
									SG.box(284,1,12,SG.pos(700,y-0.5,-340),"panel")
									for z=-346,-334,12 do
										SG.box(284,0.25,0.25,SG.pos(700,y+4,z),"steel")
										for x=568,832,22 do
											SG.box(0.3,4,0.3,SG.pos(x,y+2,z),"steel")
										end
									end
								end)
							end)
						end
						SG.group("Observation Access Bridge",nil,function()
							SG.box(284,1,12,SG.pos(700,17.5,-62),"panel")
							for _,range in ipairs({{558,644},{756,842}}) do
								for _,z in ipairs({-68,-56}) do
									SG.box(range[2]-range[1],0.3,0.3,SG.pos((range[1]+range[2])/2,22,z),"steel")
									for x=range[1],range[2],14 do
										SG.box(0.3,4,0.3,SG.pos(x,20,z),"steel")
									end
								end
							end
						end)
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
