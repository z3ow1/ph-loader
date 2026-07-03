if _G.RaikoHub then pcall(function() _G.RaikoHub.Destroy() end) end

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

local safeWait = nil
pcall(function() if typeof(task) == "table" and task.wait then safeWait = task.wait end end)
if not safeWait then safeWait = wait end
local safeSpawn = nil
pcall(function() if typeof(task) == "table" and task.spawn then safeSpawn = task.spawn end end)
if not safeSpawn then safeSpawn = function(fn) coroutine.wrap(fn)() end end

local KEY_API_URL = "https://pornhub-dyp4.onrender.com"
local KEY_FILE = "pornhub_key.dat"

local _executorName = "Unknown"
pcall(function()
    if identifyexecutor then _executorName = identifyexecutor()
    elseif getexecutorname then _executorName = getexecutorname()
    elseif syn then _executorName = "Synapse"
    elseif KRNL_LOADED then _executorName = "KRNL"
    elseif fluxus then _executorName = "Fluxus"
    end
end)

local function httpRequest(url, method, body)
    local requestFn = nil
    local candidates = {
        function() return request end,
        function() return http_request end,
        function() return (syn and syn.request) end,
        function() return (http and http.request) end,
        function() return (fluxus and fluxus.request) end,
    }
    for _, fn in ipairs(candidates) do
        local ok, result = pcall(fn)
        if ok and result and type(result) == "function" then requestFn = result; break end
    end
    if not requestFn then return nil, "No HTTP" end

    local jsonBody = nil
    if body then pcall(function() jsonBody = HttpService:JSONEncode(body) end) end

    local ok, result = pcall(function()
        return requestFn({
            Url = url, Method = method or "GET",
            Headers = {["Content-Type"] = "application/json", ["User-Agent"] = "PornHub/" .. _executorName},
            Body = jsonBody
        })
    end)
    if not ok then return nil, tostring(result) end

    if type(result) == "table" and (result.Body or result.body) then
        return result.Body or result.body, nil
    elseif type(result) == "string" then
        return result, nil
    end
    return nil, "Empty response"
end

local function httpJSON(url, method, body)
    local raw, err = httpRequest(url, method, body)
    if not raw then return nil, err end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if dok then return data, nil end
    return nil, "JSON parse failed"
end

local function getHWID()
    local hwid = nil
    local methods = {
        function() if gethwid then return gethwid() end end,
        function() if getexecutorhwid then return getexecutorhwid() end end,
        function() if syn and syn.hw_id then return syn.hw_id() end end,
        function() if get_hwid then return get_hwid() end end,
        function() return tostring(game:GetService("RbxAnalyticsService"):GetClientId()) end,
        function()
            local id = HttpService:GenerateGUID(false)
            if writefile and readfile and isfile then
                local f = "pornhub_hwid.dat"
                if isfile(f) then return readfile(f) end
                writefile(f, id)
            end
            return id
        end,
    }
    for _, fn in ipairs(methods) do
        local ok, r = pcall(fn)
        if ok and r and r ~= "" and r ~= "unknown" then hwid = tostring(r); break end
    end
    return hwid or "fb_" .. tostring(LocalPlayer.UserId)
end

local function loadSavedKey()
    local key = nil
    pcall(function()
        if readfile and isfile and isfile(KEY_FILE) then key = readfile(KEY_FILE) end
    end)
    return key
end

local function saveKey(key)
    pcall(function() if writefile then writefile(KEY_FILE, key) end end)
end

local function deleteSavedKey()
    pcall(function()
        if delfile and isfile and isfile(KEY_FILE) then delfile(KEY_FILE)
        elseif writefile then writefile(KEY_FILE, "") end
    end)
end

local function validateKey(key)
    return httpJSON(KEY_API_URL .. "/v", "POST", {
        k = key, h = getHWID(), t = math.floor(os.time()), e = _executorName
    })
end

local function fetchScript(token)
    local raw, err = httpRequest(KEY_API_URL .. "/s?tk=" .. token, "GET")
    return raw, err
end

local function validateWithTimeout(key, sec)
    local result, resultErr, done = nil, nil, false
    safeSpawn(function()
        local ok, d, e = pcall(function() return validateKey(key) end)
        if ok then result, resultErr = d, e else resultErr = tostring(d) end
        done = true
    end)
    local start = tick()
    while not done and (tick() - start) < (sec or 15) do safeWait(0.1) end
    if not done then return nil, "timeout" end
    return result, resultErr
end

-- GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PH_Loader"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999

