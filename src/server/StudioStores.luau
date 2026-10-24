-- StudioStores: stand-ins for DataStores and MemoryStore sorted maps, used only when the real ones are
-- switched off (Studio without "Enable Studio Access to API Services"). They keep data for the current
-- test session and forget it when the test stops.
local StudioStores = {}

-- works like a DataStore and an OrderedDataStore (GetSortedAsync sorts by the stored number)
function StudioStores.dataStore()
	local data, s = {}, {}
	function s:GetAsync(k) return data[k] end
	function s:SetAsync(k, v) data[k] = v end
	function s:RemoveAsync(k) local v = data[k] data[k] = nil return v end
	function s:UpdateAsync(k, fn) local v = fn(data[k]) if v ~= nil then data[k] = v end return v end
	function s:GetSortedAsync(ascending, pageSize)
		local items = {}
		for k, v in pairs(data) do table.insert(items, { key = k, value = v }) end
		table.sort(items, function(a, b)
			if a.value == b.value then return a.key > b.key end
			if ascending then return a.value < b.value end
			return a.value > b.value
		end)
		local page, pages = 1, {}
		function pages:GetCurrentPage()
			local out = {}
			for i = (page - 1) * pageSize + 1, math.min(#items, page * pageSize) do table.insert(out, items[i]) end
			return out
		end
		function pages:AdvanceToNextPageAsync() page += 1 pages.IsFinished = #items <= page * pageSize end
		pages.IsFinished = #items <= pageSize
		return pages
	end
	return s
end

-- works like a MemoryStoreSortedMap (keys sorted as text, entries expire)
function StudioStores.sortedMap()
	local data, m = {}, {}
	local function alive(k)
		local e = data[k]
		if e and e.exp < os.time() then data[k] = nil return nil end
		return e
	end
	function m:SetAsync(k, v, ttl) data[k] = { v = v, exp = os.time() + ttl } return true end
	function m:GetAsync(k) local e = alive(k) return e and e.v end
	function m:RemoveAsync(k) data[k] = nil end
	function m:UpdateAsync(k, fn, ttl)
		local e = alive(k)
		local v = fn(e and e.v)
		if v ~= nil then data[k] = { v = v, exp = os.time() + ttl } end
		return v
	end
	function m:GetRangeAsync(dir, count)
		local keys = {}
		for k in pairs(data) do if alive(k) then table.insert(keys, k) end end
		table.sort(keys, function(a, b) if dir == Enum.SortDirection.Descending then return a > b end return a < b end)
		local out = {}
		for i = 1, math.min(count, #keys) do out[i] = { key = keys[i], value = data[keys[i]].v } end
		return out
	end
	return m
end

return StudioStores
