AddCSLuaFile();

ENT.Type = "anim";
ENT.Base = "base_anim";

ENT.PrintName = "Computer(CORD)";
ENT.Author = "Chessnut";
ENT.Purpose = "Used to compute stuff.";

ENT.Spawnable = true;
ENT.Category = "gTerminal";

function ENT:OnRemove()
	if (CLIENT) then
		gTerminal[ self:EntIndex() ] = nil;
	end;
end;

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Active");
	self:NetworkVar("Bool", 1, "WarmingUp");
	self:NetworkVar("Bool", 2, "KeyType");
	self:NetworkVar("Entity", 0, "User");
end;

if (SERVER) then
	function ENT:SetOS(name)
		self.os = name;
	end;

	function ENT:GetOS()
		return self.os or "default";
	end;

	function ENT:WarmUp()
		self.WarmUpText = gTerminal.os:Call(self, "GetWarmUpText");

		if (self.WarmUpText) then
			local time = math.random(1, 3);

			self:SetWarmingUp(true);

			for i = 1, #self.WarmUpText do
				timer.Simple( i * (#self.WarmUpText / time), function()
					if ( IsValid(self) ) then
						gTerminal:Broadcast(self, self.WarmUpText[i], GT_COL_INT);

						if (i == #self.WarmUpText) then
							timer.Simple(math.Rand(1, 3), function()
								if ( IsValid(self) ) then
									gTerminal:Broadcast(self, "");
									gTerminal:Broadcast(self, "Welcome to gTerminal!");
									gTerminal:Broadcast(self, "To list all commands, type :help");

									gTerminal.os:Call(self, "Initialized");

									self:SetActive(true);
									self:SetWarmingUp(false);
								end;
							end);
						end;
					end;
				end);
			end;
		else
			gTerminal:Broadcast(self, "Welcome to gTerminal!");
			gTerminal:Broadcast(self, "To list all commands, type :help");

			gTerminal.os:Call(self, "Initialized");

			self:SetActive(true);
			self:SetWarmingUp(false);
		end;
	end;

	function ENT:SpawnFunction(client, trace)
		if (!trace.Hit) then
			return false;
		end;

		local entity = ents.Create(self.ClassName);
		entity:Initialize();
		entity:SetPos( trace.HitPos + Vector(0, 0, 32) );
		entity:Spawn();
		entity:Activate();

		return entity;
	end;

	function ENT:Initialize()
		self:SetModel("models/props_lab/monitor01a.mdl");
		self:SetMoveType(MOVETYPE_VPHYSICS);
		self:PhysicsInit(SOLID_VPHYSICS);
		self:SetSolid(SOLID_VPHYSICS);
		self:SetUseType(SIMPLE_USE);
		self:DrawShadow(false);
		self:SetActive(false);
		self:SetOS("default");
		
		local physicsObject = self:GetPhysicsObject();

		if ( IsValid(physicsObject) ) then
			physicsObject:Wake();
			physicsObject:EnableMotion(true);
		end;
	end;

	function ENT:OnRemove()
		for k, v in pairs( player.GetAll() ) do
			v[ "pass_authed_"..self:EntIndex() ] = nil;
		end;

		gTerminal.os:Call(self, "ShutDown", self);
	end;

	function ENT:Use(activator, caller)
		if (self.locked) then
			return;
		end;
		
		if ( self:GetActive() ) then
			if ( !IsValid( self:GetUser() ) ) then
				self:SetUser(activator);
				if !self:GetKeyType() then
					net.Start("gT_ActiveConsole");
						net.WriteUInt(self:EntIndex(), 16);
					net.Send(activator);
				else
					net.Start("gT_StartKeyType")
						net.WriteEntity(self)
					net.Send(activator)
				end
				gTerminal.os:Call(self, "UserInit", activator);
			end;
		elseif ( !self:GetWarmingUp() ) then
			self:WarmUp();
		end;
	end;

	function ENT:Think()
		local user = self:GetUser();

		if ( IsValid(user) ) then
			local distance = user:GetPos():Distance( self:GetPos() );

			if ( ( !self:GetActive() and !self:GetWarmingUp() ) or distance > 96 ) then
				net.Start("gT_EndTyping");
				net.Send(user);

				self:SetUser(nil);
			end;
		end;--[[
    local range = 50
    if !self.Cord then
      for k, v in pairs(ents.FindByClass("sent_provod")) do
        if (!v:GetComp()) then
          if !v:CanConnect() then return end
          local dist = self:GetPos():Distance(v:GetPos())
          if (dist <= range) then
            self.Cord = v
            v:SetComp(self)
            range = dist
          end
        end
      end
    elseif !constraint.GetAllConstrainedEntities(self)[self.Cord] then
      self.Cord = nil
    end--]]
	end;
  
else
	local math = math;
	local cam = cam;
	local render = render;
	local draw = draw;
	local surface = surface;
	local Color = Color;

	local r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255);

	function ENT:Initialize()
		self.scrW = 905;
		self.scrH = 768;
		self.maxChars = 50;
		self.maxLines = 24;
		self.lineHeight = 28.7;
		self.trapping = false;
		self.consoleText = "";
		self.nextBlink = 0;
	end;

	function ENT:Draw()
		self:DrawModel();

		if ( self:GetWarmingUp() or self:GetActive() ) then
			local angle = self:GetAngles();
			angle:RotateAroundAxis(angle:Forward(), 180);
			angle:RotateAroundAxis(angle:Right(), 265.5);
			angle:RotateAroundAxis(angle:Up(), 270);

			local offset = angle:Up() * 12.6 + angle:Forward() * -9.7 + angle:Right() * -10.85;

			cam.Start3D2D(self:GetPos() + offset, angle, 0.0215);
				render.PushFilterMin(TEXFILTER.ANISOTROPIC);
				render.PushFilterMag(TEXFILTER.ANISOTROPIC);
					surface.SetDrawColor(5, 5, 8, 255);
					surface.DrawRect(0, 0, self.scrW, self.scrH);

					local lines = gTerminal[ self:EntIndex() ] or {};

					for i = 1, self.maxLines do
						if ( lines[i] ) then
							local color = gTerminal:ColorFromIndex(lines[i].color);

							draw.SimpleText(lines[i].text or "", "gT_ConsoleFont", 1, (28.7 * i) - 28.7, color, 0, 0);
						end;
					end;

					local y = (self.maxLines + 1) * self.lineHeight;

					surface.SetDrawColor(255, 255, 255, 15);
					surface.DrawRect(1, y, self.scrW - 1, self.lineHeight);

					if ( IsValid( self:GetUser() ) ) then
						if ( self:GetUser() != LocalPlayer() ) then
							self.consoleText = self:GetUser():Name().." is typing...";
						end;
					else
						self.consoleText = "";
					end;

					draw.SimpleText("> ".. (self.consoleText or ""), "gT_ConsoleFont", 1, y, color_white, 0, 0);

					if ( self:GetWarmingUp() ) then
						if (!self.flashTime) then
							self.flashTime = CurTime() + 0.25;
						end;

						local fraction = math.Clamp( ( self.flashTime - CurTime() ) / 0.25, 0, 1 );

						surface.SetDrawColor(255, 0, 0, 255);
						surface.DrawRect(0, 0, self.scrW / 3, self.scrH * fraction);

						surface.SetDrawColor(0, 255, 0, 255);
						surface.DrawRect(self.scrW / 3, 0, self.scrW / 3, self.scrH * fraction);

						surface.SetDrawColor(0, 0, 255, 255);
						surface.DrawRect( (self.scrW * 2) / 3, 0, self.scrW / 3, self.scrH * fraction );

						if (fraction < 1 and fraction > 0.75) then
							surface.SetDrawColor(math.random(100, 255), math.random(100, 255), math.random(100, 255), 255);
							surface.DrawRect(0, 0, self.scrW, self.scrH);
						elseif (fraction < 0.5) then
							if ( self.nextBlink < CurTime() ) then
								r, g, b = math.random(0, 255), math.random(0, 255), math.random(0, 255);

								self.nextBlink = CurTime() + 0.25;
							end;

							draw.SimpleText("RES: "..self.scrW.."x"..self.scrH, "gT_ConsoleFont", self.scrW - 2, 2, Color(255, 255, 255, 255), 2, 0);
							draw.SimpleText("COL: RGB ("..r..","..g..","..b..")", "gT_ConsoleFont", self.scrW - 2, 40.7, Color(r, g, b, 255), 2, 0);
						end;
					elseif (self.flashTime) then
						self.flashTime = nil;
					end;
				render.PopFilterMin();
				render.PopFilterMag();
			cam.End3D2D();
		end;
	end;
end;
