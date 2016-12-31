nomr 			= nomr or {}
nomr.serverid 	= util.CRC(game.GetIPAddress())
nomr.lastcheck 	= nomr.lastcheck or os.time()
nomr.sessions 	= nomr.sessions or {}

include 'dash_mysql_wrapper.lua'

nomr.db = nomr.db or nomr.mysql('HOSTNAME', 'USERNAME', 'PASSWORD', 'DATABASE', 3306)

nomr.db:Query [[
	CREATE TABLE IF NOT EXISTS `sessions`(  
		`steamid64` BIGINT(20) NOT NULL,
		`time` INT NOT NULL,
		`server` BIGINT(20) NOT NULL,
		PRIMARY KEY (`steamid64`)
	);
]]

local checkactive 	= nomr.db:Prepare 'SELECT steamid64, server FROM sessions WHERE time>=? AND server != ?;'
local setactive 	= nomr.db:Prepare 'REPLACE INTO sessions(steamid64, time, server) VALUES(?, ?, ?);'
local setinactive 	= nomr.db:Prepare 'DELETE FROM sessions WHERE steamid64=?;'

hook.Add('PlayerInitialSpawn', 'nomr.PlayerInitialSpawn', function(pl)
	local steamid64 = pl:SteamID64()
	setactive:Run(steamid64, os.time(), nomr.serverid, function()
		if IsValid(pl) then
			nomr.sessions[steamid64] = pl
		end
	end)
end)

hook.Add('PlayerDisconnected', 'nomr.PlayerDisconnected', function(pl)
	local steamid64 = pl:SteamID64()
	setinactive:Run(steamid64)
	nomr.sessions[steamid64] = nil
end)

timer.Create('nomr.CheckMultirunningSessions', 5, 0, function()
	checkactive:Run(nomr.lastcheck, nomr.serverid, function(data)
		for k, v in ipairs(data) do
			local pl = nomr.sessions[v.steamid64]
			if IsValid(pl) then
				pl:Kick('Active session on another server detected')
			end
		end
	end)
	nomr.lastcheck = os.time()
end)