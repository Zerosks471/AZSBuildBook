-- AZS Build Book - class build guide (Spell Meter look)
-- Lua 5.0: keep upvalues under 32 by using one module table.
-- /azsbuild  /buildbook  /azsb

local M = {}

M.SOLID = "Interface\\Buttons\\WHITE8X8"
M.FONT = "Fonts\\FRIZQT__.TTF"
M.W = 320
M.H = 380
M.BODY_ROWS = 12
M.PAGE = 1
M.classIdx = 1
M.buildId = nil
M.frame = nil
M.launcher = nil
M.escBtn = nil
M.escInjected = nil
M.inited = nil
M.rows = {}
M.PAGES = { "Overview", "Talents", "Cards", "Jewelry" }
M.ADDON = "AZSBuildBook"

M.C = {
	gold = { 1.00, 0.86, 0.50 },
	brd = { 0.78, 0.58, 0.22 },
	hdr = { 0.34, 0.20, 0.06 },
	bg = { 0.05, 0.04, 0.03, 0.90 },
	row = { 0.10, 0.08, 0.05 },
	muted = { 0.62, 0.58, 0.50 },
	text = { 0.92, 0.88, 0.78 },
	red = { 1.00, 0.45, 0.40 },
	green = { 0.45, 0.95, 0.55 },
}

function M.say(msg)
	if DEFAULT_CHAT_FRAME then
		DEFAULT_CHAT_FRAME:AddMessage("|cffffd100AZS Build Book:|r " .. tostring(msg))
	end
end

function M.face(fs, size)
	if fs and fs.SetFont then
		fs:SetFont(M.FONT, size or 11, "OUTLINE")
	end
end

function M.panelBackdrop()
	return {
		bgFile = M.SOLID,
		edgeFile = M.SOLID,
		tile = false,
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 },
	}
end

function M.roundBackdrop()
	return {
		bgFile = M.SOLID,
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = false,
		tileSize = 16,
		edgeSize = 12,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	}
end

function M.S(v)
	if v == nil then
		return ""
	end
	return tostring(v)
end

function M.listLen(t)
	if type(t) ~= "table" then
		return 0
	end
	local n = 0
	while t[n + 1] ~= nil do
		n = n + 1
	end
	return n
end

function M.ensureDB()
	if type(AZSBuildBookDB) ~= "table" then
		AZSBuildBookDB = {}
	end
	return AZSBuildBookDB
end

function M.saveClass()
	local db = M.ensureDB()
	if type(AZSBuildBook_ClassOrder) == "table" and AZSBuildBook_ClassOrder[M.classIdx] then
		db.lastClass = AZSBuildBook_ClassOrder[M.classIdx]
	end
end

function M.detectClass()
	local z = AZS_ZONE
	if type(z) == "table" and type(z.class) == "string" and z.class ~= "" then
		local c = string.upper(z.class)
		if type(AZSBuildBook_Builds) == "table" and AZSBuildBook_Builds[c] then
			return c
		end
	end
	local db = M.ensureDB()
	if type(db.lastClass) == "string" and type(AZSBuildBook_Builds) == "table" and AZSBuildBook_Builds[db.lastClass] then
		return db.lastClass
	end
	local _, class = UnitClass("player")
	if class and type(AZSBuildBook_Builds) == "table" and AZSBuildBook_Builds[class] then
		return class
	end
	if type(AZSBuildBook_ClassOrder) == "table" then
		return AZSBuildBook_ClassOrder[1]
	end
	return "WARRIOR"
end

function M.classIndexOf(class)
	local i = 1
	while AZSBuildBook_ClassOrder and AZSBuildBook_ClassOrder[i] do
		if AZSBuildBook_ClassOrder[i] == class then
			return i
		end
		i = i + 1
	end
	return 1
end

