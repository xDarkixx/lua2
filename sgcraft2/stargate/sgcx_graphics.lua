-- SGCX cinematic Stargate renderer
-- OpenComputers / Minecraft 1.7.10 / SGCraft
-- Designed as a graphical diagnostic display: no ASCII-art gate and no hash-pattern UI.

local gml = require("gml")
local unicode = require("unicode")

local graphics = {}
local version = "2.0"

if ({...})[1] == "version_check" then return version end

local C = {
    bg = 0x03070A,
    panel = 0x07141A,
    panel2 = 0x0B2028,
    frame = 0x294650,
    edge = 0x4B6872,
    cyan = 0x39D8FF,
    blue = 0x4D8DFF,
    active = 0xFF8A32,
    hot = 0xFFE7B0,
    green = 0x45E59A,
    yellow = 0xF4D35E,
    red = 0xF05262,
    white = 0xEAF8FF,
    muted = 0x78919A,
    iris = 0x9DA7AD,
    black = 0x000000
}

local BLOCK = unicode.char(0x2588)
local DIAMOND = unicode.char(0x25C6)
local RING = unicode.char(0x25C9)
local DOT = unicode.char(0x00B7)
local GLYPH = unicode.char(0x25C7)

local function point(cx, cy, rx, ry, angle)
    local r = math.rad(angle)
    return math.floor(cx + math.cos(r) * rx + 0.5), math.floor(cy + math.sin(r) * ry + 0.5)
end

local function setBg(g, c)
    g.setBackground(c)
end

local function setFg(g, c)
    g.setForeground(c)
end

local function fill(g, x, y, w, h, c)
    if w > 0 and h > 0 then
        setBg(g, c)
        g.fill(x, y, w, h, " ")
    end
end

local function text(g, x, y, s, fg, bg)
    if x < 1 or y < 1 then return end
    setBg(g, bg or C.bg)
    setFg(g, fg or C.white)
    g.set(x, y, tostring(s or ""))
end

local function fit(s, n)
    s = tostring(s or "")
    if #s <= n then return s end
    if n <= 3 then return s:sub(1, n) end
    return s:sub(1, n - 3) .. "..."
end

local glyphPatterns = {
    {"010","101","010"},{"100","111","001"},{"111","010","100"},
    {"101","010","101"},{"110","011","110"},{"011","110","011"},
    {"111","001","111"},{"101","111","101"},{"001","111","100"},
    {"110","101","011"},{"111","100","111"},{"100","111","001"}
}

