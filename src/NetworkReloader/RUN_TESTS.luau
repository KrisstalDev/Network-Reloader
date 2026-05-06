local module = {}

local MNetworkReloader = require(script.Parent)
MNetworkReloader.init()


local tbl, curParams = {}, {}
local descendants = {game.Workspace}
local curEvent:BindableEvent?


local fireFunc = MNetworkReloader.wrapOutFunction(function (...)
	curEvent:Fire(...)
end, function ()
	return curParams
end)

local function waitForEvent()
	local args = {curEvent.Event:Wait()}
	
	MNetworkReloader.wrapInFunction(function (newTable:{})
		local equal = 0
		local allElements = 0

		local function checkTable(tbl1:{[any]:any}, tbl2:{[any]:any})
			for i, v in pairs(tbl1) do
				if #tbl2 < i then continue end

				local v1, v2 = v, tbl2[i]

				if typeof(v1) == "table" then
					checkTable(v1, v2)
					continue
				end

				if v1 == v2 or (typeof(v1) == typeof(v2) and
					((typeof(v1) == "CFrame" and v1:FuzzyEq(v2, 0.1)) or (typeof(v1) == "buffer" and buffer.tostring(v1) == buffer.tostring(v2)))) then
					equal += 1

					if typeof(v1) == "Instance" then
						v:Destroy()
					end
				end

				allElements += 1
			end
		end

		checkTable(tbl, newTable)

		print(tostring(math.round(equal/allElements*100*100)/100).."% similarity (floating point errors exist)")

		table.clear(tbl)
		table.clear(newTable)
	end)(table.unpack(args))
	
	curEvent:Destroy()
end


function module.testGarbageTable(size:number, parameters:MNetworkReloader.Parameters)
	curParams = parameters
	curEvent = Instance.new("BindableEvent")
	
	for i=1, size do
		local rand = math.random(1, 7)
		local value
		
		if rand == 1 then
			value = CFrame.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10,
				math.random(-10000, 10000)/10) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
		elseif rand == 2 then
			value = Vector3.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10, math.random(-10000, 10000)/10)
		elseif rand == 3 then
			value = Vector2.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10)
		elseif rand == 4 then
			value = Color3.fromRGB(math.random(1, 255), math.random(1, 255), math.random(1, 255))
		elseif rand == 5 then
			-- just create garbage instances
			
			local instance = Instance.new("ObjectValue")
			instance.Name = game.HttpService:GenerateGUID()
			instance.Parent = descendants[math.random(1, #descendants)]
			
			value = instance
		elseif rand == 6 then
			value = BrickColor.random()
		elseif rand == 7 then
			local size = math.random(1, 3)
			local buf = buffer.create(size*4)
			
			for i=1, size do
				buffer.writeu32(buf, (i-1)*4, math.random(-10000, 10000))
			end
			
			value = buf
		end
		
		table.insert(tbl, value)
	end
	
	task.spawn(waitForEvent)
	
	local startTime = os.clock()

	fireFunc(tbl)

	print("Time:", math.round((os.clock()-startTime)*1000*100)/100, "ms")
end

function module.testNestedTable(size:number, parameters:MNetworkReloader.Parameters)
	curParams = parameters
	curEvent = Instance.new("BindableEvent")

	for i=1, size do
		local nested = {}
		local rand = math.random(1, 3)
		local value
		
		if rand == 1 then
			value = CFrame.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10,
				math.random(-10000, 10000)/10) * CFrame.Angles(0, math.rad(math.random(-180, 180)), 0)
		elseif rand == 2 then
			value = Vector3.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10, math.random(-10000, 10000)/10)
		elseif rand == 3 then
			value = Vector2.new(math.random(-10000, 10000)/10, math.random(-10000, 10000)/10)
		end
		
		table.insert(nested, value)
		table.insert(tbl, nested)
	end
	
	task.spawn(waitForEvent)

	local startTime = os.clock()
	
	fireFunc(tbl)

	print("Time:", math.round((os.clock()-startTime)*1000*100)/100, "ms")
end


return module