function M.currentClassData()
	if type(AZSBuildBook_Builds) ~= "table" or type(AZSBuildBook_ClassOrder) ~= "table" then
		return nil
	end
	local key = AZSBuildBook_ClassOrder[M.classIdx]
	return AZSBuildBook_Builds[key], key
end

function M.currentBuild()
	local data = M.currentClassData()
	if not data or type(data.builds) ~= "table" then
		return nil
	end
	local id = M.buildId or data.default
	return data.builds[id], id, data
end

function M.setChipActive(btn, on)
	if not btn then
		return
	end
	local C = M.C
	btn.isActive = on
	if on then
		btn:SetBackdropColor(C.hdr[1], C.hdr[2], C.hdr[3], 0.95)
		btn:SetBackdropBorderColor(C.brd[1], C.brd[2], C.brd[3], 1)
		if btn.label then
			btn.label:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
		end
	else
		btn:SetBackdropColor(0.12, 0.08, 0.04, 0.85)
		btn:SetBackdropBorderColor(0.40, 0.30, 0.14, 1)
		if btn.label then
			btn.label:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
		end
	end
end

function M.makeChip(parent, w, h, text)
	local C = M.C
	local b = CreateFrame("Button", nil, parent)
	b:SetWidth(w)
	b:SetHeight(h)
	b:SetBackdrop(M.panelBackdrop())
	b:SetBackdropColor(0.12, 0.08, 0.04, 0.85)
	b:SetBackdropBorderColor(0.40, 0.30, 0.14, 1)
	local fs = b:CreateFontString(nil, "OVERLAY")
	M.face(fs, 10)
	fs:SetPoint("CENTER", b, "CENTER", 0, 0)
	fs:SetText(text or "")
	fs:SetTextColor(C.text[1], C.text[2], C.text[3])
	b.label = fs
	b:SetScript("OnEnter", function()
		local g = M.C.gold
		this:SetBackdropBorderColor(g[1], g[2], g[3], 1)
	end)
	b:SetScript("OnLeave", function()
		M.setChipActive(this, this.isActive)
	end)
	return b
end

function M.clearRows()
	local i = 1
	while i <= M.BODY_ROWS do
		local row = M.rows[i]
		if row then
			row:Hide()
			row.title:SetText("")
			row.detail:SetText("")
			row.rank:SetText("")
		end
		i = i + 1
	end
end

function M.showRow(i, rank, title, detail, tint)
	local row = M.rows[i]
	if not row then
		return
	end
	local C = M.C
	row:Show()
	if rank and rank ~= "" then
		row.rank:SetText(rank)
		row.rank:Show()
	else
		row.rank:SetText("")
		row.rank:Hide()
	end
	row.title:SetText(M.S(title))
	if detail and detail ~= "" then
		row.detail:SetText(M.S(detail))
		row.detail:Show()
	else
		row.detail:SetText("")
		row.detail:Hide()
	end
	local col = C.text
	local bar = C.brd
	if tint == "gold" then
		col = C.gold
		bar = C.gold
	elseif tint == "red" then
		col = C.red
		bar = C.red
	elseif tint == "green" then
		col = C.green
		bar = C.green
	elseif tint == "muted" then
		col = C.muted
		bar = { 0.35, 0.30, 0.22 }
	else
		bar = { C.brd[1] * 0.7, C.brd[2] * 0.7, C.brd[3] * 0.7 }
	end
	row.bar:SetVertexColor(bar[1], bar[2], bar[3], 1)
	row.title:SetTextColor(col[1], col[2], col[3])
end

function M.splitDash(line)
	line = M.S(line)
	local dash = string.find(line, " - ", 1, true)
	if dash then
		return string.sub(line, 1, dash - 1), string.sub(line, dash + 3)
	end
	return line, nil
end

