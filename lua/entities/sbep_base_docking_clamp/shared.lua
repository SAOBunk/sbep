ENT.Type 			= "anim"
ENT.Base 			= "base_gmodentity"
ENT.PrintName		= "Base Docking Clamp"
ENT.Author			= "Paradukes, Hysteria"
ENT.Category		= "SBEP"

ENT.Spawnable		= false
ENT.AdminSpawnable	= false
ENT.Owner			= nil
ENT.CPL				= nil

ENT.MDist			= 2000000

ENT.ScanDist		= 2000
ENT.DockMode			= 1 -- 0 = Disengaging, 1 = Inactive, 2 = Ready to dock, 3 = Attempting to dock, 4 = Docked
ENT.ClDockMode			= 1 -- Used to send the DMode client-side for effects
ENT.IsAirLock		= true
ENT.ConstraintTable = {}

local DCDockType = list.Get( "SBEP_DockingClampModels" )
local DD = list.Get( "SBEP_DoorControllerModels" )

function ENT:SetupDataTables()
		self:NetworkVar("Entity", 0, "LinkLock")
		self:NetworkVar("Int", 1, "DockMode")
end

function ENT:GetEFPoints()
	self.EFPoints = DCDockType[self:GetModel()].EfPoints
end
function ENT:CalcCenterPos()
	local pos = self:GetPos()
	if DCDockType[self:GetModel()].Center then
		pos = self:GetPos() + DCDockType[self:GetModel()].Center
	end
	return pos
end

function ENT:CalcForward()
	local dir = DCDockType[self:GetModel()].Forward
	local ang = dir:Angle()
	self.Forward = self:LocalToWorldAngles(ang):Forward()
	return self.Forward
end