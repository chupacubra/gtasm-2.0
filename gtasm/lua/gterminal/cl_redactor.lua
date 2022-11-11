include("sh_init.lua");
include("cl_luapad_editor.lua")

luapad = {}

local newFileText = "\n# A list with all the commands on the site [LINK]\n# Need help with something?->\n# try asking in [DISCORD/ICQ/IRC/SMS]"

local function gTASMSaveFile(name,data)
	local newFile = file.Open(name, "w", "DATA")

	if newFile != nil then
		newFile:Write(data)
	end

	newFile:Close()
	local succes = file.Exists( name, "DATA" ) -- bruh

	return succes
end

local function RecursiveGetFiles(path,str)
	local allFiles = {}
	local files,dir = file.Find(path.."/*","DATA")
	for k,v in pairs(files) do
		if str != nil then
		if string.match(v,str) then
			table.insert(allFiles,v)
		end
		else
			table.insert(allFiles,v)
		end
	end
	if #dir != 0 then
		for k,v in pairs(dir) do
			local fls = RecursiveGetFiles(path.."/"..v,str)
			allFiles[v] = fls
		end
	end
	return allFiles
end

local function dsplit(s, delimiter)
	result = {};
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        if (match==" ") or (match=="") or (match==nil) then
        else 
		table.insert(result, match);
        end 
	end
	return result;
end

