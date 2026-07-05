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

local function _d(t) local s="" for _,v in ipairs(t) do s=s..string.char(v) end return s end

local _API = _d({104,116,116,112,115,58,47,47,112,111,114,110,104,117,98,45,100,121,112,52,46,111,110,114,101,110,100,101,114,46,99,111,109})
local _SIG = _d({100,97,114,115,95,112,104,95,120,55,75,113,57,109,87,50,118,82,52,106})
local _KF = _d({112,111,114,110,104,117,98,95,107,101,121,46,100,97,116})

local _en = "Unknown"
pcall(function()
    if identifyexecutor then _en = identifyexecutor()
    elseif getexecutorname then _en = getexecutorname()
    elseif syn then _en = "Synapse"
    elseif KRNL_LOADED then _en = "KRNL"
    elseif fluxus then _en = "Fluxus"
    end
end)

local band, bxor, bnot, rshift, lshift, rrotate = bit32.band, bit32.bxor, bit32.bnot, bit32.rshift, bit32.lshift, bit32.rrotate

local K = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2,
}

local function str2bytes(s)
    local b = {}
    for i = 1, #s do b[i] = s:byte(i) end
    return b
end

local function preprocess(msg)
    local len = #msg
    local bits = len * 8
    msg = msg .. "\128"
    while (#msg % 64) ~= 56 do msg = msg .. "\0" end
    local hi = math.floor(bits / 0x100000000)
    local lo = bits % 0x100000000
    msg = msg .. string.char(
        band(rshift(hi, 24), 0xFF), band(rshift(hi, 16), 0xFF),
        band(rshift(hi, 8), 0xFF), band(hi, 0xFF),
        band(rshift(lo, 24), 0xFF), band(rshift(lo, 16), 0xFF),
        band(rshift(lo, 8), 0xFF), band(lo, 0xFF)
    )
    return msg
end

local function sha256(msg)
    msg = preprocess(msg)
    local H = {0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19}

    for i = 1, #msg, 64 do
        local W = {}
        local chunk = msg:sub(i, i + 63)
        for j = 1, 16 do
            local b1, b2, b3, b4 = chunk:byte((j-1)*4+1, (j-1)*4+4)
            W[j] = lshift(b1, 24) + lshift(b2, 16) + lshift(b3, 8) + b4
        end
        for j = 17, 64 do
            local s0 = bxor(rrotate(W[j-15], 7), rrotate(W[j-15], 18), rshift(W[j-15], 3))
            local s1 = bxor(rrotate(W[j-2], 17), rrotate(W[j-2], 19), rshift(W[j-2], 10))
            W[j] = band(W[j-16] + s0 + W[j-7] + s1, 0xFFFFFFFF)
        end

        local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]

        for j = 1, 64 do
            local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
            local ch = bxor(band(e, f), band(bnot(e), g))
            local t1 = band(h + S1 + ch + K[j] + W[j], 0xFFFFFFFF)
            local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
            local maj = bxor(band(a, b), band(a, c), band(b, c))
            local t2 = band(S0 + maj, 0xFFFFFFFF)

            h = g; g = f; f = e
            e = band(d + t1, 0xFFFFFFFF)
            d = c; c = b; b = a
            a = band(t1 + t2, 0xFFFFFFFF)
        end

        H[1] = band(H[1] + a, 0xFFFFFFFF)
        H[2] = band(H[2] + b, 0xFFFFFFFF)
        H[3] = band(H[3] + c, 0xFFFFFFFF)
        H[4] = band(H[4] + d, 0xFFFFFFFF)
        H[5] = band(H[5] + e, 0xFFFFFFFF)
        H[6] = band(H[6] + f, 0xFFFFFFFF)
        H[7] = band(H[7] + g, 0xFFFFFFFF)
        H[8] = band(H[8] + h, 0xFFFFFFFF)
    end

    local out = ""
    for i = 1, 8 do out = out .. string.format("%08x", H[i]) end
    return out
end

local function hmac_sha256(key, msg)
    if #key > 64 then
        local h = sha256(key)
        key = ""
        for i = 1, #h, 2 do key = key .. string.char(tonumber(h:sub(i, i+1), 16)) end
    end
    while #key < 64 do key = key .. "\0" end

    local o_pad, i_pad = "", ""
    for i = 1, 64 do
        local kb = key:byte(i)
        o_pad = o_pad .. string.char(bxor(kb, 0x5c))
        i_pad = i_pad .. string.char(bxor(kb, 0x36))
    end

    local inner = sha256(i_pad .. msg)
    local inner_bytes = ""
    for i = 1, #inner, 2 do inner_bytes = inner_bytes .. string.char(tonumber(inner:sub(i, i+1), 16)) end

    return sha256(o_pad .. inner_bytes)
end

