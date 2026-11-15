local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local Attributes = {BraceThickness=1.1}
return {
	Attributes = Attributes,
	Schema = { BraceThickness = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{BraceThickness=1.1}
					SG.group("Structural Scaffolding",nil,function()
						for _,x in ipairs({548,852}) do
							for z=-330,-90,40 do
								SG.group("Wall Steel Bay "..x.." "..z,nil,function()
									SG.box(3,188,3,SG.pos(x,0,z),"steel")
									for y=-74,34,36 do
										SG.segment(x,y,z,x,y+36,z+40,A.BraceThickness,"steel")
										SG.segment(x,y+36,z,x,y,z+40,A.BraceThickness,"steel")
										SG.box(2,2,40,SG.pos(x,y+36,z+20),"steel")
									end
								end)
							end
						end
						for x=580,820,40 do
							SG.group("Rear Frame "..x,nil,function()
								SG.box(3,188,3,SG.pos(x,0,-350),"steel")
								for y=-74,34,36 do
									SG.segment(x,y,-350,x+40,y+36,-350,A.BraceThickness,"steel")
									SG.segment(x+40,y,-350,x,y+36,-350,A.BraceThickness,"steel")
								end
							end)
						end
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
