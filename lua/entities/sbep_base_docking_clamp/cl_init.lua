include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

local DCDockType = list.Get( "SBEP_DockingClampModels" )
local DD = list.Get( "SBEP_DoorControllerModels" )
function ENT:Initialize()
	self.CMat = Material( "cable/blue_elec" )
	self.SMat = Material( "sprites/light_glow02_add" )
	self.STime = CurTime()
	self.EfPoints = {}
	self.Model = ClientsideModel("models/spacebuild/s1t1.mdl")
	self.Model:SetNoDraw(true)
	local rmins, rmaxs = self:GetModelRenderBounds()
	self:SetRenderBounds(rmins * 15, rmaxs * 15)
	self:GetEFPoints()
	self:CalcCenterPos()
	self:CalcForward()
	self.StartTime = CurTime()
end
function Bezier4(P0, P1, P2, P3, Step)
	return P0 * ( 1 - Step ) ^ 3 + 3 * P1 * Step * ( 1 - Step ) ^ 2 + 3 * P2 * Step ^ 2 * ( 1 - Step ) + Step ^ 3 * P3
end
function ENT:Draw()
	self.Model = self.Model or ClientsideModel("models/spacebuild/s1t1.mdl", RENDERGROUP_BOTH)
	self.Entity:DrawModel()
	local DockMode = self:GetDockMode()
	if DockMode == 1 or DockMode == 3 then
		self.StartTime = nil
	end
	if DockMode == 3 or DockMode == 4 then
		self.StartTime = self.StartTime or CurTime()
		local scroll = math.min((CurTime() - self.StartTime) * 2, 1)
		local LinkLock = self:GetLinkLock()
		if LinkLock and LinkLock:IsValid() and self:EntIndex() < LinkLock:EntIndex() and self:GetPos():DistToSqr(LinkLock:GetPos()) <= self.MDist then
			local dir = -(self:CalcCenterPos() - LinkLock:CalcCenterPos()):GetNormalized()
			local clipdir = self:CalcForward()
			local clipdir2 = -LinkLock:CalcForward()
			local cplength = 500
			local start = self:CalcCenterPos() - clipdir * 47
			local start2 = self:CalcCenterPos() + clipdir * cplength
			local endpos = LinkLock:CalcCenterPos()
			local endpos2 = LinkLock:CalcCenterPos() - clipdir2 * cplength
			local resolution = (self:CalcCenterPos():Distance(LinkLock:CalcCenterPos())) / 70 + 5
			for i=1, resolution * scroll do
				dir = -(Bezier4(start, start2, endpos2, endpos, (i)/resolution) - Bezier4(start, start2, endpos2, endpos, (i-1)/resolution)):GetNormalized()
				self.Model:SetPos(LerpVector(scroll, Bezier4(start, start2, endpos2, endpos, (i-2)/resolution), Bezier4(start, start2, endpos2, endpos, (i)/resolution)))
				self.Model:SetAngles(dir:Angle())
				self.Model:SetupBones()
				self.Model:DrawModel()
			end
		end
		else
		if !self.EfError then
			print("No effect data")
			self.EfError = true
		end
	end
	
end
function ENT:DrawTranslucent()
	
	if self.STime > CurTime() + 5 then return end
	if self.EfPoints and table.getn(self.EfPoints) > 0 then
		local DockMode = self:GetDockMode()
		
		if DockMode == 2 or DockMode == 3 or DockMode == 4 then
			for x = 1,table.getn(self.EfPoints),1 do
				render.SetMaterial( self.SMat )	
				local color = Color( 100, 100, 150, 100 )
				render.DrawSprite( self.Entity:CalcCenterPos() + self.Entity:GetRight() * self.EfPoints[x].x + self.Entity:GetForward() * self.EfPoints[x].y + self.Entity:GetUp() * self.EfPoints[x].z, 20, 20, color )
				
				local NP = 0
				if x < table.getn(self.EfPoints) then
					NP = x + 1
					else
					NP = 1
				end
				local Sz = 10
				if DockMode == 3 then Sz = 5 end
				
				render.SetMaterial( self.CMat )
				local Scroll = 0
				if DockMode == 2 then
					Scroll = math.fmod(CurTime()*5,128)
					else
					Scroll = math.fmod(CurTime()*64,128)
				end
				render.DrawBeam( self.Entity:CalcCenterPos() + self.Entity:GetRight() * self.EfPoints[x].x + self.Entity:GetForward() * self.EfPoints[x].y + self.Entity:GetUp() * self.EfPoints[x].z, self.Entity:CalcCenterPos() + self.Entity:GetRight() * self.EfPoints[NP].x + self.Entity:GetForward() * self.EfPoints[NP].y + self.Entity:GetUp() * self.EfPoints[NP].z, Sz, Scroll + 10, Scroll, Color( 255, 255, 255, 255 ) ) 
			end
		end
		
		else
		if !self.EfError then
			print("No effect data")
			self.EfError = true
		end
	end
end

function ENT:Think()
	for i = 1,10 do
		local Vec = self.Entity:GetNetworkedVector("EfVec"..i)
		if Vec and Vec ~= Vector(0,0,0) then
			self.EfPoints[i] = {}
			self.EfPoints[i].x = Vec.x
			self.EfPoints[i].y = Vec.y
			self.EfPoints[i].z = Vec.z
			self.EfPoints[i].sp = self.Entity:GetNetworkedInt("EfSp"..i) or 0
		end
	end
end
function ENT:OnRemove()
	if IsValid(self.Model) then
		self.Model:Remove()
	end
end