function M.fillOverview(b)
	local i = 1
	M.showRow(i, nil, M.S(b.name), M.S(b.tagline), "gold")
	i = i + 1
	M.showRow(i, nil, "Race", M.S(b.race), "muted")
	i = i + 1
	local core = b.core
	local c = 1
	while type(core) == "table" and core[c] and i <= M.BODY_ROWS do
		local head, rest = M.splitDash(core[c])
		M.showRow(i, "*", head, rest, "green")
		i = i + 1
		c = c + 1
	end
	if i <= M.BODY_ROWS then
		M.showRow(i, "!", "Avoid", M.S(b.avoid), "red")
		i = i + 1
	end
	if i <= M.BODY_ROWS then
		M.showRow(i, nil, "Armory", M.S(b.armory), "muted")
	end
end

function M.fillTalents(b)
	local i = 1
	M.showRow(i, nil, "31-pt core order", "Top to bottom. * = keystone.", "gold")
	i = i + 1
	local talents = b.talents
	local n = 1
	while type(talents) == "table" and talents[n] and i <= M.BODY_ROWS do
		local line = M.S(talents[n])
		local tint = "normal"
		if string.find(line, "*", 1, true) then
			tint = "gold"
		end
		M.showRow(i, tostring(n), line, nil, tint)
		i = i + 1
		n = n + 1
	end
	if i <= M.BODY_ROWS and b.tip then
		M.showRow(i, nil, "Tip", M.S(b.tip), "muted")
	end
end

function M.fillList(title, list, tip)
	local i = 1
	M.showRow(i, nil, title, tip, "gold")
	i = i + 1
	local n = 1
	while type(list) == "table" and list[n] and i <= M.BODY_ROWS do
		M.showRow(i, tostring(n), M.S(list[n]), nil, "normal")
		i = i + 1
		n = n + 1
	end
end

function M.refresh()
	local frame = M.frame
	if not frame or not frame.ready then
		return
	end
	local b, id, data = M.currentBuild()
	M.clearRows()
	if not b or not data then
		frame.headerTitle:SetText("Build Guide")
		frame.buildName:SetText("No build data (Builds.lua?)")
		return
	end

	frame.headerTitle:SetText(M.S(data.label))
	frame.buildName:SetText(M.S(b.name) .. " | " .. M.S(b.tree))
	frame.classCount:SetText(tostring(M.classIdx) .. "/" .. tostring(M.listLen(AZSBuildBook_ClassOrder)))

	local ti = 1
	while frame.tabs[ti] do
		M.setChipActive(frame.tabs[ti], ti == M.PAGE)
		ti = ti + 1
	end

	local altCount = 0
	for _ in pairs(data.builds) do
		altCount = altCount + 1
	end
	if altCount > 1 then
		frame.altBtn:Show()
		if id == data.default then
			frame.altBtn.label:SetText("Alt")
		else
			frame.altBtn.label:SetText("Main")
		end
		M.setChipActive(frame.altBtn, id ~= data.default)
	else
		frame.altBtn:Hide()
	end

	if M.PAGE == 1 then
		M.fillOverview(b)
	elseif M.PAGE == 2 then
		M.fillTalents(b)
	elseif M.PAGE == 3 then
		M.fillList("Priority cards", b.cards, M.S(b.tip))
	else
		M.fillList("Jewelry priorities", b.jewelry, "CDR = cooldown reduction")
	end
end

