local Cache = {}
Cache.__index = Cache

-- Ring buffer LRU cache.
-- O(1) lookup via hash table. O(1) eviction via ring overwrite.
function Cache.new(max_size)
  return setmetatable({
    _max  = max_size or 200,
    _data = {},   -- { [text] = translation }
    _ring = {},   -- fixed-size array [1..max_size]
    _head = 1,    -- next write position (oldest entry to evict)
    _size = 0,
  }, Cache)
end

function Cache:get(key)
  return self._data[key]
end

function Cache:set(key, value)
  if self._data[key] then return end  -- already cached
  -- evict oldest if full
  if self._size >= self._max then
    local old_key = self._ring[self._head]
    if old_key then self._data[old_key] = nil end
  else
    self._size = self._size + 1
  end
  self._ring[self._head] = key
  self._data[key] = value
  self._head = (self._head % self._max) + 1
end

function Cache:size()
  return self._size
end

return Cache
