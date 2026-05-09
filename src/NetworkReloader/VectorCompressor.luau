--!native
--!strict

local module = {}

local function V3toSTR(v:Vector3):string
	local result = string.pack("fff", v.X, v.Y, v.Z)
	
	-- Without this, the JSON conversion will result in an error
	result = buffer.tostring(game:GetService("EncodingService"):Base64Encode(buffer.fromstring(result)))
	
	return "\\V3"..result
end

local function V2toSTR(v:Vector2):string
	local result = string.pack("ff", v.X, v.Y)
	
	-- Without this, the JSON conversion will result in an error
	result = buffer.tostring(game:GetService("EncodingService"):Base64Encode(buffer.fromstring(result)))

	return "\\V2"..result
end

local function V3toBUF(v:Vector3):buffer
	local buf = buffer.create(13)
	
	buffer.writei8(buf, 0, 13)
	
	buffer.writef32(buf, 1, v.X)
	buffer.writef32(buf, 5, v.Y)
	buffer.writef32(buf, 9, v.Z)
	
	return buf
end

local function V2toBUF(v:Vector2):buffer
	local buf = buffer.create(9)
	
	buffer.writei8(buf, 0, 9)

	buffer.writef32(buf, 1, v.X)
	buffer.writef32(buf, 5, v.Y)

	return buf
end

local function BUFtoV3(buf:buffer):Vector3
	return Vector3.new(buffer.readf32(buf, 1), buffer.readf32(buf, 5), buffer.readf32(buf, 9))
end

local function BUFtoV2(buf:buffer):Vector2
	return Vector2.new(buffer.readf32(buf, 1), buffer.readf32(buf, 5))
end

local function BUFtoCF(buf:buffer):CFrame
	local ns = {}

	for i=1, 7 do
		table.insert(ns, buffer.readf32(buf, (i-1)*4+1))
	end

	return CFrame.new(ns[1], ns[2], ns[3])*CFrame.fromAxisAngle(Vector3.new(ns[4], ns[5], ns[6]), ns[7]).Rotation
end

local function CFtoBUF(cfr:CFrame):buffer
	local buf = buffer.create(29)
	local vec, angle = cfr:ToAxisAngle()
	
	buffer.writei8(buf, 0, 29)
	
	for i, v in pairs({cfr.X, cfr.Y, cfr.Z, vec.X, vec.Y, vec.Z, angle}) do
		buffer.writef32(buf, (i-1)*4+1, v)
	end
	
	return buf
end

local function CFtoSTR(cfr:CFrame):string
	local vec, angle = cfr:ToAxisAngle()
	local arguments = {cfr.X, cfr.Y, cfr.Z, vec.X, vec.Y, vec.Z, angle}
	
	local result = string.pack("fffffff", table.unpack(arguments))
	
	-- CFrame press goes brrrrr
	
	-- Without this, the JSON conversion will result in an error
	result = buffer.tostring(game:GetService("EncodingService"):Base64Encode(buffer.fromstring(result)))
	
	return "\\C"..result
end

local function STRtoCF(str:string):CFrame
	-- Don't forget the encoding
	local result = buffer.tostring(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(str:sub(3, #str))))
	
	local ns:{number|any} = table.pack(string.unpack("fffffff", result))
	
	return CFrame.new(ns[1], ns[2], ns[3])*CFrame.fromAxisAngle(Vector3.new(ns[4], ns[5], ns[6]), ns[7]).Rotation
end


function module.CompressVector(vec:Vector3|Vector2, buffers:boolean):buffer|string
	if buffers then
		return if typeof(vec) == "Vector3" then V3toBUF(vec) else V2toBUF(vec)
	else
		return if typeof(vec) == "Vector3" then V3toSTR(vec) else V2toSTR(vec)
	end
end

function module.DecompressVector(val:buffer|string, buffers:boolean):Vector3|Vector2
	if typeof(val) == "buffer" then
		return if buffer.len(val) == 13 then BUFtoV3(val) else BUFtoV2(val)
	else
		-- Don't forget the encoding
		local result = buffer.tostring(game:GetService("EncodingService"):Base64Decode(buffer.fromstring(val:sub(4, #val))))
		local args:{number|any} = table.pack(string.unpack(if val:sub(3, 3) == "3" then "fff" else "ff", result))
		
		return if #args == 3 then Vector2.new(tonumber(args[1]), tonumber(args[2])) else Vector3.new(tonumber(args[1]), tonumber(args[2]), tonumber(args[3]))
	end
end

function module.CompressCFrame(cfr:CFrame, buffers:boolean):buffer|string
	if buffers then
		return CFtoBUF(cfr)
	else
		return CFtoSTR(cfr)
	end
end

function module.DecompressCFrame(val:buffer|string):CFrame
	if typeof(val) == "buffer" then
		return BUFtoCF(val)
	else
		return STRtoCF(val)
	end
end


return module