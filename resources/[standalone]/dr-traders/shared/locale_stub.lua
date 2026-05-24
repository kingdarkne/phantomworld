-- Minimal Locale compatible with qb-core/shared/locale.lua (QBX servers have no qb-core).
Locale = Locale or {}
setmetatable(Locale, {
    __call = function(self, opts)
        return self:new(opts)
    end,
})

function Locale:new(opts)
    local o = {
        phrases = opts.phrases or {},
        warnOnMissing = opts.warnOnMissing,
    }
    setmetatable(o, self)
    self.__index = self
    return o
end

function Locale:t(key)
    local node = self.phrases
    for part in string.gmatch(key, '[^.]+') do
        if type(node) ~= 'table' then
            node = nil
            break
        end
        node = node[part]
    end
    if node == nil and self.warnOnMissing then
        print(('[dr-traders] missing locale: %s'):format(key))
    end
    return node or key
end
