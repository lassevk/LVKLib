LVK = CreateFrame("Frame")

LVK.ColorCodes = {
    ["r"] = "|cFFFF0000",
    ["R"] = "|cFFFF8080",
    ["g"] = "|cFF00FF00",
    ["G"] = "|cFF80FF80",
    ["b"] = "|cFF0000FF",
    ["B"] = "|cFF8080FF",
    ["w"] = "|cFFFFFFFF",
    ["W"] = "|cFFFFFFFF",
    ["y"] = "|cFFFFFF00",
    ["Y"] = "|cFFFFFF80",
    ["<"] = "|r"
}

function LVK:Colorize(msg)
    local result = ""
    local i = 1
    local oldI = 0
    while i <= #msg do
        if oldI == i then
            break
        end
        oldI = i

        local c = msg:sub(i, i)

        if c == "|" then
            local code = ""

            while i < #msg do
                i = i + 1
                c = msg:sub(i, i)
                if c == "|" then
                    i = i + 1
                    break
                end
                code = code .. c
            end
            result = result .. (LVK.ColorCodes[code] or ("|" .. code .. "|"))
        else
            result = result .. c
            i = i + 1
        end
    end
    return result
end

function LVK:Print(msg, ...)
    if #{...} > 0 then
        msg = string.format(msg, ...)
    end
    print(self:Colorize(msg))
end

function LVK:DebugPrint(msg, ...)
    if not LVKSavedData.debug then
        return
    end
    self:Print("|y|DEBUG: |<|" .. msg, ...)
end

function LVK:PrintAddonLoaded(addon)
    self:Print("|y|%s|<| version |g|%s|<| loaded", GetAddOnMetadata(addon, "Title"), GetAddOnMetadata(addon, "Version") .. "|<|")
end

function LVK:Dump(obj, name)
    local formatString = function(str)
        local output = ""
        for i = 1, #str do
            local c = str:sub(i, i)
            if c == "\"" then
                output = output .. "\\" .. c
            elseif c == "\n" then
                output = output .. "\\n"
            elseif c == "\r" then
                output = output .. "\\r"
            elseif c == "\\" then
                output = output .. "\\\\"
            elseif c == "\a" then
                output = output .. "\\a"
            elseif c == "\b" then
                output = output .. "\\b"
            elseif c == "\f" then
                output = output .. "\\f"
            elseif c == "\t" then
                output = output .. "\\t"
            elseif c == "\v" then
                output = output .. "\\v"
            else
                output = output .. c
            end
        end
        return "\"" .. output .. "\""
    end
    local toString = function(value)
        if (type(value) == string) then
            return formatString(value)
        else
            return tostring(value)
        end
    end

    local dump

    local dumpers = {
        ["string"] = function(prefix, str, indent)
            self:Print("%s = %s", prefix, formatString(str))
        end,
        ["number"] = function(prefix, num, indent)
            if num == math.floor(num) then
                self:Print("%s = %d (0x%x)", prefix, num, num)
            else
                self:Print("%s = %f", prefix, num)
            end
        end,
        ["table"] = function(prefix, tbl, indent)
            self:Print(prefix)
            self:Print("%s{", indent:sub(1, #indent - 2))
            local any = false
            for key, value in pairs(tbl) do
                dump(value, toString(key), indent .. "  ")
                any = true
            end
            if not any then
                for key, value in ipairs(tbl) do
                    dump(value, toString(key), indent .. "  ")
                end
            end
            self:Print("%s}", indent:sub(1, #indent - 2))
        end,
    }

    dump = function(obj, name, indent)
        if type(name) ~= "string" then
            name = tostring(name)
        end
        local prefix = string.format("%s%s: %s", indent, name, type(obj))

        dumper = dumpers[type(obj)]
        if dumper ~= nil then
            dumper(prefix, obj, indent .. "  ")
        else
            self:Print("%s = %s", prefix, tostring(obj))
        end
    end

    dump(obj, name or "value", "")
end

function LVK:DebugDump(obj, name)
    if not LVKSavedData.debug then
        return
    end
    self:Dump(obj, self:Colorize("|y|DEBUG: |<|" .. (name or "value")))
end

function LVK:LoadSavedData(data)
    if data == nil then
        return {
            version = 1,
            debug = false
        }
    end

    return data
end

function LVK:SetDebug(flag)
    LVKSavedData.debug = flag
    if LVKSavedData.debug then
        self:Print("|y|LVKLib|<| |g|Debugging|<| is now |y|enabled|<|")
    else
        self:Print("|y|LVKLib|<| |g|Debugging|<| is now |y|disabled|<|")
    end
end

function LVK:Loaded()
    LVKSavedData = self:LoadSavedData(LVKSavedData)
    self:PrintAddonLoaded("LVKLib")
    self:DebugDump(LVKSavedData, "LVKSavedData")
end

function LVK:ADDON_LOADED(addon)
    if addon == "LVKLib" then
        LVK:Loaded()
        self:UnregisterEvent("ADDON_LOADED")
    end
end

function LVK:Init()
    self:RegisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...);
    end);
end

LVK:Init()