local parented = false
local pMethods = {
    function() if type(gethui) == "function" then local c = gethui(); if c then ScreenGui.Parent = c; return true end end end,
    function() if type(get_hidden_gui) == "function" then local c = get_hidden_gui(); if c then ScreenGui.Parent = c; return true end end end,
    function() ScreenGui.Parent = game:GetService("CoreGui"); return ScreenGui.Parent ~= nil end,
    function() if cloneref then ScreenGui.Parent = cloneref(game:GetService("CoreGui")); return ScreenGui.Parent ~= nil end end,
    function() ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui", 3); return ScreenGui.Parent ~= nil end,
}
for _, fn in ipairs(pMethods) do
    if parented then break end
    local ok, r = pcall(fn)
    if ok and r then parented = true end
end
if not ScreenGui.Parent then warn("[PornHub] No GUI parent"); return end
pcall(function() if syn and syn.protect_gui then syn.protect_gui(ScreenGui) end end)
pcall(function() if protect_gui then protect_gui(ScreenGui) end end)

local function makeLabel(text, size, pos, color, parent)
    local l = Instance.new("TextLabel", parent)
    l.Size = size; l.Position = pos
    l.BackgroundTransparency = 1; l.Text = text
    l.TextColor3 = color or Color3.fromRGB(255, 153, 0)
    l.TextSize = 14; l.Font = Enum.Font.SourceSansBold
    l.TextXAlignment = Enum.TextXAlignment.Center; l.ZIndex = 303
    return l
end

local function showKeyUI()
    local keyDone = Instance.new("BindableEvent")

    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.4
    overlay.BorderSizePixel = 0; overlay.ZIndex = 300
    overlay.Parent = ScreenGui

    local kf = Instance.new("Frame")
    kf.Size = UDim2.new(0, 380, 0, 0)
    kf.Position = UDim2.new(0.5, -190, 0.5, -110)
    kf.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    kf.BorderSizePixel = 0; kf.ClipsDescendants = true; kf.ZIndex = 301
    kf.Parent = ScreenGui
    Instance.new("UICorner", kf).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", kf)
    stroke.Color = Color3.fromRGB(255, 153, 0); stroke.Thickness = 2; stroke.Transparency = 1

    local bar = Instance.new("Frame", kf)
    bar.Size = UDim2.new(1, 0, 0, 36); bar.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
    bar.BorderSizePixel = 0; bar.ZIndex = 302
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 12)
    local barFix = Instance.new("Frame", bar)
    barFix.Size = UDim2.new(1, 0, 0, 14); barFix.Position = UDim2.new(0, 0, 1, -14)
    barFix.BackgroundColor3 = Color3.fromRGB(8, 8, 8); barFix.BorderSizePixel = 0; barFix.ZIndex = 302

    makeLabel("PORNHUB AUTHENTICATION", UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), Color3.fromRGB(255,153,0), bar).ZIndex = 303

    makeLabel("Enter your license key", UDim2.new(1,-40,0,20), UDim2.new(0,20,0,48), Color3.fromRGB(140,140,140), kf).TextSize = 13

    local inputBg = Instance.new("Frame", kf)
    inputBg.Size = UDim2.new(1, -40, 0, 36); inputBg.Position = UDim2.new(0, 20, 0, 76)
    inputBg.BackgroundColor3 = Color3.fromRGB(22, 22, 22); inputBg.BorderSizePixel = 0; inputBg.ZIndex = 303
    Instance.new("UICorner", inputBg).CornerRadius = UDim.new(0, 8)
    local iStroke = Instance.new("UIStroke", inputBg); iStroke.Color = Color3.fromRGB(35,35,35); iStroke.Thickness = 1

    local input = Instance.new("TextBox", inputBg)
    input.Size = UDim2.new(1, -16, 1, 0); input.Position = UDim2.new(0, 8, 0, 0)
    input.BackgroundTransparency = 1; input.Text = ""; input.PlaceholderText = "XXXX-XXXX-XXXX-XXXX"
    input.PlaceholderColor3 = Color3.fromRGB(60,60,60); input.TextColor3 = Color3.fromRGB(255,255,255)
    input.TextSize = 15; input.Font = Enum.Font.Code; input.ClearTextOnFocus = false; input.ZIndex = 304

    local status = makeLabel("", UDim2.new(1,-40,0,16), UDim2.new(0,20,0,116), Color3.fromRGB(240,60,60), kf)
    status.TextSize = 12; status.Font = Enum.Font.SourceSans; status.TextXAlignment = Enum.TextXAlignment.Left

    local btn = Instance.new("TextButton", kf)
    btn.Size = UDim2.new(1, -40, 0, 34); btn.Position = UDim2.new(0, 20, 0, 138)
    btn.BackgroundColor3 = Color3.fromRGB(255, 153, 0); btn.BorderSizePixel = 0
    btn.Text = "VALIDATE KEY"; btn.TextColor3 = Color3.fromRGB(0,0,0)
    btn.TextSize = 14; btn.Font = Enum.Font.SourceSansBold; btn.ZIndex = 303; btn.AutoButtonColor = false
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    TweenService:Create(kf, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 380, 0, 190)}):Play()
    safeWait(0.15)
    TweenService:Create(stroke, TweenInfo.new(0.2), {Transparency = 0}):Play()

    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,180,50)}):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(255,153,0)}):Play() end)
    input.Focused:Connect(function() TweenService:Create(iStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(255,153,0)}):Play() end)
    input.FocusLost:Connect(function() TweenService:Create(iStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(35,35,35)}):Play() end)

    local validating = false
    local function doValidate()
        if validating then return end
        local key = string.gsub(input.Text, "%s+", "")
        if key == "" then status.Text = "Enter a key"; status.TextColor3 = Color3.fromRGB(240,60,60); return end

        validating = true
        btn.Text = "VALIDATING..."; btn.BackgroundColor3 = Color3.fromRGB(140,140,140)
        status.Text = "Connecting..."; status.TextColor3 = Color3.fromRGB(140,140,140)

        safeSpawn(function()
            local data, err = validateWithTimeout(key, 15)

            if data and data.s then
                status.Text = "Valid! Loading script..."; status.TextColor3 = Color3.fromRGB(75,230,100)
                btn.Text = "ACCESS GRANTED"; btn.BackgroundColor3 = Color3.fromRGB(75,230,100)
                saveKey(key)
                safeWait(0.5)

                local token = data.tk or ""
                local script, serr = fetchScript(token)
                if script and #script > 100 then
                    pcall(function() kf:Destroy() end)
                    pcall(function() overlay:Destroy() end)
                    pcall(function() ScreenGui:Destroy() end)
                    local fn, lerr = loadstring(script)
                    if fn then fn() else warn("[PornHub] Load error: " .. tostring(lerr)) end
                    keyDone:Fire(true)
                else
                    status.Text = "Script fetch failed"; status.TextColor3 = Color3.fromRGB(240,60,60)
                    btn.Text = "VALIDATE KEY"; btn.BackgroundColor3 = Color3.fromRGB(255,153,0)
                    validating = false
                end
            else
                local errMsg = "Invalid key"
                if err == "timeout" then errMsg = "Server waking up... try again"
                elseif data and data.e == "expired" then errMsg = "Key expired"
                elseif data and data.e == "paused" then errMsg = "Key paused"
                elseif not data then errMsg = err or "Connection failed" end
                status.Text = errMsg; status.TextColor3 = Color3.fromRGB(240,60,60)
                btn.Text = "VALIDATE KEY"; btn.BackgroundColor3 = Color3.fromRGB(255,153,0)
                TweenService:Create(iStroke, TweenInfo.new(0.15), {Color = Color3.fromRGB(240,60,60)}):Play()
                safeWait(0.5)
                TweenService:Create(iStroke, TweenInfo.new(0.3), {Color = Color3.fromRGB(35,35,35)}):Play()
                validating = false
            end
        end)
    end

    btn.MouseButton1Click:Connect(doValidate)
    input.FocusLost:Connect(function(enter) if enter then doValidate() end end)

    keyDone.Event:Wait()
    keyDone:Destroy()
    return true
