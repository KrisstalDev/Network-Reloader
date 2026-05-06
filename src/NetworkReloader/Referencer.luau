local module = {}

local MRandomGen = require(script.Parent.RandomGen)
--local referencesFolder:Folder? = nil


function module.processOut(obj:Instance, usePath:boolean)
	if usePath then
		local path = {obj}
		local pathStr = ""
		
		if obj.Parent ~= game then
			repeat
				path[#path+1] = path[#path].Parent
			until path[#path].Parent == game
		end
		
		for i=#path, 1, -1 do
			pathStr ..= path[i].Name.."/./."
		end
		
		return "\\R"..pathStr:sub(1, #pathStr-4)
	else
		--[[assert(game["Run Service"]:IsServer(), "Can't create references on client!")
		
		local reference:ObjectValue = referencesFolder:FindFirstChild("Inactive") or Instance.new("ObjectValue")
		reference.Name = MRandomGen.randomString(5)
		reference.Value = obj
		reference.Parent = referencesFolder
		
		task.spawn(function () -- make inactive
			task.wait(3)
			
			reference.Name = "Inactive"
		end)]]
		
		local id = MRandomGen.randomString(10)
		
		game.CollectionService:AddTag(obj, id)
		
		return "\\R"..id
	end
end

function module.processIn(reference:string, usePath:boolean)
	if usePath then
		local split = reference:split("/./.")
		local curObj = game
		
		for i, v in pairs(split) do
			assert(curObj:FindFirstChild(v), "Didn't find path instance!")
			
			curObj = curObj[v]
		end
		
		return curObj
	else
		--[[local referenceInstance:ObjectValue? = referencesFolder:FindFirstChild(reference)
		
		assert(referenceInstance and referenceInstance.Value, "Didn't find reference!")]]
		
		local instances = game.CollectionService:GetTagged(reference)
		
		assert(instances and #instances == 1, "Didn't find reference!")
		
		game.CollectionService:RemoveTag(instances[1], reference)
		
		return instances[1]
	end
end

function module.init()
	-- New system implemented
	
	--[[if game["Run Service"]:IsClient() then
		repeat task.wait(0.1) until #game.CollectionService:GetTagged("REFERENCESFOLDER") > 0
		
		referencesFolder = game.CollectionService:GetTagged("REFERENCESFOLDER")[1]
	else
		task.wait(0.1)
		
		if #game.CollectionService:GetTagged("REFERENCESFOLDER") > 0 then
			referencesFolder = game.CollectionService:GetTagged("REFERENCESFOLDER")[1]
		else
			referencesFolder = Instance.new("Folder")
			referencesFolder.Name = MRandomGen.randomString(6)
			referencesFolder:AddTag("REFERENCESFOLDER")
			referencesFolder.Parent = game.ReplicatedStorage
		end
	end]]
end

return module