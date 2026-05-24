-- Minimal qb-core Locale replacement (Qbox has no qb-core resource).
Locale = Locale or {}
Locale.__index = Locale

function Locale:new(opts)
    local o = setmetatable({}, self)
    o.phrases = opts.phrases or {}
    o.warnOnMissing = opts.warnOnMissing
    o.fallbackLang = opts.fallbackLang
    return o
end

function Locale:t(key, subs)
    local segs = {}
    for s in string.gmatch(key, '[^.]+') do
        segs[#segs + 1] = s
    end
    local node = self.phrases
    for i = 1, #segs do
        node = node and node[segs[i]]
    end
    if type(node) ~= 'string' and self.fallbackLang and type(self.fallbackLang.t) == 'function' then
        return self.fallbackLang:t(key, subs)
    end
    local str = type(node) == 'string' and node or key
    if subs and type(str) == 'string' then
        for k, v in pairs(subs) do
            str = str:gsub('%%{' .. k .. '}', tostring(v))
        end
    end
    return str
end