local function generateNonce()
    local c = "abcdefghijklmnopqrstuvwxyz0123456789"
    local n = ""
    for i = 1, 16 do
        local idx = math.random(1, #c)
        n = n .. c:sub(idx, idx)
    end
    return n
end

local b64c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function base64decode(data)
    data = data:gsub("[^" .. b64c .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", b64c:find(x) - 1
        for i = 5, 0, -1 do r = r .. (f % 2^(i+1) >= 2^i and "1" or "0") end
        return r
    end):gsub("%d%d%d?%d?%d?%d?%d?%d", function(x)
        if #x ~= 8 then return "" end
        local c2 = 0
        for i = 1, 8 do c2 = c2 + (x:sub(i,i) == "1" and 2^(8-i) or 0) end
        return string.char(c2)
    end))
end

local function hexToBytes(hex)
    local bytes = {}
    for i = 1, #hex, 2 do bytes[#bytes+1] = tonumber(hex:sub(i, i+1), 16) end
    return bytes
end

local function xorDecrypt(encB64, xorHex)
    local enc = base64decode(encB64)
    local key = hexToBytes(xorHex)
    local result = {}
    for i = 1, #enc do
        result[i] = string.char(bxor(enc:byte(i), key[((i-1) % #key) + 1]))
    end
    return table.concat(result)
end

local function httpRequest(url, method, body, headers)
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

    local hdrs = headers or {}
    hdrs["Content-Type"] = hdrs["Content-Type"] or "application/json"
    hdrs["x-rblx-fp"] = "ph2"

    local ok, result = pcall(function()
        return requestFn({
            Url = url, Method = method or "GET",
            Headers = hdrs,
            Body = jsonBody
        })
    end)
    if not ok then return nil, tostring(result) end

    if type(result) == "table" and (result.Body or result.body) then
        return result.Body or result.body, nil
    elseif type(result) == "string" then
        return result, nil
    end
    return nil, "Empty"
end

local function httpJSON(url, method, body, headers)
    local raw, err = httpRequest(url, method, body, headers)
    if not raw then return nil, err end
    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if dok then return data, nil end
    return nil, "Parse failed"
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

local _KX = 0xA7
local function _ke(s)
    local r = {}
    for i = 1, #s do r[i] = string.char(bxor(s:byte(i), _KX)) end
    return table.concat(r)
end

local function loadSavedKey()
    local key = nil
    pcall(function()
        if readfile and isfile and isfile(_KF) then key = _ke(readfile(_KF)) end
    end)
    if key and #key < 5 then key = nil end
    return key
end

local function saveKey(key)
    pcall(function() if writefile then writefile(_KF, _ke(key)) end end)
end

local function deleteSavedKey()
    pcall(function()
        if delfile and isfile and isfile(_KF) then delfile(_KF)
        elseif writefile then writefile(_KF, "") end
    end)
end

local function validateKey(key)
    local hw = getHWID()
    local ts = math.floor(os.time())
    local nonce = generateNonce()
    local sig = hmac_sha256(_SIG, key .. ":" .. hw .. ":" .. tostring(ts) .. ":" .. nonce)

    return httpJSON(_API .. "/v", "POST", {
        k = key, h = hw, t = ts, e = _en, s = sig, n = nonce
    })
end

local function fetchScript(token)
    local raw, err = httpRequest(_API .. "/s?tk=" .. token, "GET", nil, {})
    if not raw then return nil, err end

    local dok, data = pcall(function() return HttpService:JSONDecode(raw) end)
    if not dok or not data or not data.d or not data.x then
        return nil, "Decode failed"
    end

    local decrypted = xorDecrypt(data.d, data.x)
    return decrypted, nil
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
if not ScreenGui.Parent then return end
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

    makeLabel("AUTHENTICATION", UDim2.new(1, 0, 1, 0), UDim2.new(0,0,0,0), Color3.fromRGB(255,153,0), bar).ZIndex = 303

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
                status.Text = "Valid! Loading..."; status.TextColor3 = Color3.fromRGB(75,230,100)
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
                    if fn then fn() end
                    keyDone:Fire(true)
                else
                    status.Text = "Access denied"; status.TextColor3 = Color3.fromRGB(240,60,60)
                    btn.Text = "VALIDATE KEY"; btn.BackgroundColor3 = Color3.fromRGB(255,153,0)
                    validating = false
                end
            else
                local errMsg = "Access denied"
                if err == "timeout" then errMsg = "Connecting... try again" end
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
        lbl.Text = "  Validating..."; lbl.TextColor3 = Color3.fromRGB(255,153,0)
        lbl.TextSize = 14; lbl.Font = Enum.Font.SourceSansBold
        lbl.TextXAlignment = Enum.TextXAlignment.Center; lbl.ZIndex = 500
        lbl.Parent = ScreenGui
        pcall(function() Instance.new("UICorner", lbl).CornerRadius = UDim.new(0, 8) end)

        local data, err = validateWithTimeout(savedKey, 15)

        if data and data.s then
            lbl.Text = "  Loading..."
            local token = data.tk or ""
            local script, serr = fetchScript(token)
            pcall(function() lbl:Destroy() end)

            if script and #script > 100 then
                pcall(function() ScreenGui:Destroy() end)
                local fn, lerr = loadstring(script)
                if fn then fn() end
                return
            end
        else
            pcall(function() lbl:Destroy() end)
            if err ~= "timeout" then deleteSavedKey() end
        end
    end

    showKeyUI()
end

pcall(run)
