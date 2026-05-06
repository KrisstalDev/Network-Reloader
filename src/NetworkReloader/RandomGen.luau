--!native

local module = {}

function module.randomString(len:number, notAllowed:{}?)
	notAllowed = notAllowed or {}
	
	local codes:{number} = {}
	local random = Random.new()
	
	for i=1, len do
		local randomType:number
		
		repeat
			randomType = math.random(1, 3)
		until not table.find(notAllowed, randomType)
		
		if randomType == 1 then
			table.insert(codes, random:NextInteger(48, 57))
		elseif randomType == 2 then
			table.insert(codes, random:NextInteger(65, 90))
		elseif randomType == 3 then
			table.insert(codes, random:NextInteger(97, 122))
		end
	end
	
	return string.char(table.unpack(codes))
end

return module