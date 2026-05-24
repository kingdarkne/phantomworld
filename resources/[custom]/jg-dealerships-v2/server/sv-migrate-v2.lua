Migrate = Migrate or {}

Migrate.Server = Migrate.Server or {}

local function SplitString(text, delimiter)

    local result = {}

    local pattern = "([^" .. delimiter .. "]+)"

    for match in string.gmatch(text, pattern) do

        local trimmed = string.gsub(match, "^%s*(.-)%s*$", "%1")

        table.insert(result, trimmed)

    end

    return result

end

function Migrate.Server.RunV2Migration()

    print("1. Running migration-v2.sql...")

    local success = pcall(function()

        local resourcePath = GetResourcePath(GetCurrentResourceName())

        local filePath = resourcePath .. "/install/migration-v2.sql"

        local file = assert(io.open(filePath, "rb"))

        local sqlContent = file:read("*all")

        file:close()

        local sqlStatements = SplitString(sqlContent, ";")

        MySQL.transaction.await(sqlStatements)

    end)

    if not success then

        print("^1[SQL ERROR] There was an error while running migration-v2.sql. Please run it manually from the 'install' folder.^0")

        return

    end

    print("migration-v2.sql executed successfully")

    local useRGBColors = Config.UseRGBColors

    local colorOptions = Config.VehicleColourOptions

    print("2. Migrating display vehicles... (dealership_dispveh)")

    if colorOptions then

        local displayVehicles = MySQL.query.await("SELECT * FROM dealership_dispveh")

        if displayVehicles and #displayVehicles > 0 then

            for _, vehicle in ipairs(displayVehicles) do

                local colorIndex = vehicle.color and tonumber(vehicle.color)

                if colorIndex then

                    local colorOption = colorOptions[colorIndex]

                    if colorOption then

                        local newColorValue = nil

                        if useRGBColors then

                            if colorOption.hex then

                                local r, g, b = lib.math.hextorgb(colorOption.hex)

                                newColorValue = json.encode({r = r, g = g, b = b})

                            end

                        else

                            if colorOption.index then

                                newColorValue = colorOption.index

                            end

                        end

                        if newColorValue then

                            MySQL.update.await(

                                "UPDATE dealership_dispveh SET color = ? WHERE id = ?",

                                {newColorValue, vehicle.id}

                            )

                        end

                    end

                end

            end

        end

    end

    print("Migration complete")

end
