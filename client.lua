local menu = nil
local locationsData = {}
local _menuPool = NativeUI.CreatePool()

function parseCoords(str)
    local x, y, z = string.match(str, "([^,]+),%s*([^,]+),%s*([^,]+)")
    return vector3(tonumber(x), tonumber(y), tonumber(z))
end

function CreateTeleportMenu()
    if not locationsData or #locationsData == 0 then
        notify("~r~Teleport locations not loaded!")
        return
    end

    if menu then return end

    menu = NativeUI.CreateMenu("Teleport Menu", "~b~Choose a category")
    menu:Visible(true)
    menu:SetMenuWidthOffset(0)
    menu:RefreshIndex()
    menu:Visible(true)

    _menuPool:Add(menu)
    menu:RefreshIndex()

    for _, categoryData in ipairs(locationsData) do
        local category = categoryData.category
        local sub = _menuPool:AddSubMenu(menu, category, "Teleport to a " .. category .. " location")

        for _, locEntry in ipairs(categoryData.locations) do
            local loc = parseCoords(locEntry.coords)
            local item = NativeUI.CreateItem(locEntry.name, "Teleport to " .. locEntry.name)
            sub:AddItem(item)

            item.Activated = function(_, selectedItem)
                if selectedItem == item then
                    SetEntityCoords(PlayerPedId(), loc.x, loc.y, loc.z)
                    if locEntry.heading then
                        SetEntityHeading(PlayerPedId(), locEntry.heading)
                    end
                    notify("Teleported to ~g~" .. locEntry.name)
                    menu:Visible(false)
                end
            end
        end

        sub:RefreshIndex()
    end
end

function notify(msg)
    SetNotificationTextEntry("STRING")
    AddTextComponentSubstringPlayerName(msg)
    DrawNotification(false, true)
end

RegisterCommand("teleport", function()
    CreateTeleportMenu()
    if menu then menu:Visible(true) end
end, false)

Citizen.CreateThread(function()
    local resourceName = GetCurrentResourceName()
    local rawJson = LoadResourceFile(resourceName, "coordinates.json")

    if not rawJson then
        print("^1[TeleportMenu] ERROR: coordinates.json not found in resource '" .. resourceName .. "'^7")
    else
        locationsData = json.decode(rawJson)
        print("^2[TeleportMenu] Loaded coordinates.json successfully^7")
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        _menuPool:ProcessControl()
        _menuPool:Draw()
    end
end)
