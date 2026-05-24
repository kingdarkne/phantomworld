Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.Handler = Interactions.Client.Handler or {}

local interactionMethod = Config.InteractionMethod or "textui"

local interactionIdCounter = 0

local function generateInteractionId(prefix)

    interactionIdCounter = interactionIdCounter + 1

    return string.format("%s_%d_%d", prefix, GetGameTimer(), interactionIdCounter)

end

function Interactions.Client.SetEntityOutline(entity, r, g, b, a)

    if not DoesEntityExist(entity) then

        return

    end

    SetEntityDrawOutlineColor(r, g, b, a)

    SetEntityDrawOutlineShader(1)

    SetEntityDrawOutline(entity, true)

end

function Interactions.Client.Handler.AddEntityInteraction(entity, entityType, label, key, callback, distance, canInteract)

    if canInteract then

        if not canInteract() then

            return {}

        end

    end

    distance = distance or 2.5

    local entityHandle = entity

    if type(entity) == "table" then

        if entity.entity then

            entityHandle = entity.entity

        end

    end

    local interactionId = "entity_" .. entityHandle

    if interactionMethod == "target" then

        Framework.Client.RegisterTarget("entity", nil, entityHandle, label, callback)

        return {

            method = "target",

            type = "entity",

            entity = entityHandle,

            id = interactionId

        }

    elseif interactionMethod == "3dtextui" then

        Framework.Client.TextUI3dAdd("entity", nil, entityHandle, label, callback)

        return {

            method = "3dtextui",

            type = "entity",

            entity = entityHandle,

            id = interactionId

        }

    elseif interactionMethod == "radial" then

        local point = lib.points.new({

            coords = GetEntityCoords(entityHandle),

            radius = distance,

            distance = distance,

            entity = entityHandle,

            interactionId = interactionId

        })

        function point:onEnter()

            Framework.Client.RadialMenuAdd(self.interactionId, label, callback)

        end

        function point:onExit()

            Framework.Client.RadialMenuRemove(self.interactionId)

        end

        function point:nearby()

            if DoesEntityExist(self.entity) then

                self.coords = GetEntityCoords(self.entity)

            end

        end

        return {

            method = "radial",

            type = "entity",

            entity = entityHandle,

            point = point,

            id = interactionId

        }

    elseif interactionMethod == "textui" then

        local point = lib.points.new({

            coords = GetEntityCoords(entityHandle),

            radius = distance,

            distance = distance,

            entity = entityHandle,

            interactionId = interactionId,

            canInteract = canInteract,

            _removed = false

        })

        function point:onEnter()

            if self._removed then

                return

            end

            if self.canInteract then

                if not self.canInteract() then

                    return

                end

            end

            Interactions.Client.TextUIManager.Show(

                self.interactionId,

                label,

                key,

                callback

            )

        end

        function point:onExit()

            Interactions.Client.TextUIManager.Hide(self.interactionId)

        end

        function point:nearby()

            if self._removed then

                return

            end

            if DoesEntityExist(self.entity) then

                self.coords = GetEntityCoords(self.entity)

            end

            if self.canInteract then

                if self.canInteract() then

                    if not Interactions.Client.TextUIManager.IsShowingId(self.interactionId) then

                        Interactions.Client.TextUIManager.Show(

                            self.interactionId,

                            label,

                            key,

                            callback

                        )

                    end

                else

                    Interactions.Client.TextUIManager.Hide(self.interactionId)

                end

            end

        end

        return {

            method = "textui",

            type = "entity",

            entity = entityHandle,

            point = point,

            id = interactionId,

            canInteract = canInteract

        }

    end

    return {}

end

