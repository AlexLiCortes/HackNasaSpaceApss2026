local SG = require(game:GetService("ReplicatedStorage").SceneGeneration.SG)
local DP = require(game:GetService("ReplicatedStorage").SceneGeneration.DP)
local Attributes = {TreadWidth=8,RailHeight=4}
return {
	Attributes = Attributes,
	Schema = { TreadWidth = { shape = false }, RailHeight = { shape = false } },
	OnGenerate = function(parameters, container)
		SG.into(container, function()
					local A=SG.attributes{TreadWidth=8,RailHeight=4}
					SG.group("Personnel Stair Tower",nil,function()
						for flight=1,4 do
							local bottom=-94+(flight-1)*36
							if flight==1 then bottom=-94 end
							local rise=36
							if flight==1 then rise=40 end
							local top=bottom+rise
							if flight>1 then
								bottom=-54+(flight-2)*36
								top=bottom+36
							end
							local x=580
							if flight%2==0 then x=592 end
							local startZ=-320
							local direction=1
							if flight%2==0 then startZ=-248 direction=-1 end
							SG.group("Stair Flight "..flight,nil,function()
								for i=1,40 do
									local z=startZ+direction*(i-0.5)*1.8
									local y=bottom+rise*i/40
									SG.box(A.TreadWidth,0.5,1.85,SG.pos(x,y-0.25,z),"steel")
								end
								for _,edge in ipairs({x-A.TreadWidth/2,x+A.TreadWidth/2}) do
									SG.segment(edge,bottom+A.RailHeight,startZ,edge,top+A.RailHeight,startZ+direction*72,0.3,"steel")
									for i=0,8 do
										SG.box(0.25,A.RailHeight,0.25,SG.pos(edge,bottom+rise*i/8+A.RailHeight/2,startZ+direction*72*i/8),"steel")
									end
								end
								SG.box(42,1,12,SG.pos(575,top-0.5,startZ+direction*72),"panel")
							end)
						end
						SG.group("Stair Direction Plate",nil,function()
							SG.box(0.5,7,0.5,SG.pos(601,-90.5,-241),"steel")
							local plate=SG.box(9,5,0.3,SG.cframe(601,-86,-241,0,180,0),"ink")
							local art=DP.decal("rbxassetid://123059757396951")
							DP.applyDecalOnFace(plate,plate.CFrame.LookVector,art)
						end)
					end)

		end, parameters.Attributes, parameters.Size)
	end,
}
