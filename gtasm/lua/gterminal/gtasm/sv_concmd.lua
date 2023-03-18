--todo

--concommand.Add( "gt_stop_all", function callback, function autoComplete = nil, string helpText = "nil", number flags = 0 ) stop all script (if !admin then only your (?))
--concommand.Add( "gt_maxmemory", function callback, function autoComplete = nil, string helpText = "nil", number flags = 0 ) add a block memory
concommand.Add( "gt_stop_all", function(ply)
    if ply:IsAdmin() == false then
        return
    end
    
    for k,v in pairs(hook.GetTable().Tick) do
        if string.find(k,"gT_") then
            local es  = string.gsub(k,"gT_","")
            local eid = tonumber(es)

            if IsValid(Entity(eid)) then
                gTASM:ErrorScript(Entity(eid), GT_E_PIRATE, {LOCATION = game.GetMap(), POSITION = tostring(Entity(eid):GetPos()),TIME_TO_DEST = "10 minutes" })
            end
        end

    end
end)
