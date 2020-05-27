include('shared.lua')
ENT.RenderGroup = RENDERGROUP_BOTH

local DCDockType = list.Get( "SBEP_DockingClampModels" )
local DD = list.Get( "SBEP_DoorControllerModels" )

function ENT:Initialize()
	self.CMat = Material( "cable/blue_elec" )
	self.WMat = Material( "trails/smoke" )
	self.SMat = Material( "sprites/light_glow02_add" )
	self.STime = CurTime()
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
		local LinkLock = self:GetLinkLock()
		
		if DockMode == 2 or DockMode == 3 or DockMode == 4 then
			local ef = table.Copy(self.EfPoints)
			
			for x = 1,table.getn(ef),1 do
				local offset = self.Entity:GetRight() * ef[x].vec.x + self.Entity:GetForward() * ef[x].vec.y + self.Entity:GetUp() * ef[x].vec.z
				render.SetMaterial( self.SMat )	
				local color = Color( 100, 100, 150, 100 )
				render.DrawSprite( self.Entity:CalcCenterPos() + offset, 20, 20, color )
				
				local NP = 0
				if x < table.getn(ef) then
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
				render.DrawBeam( self.Entity:CalcCenterPos() + self.Entity:GetRight() * ef[x].vec.x + self.Entity:GetForward() * ef[x].vec.y + self.Entity:GetUp() * ef[x].vec.z, self.Entity:CalcCenterPos() + self.Entity:GetRight() * ef[NP].vec.x + self.Entity:GetForward() * ef[NP].vec.y + self.Entity:GetUp() * ef[NP].vec.z, Sz, Scroll + 10, Scroll, Color( 255, 255, 255, 255 ) ) 
			end
			if IsValid(LinkLock) then
				table.sort(ef,  function(a, b) return a.sp > b.sp end)
				for x = 1,table.getn(ef),1 do
					local offset = self.Entity:GetRight() * ef[x].vec.x + self.Entity:GetForward() * ef[x].vec.y + self.Entity:GetUp() * ef[x].vec.z
					local ef2 = table.Copy(LinkLock.EfPoints)
					
					table.sort(ef2,  function(a, b) return a.sp > b.sp end)
					if DockMode == 4 and LinkLock and LinkLock:IsValid() and self:EntIndex() < LinkLock:EntIndex() then
						if ef2[5 - x] and ef2[5 - x].sp != 0 then
							local offset2 = LinkLock.Entity:GetRight() * ef2[5 - x].vec.x + LinkLock.Entity:GetForward() * ef2[5 - x].vec.y + LinkLock.Entity:GetUp() * ef2[5 - x].vec.z
							local clipdir = self:CalcForward()
							local clipdir2 = -LinkLock:CalcForward()
							local cplength = 500
							local start = offset + self:CalcCenterPos()
							local start2 = offset + self:CalcCenterPos() + clipdir * cplength
							local endpos = offset2 + LinkLock:CalcCenterPos()
							local endpos2 = offset2 + LinkLock:CalcCenterPos() - clipdir2 * cplength
							local Scroll = math.fmod(CurTime() * 64,128)
							render.SetMaterial( self.CMat )
							render.DrawBeam( offset + self:CalcCenterPos(), Bezier4(start, start2, endpos2, endpos,(0.1)), 15, Scroll + 10, Scroll,Color( 255, 255, 255, 15 ) ) 
							for i=2, 9 do
								render.DrawBeam( Bezier4(start, start2, endpos2, endpos, i / 10), Bezier4(start, start2, endpos2, endpos,((i - 1) / 10)), 15, Scroll + 10, Scroll,Color( 255, 255, 255, 15 ) ) 
							end
							render.DrawBeam( offset2 + LinkLock:CalcCenterPos(), Bezier4(start, start2, endpos2, endpos,(0.9)), 15, Scroll + 10, Scroll,Color( 255, 255, 255, 15 ) ) 
						end
					end
				end
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
	
end
function ENT:OnRemove()
	if IsValid(self.Model) then
		self.Model:Remove()
	end
end