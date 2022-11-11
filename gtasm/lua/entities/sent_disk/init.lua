AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")
include("cl_init.lua")
duplicator.RegisterEntityModifier( "gT_Disk", function(p,e,d)
end)
duplicator.RegisterEntityModifier( "gT_DiskN", function(p,e,d)
end)
function ENT:Initialize()
	self:SetModel("models/floppy.mdl")
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	local phys = self:GetPhysicsObject()
	if (IsValid(phys)) then
		phys:Wake()
		phys:EnableMotion(true)
	end
end

function ENT:OnDuplicated( entTable )
	if entTable.EntityMods.gT_Disk then
		self.Files = entTable.EntityMods.gT_Disk
	end
  if entTable.EntityMods.gT_DiskN then
    self.name = entTable.EntityMods.gT_DiskN[1]
  end
end

function ENT:GetNameD()
  if self.name then
    return self.name
  else
    return "NewDisket"
  end
end

function ENT:SetNameD(str)
	self.name = str
  duplicator.StoreEntityModifier( self,"gT_DiskN",{self.name} )
	duplicator.CopyEntTable( self )
end

function ENT:SetData(data)
	self.Files = data
	duplicator.StoreEntityModifier( self,"gT_Disk",self.Files )
	duplicator.CopyEntTable( self )
end

function ENT:GetData()
	if self.Files then
		return self.Files
	else
		return {}
	end 
end