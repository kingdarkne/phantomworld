Locales = {}

function _(str, ...)
	local locale = Locales[AK4Y.Locale]

	if not locale then
		--print("Locale '" .. AK4Y.Locale .. "' not found.")

		if not Locales["en"] then
			error("Locale 'en' not found.")
		end

		locale = Locales["en"]
	end

	if locale[str] then
		return string.format(locale[str], ...)
	else
		error("Locale string '" .. str .. "' not found.")
	end
end

function _U(str, ...)
	return _(str, ...):gsub("^%l", string.upper)
end
