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
ENT.mdl = Model("models/spacebuild/s1t1.mdl")
local DCDockType = list.Get( "SBEP_DockingClampModels" )
local DD = list.Get( "SBEP_DoorControllerModels" )

function ENT:FindModelSize()
	local cmins, cmaxs = self.Model:GetModelBounds()
	local dist = cmins:Distance(cmaxs)/2
	dist = dist * 0.1
	dist = math.floor(dist)
	dist = dist * 10
	dist = math.max(10, dist)
	return dist
end

function ENT:SetupDataTables()
		self:NetworkVar("Entity", 0, "LinkLock")
		self:NetworkVar("Int", 1, "DockMode")
		self:NetworkVar("Int", 2, "MDist")
		self:NetworkVar("String", 3, "TubeModel")
end

function ENT:GetEFPoints()
	self.EFPoints = DCDockType[self:GetModel()].EfPoints
	self.EfPoints = DCDockType[self:GetModel()].EfPoints
end
function ENT:CalcCenterPos()
	local pos = self:GetPos()
	if DCDockType[self:GetModel()].Center then
		pos = self:LocalToWorld(DCDockType[self:GetModel()].Center)
	end
	return pos
end

function ENT:CalcForward()
	local dir = DCDockType[self:GetModel()].Forward
	local ang = dir:Angle()
	self.Forward = self:LocalToWorldAngles(ang):Forward()
	return self.Forward
end

if SC then
	function ENT:FindAllConnectedShips(cores, clamps)
		local connectedShips = cores or {}
		if IsValid(self.LinkLock) and IsValid(self.SC_CoreEnt) and IsValid(self.LinkLock.SC_CoreEnt) then
			local checkedclamps = clamps or {self}
			connectedShips[tostring(self.SC_CoreEnt:EntIndex())] = self.SC_CoreEnt
			table.insert(checkedclamps, self)
			if IsValid(self.SC_CoreEnt) and IsValid(self.LinkLock.SC_CoreEnt) then
				for k,v in pairs(self.LinkLock.SC_CoreEnt.ConWeldTable) do
					if v.IsAirLock and !table.HasValue(checkedclamps, v) then
						table.Merge(connectedShips, v:FindAllConnectedShips(connectedShips, checkedclamps))
					end
				end
			end
		end
		return connectedShips
	end
end