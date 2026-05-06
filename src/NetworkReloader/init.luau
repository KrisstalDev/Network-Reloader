--[=[

	Made by Krisstal (KrisstalDev).
	
	░███    ░██ ░█████████  
	░████   ░██ ░██     ░██ 
	░██░██  ░██ ░██     ░██ 
	░██ ░██ ░██ ░█████████  
	░██  ░██░██ ░██   ░██   
	░██   ░████ ░██    ░██  
	░██    ░███ ░██     ░██ 
	
	This module is intended to be a "reloader" or "reviver" for situations with high network usage.
	This module is a wrapper, so you don't have to remake something in order to make it work.
	
	Go to line 129 if you want to test its effectiveness.
	
]=]

local module = {}

local MReferencer = require(script.Referencer)
local MLZW = require(script.LZW)
local MVectorCompressor = require(script.VectorCompressor)

export type Parameters = {
	ReferencerUsePath:boolean,
	SendCompressionLeftovers:boolean,
	PrintSize:boolean,
	Enabled:{
		Referencer:boolean,
		StringVectors:boolean,
		BufferVectors:boolean,
		LZWCompression:boolean,
		ZstdCompressionLevel:number?,
		HexColor3:boolean,
		StringBrickColors:boolean,
		StringCFrames:boolean,
		BufferCFrames:boolean,
		JsonBuffers:boolean,
	}
}


function module.getRequestSize(request:string|{}|buffer)
	local buf:buffer
	
	if typeof(request) == "string" then
		buf = buffer.fromstring(request)
	elseif typeof(request) == "table" then
		buf = buffer.fromstring(game.HttpService:JSONEncode(request))
	elseif typeof(request) == "buffer" then
		buf = request
	end
	
	return buffer.len(buf)
end

function module.requestOut(parameters:Parameters, ...)
	local leftovers = {}
	local leftoversCount = 0
	
	local function processTable(tbl:{[any]:any}, leftoversTable:{}):{[any]:any}
		local newTable = {}
		
		for i, v in pairs(tbl) do
			local vType = typeof(v)
			
			if vType == "table" then
				leftoversTable[i] = {}
				
				v = processTable(v, leftoversTable[i])
			elseif parameters.Enabled.Referencer and vType == "Instance" then
				v = MReferencer.processOut(v, parameters.ReferencerUsePath)
			elseif vType == "Vector3" or vType == "Vector2" then
				if parameters.Enabled.StringVectors then
					v = MVectorCompressor.CompressVector(v, false)
				elseif parameters.Enabled.BufferVectors then
					v = MVectorCompressor.CompressVector(v, true)
				end
			elseif parameters.Enabled.HexColor3 and vType  == "Color3" then
				v = v:ToHex()
			elseif parameters.Enabled.StringBrickColors and vType == "BrickColor" then
				v = "\\B"..tostring(v.Number)
			elseif vType == "CFrame" then
				if parameters.Enabled.BufferCFrames then
					v = MVectorCompressor.CompressCFrame(v, true)
				elseif parameters.Enabled.StringCFrames then
					v = MVectorCompressor.CompressCFrame(v, false)
				end
			elseif parameters.Enabled.JsonBuffers and vType == "buffer" then
				v = "\\JB"..game.HttpService:JSONEncode(v)
			end
			
			if (parameters.Enabled.ZstdCompressionLevel or parameters.Enabled.LZWCompression) and not table.find({
				"number", "string", "boolean", "table", "nil", "buffer"}, typeof(v)) then
				
				if not parameters.SendCompressionLeftovers then continue end
				
				newTable[i] = "\\LOF"
				
				if typeof(i) == "number" then i = "\\N"..tostring(i) end
				
				leftoversCount += 1
				leftoversTable[i] = if typeof(v) == "table" then leftoversTable[i] else v
			else
				if not parameters.SendCompressionLeftovers and typeof(i) == "number" then
					table.insert(newTable, v)
				else
					newTable[i] = v
				end
			end
		end
		
		return newTable
	end
	
	local result = processTable({...}, leftovers)
	
	if parameters.Enabled.LZWCompression then
		result = {MLZW:Compress(game.HttpService:JSONEncode(result))}
	elseif parameters.Enabled.ZstdCompressionLevel then
		local buf = buffer.fromstring(game.HttpService:JSONEncode(result))
		
		result = {game:GetService("EncodingService"):CompressBuffer(buf, Enum.CompressionAlgorithm.Zstd, parameters.Enabled.ZstdCompressionLevel)}
	end
	
	local size = module.getRequestSize(result[1])
	
	
	if parameters.PrintSize then
		print("JSON Size:", size, "B  ", size/1024, "KB")
		print("Leftovers count:", leftoversCount)
	end
	
	return parameters, result, if parameters.SendCompressionLeftovers then leftovers else nil