function M.createRow(parent)
	local C = M.C
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(22)
	row:SetBackdrop(M.panelBackdrop())
	row:SetBackdropColor(C.row[1], C.row[2], C.row[3], 0.65)
	row:SetBackdropBorderColor(0.22, 0.18, 0.12, 0.9)

	local bar = row:CreateTexture(nil, "ARTWORK")
	bar:SetTexture(M.SOLID)
	bar:SetWidth(2)
	bar:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -1)
	bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 1, 1)
	bar:SetVertexColor(C.brd[1], C.brd[2], C.brd[3], 1)
	row.bar = bar

	local rank = row:CreateFontString(nil, "OVERLAY")
	M.face(rank, 10)
	rank:SetPoint("LEFT", row, "LEFT", 8, 0)
	rank:SetWidth(16)
	rank:SetJustifyH("CENTER")
	rank:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
	row.rank = rank

	local title = row:CreateFontString(nil, "OVERLAY")
	M.face(title, 11)
	title:SetPoint("LEFT", row, "LEFT", 26, 4)
	title:SetPoint("RIGHT", row, "RIGHT", -8, 4)
	title:SetJustifyH("LEFT")
	title:SetTextColor(C.text[1], C.text[2], C.text[3])
	row.title = title

	local detail = row:CreateFontString(nil, "OVERLAY")
	M.face(detail, 9)
	detail:SetPoint("LEFT", row, "LEFT", 26, -7)
	detail:SetPoint("RIGHT", row, "RIGHT", -8, -7)
	detail:SetJustifyH("LEFT")
	detail:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
	row.detail = detail

	row:Hide()
	return row
end

function M.onPrevClass()
	M.classIdx = M.classIdx - 1
	if M.classIdx < 1 then
		M.classIdx = M.listLen(AZSBuildBook_ClassOrder)
	end
	M.buildId = nil
	M.PAGE = 1
	M.saveClass()
	M.refresh()
end

function M.onNextClass()
	M.classIdx = M.classIdx + 1
	if M.classIdx > M.listLen(AZSBuildBook_ClassOrder) then
		M.classIdx = 1
	end
	M.buildId = nil
	M.PAGE = 1
	M.saveClass()
	M.refresh()
end

function M.onAltBuild()
	local data = M.currentClassData()
	if not data or type(data.builds) ~= "table" then
		return
	end
	local ids = {}
	local n = 0
	for id, _ in pairs(data.builds) do
		n = n + 1
		ids[n] = id
	end
	local a = 1
	while a <= n do
		local b = a + 1
		while b <= n do
			if ids[b] < ids[a] then
				local tmp = ids[a]
				ids[a] = ids[b]
				ids[b] = tmp
			end
			b = b + 1
		end
		a = a + 1
	end
	local cur = M.buildId or data.default
	local nextId = ids[1]
	local i = 1
	while i <= n do
		if ids[i] == cur then
			nextId = ids[i + 1] or ids[1]
			break
		end
		i = i + 1
	end
	M.buildId = nextId
	M.PAGE = 1
	M.refresh()
end

function M.onTab(idx)
	M.PAGE = idx
	M.refresh()
end

function M.getPhase()
	if type(AZS_GetPhase) ~= "function" then
		return nil
	end
	local ok, phase = pcall(AZS_GetPhase)
	if ok then
		return phase
	end
	return nil
end

function M.createLauncher()
	if M.launcher then
		M.launcher:Show()
		M.launcher:Raise()
		return
	end
	if not UIParent then
		return
	end
	local C = M.C
	local btn = CreateFrame("Button", "AZSBuildBookLauncher", UIParent)
	btn:SetWidth(120)
	btn:SetHeight(28)
	-- Top-center: visible in-world ready/playing (not on Bevy Character lobby).
	btn:SetPoint("TOP", UIParent, "TOP", 0, -12)
	btn:SetBackdrop(M.roundBackdrop())
	btn:SetBackdropColor(C.hdr[1], C.hdr[2], C.hdr[3], 0.98)
	btn:SetBackdropBorderColor(C.brd[1], C.brd[2], C.brd[3], 1)
	btn:SetFrameStrata("TOOLTIP")
	btn:SetFrameLevel(10000)
	btn:EnableMouse(true)
	btn:RegisterForDrag("LeftButton")
	btn:SetMovable(true)
	btn:SetScript("OnDragStart", function()
		this:StartMoving()
	end)
	btn:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
	end)
	local fs = btn:CreateFontString(nil, "OVERLAY")
	M.face(fs, 13)
	fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
	fs:SetText("Build Guide")
	fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
	btn.label = fs
	btn:SetScript("OnEnter", function()
		local g = M.C.gold
		this:SetBackdropBorderColor(g[1], g[2], g[3], 1)
	end)
	btn:SetScript("OnLeave", function()
		local b = M.C.brd
		this:SetBackdropBorderColor(b[1], b[2], b[3], 1)
	end)
	btn:SetScript("OnClick", function()
		M.toggleBook()
	end)
	btn:Show()
	btn:Raise()
	M.launcher = btn