local function drawGlyph(g, x, y, index, fg, bg)
    local p = glyphPatterns[((index - 1) % #glyphPatterns) + 1]
    for yy = 1, 3 do
        for xx = 1, 3 do
            if p[yy]:sub(xx, xx) == "1" then
                text(g, x + xx - 2, y + yy - 2, GLYPH, fg, bg)
            end
        end
    end
end

local function drawChevron(g, cx, cy, rx, ry, angle, active, pulse)
    local x, y = point(cx, cy, rx, ry, angle)
    local col = active and C.active or C.frame
    if pulse and active then col = C.hot end
    fill(g, x - 2, y - 1, 5, 3, C.panel)
    text(g, x - 1, y - 1, DIAMOND, col, C.panel)
    text(g, x - 1, y + 1, DIAMOND, col, C.panel)
    fill(g, x - 1, y, 3, 1, col)
end

local function drawRing(g, cx, cy, rx, ry, active, rotation)
    for ring = 0, 3 do
        for a = 0, 350, 10 do
            local x, y = point(cx, cy, rx - ring, ry - ring, a + rotation)
            local col = active and (ring < 2 and C.cyan or C.edge) or C.frame
            text(g, x, y, ring == 0 and RING or DOT, col, C.panel)
        end
    end
end

local function drawHorizon(g, cx, cy, rx, ry, phase)
    for y = -ry + 2, ry - 2 do
        local width = math.max(2, math.floor(rx * math.sqrt(math.max(0, 1 - (y * y) / (ry * ry)))))
        local start = cx - width
        local line = ""
        for i = 1, width * 2 + 1 do
            local n = (i + y + phase) % 5
            line = line .. ((n == 0 or n == 1) and "•" or " ")
        end
        text(g, start, cy + y, line, (y % 2 == 0) and C.cyan or C.blue, C.panel)
    end
end

local function drawIris(g, cx, cy, rx, ry)
    for i = 0, 7 do
        local angle = i * 45
        for r = 2, math.max(3, math.min(rx, ry) - 2) do
            local x, y = point(cx, cy, r, math.floor(r * 0.62), angle)
            text(g, x, y, BLOCK, C.iris, C.panel2)
        end
    end
    text(g, cx - 5, cy - 1, "◀ IRIS ▶", C.white, C.iris)
    text(g, cx - 5, cy + 1, "  CLOSED", C.red, C.iris)
end

local function drawSideTelemetry(t)
    local g = t.renderTarget
    local x = t.posX + 50
    local y = t.posY + 2
    local d = t.data or {}
    local state = tostring(d.state or "NO INTERFACE")
    local engaged = tonumber(d.engaged or 0) or 0
    local iris = tostring(d.iris or "Offline")

    fill(g, x, y, 17, 31, C.panel)
    fill(g, x, y, 17, 1, C.panel2)
    text(g, x + 1, y, "GATE TELEMETRY", C.cyan, C.panel2)
    text(g, x + 1, y + 2, "STATE", C.muted, C.panel)
    text(g, x + 1, y + 3, fit(state:upper(), 15), state == "Connected" and C.green or (state == "Offline" and C.red or C.white), C.panel)
    text(g, x + 1, y + 5, "CHEVRON ARRAY", C.muted, C.panel)
    for i = 1, 9 do
        local col = i <= engaged and C.active or C.frame
        fill(g, x + 1 + ((i - 1) % 3) * 5, y + 6 + math.floor((i - 1) / 3) * 2, 4, 1, col)
    end
    text(g, x + 1, y + 13, "IRIS", C.muted, C.panel)
    text(g, x + 1, y + 14, fit(iris:upper(), 15), iris == "Closed" and C.red or (iris == "Open" and C.green or C.yellow), C.panel)
    text(g, x + 1, y + 16, "LINK", C.muted, C.panel)
    text(g, x + 1, y + 17, d.remote and "REMOTE LOCKED" or "NO REMOTE", d.remote and C.green or C.muted, C.panel)
    text(g, x + 1, y + 19, "MODE", C.muted, C.panel)
    text(g, x + 1, y + 20, d.direction and tostring(d.direction):upper() or "STANDBY", C.cyan, C.panel)
    text(g, x + 1, y + 23, "LOCAL", C.muted, C.panel)
    text(g, x + 1, y + 24, fit(d.local or "UNKNOWN", 15), C.white, C.panel)
    text(g, x + 1, y + 26, "REMOTE", C.muted, C.panel)
    text(g, x + 1, y + 27, fit(d.remote or "—", 15), C.white, C.panel)
end

function graphics.createStargateComponent(gui, startX, startY)
    local backgroundColor = gml.api.findStyleProperties(gui, "fill-color-bg") or C.bg
    local totalWidth = 68
    local totalHeight = 35
    local t = gml.api.baseComponent(gui, startX, startY, totalWidth, totalHeight, "stargate", false)

    t.symbolIndex = 0
    t.symbols = {}
    t.shouldDraw = true
    t.connected = false
    t.irisClosed = false
    t.redrawRequired = false
    t.data = {}
    t.phase = 0

    t.setData = function(self, data)
        self.data = data or {}
        self.connected = self.data.state == "Connected" or self.data.state == "Opening"
        self.irisClosed = tostring(self.data.iris or "") == "Closed"
        self:draw()
    end

    t.onIrisOpened = function(self)
        self.irisClosed = false
        self:draw()
    end

    t.onIrisClosed = function(self)
        self.irisClosed = true
        self:draw()
    end

    t.onConnected = function(self, remoteAddress)
        self.connected = true
        self.data.remote = remoteAddress or self.data.remote
        if remoteAddress and self.symbolIndex == 0 then
            for i = 1, math.min(9, #remoteAddress) do
                self.lockSymbol(self, i, remoteAddress:sub(i, i), true)
            end
        end
        self:draw()
    end

    t.onDisconnected = function(self)
        self.connected = false
        self.data.remote = nil
        self:lockSymbol(0)
        self:draw()
    end

    t.onSymbolLocked = function(self, number, symbolLetter)
        self:lockSymbol(number, symbolLetter)
    end

    t.suspendDrawing = function(self)
        self.shouldDraw = false
    end

    t.activateDrawing = function(self)
        self.shouldDraw = true
        if self.redrawRequired then
            self:draw()
            self.redrawRequired = false
        end
    end

    t.lockSymbol = function(self, number, symbolLetter)
        if number == 0 then
            self.symbolIndex = 0
            self.symbols = {}
            self:draw()
            return
        end
        if number >= 1 and number <= 9 then
            self.symbolIndex = math.max(self.symbolIndex, number)
            self.symbols[number] = symbolLetter or ""
            self:draw()
        end
    end

    t.draw = function(self)
        if self:isHidden() then return end
        if not self.shouldDraw then
            self.redrawRequired = true
            return
        end

        local g = self.renderTarget
        local x = self.posX
        local y = self.posY
        local w = totalWidth
        local h = totalHeight
        local state = tostring(self.data.state or "Idle")
        local active = state ~= "Offline" and state ~= "NO INTERFACE" and state ~= "API ERROR"
        local dialing = state == "Dialling"
        local pulse = (self.phase % 4) < 2

        fill(g, x, y, w, h, C.panel)
        fill(g, x, y, w, 1, C.cyan)
        fill(g, x, y + h - 1, w, 1, C.frame)
        fill(g, x, y, 1, h, C.frame)
        fill(g, x + w - 1, y, 1, h, C.frame)
        text(g, x + 2, y, "STARGATE // SGCX", C.white, C.cyan)
        text(g, x + w - 13, y, active and "ONLINE" or "OFFLINE", active and C.green or C.red, C.cyan)

        local cx = x + 28
        local cy = y + 17
        local rx = 21
        local ry = 13

        fill(g, cx - rx + 2, cy - ry + 2, rx * 2 - 4, ry * 2 - 4, C.black)
        drawRing(g, cx, cy, rx, ry, active, dialing and ((self.phase * 14) % 360) or 0)

        for i = 1, 39 do
            local angle = -90 + (i - 1) * (360 / 39)
            local gx, gy = point(cx, cy, rx - 5, ry - 4, angle)
            local locked = self.symbols[i] ~= nil or i <= self.symbolIndex
            drawGlyph(g, gx, gy, i, locked and C.active or C.edge, C.panel)
        end

        local engaged = tonumber(self.data.engaged or self.symbolIndex or 0) or 0
        for i = 1, 9 do
            local angle = -90 + (i - 1) * 40
            drawChevron(g, cx, cy, rx + 1, ry + 1, angle, i <= engaged, pulse)
        end

        if self.irisClosed then
            drawIris(g, cx, cy, rx - 7, ry - 5)
        elseif state == "Connected" or state == "Opening" then
            drawHorizon(g, cx, cy, rx - 7, ry - 5, self.phase)
        elseif dialing then
            text(g, cx - 6, cy, "DIALING", C.cyan, C.panel)
            text(g, cx - 8, cy + 2, string.format("SEQUENCE %d/9", engaged), C.active, C.panel)
        elseif state == "Idle" then
            text(g, cx - 5, cy, "STANDBY", C.yellow, C.panel)
        elseif state == "Closing" then
            text(g, cx - 4, cy, "CLOSING", C.cyan, C.panel)
        elseif not active then
            text(g, cx - 5, cy, "NO LINK", C.red, C.panel)
        end

        local address = self.data.remote or ""
        text(g, x + 3, y + h - 3, "REMOTE", C.muted, C.panel)
        text(g, x + 11, y + h - 3, fit(address ~= "" and address or "—", 17), C.white, C.panel)
        text(g, x + 34, y + h - 3, "CHEVRONS", C.muted, C.panel)
        text(g, x + 44, y + h - 3, string.format("%d / 9", engaged), C.active, C.panel)
        drawSideTelemetry(self)

        self.visible = true
    end

    t.tick = function(self)
        self.phase = self.phase + 1
        if self.shouldDraw then self:draw() end
    end

    t:draw()
    return t
end

return graphics