end

function module.requestIn(parameters:Parameters, result:{[any]:any}, leftovers:{[any]:any})
	local request:{any}
	
	if parameters.Enabled.LZWCompression then
		request = game.HttpService:JSONDecode(MLZW:Decompress(result[1]))
	elseif parameters.Enabled.ZstdCompressionLevel then
		request = game.HttpService:JSONDecode(buffer.tostring(game:GetService("EncodingService"):DecompressBuffer(result[1], Enum.CompressionAlgorithm.Zstd)))
	else
		request = result
	end
	
	if leftovers and #result == 1 then
		local function fillTable(requestTbl:{[any]:any}, leftoversTbl:{[any]:any})
			for i, v in pairs(leftoversTbl) do
				if typeof(i) == "string" and i:sub(1, 2) == "\\N" then
					local num = tonumber(i:sub(3, #i))
					
					if num then
						i = num
					end
				end
				
				if typeof(v) == "table" and requestTbl[i] then
					fillTable(requestTbl[i], v)
					continue
				end
				
				requestTbl[i] = v
			end
		end
		
		fillTable(request, leftovers)
	end
	
	local function processTable(tbl:{[any]:any})
		for i, v in pairs(tbl) do
			if typeof(v) == "table" then
				v = processTable(v)
			elseif typeof(v) == "string" then
				if parameters.Enabled.Referencer and #v >= 2 and v:sub(1, 2) == "\\R" then
					v = MReferencer.processIn(v:sub(3, #v), parameters.ReferencerUsePath)
				elseif parameters.Enabled.StringVectors and #v >= 7 and v:sub(1, 2) == "\\V" then
					v = MVectorCompressor.DecompressVector(v, false)
				elseif parameters.Enabled.HexColor3 and #v == 6 and tonumber(v, 16) then
					v = Color3.fromHex(v)
				elseif parameters.Enabled.StringBrickColors and #v >= 3 and v:sub(1, 2) == "\\B" then
					v = BrickColor.new(tonumber(v:sub(3, #v)))
				elseif parameters.Enabled.StringCFrames and #v >= 3 and v:sub(1, 2) == "\\C" then
					v = MVectorCompressor.DecompressCFrame(v, false)
				elseif parameters.Enabled.JsonBuffers and #v >= 4 and v:sub(1, 3) == "\\JB" then
					v = game.HttpService:JSONDecode(v:sub(4, #v))
				end
			elseif typeof(v) == "buffer" then
				if parameters.Enabled.BufferVectors and ((buffer.len(v) == 9 and buffer.readi8(v, 0) == 9) or (buffer.len(v) == 13 and buffer.readi8(v, 0) == 13)) then
					v = MVectorCompressor.DecompressVector(v, true)
				elseif parameters.Enabled.BufferCFrames and (buffer.len(v) == 29 and buffer.readi8(v, 0) == 29) then
					v = MVectorCompressor.DecompressCFrame(v, true)
				end
			end

			tbl[i] = v
		end

		return tbl
	end

	return table.unpack(processTable(request))
end

--[=[
	Wraps the OUT function to automatically process original requests
	outFunc - a function that fires the event with the given arguments
	returns a function that you need to use instead of the default fire function
]=]
function module.wrapOutFunction(outFunc:(...any)->(), parametersGetFunction:()->(Parameters))
	return function (...)
		outFunc(module.requestOut(parametersGetFunction(), ...))
	end
end

--[=[
	Wraps the IN function to automatically process compressed requests
	inFunc - a function that will fire with the sent arguments after they are processed
	returns a function that you need to connect to the event
]=]
function module.wrapInFunction(inFunc:(...any)->())
	return function (...)
		inFunc(module.requestIn(...))
	end
end

function module.init()
	MReferencer.init()
	
	return module
end

return module