local Cache = {}
Cache.__index = Cache

-- LRU cache backed by a hash table + access-ordered array.
-- O(1) lookup, O(n) promote/evict — fine for n ≤ a few hundred.
function Cache.new(max_size)
  return setmetatable({
    _max   = max_size or 200,
    _data  = {},   -- { [key] = value }
    _order = {},   -- keys ordered by access time, most recent at end
  }, Cache)
end

function Cache:get(key)
  local val = self._data[key]
  if val == nil then return nil end
  self:_promote(key)
  return val
end

function Cache:set(key, value)
  if self._data[key] then return end
  if #self._order >= self._max then
    local evict = table.remove(self._order, 1)
    self._data[evict] = nil
  end
  self._data[key] = value
  self._order[#self._order + 1] = key
end

function Cache:_promote(key)
  local order = self._order
  for i = #order, 1, -1 do
    if order[i] == key then
      if i == #order then return end
      table.remove(order, i)
      order[#order + 1] = key
      return
    end
  end
end

function Cache:size()
  return #self._order
end

return Cache