end

local function run()
    local savedKey = loadSavedKey()
    if savedKey and savedKey ~= "" then
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0, 260, 0, 34)
        lbl.Position = UDim2.new(0.5, -130, 0.5, -17)
        lbl.BackgroundColor3 = Color3.fromRGB(10, 10, 10); lbl.BorderSizePixel = 0
        lbl.Text = "  PornHub - Validating..."; lbl.TextColor3 = Color3.fromRGB(255,153,0)
        lbl.TextSize = 14; lbl.Font = Enum.Font.SourceSansBold
        lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.ZIndex = 500
        lbl.Parent = ScreenGui
        pcall(function() Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8) end)

        local data, err = validateWithTimeout(savedKey, 15)

        if data and data.s then
            lbl.Text = "  PornHub - Loading..."
            local token = data.tk or ""
            local script, serr = fetchScript(token)
            pcall(function() lbl:Destroy() end)

            if script and #script > 100 then
                pcall(function() ScreenGui:Destroy() end)
                local fn, lerr = loadstring(script)
                if fn then fn() else warn("[PornHub] Load error: " .. tostring(lerr)) end
                return
            else
                warn("[PornHub] Script fetch failed: " .. tostring(serr))
            end
        else
            pcall(function() lbl:Destroy() end)
            if err ~= "timeout" then deleteSavedKey() end
        end
    end

    showKeyUI()
end

run()
