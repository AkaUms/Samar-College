-- Decodes SC_LogoData into an RGBA buffer for an EditableImage.
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local map = {}
for i = 1, #B64 do map[string.byte(B64, i)] = i - 1 end
local function b64decode(s)
	local out = buffer.create(math.floor(#s * 3 / 4))
	local n, acc, bits = 0, 0, 0
	for i = 1, #s do
		local v = map[string.byte(s, i)]
		if v then
			acc = bit32.bor(bit32.lshift(acc, 6), v) bits += 6
			if bits >= 8 then
				bits -= 8
				buffer.writeu8(out, n, bit32.band(bit32.rshift(acc, bits), 0xFF)) n += 1
				acc = bit32.band(acc, bit32.lshift(1, bits) - 1)
			end
		end
	end
	return out, n
end
return function(logo)
	local S = logo.size
	local pal = logo.palette
	local raw, len = b64decode(logo.data)
	local px = buffer.create(S * S * 4)
	local p, k = 0, 0
	local function put(ci, count)
		local r, g, b = pal[ci * 3 + 1], pal[ci * 3 + 2], pal[ci * 3 + 3]
		for _ = 1, count do
			if p >= S * S then return end
			local o = p * 4
			buffer.writeu8(px, o, r) buffer.writeu8(px, o + 1, g) buffer.writeu8(px, o + 2, b) buffer.writeu8(px, o + 3, 255)
			p += 1
		end
	end
	while k < len do
		local v = buffer.readu8(raw, k)
		if v >= 48 then put(buffer.readu8(raw, k + 1), v - 48 + 3) k += 2
		else put(v, 1) k += 1 end
	end
	return px, S, p
end