function Interactions.Client.Handler.AddPointInteraction(coords, distance, label, key, callback, zonePoints, canInteract)

    distance = distance or 2.5

    if canInteract then

        if not canInteract() then

            return {}

        end

    end

    local interactionCoords = coords

    if zonePoints then

        interactionCoords = Utils.Client.GetPolygonCenter(zonePoints)

    end

    if interactionMethod == "target" then

        local targetId = Framework.Client.RegisterTarget("coords", interactionCoords, nil, label, callback)

        if not targetId then

            print("[Interactions.Client.Handler] Failed to add target for coords:", interactionCoords)

            return {}

        end

        return {

            method = "target",

            type = "coords",

            coords = interactionCoords,

            id = targetId

        }

    elseif interactionMethod == "3dtextui" then

        local textUIId = Framework.Client.TextUI3dAdd("coords", interactionCoords, nil, label, callback)

        if not textUIId then

            print("[Interactions.Client.Handler] Failed to add 3dtextui for coords:", interactionCoords)

            return {}

        end

        return {

            method = "3dtextui",

            type = "coords",

            coords = interactionCoords,

            id = textUIId,

            removed = false

        }

    elseif interactionMethod == "radial" then

        local interactionId = generateInteractionId("radial")

        local point = lib.points.new({

            coords = interactionCoords,

            radius = distance,

            distance = distance,

            interactionId = interactionId

        })

        function point:onEnter()

            Framework.Client.RadialMenuAdd(self.interactionId, label, callback)

        end

        function point:onExit()

            Framework.Client.RadialMenuRemove(self.interactionId)

        end

        return {

            method = "radial",

            type = "coords",

            coords = interactionCoords,

            point = point,

            id = interactionId

        }

    elseif interactionMethod == "textui" then

        local interactionId = generateInteractionId("textui")

        local point = lib.points.new({

            coords = interactionCoords,

            radius = distance,

            distance = distance,

            interactionId = interactionId,

            canInteract = canInteract,

            _removed = false

        })

        function point:onEnter()

            if self._removed then

                return

            end

            if self.canInteract then

                if not self.canInteract() then

                    return

                end

            end

            Interactions.Client.TextUIManager.Show(

                self.interactionId,

                label,

                key,

                callback

            )

        end

        function point:onExit()

            Interactions.Client.TextUIManager.Hide(self.interactionId)

        end

        function point:nearby()

            if self._removed then

                return

            end

            if self.canInteract then

                if self.canInteract() then

                    if not Interactions.Client.TextUIManager.IsShowingId(self.interactionId) then

                        Interactions.Client.TextUIManager.Show(

                            self.interactionId,

                            label,

                            key,

                            callback

                        )

                    end

                else

                    Interactions.Client.TextUIManager.Hide(self.interactionId)

                end

            end

        end

        return {

            method = "textui",

            type = "coords",

            coords = interactionCoords,

            point = point,

            id = interactionId,

            canInteract = canInteract

        }

    end

    return {}

end

function Interactions.Client.Handler.RemoveEntityInteraction(interaction)

    if not interaction then

        return

    end

    if interaction.method == "target" then

        if interaction.type == "entity" then

            if DoesEntityExist(interaction.entity) then

                Framework.Client.RemoveTarget("entity", nil, interaction.entity)

            end

        end

    elseif interaction.method == "3dtextui" then

        if interaction.type == "entity" then

            if DoesEntityExist(interaction.entity) then

                Framework.Client.TextUI3dRemove("entity", nil, interaction.entity)

            end

        end

    elseif interaction.method == "radial" then

        if interaction.point then

            if interaction.id then

                Framework.Client.RadialMenuRemove(interaction.id)

            end

            interaction.point:remove()

        end

    elseif interaction.method == "textui" then

        if interaction.point then

            interaction.point._removed = true

            if interaction.id then

                Interactions.Client.TextUIManager.Hide(interaction.id)

            end

            interaction.point:remove()

        end

    end

end

function Interactions.Client.Handler.RemovePointInteraction(interaction)

    if not interaction then

        return

    end

    if interaction.method == "target" then

        if interaction.type == "coords" then

            if interaction.id then

                Framework.Client.RemoveTarget("coords", interaction.id, nil)

            end

        end

    elseif interaction.method == "3dtextui" then

        if interaction.type == "coords" then

            if interaction.id then

                if interaction.removed then

                    return

                end

                local idType = type(interaction.id)

                if idType ~= "number" and idType ~= "string" then

                    print("[Interactions.Client.Handler] Invalid 3dtextui ID type:", idType, interaction.id)

                    return

                end

                Framework.Client.TextUI3dRemove("coords", interaction.id, nil)

                interaction.removed = true

            end

        end

    elseif interaction.method == "radial" then

        if interaction.point then

            if interaction.id then

                Framework.Client.RadialMenuRemove(interaction.id)

            end

            interaction.point:remove()

        end

    elseif interaction.method == "textui" then

        if interaction.point then

            interaction.point._removed = true

            if interaction.id then

                Interactions.Client.TextUIManager.Hide(interaction.id)

            end

            interaction.point:remove()

        end

    end

end