end

function M.onPhaseTick()
	M.createLauncher()
	M.tryInjectEscMenu()
	local phase = M.getPhase()
	if M.launcher then
		M.launcher:Show()
		M.launcher:Raise()
	end
	-- Auto-open once when entering in-world ready (zone loaded, run not started).
	if phase == "ready" and not M.openedForReady then
		M.openedForReady = true
		M.showBook()
	elseif phase and phase ~= "ready" then
		M.openedForReady = nil
	end
end

function M.tryInjectEscMenu()
	if M.escInjected then
		return
	end
	if type(DFRL) ~= "table" or not DFRL.menuframe then
		return
	end
	local menu = DFRL.menuframe
	local C = M.C
	local btn = CreateFrame("Button", "AZSBuildBookEscBtn", menu)
	btn:SetWidth(140)
	btn:SetHeight(28)
	btn:SetPoint("TOP", menu, "BOTTOM", 0, -6)
	btn:SetBackdrop(M.panelBackdrop())
	btn:SetBackdropColor(C.hdr[1], C.hdr[2], C.hdr[3], 0.95)
	btn:SetBackdropBorderColor(C.brd[1], C.brd[2], C.brd[3], 1)
	btn:SetFrameStrata("FULLSCREEN_DIALOG")
	local fs = btn:CreateFontString(nil, "OVERLAY")
	M.face(fs, 12)
	fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
	fs:SetText("Build Guide")
	fs:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
	btn:SetScript("OnEnter", function()
		local g = M.C.gold
		this:SetBackdropBorderColor(g[1], g[2], g[3], 1)
	end)
	btn:SetScript("OnLeave", function()
		local b = M.C.brd
		this:SetBackdropBorderColor(b[1], b[2], b[3], 1)
	end)
	btn:SetScript("OnClick", function()
		if DFRL and DFRL.menuframe then
			DFRL.menuframe:Hide()
		end
		M.showBook()
	end)
	M.escBtn = btn
	M.escInjected = true
end

