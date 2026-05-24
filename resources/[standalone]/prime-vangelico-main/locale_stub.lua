-- QBX: no qb-core locale file
Locale = Locale or {}
function Locale:new(opts)
    local o = { phrases = opts.phrases or {}, warnOnMissing = opts.warnOnMissing }
    setmetatable(o, self)
    self.__index = self
    return o
end
function Locale:t(key)
    local node = self.phrases
    for part in string.gmatch(key, '[^.]+') do
        if type(node) ~= 'table' then node = nil break end
        node = node[part]
    end
    return node or key
end
