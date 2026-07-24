--[[
	ExonHub Loader — execute THIS file to test locally.

	Loads from executor workspace:
	  ExonHub/ExonHub.lua
	  ExonHub/ExonKey.lua
	  …

	Do NOT use the old GitHub download loader for testing — that is the old hub
	without the key system.

	Release: set MAIN_URL after Luraph upload.
]]
local ROOT = "ExonHub"

local function pick(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) == "function" then
			return v
		end
	end
end

local readfile = pick(readfile)
local isfile = pick(isfile)
local loadfn = pick(load, loadstring)

local function readPath(path)
	if not (readfile and isfile) then
		return nil
	end
	local ok, exists = pcall(isfile, path)
	if not (ok and exists) then
		return nil
	end
	local ok2, data = pcall(readfile, path)
	return ok2 and data or nil
end

local function runSource(src, label)
	if not loadfn then
		error("[ExonHub] No load/loadstring available.")
	end
	local chunk, err = loadfn(src, label or "ExonHub")
	if not chunk then
		error("[ExonHub] Compile failed: " .. tostring(err))
	end
	return chunk()
end

-- Release URL (set after Luraph upload). Leave nil for local dev files.
local MAIN_URL = nil

if MAIN_URL and MAIN_URL ~= "" then
	local request = pick(syn and syn.request, http and http.request, http_request, request)
	local body
	if game.HttpGet then
		local ok, res = pcall(game.HttpGet, game, MAIN_URL)
		if ok then body = res end
	end
	if not body and request then
		local ok, res = pcall(request, { Url = MAIN_URL, Method = "GET" })
		if ok and type(res) == "table" then
			body = res.Body or res.body
		end
	end
	if not body then
		error("[ExonHub] Failed to download main script.")
	end
	runSource(body, "ExonHub@remote")
else
	local candidates = {
		ROOT .. "/ExonHub.lua",
		ROOT .. "\\ExonHub.lua",
		"ExonHub.lua",
		"src/ExonHub.lua",
	}
	for _, path in ipairs(candidates) do
		local src = readPath(path)
		if src then
			runSource(src, path)
			return
		end
	end
	error("[ExonHub] Main script not found. Copy the ExonHub folder into your executor workspace.")
end