function M.createUI()
	if M.frame and M.frame.ready then
		return true
	end

	if M.frame then
		M.frame:Hide()
		M.frame = nil
	end

	local C = M.C
	local f = CreateFrame("Frame", "AZSBuildBookFrame", UIParent)
	f:SetWidth(M.W)
	f:SetHeight(M.H)
	f:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -24, -40)
	f:SetBackdrop(M.roundBackdrop())
	f:SetBackdropColor(C.bg[1], C.bg[2], C.bg[3], C.bg[4])
	f:SetBackdropBorderColor(C.brd[1], C.brd[2], C.brd[3], 1)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function()
		this:StartMoving()
	end)
	f:SetScript("OnDragStop", function()
		this:StopMovingOrSizing()
	end)
	f:SetFrameStrata("TOOLTIP")
	f:SetFrameLevel(10001)
	f:Hide()

	if type(UISpecialFrames) == "table" then
		local si = 1
		local found = false
		while UISpecialFrames[si] do
			if UISpecialFrames[si] == "AZSBuildBookFrame" then
				found = true
				break
			end
			si = si + 1
		end
		if not found then
			UISpecialFrames[si] = "AZSBuildBookFrame"
		end
	end

	local header = CreateFrame("Button", nil, f)
	header:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -8)
	header:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)
	header:SetHeight(26)
	header:SetBackdrop(M.panelBackdrop())
	header:SetBackdropColor(C.hdr[1], C.hdr[2], C.hdr[3], 0.92)
	header:SetBackdropBorderColor(0.66, 0.49, 0.19, 0.85)
	header:RegisterForDrag("LeftButton")
	header:SetScript("OnDragStart", function()
		M.frame:StartMoving()
	end)
	header:SetScript("OnDragStop", function()
		M.frame:StopMovingOrSizing()
	end)

	local headerTitle = header:CreateFontString(nil, "OVERLAY")
	M.face(headerTitle, 12)
	headerTitle:SetPoint("LEFT", header, "LEFT", 10, 0)
	headerTitle:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
	headerTitle:SetText("Build Guide")
	f.headerTitle = headerTitle

	local badge = header:CreateFontString(nil, "OVERLAY")
	M.face(badge, 9)
	badge:SetPoint("LEFT", headerTitle, "RIGHT", 8, 0)
	badge:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
	badge:SetText("GUIDE")

	local closeBtn = CreateFrame("Button", nil, header)
	closeBtn:SetWidth(18)
	closeBtn:SetHeight(18)
	closeBtn:SetPoint("RIGHT", header, "RIGHT", -4, 0)
	closeBtn:SetBackdrop(M.panelBackdrop())
	closeBtn:SetBackdropColor(0.08, 0.06, 0.04, 0.9)
	closeBtn:SetBackdropBorderColor(0.45, 0.35, 0.18, 1)
	local xMark = closeBtn:CreateFontString(nil, "OVERLAY")
	M.face(xMark, 10)
	xMark:SetPoint("CENTER", closeBtn, "CENTER", 1, 1)
	xMark:SetText("x")
	xMark:SetTextColor(C.gold[1], C.gold[2], C.gold[3])
	closeBtn:SetScript("OnClick", function()
		M.frame:Hide()
	end)

	local prevC = M.makeChip(f, 22, 20, "<")
	prevC:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -8)
	prevC:SetScript("OnClick", M.onPrevClass)

	local nextC = M.makeChip(f, 22, 20, ">")
	nextC:SetPoint("LEFT", prevC, "RIGHT", 3, 0)
	nextC:SetScript("OnClick", M.onNextClass)

	local altBtn = M.makeChip(f, 44, 20, "Alt")
	altBtn:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -8)
	altBtn:SetScript("OnClick", M.onAltBuild)
	f.altBtn = altBtn

	local classCount = f:CreateFontString(nil, "OVERLAY")
	M.face(classCount, 9)
	classCount:SetPoint("RIGHT", altBtn, "LEFT", -6, 0)
	classCount:SetTextColor(C.muted[1], C.muted[2], C.muted[3])
	classCount:SetText("1/9")
	f.classCount = classCount

	local buildName = f:CreateFontString(nil, "OVERLAY")
	M.face(buildName, 11)
	buildName:SetPoint("LEFT", nextC, "RIGHT", 8, 0)
	buildName:SetPoint("RIGHT", classCount, "LEFT", -6, 0)
	buildName:SetJustifyH("LEFT")
	buildName:SetTextColor(C.text[1], C.text[2], C.text[3])
	buildName:SetText("Build")
	f.buildName = buildName

	f.tabs = {}
	local tabW = 72
	local tx = 8
	local ti = 1
	while M.PAGES[ti] do
		local tab = M.makeChip(f, tabW, 18, M.PAGES[ti])
		tab:SetPoint("TOPLEFT", f, "TOPLEFT", tx, -64)
		tab.pageIndex = ti
		tab:SetScript("OnClick", function()
			M.onTab(this.pageIndex)
		end)
		f.tabs[ti] = tab
		tx = tx + tabW + 3
		ti = ti + 1
	end

	local y = -90
	local ri = 1
	while ri <= M.BODY_ROWS do
		local row = M.createRow(f)
		row:SetPoint("TOPLEFT", f, "TOPLEFT", 8, y)
		row:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, y)
		M.rows[ri] = row
		y = y - 23
		ri = ri + 1
	end

	local foot = f:CreateFontString(nil, "OVERLAY")
	M.face(foot, 8)
	foot:SetPoint("BOTTOM", f, "BOTTOM", 0, 8)
	foot:SetTextColor(0.45, 0.40, 0.32)
	foot:SetText("/azsbuild  |  drag header to move")

	f.ready = true
	M.frame = f
	return true