local function CallRedDerm(entity,cont,name)
	local function DMCreateFile()

	end

	local function DMRemoveFile()

	end

	local frame = vgui.Create( "DFrame" )
	frame:SetSize( 625, 475 )
	frame:Center()
	frame:MakePopup()
	frame:SetTitle( "gTASM Redactor" )
	frame:SetSizable( true )
  	fw,fh = frame:GetSize()
	
	--local EditorPanel = vgui.Create( "DPanel", frame )
	--EditorPanel:Dock(FILL)


	local ButtonPanel = vgui.Create( "DPanel", frame )
	ButtonPanel:Dock(TOP)
	ButtonPanel:SetPos(5,25)
	ButtonPanel:SetSize(fw-168,25)

	local BFileList = vgui.Create("DIconLayout",ButtonPanel)
	BFileList:Dock(LEFT)
	BFileList:DockMargin(3, 3, 3, 3)
	BFileList:SetSpaceX( 5 )


	local SaveB = BFileList:Add("DImageButton")
	SaveB:SetSize(18,18)
	SaveB:SetIcon( "icon16/script_save.png" )
	SaveB:SetToolTip("Save script")

	local AddB = BFileList:Add("DImageButton")
	AddB:SetSize(18,18)
	AddB:SetIcon( "icon16/script_add.png" )
	AddB:SetToolTip("Add a new file")

	local RemB = BFileList:Add("DImageButton")
	RemB:SetSize(18,18)
	RemB:SetIcon( "icon16/script_delete.png" )
	RemB:SetToolTip("Close active tab file")
	
	local BMisc = vgui.Create("DIconLayout",ButtonPanel)
	BMisc:Dock(RIGHT)
	BMisc:DockMargin(3, 3, 3, 3)
	BMisc:SetSpaceX( 5 )

	local BInfo = BMisc:Add("DImageButton")
	BInfo:SetSize(18,18)
	BInfo:SetIcon( "icon16/information.png" )
	BInfo:SetToolTip("LuaPad Editor - Syranide\n\nEdited - DarKSunrise aka Assassini")

	local BGuide = BMisc:Add("DImageButton")
	BGuide:SetSize(18,18)
	BGuide:SetIcon( "icon16/book_open.png" )
	BGuide:SetToolTip("HOW PROGRAMMING ON THIS $%@?")

	local BSet = BMisc:Add("DImageButton")
	BSet:SetSize(18,18)
	BSet:SetIcon( "icon16/wrench.png" )
	BSet:SetToolTip("Settings(no)")

	local UplB = vgui.Create("DButton",ButtonPanel)
	UplB:SetSize( 70, 10 )
	UplB:Dock( LEFT )
	UplB:DockMargin(15, 0, 0, 0)
	UplB:SetSize( 70, 10 )
	UplB:SetText("Upload")
	UplB:SetEnabled(entity != Entity(0))

	local ESheet = vgui.Create( "DPropertySheet", frame )
	ESheet:SetPos( 5, 50 )
	ESheet:SetSize(fw-168, fh - 55)
	ESheet.LFile = {}
	
	function ESheet:AddFile(name,text,fromTerminal)
		if fromTerminal then
			name = "gtasm/"..name..".txt" -- shit
		end
		local textentry = vgui.Create("LuapadEditor", ESheet)
		textentry:Dock(FILL)
		textentry:DockMargin(0, -7, 0, 0)
		textentry:SetText(text or newFileText)
		textentry:RequestFocus()
		textentry.FRG = fromTerminal
		
		if name then
			local n = string.StripExtension(string.GetFileFromFilename( name ))
			textentry.name = n
		else
			textentry.name = "newfile" 
		end 


		function luapad.CheckGlobal(func)
			return "func"
		end

		function luapad.SaveTheFile()
			-- On CTRL-S
		end
		local tab = self:AddSheet( name or "New File", textentry )
		
		--if fromTerminal then

		--end

		self:SwitchToName( name or "New File")
	end
	if entity != Entity(0) then
		ESheet:AddFile(name,cont,true)
	else
		ESheet:AddFile()
	end

    local DBrowser = vgui.Create( "DPanel", frame )
    DBrowser:SetPos( fw - 160, 25 )
    DBrowser:SetSize(155, fh - 30)

	local BSearch = vgui.Create( "DTextEntry", DBrowser )
	BSearch:Dock( TOP )
	BSearch:SetPlaceholderText("Search files...")

	function BSearch:OnEnter()
		FindFile(self:GetValue())
		chat.AddText( self:GetValue() )
	end

    local DTree = vgui.Create( "DTree", DBrowser )
    DTree:Dock(FILL)
	DTree.SelNode = nil
	local DNode

	function DTree:SetupFileList()
		if DNode != nil then
			DNode:Remove()
		end
		DNode = DTree:AddNode("gtasm")
		DNode:SetDoubleClickToOpen( true )
		DNode:MakeFolder("gtasm", "DATA", true, "*",false)
		function DNode:OnNodeSelected( node )
			if DTree.SelNode != node then
				DTree.SelNode = node
			else
				local file = file.Read( node:GetFileName(), "DATA" )
				if ESheet.LFile[node:GetFileName()] then
					ESheet:SwitchToName(node:GetFileName())
				else
					ESheet:AddFile(node:GetFileName(),file)
					ESheet.LFile[node:GetFileName()] = true
				end
				DTree.SelNode = nil
			end
		end
		DNode:SetExpanded(true)
	end

	function DTree:GetDirPath(node)
		local str = ""
		local nodeend = false 
		while nodeend != true do
			str = str .. string.reverse(node:GetText()) .. "/"
			--if node:GetParentNode() != nil then
				--node = node:GetParentNode()
			--end
			if node:GetParentNode() == nil then
				nodeend = true
			else
				node = node:GetParentNode()
			end
		end
		return string.reverse(str)
	end
	
	function DTree:DoRightClick( node )
		if node:GetFolder() then
			if file.IsDir(node:GetFolder(), "DATA") == false then 
				return
			end
			local menu = DermaMenu()

			menu:AddOption( "New file", function()
				Derma_StringRequest(
					"The name of file", 
					"Creating file",
					"newfile",
					function(text)
						print("Create file - ",node:GetFolder().."/"..text..".txt")
						if file.Exists( node:GetFolder().."/"..text..".txt", "DATA" ) then
							Derma_Query(
								"The file "..text..".txt already exist",
								"Rewrite?:",

								"Yeah, rewrite",
								function()
									gTASMSaveFile(node:GetFolder()..text..".txt", "")
									ESheet:GetActiveTab():GetPanel().ValueChanged = false
									ESheet:GetActiveTab():SetText(node:GetFolder().."/"..text..".txt")
									self:SetupFileList()
								end,

								"Nooo!!!",
								function()
									--nothing
								end
							)
						else
							gTASMSaveFile(node:GetFolder().."/"..text..".txt", "")
							ESheet:GetActiveTab():GetPanel().ValueChanged = false
							ESheet:GetActiveTab():SetText(node:GetFolder().."/"..text..".txt")
							self:SetupFileList()
						end
					end,
					function(text) return  end
				)
			end)

			menu:AddOption( "New folder", function()
				Derma_StringRequest(
					"The name of folder", 
					"Creating folder",
					"newfolder",
					function(text)
						if file.IsDir(node:GetFolder().."/"..text,"DATA") then
							Derma_Message("The folder with this name already existed", "Error of creating folder", "OK")
							return
						end
						file.CreateDir( node:GetFolder().."/"..text )
						self:SetupFileList()
					end
				)
			end)

			menu:AddOption( "Delete folder", function()
				Derma_Query(
					"DELETE folder ".. node:GetFolder().." ?",
					"Delete action",
					"Yes",
					function()
						file.Delete(node:GetFolder())
						self:SetupFileList()
					end,
					"No",
					function() return  
				end)
			end)

			menu:Open()

		elseif node:GetFileName() then
			local menu = DermaMenu()
			
			menu:AddOption( "Open file", function()
				local file = file.Read( node:GetFileName(), "DATA" )
				if ESheet.LFile[node:GetFileName()] then
					ESheet:SwitchToName(node:GetFileName())
				else
					ESheet:AddFile(node:GetFileName(),file)
					ESheet.LFile[node:GetFileName()] = true
				end
			end)
			
			menu:AddOption( "Delete file", function()
				Derma_Query(
				"DELETE file ".. node:GetFileName().." ?",
				"Delete action",
				"Yes",
				function()
					file.Delete(node:GetFileName())
					self:SetupFileList()
				end,
				"No",
				function() return  end)
			end)

			menu:AddOption( "Rename file", function()
				Derma_StringRequest(
					"The name of file", 
					"Rename action",
					"newfile",
					function(text)
						local fold = node:GetParentNode():GetFolder()
						print(fold.."/"..text..".txt",node:GetFileName())
						if file.Exists( fold.."/"..text..".txt", "DATA" ) then
							Derma_Message("The file with this name already existed", "Error of creating file", "OK")
							return
						--file.CreateDir( node:GetFolder().."/"..text )
						end
						file.Rename( node:GetFileName(), fold.."/"..text..".txt" )
						self:SetupFileList()
					end
				)
				
			end)
			
			menu:Open()
		end
	end
	DTree:SetupFileList()

	local div = vgui.Create( "DHorizontalDivider", frame )
	div:Dock( FILL )
	div:SetRight( DBrowser)
	div:SetLeft(ESheet)
	div:SetDividerWidth( 4 )
	div:SetRightMin( 50 )
	div:SetLeftWidth( 125 )
	div:SetLeftWidth( fw - 168 )

	function frame:OnSizeChanged( nw, nh )
		fw,fh = nw,nh
		ButtonPanel:SetSize(fw-168,25)
		DBrowser:SetPos( nw - 160, 25 )
		DBrowser:SetSize(155, nh - 30)
		ESheet:SetSize(nw-168, nh - 55)
	end

	function frame:OnClose()
		LocalPlayer().gTASM_editor = nil
	end

	function RemB:DoClick()
		PrintTable(ESheet.LFile)
		if ESheet:GetActiveTab():GetPanel().ValueChanged then
			print(ESheet:GetActiveTab():GetPanel().ValueChanged)
			Derma_Query(
				"Need save file?",
				"Confirmation:",
				"Yes",
				function()
					if ESheet:GetActiveTab():GetText() == "New File" then
						Derma_StringRequest(
							"The name of file", 
							"",
							"newfile",
							function(text)
								local val  = ESheet:GetActiveTab():GetPanel():GetValue()
								if file.Exists( "gtasm/"..text..".txt", "DATA" ) then
									Derma_Query(
										"The file "..text..".txt already exist",
										"Rewrite?:",
										"Yeah, rewrite",
										function()
											local val  = ESheet:GetActiveTab():GetPanel():GetValue()
											gTASMSaveFile("gtasm/"..text..".txt",val)
											
											if #ESheet:GetItems() > 1 then
												ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
												ESheet:CloseTab(ESheet:GetActiveTab(), true)
											else
												ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
												local tab = ESheet:GetActiveTab()
												ESheet:AddFile()
												ESheet:CloseTab(tab, true)
											end
											DTree:SetupFileList()
										end,
										"Nooo!!!",
										function() end
									)
								end
							end,
							function(text) print("Cancelled input") end
						)
					else
						local name = ESheet:GetActiveTab():GetText()
						local val  = ESheet:GetActiveTab():GetPanel():GetValue()


						if #ESheet:GetItems() > 1 then
							ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
							ESheet:CloseTab(ESheet:GetActiveTab(), true)
						else
							ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
							local tab = ESheet:GetActiveTab()
							ESheet:AddFile()
							ESheet:CloseTab(tab, true)
						end
						DTree:SetupFileList()
					end
				end,
				"No",
				function()
					if #ESheet:GetItems() > 1 then
						ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
						ESheet:CloseTab(ESheet:GetActiveTab(), true)
					else
						ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
						local tab = ESheet:GetActiveTab()
						ESheet:AddFile()
						ESheet:CloseTab(tab, true)
					end
					DTree:SetupFileList()
				end
			)
		else
			if #ESheet:GetItems() > 1 then
				ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
				ESheet:CloseTab(ESheet:GetActiveTab(), true)
			else
				ESheet.LFile[ESheet:GetActiveTab():GetText()] = nil
				local tab = ESheet:GetActiveTab()
				ESheet:AddFile()
				ESheet:CloseTab(tab, true)
			end
			DTree:SetupFileList()
		end
		--DTree:SetupFileList()
	end

	function AddB:DoClick()
		ESheet:AddFile()
	end

	function SaveB:DoClick()
		if ESheet:GetActiveTab():GetText() == "New File" then
			Derma_StringRequest(
				"The name of file", 
				"Creating file",
				"newfile",
				function(text)
					print("save file - ","gtasm/"..text..".txt")
					if file.Exists( "gtasm/"..text..".txt", "DATA" ) then
						Derma_Query(
							"The file "..text..".txt already exist",
							"Rewrite?:",
							"Yeah, rewrite",
							function()
								local val  = ESheet:GetActiveTab():GetPanel():GetValue()
								gTASMSaveFile("gtasm/"..text..".txt",val)
								ESheet:GetActiveTab():GetPanel().ValueChanged = false
								ESheet:GetActiveTab():SetText("gtasm/"..text..".txt")
								DTree:SetupFileList()
							end,
							"Nooo!!!",
							function()
								--nothing
							end
						)
					else
						local val  = ESheet:GetActiveTab():GetPanel():GetValue()
						gTASMSaveFile("gtasm/"..text..".txt",val)
						ESheet:GetActiveTab():GetPanel().ValueChanged = false
						ESheet:GetActiveTab():SetText("gtasm/"..text..".txt")
						DTree:SetupFileList()
					end
				end,
				function(text) print("Cancelled input") end
			)
		else
			local name = ESheet:GetActiveTab():GetText()
			local val  = ESheet:GetActiveTab():GetPanel():GetValue()
			gTASMSaveFile(name,val)
			ESheet:GetActiveTab():GetPanel().ValueChanged = false
			DTree:SetupFileList()
		end
	end

	function UplB:DoClick()
		--local name = table.concat()
		hook.Run("gT_SaveScript",entity, ESheet:GetActiveTab():GetPanel().name, ESheet:GetActiveTab():GetPanel():GetValue())
	end
end



net.Receive("gT_RedDerm", function()
	local entity = net.ReadEntity()
	local cont = net.ReadString()
	local name = net.ReadString()
	CallRedDerm(entity,cont,name)
end)


hook.Add("gT_SaveScript", "savescript", function(entity,name,value,frame)
	net.Start("gT_SaveDerm");
	net.WriteEntity(entity)
	net.WriteString(value);
	net.WriteString(name)
	net.SendToServer()
end)