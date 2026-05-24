Interactions = Interactions or {}

Interactions.Client = Interactions.Client or {}

Interactions.Client.EntityStreaming = Interactions.Client.EntityStreaming or {}

function Interactions.Client.EntityStreaming.CreateWrapper(coords, model, options)

    local wrapper = {

        entity = nil,

        coords = coords,

        model = model,

        options = options or {},

        streamingPoint = nil,

        interactionData = nil,

        activeInteraction = nil,

        _removed = false,

        _spawning = false

    }

    return wrapper

end

function Interactions.Client.EntityStreaming.SetupStreaming(wrapper, spawnFunc, entityType, cleanupFunc)

    local coords = wrapper.coords

    local enableStreaming = wrapper.options.enableStreaming

    if not cleanupFunc then

        cleanupFunc = function(entity)

            if entityType == "ped" then

                DeletePed(entity)

            else

                DeleteEntity(entity)

            end

        end

    end

    if not enableStreaming then

        wrapper.entity = spawnFunc()

        return

    end

    wrapper.streamingPoint = lib.points.new({

        coords = vec3(coords.x, coords.y, coords.z),

        distance = Config.EntityStreamingDistance or 150.0

    })

    wrapper.streamingPoint.onEnter = function(self)

        if wrapper._removed then

            return

        end

        if wrapper._spawning then

            return

        end

        DebugPrint(

            "[EntityStreaming] onEnter: " .. tostring(wrapper.model) ..

            " entity=" .. tostring(wrapper.entity) ..

            " _spawning=" .. tostring(wrapper._spawning)

        )

        if wrapper.entity then

            if DoesEntityExist(wrapper.entity) then

                return

            else

                wrapper.entity = nil

            end

        end

        wrapper._spawning = true

        wrapper.entity = spawnFunc()

        wrapper._spawning = false

        DebugPrint(

            "[EntityStreaming] Spawned: " .. tostring(wrapper.model) ..

            " entity=" .. tostring(wrapper.entity)

        )

        if not wrapper.interactionData then

            return

        end

        local interactionData = wrapper.interactionData

        wrapper.activeInteraction = Interactions.Client.Handler.AddEntityInteraction(

            wrapper.entity,

            entityType,

            interactionData.label,

            interactionData.key,

            interactionData.onInteract,

            interactionData.distance,

            interactionData.canInteract

        )

    end

    wrapper.streamingPoint.onExit = function(self)

        if wrapper.entity and DoesEntityExist(wrapper.entity) then

            if wrapper.activeInteraction then

                Interactions.Client.Handler.RemoveEntityInteraction(wrapper.activeInteraction)

                wrapper.activeInteraction = nil

            end

            cleanupFunc(wrapper.entity)

            wrapper.entity = nil

        end

    end

end