end

function M.showBook(forceClass)
	if type(AZSBuildBook_Builds) ~= "table" then
		M.say("Builds.lua failed to load.")
		return
	end
	local ok, err = pcall(M.createUI)
	if not ok then
		M.say("UI error: " .. M.S(err))
		M.frame = nil
		return
	end
	if forceClass and AZSBuildBook_Builds[forceClass] then
		M.classIdx = M.classIndexOf(forceClass)
	else
		M.classIdx = M.classIndexOf(M.detectClass())
	end
	M.buildId = nil
	M.PAGE = 1
	M.saveClass()
	M.frame:Show()
	local rok, rerr = pcall(M.refresh)
	if not rok then
		M.say("Refresh error: " .. M.S(rerr))
	end
end

function M.hideBook()
	if M.frame then
		M.frame:Hide()
	end
end

function M.toggleBook()
	if M.frame and M.frame:IsShown() then
		M.hideBook()
	else
		M.showBook()
	end
end

function M.init()
	if M.inited then
		return
	end
	M.ensureDB()
	M.createLauncher()
	M.tryInjectEscMenu()
	M.inited = true
end

SLASH_AZSBUILDBOOK1 = "/azsbuild"
SLASH_AZSBUILDBOOK2 = "/buildbook"
SLASH_AZSBUILDBOOK3 = "/azsb"
SlashCmdList["AZSBUILDBOOK"] = function(msg)
	msg = string.lower(string.gsub(msg or "", "^%s*(.-)%s*$", "%1"))
	M.init()
	if msg == "" or msg == "toggle" then
		M.toggleBook()
		return
	end
	if msg == "hide" or msg == "close" then
		M.hideBook()
		return
	end
	local map = {
		warrior = "WARRIOR",
		mage = "MAGE",
		hunter = "HUNTER",
		warlock = "WARLOCK",
		paladin = "PALADIN",
		priest = "PRIEST",
		shaman = "SHAMAN",
		rogue = "ROGUE",
		druid = "DRUID",
		warr = "WARRIOR",
		lock = "WARLOCK",
		pala = "PALADIN",
		sham = "SHAMAN",
	}
	local key = map[msg] or string.upper(msg)
	if type(AZSBuildBook_Builds) == "table" and AZSBuildBook_Builds[key] then
		M.showBook(key)
		return
	end
	M.say("/azsbuild [class]")
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev.elapsed = 0
ev:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if arg1 ~= M.ADDON then
			return
		end
		M.ensureDB()
		M.createLauncher()
		M.tryInjectEscMenu()
		M.inited = true
		return
	end
	if event == "PLAYER_LOGIN" then
		M.init()
		if type(AZSBuildBook_Builds) ~= "table" then
			M.say("WARNING: Builds.lua missing - guide data unavailable.")
		else
			M.say("Build Guide loads in-world (not on Character lobby). Button at top, or /azsbuild")
		end
		return
	end
	if event == "PLAYER_ENTERING_WORLD" then
		M.init()
		M.openedForReady = nil
		M.onPhaseTick()
	end
end)

-- Keep launcher alive; DFRL menu inject; detect ready phase.
ev:SetScript("OnUpdate", function()
	this.elapsed = (this.elapsed or 0) + (arg1 or 0.05)
	if this.elapsed < 0.5 then
		return
	end
	this.elapsed = 0
	M.onPhaseTick()
end)
