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

function LVK:Colorize(msg, ...)
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

    if #{...} > 0 then
        result = string.format(result, ...)
    end
    return result
end

function LVK:Print(msg, ...)
    DEFAULT_CHAT_FRAME:AddMessage(self:Colorize(msg, ...))
end

function LVK:ErrorPrint(msg, ...)
    self:Print("|r|Error: |<|" .. msg, ...)
end

function LVK:DebugPrint(msg, ...)
    if not LVKSavedData.debug then
        return
    end
    self:Print("|y|DEBUG: |<|" .. msg, ...)
end

function LVK:PrintAddonLoaded(addon)
    self:Print("|y|%s|<| version |g|%s|<| loaded", GetAddOnMetadata(addon, "Title"), GetAddOnMetadata(addon, "Version"))
end

function LVK:FormatString(str)
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
        elseif c == '|' then
            output = output .. "||"
        else
            output = output .. c
        end
    end
    return "\"" .. output .. "\""
end

function LVK:GetItemString(itemLink)
    return string.match(itemLink, "item[%-?%d:]+")
end

function LVK:Dump(obj, name)
    local already = {}

    local toString = function(value)
        if (type(value) == string) then
            return self:FormatString(value)
        else
            return tostring(value)
        end
    end

    local dump

    local dumpers = {
        ["string"] = function(prefix, str, indent)
            self:Print("%s = %s", prefix, self:FormatString(str))
        end,
        ["number"] = function(prefix, num, indent)
            if num == math.floor(num) then
                self:Print("%s = %d (0x%x)", prefix, num, num)
            else
                self:Print("%s = %f", prefix, num)
            end
        end,
        ["table"] = function(prefix, tbl, indent)
            if already[tbl] then
                self:Print("%s = %s (already dumped)", prefix, toString(tbl))
                return
            end
            already[obj] = true

            self:Print("%s = %s", prefix, toString(tbl))
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

        if obj == nil then
            self:Print("%s = nil", prefix)
            return
        end

        dumper = dumpers[type(obj)]
        if dumper ~= nil then
            dumper(prefix, obj, indent .. "  ")
        else
            if already[obj] then
                self:Print("%s = %s (already dumped)", prefix, toString(obj))
                return
            end
            already[obj] = true
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
end

function LVK:ADDON_LOADED(addon)
    if addon ~= "LVKLib" then
        return
    end

    LVK:Loaded()
    self:UnregisterEvent("ADDON_LOADED")
end

function LVK:Init()
    self:RegisterEvent("ADDON_LOADED")
    self:SetScript("OnEvent", function(self, event, ...)
        self[event](self, ...);
    end);
end

function LVK:Test()
    local a = { }
    a["x"] = a
    self:Dump(a)
end

function LVK:SplitSlash(str)
    local result = { }

    local quote = " "

    local i = 1
    local oldI = 0
    local current = ""
    while i <= #str do
        if oldI == i then
            self:DebugPrint("SplitSlash terminated early, did not advance from position %d in %s", i, self:FormatString(str))
            break
        end
        oldI = i

        local c = str:sub(i, i)
        if quote ~= " " then
            if c == quote then
                quote = " "
                i = i + 1
            else
                current = current .. c
                i = i + 1
            end
        else
            if c == "\"" or c == "\'" then
                quote = c
                i = i + 1
            elseif c == " " then
                if current ~= "" then
                    table.insert(result, current)
                    current = ""
                end
                i = i + 1
            else
                current = current .. c
                i = i + 1
            end
        end
    end
    if current ~= "" then
        table.insert(result, current)
    end
    return result
end

function LVK:ExecuteSlash(str, frame)
    local parts = self:SplitSlash(str)

    if #parts >= 1 then
        local name = string.upper(parts[1]):sub(1, 1) .. string.lower(parts[1]:sub(2, #parts[1]))
        local functionName = "Slash_" .. name

        local exceptFirst = {unpack(parts)}
        table.remove(exceptFirst, 1)
    
        if frame[functionName] then
            frame[functionName](frame, exceptFirst)
            return true
        end

        if frame["Slash_Default"] then
            frame["Slash_Default"](frame, exceptFirst)
            return true
        end

        if frame["Slash_Help"] then
            self:Print("|r|Invalid command: |<| '|y|%s|<|', use '|y|help|<|' command for help on syntax and usage", str)
        end

        return false
    end
end

function LVK:ShowHelp(tbl, key)
    local help = tbl[key]
    if not help then
        self:Error("No help key '|y|%s|<|'", key)
        return
    end

    if type(help) == "table" then
        for _, v in ipairs(help) do
            self:Print(v)
        end
    else
        self:Print(help)
    end
end

LVK:Init()