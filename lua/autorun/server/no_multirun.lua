local serverid = util.CRC(GetConVarString('ip') .. ':' .. GetConVarString('hostport'))

hook.Add('Initialize', 'nomr.Initialize', function()
	tmysql.query('DELETE FROM sessions WHERE server = ' .. serverid .. ';')
end)

hook.Add('CheckPassword', 'nomr.CheckPassword', function(steamid64)
	tmysql.query('SELECT steamid64, server FROM sessions WHERE steamid64=' .. tmysql.escape(steamid64) .. ' AND time >= (UNIX_TIMESTAMP() - 0.5) AND server != ' .. serverid .. ';', function(data)
		if (#data > 0) then
			game.KickID(util.SteamIDFrom64(steamid64), 'Active session on another server detected') -- if we create your session here you wont be able to join other servers if you lose connection before you're authed
		end
	end)
end)

hook.Add('PlayerAuthed', 'nomr.PlayerAuthed', function(pl)
	tmysql.query('SELECT steamid64, server FROM sessions WHERE steamid64=' .. tmysql.escape(pl:SteamID64()) .. ' AND time >= (UNIX_TIMESTAMP() - 0.5) AND server != ' .. serverid .. ';', function(data)
		if IsValid(pl) then
			if (#data > 0) then
				game.KickID(pl:SteamID(), 'Active session on another server detected') -- You tried to join before your session was made
			else
				tmysql.query('REPLACE INTO sessions(steamid64, time, server) VALUES(' .. tmysql.escape(pl:SteamID64()) .. ', UNIX_TIMESTAMP(), ' .. serverid .. ');')
			end
		end
	end)
end)

hook.Add('PlayerDisconnected', 'nomr.PlayerDisconnected', function(pl)
	tmysql.query('DELETE FROM sessions WHERE steamid64=' .. tmysql.escape(pl:SteamID64()) .. ' AND server = ' .. serverid .. ';')
end)

timer.Create('nomr.UpdateSessions', 0.25, 0, function()
	tmysql.query('UPDATE sessions SET time = UNIX_TIMESTAMP() WHERE server = ' .. serverid .. ';')
end)