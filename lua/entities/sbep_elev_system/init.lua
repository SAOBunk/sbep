AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( "shared.lua" ) 

local PT = {SMALLBRIDGE = {}, MODBRIDGE = {} }
PT.SMALLBRIDGE.S = {
		Defaults = { LiftOffset = 4.65, Increment = -60.45, TargetOffset = -60.45, MoveSound = "plats/skylift_move.wav", StopSound = "plats/skylift_stop.wav" }, --each panel model uses these defaults
		Panels = {
			--order of models matters, it depends on ModelAccessTable and defines which model is being used for the different exits
			{ Model = "models/smallbridge/elevators_small/sbselevp0.mdl" },
			{ Model = "models/smallbridge/elevators_small/sbselevp1.mdl", LiftOffset = 4.65, Increment = -60.45, TargetOffset = -60.45 }, --defaults can be overridden based on panel model like this example shows
			{ Model = "models/smallbridge/elevators_small/sbselevp2e.mdl" },
			{ Model = "models/smallbridge/elevators_small/sbselevp2r.mdl" },
			{ Model = "models/smallbridge/elevators_small/sbselevp3.mdl" }
		}
}

PT.SMALLBRIDGE.L = {
	Defaults = { LiftOffset = 4.65, Increment = -60.45, TargetOffset = -60.45, MoveSound = "plats/skylift_move.wav", StopSound = "plats/skylift_stop.wav" },
	Panels = {
		{ Model = "models/smallbridge/elevators_Large/sblelevp0.mdl" },
		{ Model = "models/smallbridge/elevators_Large/sblelevp1.mdl" },
		{ Model = "models/smallbridge/elevators_Large/sblelevp2e.mdl" },
		{ Model = "models/smallbridge/elevators_Large/sblelevp2r.mdl" },
		{ Model = "models/smallbridge/elevators_Large/sblelevp3.mdl" }
	}
}

PT.MODBRIDGE.S = {
	Defaults = { LiftOffset = 81.65, Increment = 100, TargetOffset = 100, MoveSound = "plats/skylift_move.wav", StopSound = "plats/skylift_stop.wav" },
	Panels = {
		{ Model = "models/cerus/modbridge/misc/elevator/elev_111.mdl" },
		{ Model = "models/cerus/modbridge/misc/elevator/elev_111.mdl" },
		{ Model = "models/cerus/modbridge/misc/elevator/elev_111.mdl" },
		{ Model = "models/cerus/modbridge/misc/elevator/elev_111.mdl" },
		{ Model = "models/cerus/modbridge/misc/elevator/elev_111.mdl" }
	}
}

local DD = list.Get( "SBEP_DoorControllerModels" )

local Soundfonts = {
	["Scrappers"] = {
		StartSound = "plats/elevator_start1.wav",
		MoveSound = "plats/skylift_move.wav",
		StopSound = "plats/skylift_stop.wav",
	},
	["Advanced"] = {
		StartSound = "Portal.elevator_chime",
		MoveSound = "ambient/machines/wall_loop1.wav",
		StopSound = "Portal.elevator_ding",
	},
	["SlyBridge"] = {
		StartSound = "outland_06.forklift_start",
		MoveSound = "streetwar.d3_c17_08_lift_move",
		StopSound = "streetwar.d3_c17_08_lift_stop",
	},
	["MedBridge2"] = {
		MoveSound = "d3_citadel.breenlift1_move",
		StopSound = "d3_citadel.breenlift1_stop",
	},
	["Jaanus"] = {
		StartSound = "d3_citadel.small_elevator_start",
		MoveSound = "d3_citadel.small_elevator_move",
		StopSound = "d3_citadel.small_elevator_stop",
	},
	["Modbridge"] = {
		MoveSound = "plats/platform_start_lp_01.wav",
		StopSound = "plats/platform_stop_01.wav",
	},
}

function ENT:Initialize()
	
	self:SetUseType( SIMPLE_USE )

	self.PartTable  = {}
	self.SystemTable  = {}
	self.SystemTable.Panel  = {}
	self.FloorTable  = {}
	self.HatchTable  = {}
	
	if self.Usable == nil then
		self.Usable = true
		self.SystemTable.Usable = true
	else
		self.SystemTable.Usable = self.Usable
	end
	self:SetSystemSize( "S" )
	self.SystemTable.Skin   = self.Skin or 0
	
	self.Entity:SetNetworkedInt( "ActivePart" , 1 )
	self.Entity:SetNetworkedInt( "SBEP_LiftPartCount" , 0 )
	--self:SetModel( PMT[self.Size[1]][5] ) 
	
	self.LiftActive = (false)
	
	self.SystemTable.ModelAccessTable = {0,0,0,0}

	self.SystemTable.CurrentFloor = 1
	
	self.CallFloorTable = {} --for queuing
	self.IsHolding = false
	self.TimerArriveDelay = 0
	self.TimerArriveStartTime = CurTime()
	self.TimerHoldDelay = 0
	self.TimerHoldStartTime = CurTime()
	
	
	
	self.Index = tostring( self:EntIndex() )
	
	self.Increment = -60.45
	self.TargetOffset = -60.45
	
	self.SystemTable.AngleYawOffset = 90
	
	self.ShadowParams = {}
		self.ShadowParams.maxangular = 50000 --What should be the maximal angular force applied
		self.ShadowParams.maxangulardamp = 10000 -- At which force/speed should it start damping the rotation
		self.ShadowParams.maxspeed = 1000000 -- Maximal linear force applied
		self.ShadowParams.maxspeeddamp = 10000-- Maximal linear force/speed before  damping
		self.ShadowParams.dampfactor = 0.8 -- The percentage it should damp the linear/angular force if it reachs it's max ammount
		self.ShadowParams.teleportdistance = 100 -- If it's further away than this it'll teleport (Set to 0 to not teleport)

	self:CheckSkin()
	self.Speed = 2
	self:PhysicsInitialize()
	
	self:StartMotionController()
	
	self:SetTrigger(true)
	
	self.Startup = false
end

function ENT:PhysicsInitialize()
	self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
	local phys = self:GetPhysicsObject()  	
	if IsValid(phys) then  		
		phys:Wake() 
		phys:AddGameFlag(FVPHYSICS_NO_IMPACT_DMG)
		phys:AddGameFlag(FVPHYSICS_CONSTRAINT_STATIC)
		phys:EnableGravity(false)
		phys:EnableMotion(true)
		phys:EnableDrag(false)
		phys:SetMass( 1000 )
	end
end

hook.Add("EntityTakeDamage", "ProtectFromImpactDamage", function(ent, dmg)
	if dmg:IsFallDamage() and ent:GetGroundEntity():GetClass() == "sbep_elev_system" then
		return true
	end
end)

function ENT:CreatePart()
	local NP = ents.Create( "sbep_elev_housing" )
		NP.Cont = self.Entity
		NP:Spawn()
		NP:SetRenderMode( 1 )
		self.Entity:DeleteOnRemove( NP )
		if CPPI and NP.CPPISetOwner then NP:CPPISetOwner( self.Entity:GetOwner() ) end
	return NP
end

function ENT:AddPartToTable( part , pos )
	table.insert( self.PartTable , pos , part )
	part.PartData.PN = pos or self:GetPartCount()
	local ang = self.Entity:GetAngles()
	if self:GetOwner():GetInfo("sbep_lift_designer_set") == "Modbridge" then
		ang = part:GetAngles()
	end
	part.PartData.Pitch, part.PartData.Yaw, part.PartData.Roll = ang.p, (ang.y + 90), ang.r
	self:SetNetworkedInt( "SBEP_LiftPartCount" , self:GetPartCount() )
end

function ENT:RemovePartFromTable( pos )
	self.PartTable[ pos ]:Remove()
	table.remove( self.PartTable , pos )
	self:SetNetworkedInt( "SBEP_LiftPartCount" , self:GetPartCount() )
end

function ENT:RefreshParts( N ) --Refreshes parts from the nth position upwards.
	for n,Part in ipairs( self.PartTable ) do		
		if n >= N then
			Part.PartData.PN = n
			Part:UpdateHeightOffsets()
			Part:RefreshAng()
		end
	end
end

function ENT:AddArriveDelay( delay )
	self.TimerArriveStartTime = CurTime()
	if delay > self.TimerArriveDelay then
		self.TimerArriveDelay = delay
	end
end

function ENT:AddHoldDelay( delay )
	self.TimerHoldStartTime = CurTime()
	if delay > self.TimerHoldDelay then
		self.TimerHoldDelay = delay
	end
	self.IsHolding = true
end

function ENT:GetPartCount()
	return #self.PartTable
end

function ENT:GetFloorCount()
	return #self.FloorTable
end

function ENT:SetSystemSize( size )
	if size == "L" or size == 2 then
		self.Size = { "L" , "l" , "Large" , 1 }
		self.SystemTable.Size = self.Size
	else
		self.Size = { "S" , "s" , "Small" , 0 }
		self.SystemTable.Size = self.Size
	end
end

function ENT:GetSystemSize()
	if self.Size then
		return self.Size[1]
	end
end

function ENT:CheckSkin()
	if self:SkinCount() > 5 then
		self:SetSkin( self.SystemTable.Skin * 2 )
	else
		self:SetSkin( self.SystemTable.Skin )
	end
end

function ENT:StartTouch(ent)
	self.HandledPlayers = self.HandledPlayers or {}
	if ent:IsPlayer() then
		self.HandledPlayers[ent:EntIndex()] = ent
	end
end

function ENT:EndTouch(ent)
	self.HandledPlayers = self.HandledPlayers or {}
	if ent:IsPlayer() then
		table.remove(self.HandledPlayers, ent:EntIndex())
		ent.InElevator = CurTime() + 0.5
		ent:SetGroundEntity(self)
	end
	if self.ATL and not self.ATLFlagged then
		ent:SetVelocity(-ent:GetVelocity())
		self.ATLFlagged = true
	end
end

function ENT:Use()
	if !self.UsableElev then return end
	local cnt = (self.CallFloorTable[1] + 1) % (self:GetFloorCount() + 1) 
	self:AddCallFloorNum( cnt )
end

function ENT:Think()
	for k,v in pairs(self.HandledPlayers) do
		v:SetVelocity(self:GetVelocity())
	end
	local phys = self:GetPhysicsObject()  	
	if IsValid(phys) then  		
		phys:Wake() 
		phys:EnableMotion(true)
		phys:SetMass( 1000 )
	end
	if constraint.FindConstraint(self, "Weld") then constraint.RemoveConstraints(self, "Weld") end
	if IsValid(self:GetParent()) then self:SetParent() end
	
	if IsValid(self.PartTable[1]) and IsValid(self.PartTable[1].SC_CoreEnt) then
		self.SC_CoreEnt = self.PartTable[1].SC_CoreEnt
	end
	
	if !self.LiftActive then
		self.Entity:NextThink( CurTime() + 0.05 )
		return true
	end
	self.Entity:NextThink( CurTime() )
	self:UseTriggerBounds(true)
	--self:DoLiftMovement()
	if self.CallFloorTable[1] then
		self.TargetOffset = self.FloorTable[self:GetFloorNum()]
	end
	if self.PartTable[1] and not constraint.FindConstraint(self, "NoCollide") then
		--self:SetParent(self.PartTable[1])
		constraint.NoCollide(self, self.PartTable[1], 0, 0, 0, true, 0)

	end
	self.ATL = ( math.Round(self.Increment) == math.Round( self.TargetOffset ) )

	if self.ATL ~= self.OldATL then
		if self.SystemTable.UseDoors then
			self:CheckDoorStatus()
		end
		if self.ATL then
			self.Startup = true
			if self.SystemTable.StartSound then self.SystemTable.StartSound:FadeOut(0.2) end
			if self.SystemTable.MoveSound then self.SystemTable.MoveSound:Stop() end
			if self.SystemTable.MusicSound then self.SystemTable.MusicSound:FadeOut(0.2) end
			if self.SystemTable.StopSound then
				self.SystemTable.StopSound:Stop()
				self.SystemTable.StopSound:Play()
				util.ScreenShake( self:GetPos(), 1, 1, 0.3, 300 )
			end
			self:AddArriveDelay( 4 )
		elseif self.SystemTable.UseDoors then
			self:AddHoldDelay( 2 )
		end
		if not self.ATL then
			self.ATLFlagged = false
		end
	end
	self.OldATL = self.ATL
	
	if --[[self.IsHolding ~= self.OIH  and ]] self.SystemTable.UseDoors then
		self:CheckDoorStatus()
	end
	--self.OIH = self.IsHolding
	
	if self.TimerArriveDelay > 0 and CurTime() > ( self.TimerArriveStartTime + self.TimerArriveDelay ) and #self.CallFloorTable > 1 then
		table.remove( self.CallFloorTable , 1 ) 
		self.TimerArriveDelay = 0
	end
	
	if self.TimerHoldDelay > 0 and CurTime() < ( self.TimerHoldStartTime + self.TimerHoldDelay ) then
		if WireAddon then WireLib.TriggerOutput( self , "Holding" , 1 ) end
		return true
	elseif self.TimerHoldDelay > 0 and CurTime() > ( self.TimerHoldStartTime + self.TimerHoldDelay ) then
		self.TimerHoldDelay = 0
		if self.IsHolding then
			self:AddHoldDelay( 2 )
		end
		self.IsHolding = false
		if WireAddon then WireLib.TriggerOutput( self , "Holding" , 0 ) end
	end

	if self.ATL then return true end
	
	self.Increment = self.Increment + math.Clamp( ( self.TargetOffset - self.Increment) , -self.Speed , self.Speed)
	
	local D = 100000
	local F = 0
	for n,H in ipairs( self.FloorTable ) do
		local d = math.abs(H - self.Increment)
		if d < D then
			D = d
			F = n
		end
	end

	if F ~= self.OldCF then
		self.SystemTable.CurrentFloor = F
		if WireAddon then WireLib.TriggerOutput( self , "Floor" , self.SystemTable.CurrentFloor ) end
	end
	if self.Startup and self.SystemTable.MoveSound then self.SystemTable.MoveSound:Play() end
	if self.Startup and self.SystemTable.StartSound then self.SystemTable.StartSound:Play() end
	if self.Startup and self.SystemTable.MusicSound then
		self.SystemTable.MusicSound:Play()
	end
	self.OldCF = self.SystemTable.CurrentFloor
	if self.TargetOffset > self.Increment then
		self.Direction = 1
	else
		self.Direction = -1
	end
	
	if self.SystemTable.UseHatches then
		self:CheckHatchStatus()
	end
	
	
	return true
end

function ENT:PhysicsSimulate( phys, deltatime )
	
	if !self.LiftActive or !self.PartTable or !IsValid(self.PartTable[1]) or !IsValid(self.PartTable[self:GetPartCount()]) then return SIM_NOTHING end

	local Pos1 = self.PartTable[1]:GetPos()
	local Pos2 = self.PartTable[self:GetPartCount()]:GetPos()
	
	self.ShaftDirectionVector = Pos2 - Pos1
	self.ShaftDirectionVector:Normalize()
	
	self.CurrentElevPos = Pos1 + (self.ShaftDirectionVector * self.Increment)
	self.CurrentElevAng = self.PartTable[1]:GetAngles()
	if self.PartTable[1].PartData.Inv then
		self.CurrentElevAng = self.CurrentElevAng + Angle( 0 , 0 , 180 )
	end

	self.CurrentElevAng:RotateAroundAxis( self.ShaftDirectionVector , self.SystemTable.AngleYawOffset )
	
	phys:Wake()
	self.ShadowParams.secondstoarrive = 0.01
	self.ShadowParams.pos = self.CurrentElevPos
	self.ShadowParams.angle = self.CurrentElevAng
	self.ShadowParams.deltatime = deltatime
	
	return phys:ComputeShadowControl(self.ShadowParams)

end

-- hook.Add("SetupMove", "DoElevatorMovement", function(ply, mv, cmd)
	-- local ent = ply:GetGroundEntity()
	-- local tr = util.TraceLine({
		-- start = ply:WorldSpaceCenter(),
		-- endpos = ply:WorldSpaceCenter() - ply:GetUp() * 55,
		-- filter = function(ent) if ent:GetClass() == "sbep_elev_system" then return true else return false end end
	-- })
	-- if IsValid(tr.Entity) and tr.Entity:GetClass() == "sbep_elev_system" then ent = tr.Entity end
	-- if IsValid(ent) and ent:GetClass() == "sbep_elev_system" then
		-- ent.LastCurrentElevPos = ent.LastCurrentElevPos or ent:GetPos()
		-- local vec = (ent:GetPos() - ent.LastCurrentElevPos)
		-- if vec:Length() > 1 then				
			-- if vec.z < 1 then
				-- if vec:GetNormalized():Dot(ent:GetUp()) > 0 then
					-- vec = vec * 2
				-- end
				-- mv:SetOrigin(mv:GetOrigin() + vec)
				-- ply:SetGroundEntity(ent)
			-- else
				-- mv:SetOrigin(tr.HitPos)
			-- end
			-- mv:SetVelocity(mv:GetVelocity() + vec)
		-- end
		-- end
-- end)

function ENT:CheckHatchStatus()
	if 	!self.SystemTable.UseHatches 	 or
		!self.LiftActive 		 or
		self.ATL 				 or
		!self.HatchTable then return end

	for k,V in pairs( self.HatchTable ) do
		if V:GetSkin() ~= self.SystemTable.Skin then V:SetSkin( self.SystemTable.Skin ) end
		if self.Direction == 1 then
			if self.Increment > ( V.HatchData.HO + 20 ) then
				V.OpenTrigger = false
			elseif self.Increment > ( V.HatchData.HO - 240 ) then
				V.OpenTrigger = true
				V:SetNotSolid(true)
			end
		elseif self.Direction == -1 then
			if self.Increment < ( V.HatchData.HO - 100 ) then
				V.OpenTrigger = false
			elseif self.Increment < ( V.HatchData.HO + 50 ) then
				V.OpenTrigger = true
				V:SetNotSolid(true)
			end
		end
		if self.ATL then
			V.OpenTrigger = false
			V:SetNotSolid(false)
		end
		V:SetPlaybackRate(self.Speed)
		V.Speed = self.Speed
	end
end

function ENT:CheckDoorStatus()
	if (!self.SystemTable.UseDoors) or (!self.LiftActive) or !self.PartTable then return end

	if self.ATL then
		for k,V in ipairs( self.PartTable[ self:FloorToPartNum( self:GetFloorNum() ) ].PartData.FloorDoorTable ) do
			V.OpenTrigger = true
		end
	elseif !self.IsHolding then
		for k,V in ipairs( self.PartTable ) do
			for m,D in ipairs( V.PartData.FloorDoorTable ) do
				D.OpenTrigger = false
			end
		end
	end
end

function ENT:FinishSystem()

	self:RefreshParts( 1 ) --Refreshes all parts
	self:RemovePartFromTable( self:GetPartCount() ) --Removes the top ghost entity
	local C = self:GetPartCount()

	local P2 = self.PartTable[ C ] --Switches the top and bottom parts to have floors/ceilings
		if P2.PartData.Inv then
			P2:SetPartClass( "B" )
		else
			P2:SetPartClass( "T" )
		end	
	local P1 = self.PartTable[ 1 ]
		if P1.PartData.Inv then
			P1:SetPartClass( "T" )
		else
			P1:SetPartClass( "B" )
		end
	self:RefreshParts( 1 ) --Refreshes all parts

	for n,Part in ipairs( self.PartTable ) do
		Part:SetRenderMode( RENDERMODE_NORMAL )
		Part:SetColor( Color( 255 , 255 , 255 , 255 )) --Makes sure everything is opaque again
		self:CalcPanelModel( n ) --Works out what model the lift panel should be
		Part:PhysicsInitialize() --Calls physics for all the parts, which have all had models changed
	end
	self:PhysicsInitialize() --Calls physics for self
	
	self:CheckSkin() --Sets skin of self
	
	self:StartMotionController()
	
	self.SystemTable.model = self:GetModel()
	
	self:WeldSystem() --Welds and Nocollides the parts appropriately
	
	self.Entity:GetPhysicsObject():EnableMotion( true )
	
	self.Increment = self.SystemTable.Panel.Increment or PT[self.Entity.Set][self.Size[1]].Defaults.Increment or 0

	self.TargetOffset = self.SystemTable.Panel.TargetOffset or PT[self.Entity.Set][self.Size[1]].Defaults.TargetOffset or 0

	self.LiftOffset = self.SystemTable.Panel.LiftOffset or PT[self.Entity.Set][self.Size[1]].Defaults.LiftOffset or 0

	self:CreateSounds()
	
	for n,Part in ipairs( self.PartTable ) do --Setting up the floors 
		if !Part.PartData.SD.IsShaft then
			Part:MakeWire()
			local C3 = math.Clamp( Part.PartData.Roll , 0 , 1 )
			local C4 = math.abs( C3 - 1 )
			if Part.PartData.SD.MultiFloorTable then
				Part.PartData.FloorOffset = {}
				Part.PartData.FN = {}
				for m,n in ipairs( Part.PartData.SD.MultiFloorTable ) do
					Part.PartData.FloorOffset[m] = Part.PartData.HO - C3*Part.PartData.ZUD - C4*Part.PartData.ZDD + self.LiftOffset + n
					table.insert( self.FloorTable , Part.PartData.FloorOffset[m] )
					Part.PartData.FN[m] = self:GetFloorCount()
				end
			else
				Part.PartData.FloorOffset = Part.PartData.HO - C3*Part.PartData.ZUD - C4*Part.PartData.ZDD + self.LiftOffset --Calculates floor offset, depending on part roll offset
				table.insert( self.FloorTable , Part.PartData.FloorOffset )
				Part.PartData.FN = self:GetFloorCount()
			end
		end
	end
	
	if self.SystemTable.UseHatches then
		self:CreateHatches()
	elseif self.SystemTable.UseDoors then
		self:CreateDoors()
	end
	
	self:MakeWire()
	
	self:AddCallFloorNum( 1 )
	
	self.LiftActive = (true)
	
	local ply = self.Entity:GetOwner()
	undo.Create( "SBEP Lift System" )
		undo.AddEntity( self )
		for _,Part in ipairs( self.PartTable ) do
			undo.AddEntity( Part )
			if Part.PartData and Part.PartData.FloorDoorTable then
				for _,D in ipairs( Part.PartData.FloorDoorTable ) do
					undo.AddEntity( D )
				end
			end
		end
		for _,Part in ipairs( self.HatchTable ) do
			undo.AddEntity( Part )
		end
		undo.SetPlayer( ply )
	undo.Finish()

	self:SetOwner(nil)
	if CPPI and self.CPPISetOwner then self:CPPISetOwner(ply) end
end

function ENT:CreateHatches()		--Creating Hatches. Each Hatch is paired with the part below it, so the top part has no hatch associated.
	--print( "Making Hatches" )
	for k,V in pairs(self.PartTable) do
		local V1 = self.PartTable[k + 1]
		if !(k == self:GetPartCount()) and !(V.PartData.SD.IsShaft and V1.PartData.SD.IsShaft) then
			local NH = ents.Create( "sbep_base_door" )
				--print( "Made Hatch" )
				NH:Spawn()
				NH.HatchData = {}
				NH:SetDoorType( "Door_ElevHatch_"..self.Size[1] )
				timer.Simple(0, function()
					if IsValid(NH) and IsValid(self) then
						NH:SetSkin( self.SystemTable.Skin )
					end
				end)
					local C3 = math.Clamp( V.PartData.Roll , 0 , 1 )
					local C4 = math.abs( C3 - 1 )
					local S = 1
					if V1.PartData.SD.IsShaft then S = -1 end
				NH.HatchData.PO = C3*V.PartData.ZDD + C4*V.PartData.ZUD + S*4.65	--Offset from paired part
				NH.HatchData.HO = V.PartData.HO + NH.HatchData.PO					--Offset from system origin
			NH:Attach( V , Vector(0,0,NH.HatchData.PO) , V:GetAngles() )
			if CPPI and NH.CPPISetOwner then NH:CPPISetOwner( self:GetOwner() ) end

			table.insert( self.HatchTable , NH )
		end
	end
end

function ENT:CreateDoors()
	for n,Part in ipairs( self.PartTable ) do
		Part.PartData.FloorDoorTable = {}
		local data = DD[ string.lower( Part.PartData.model ) ]
		if data then
			for n,I in ipairs( data ) do
				if !(I.type == "Door_ElevHatch_S" or I.type == "Door_ElevHatch_L") then
					local ND = ents.Create( "sbep_base_door" )
						ND:Spawn()
						ND:Initialize()
						ND:SetDoorType( I.type )
						ND:Attach( Part, I.V, I.A )
						if CPPI and ND.CPPISetOwner then ND:CPPISetOwner( self:GetOwner() ) end
					table.insert( Part.PartData.FloorDoorTable , ND )
					self.Entity:DeleteOnRemove( ND )
				end
			end
		end
	end
end

function ENT:WeldSystem() --Welds and nocollides the system once completed.
	local C = self:GetPartCount()
	if C > 1 then
		for k,V in ipairs( self.PartTable ) do
			if IsValid( V ) and IsValid(self.PartTable[k + 1]) then
				constraint.Weld( V , self.PartTable[k + 1] , 0 , 0 , 0 , true )
			end
			if IsValid( V ) and IsValid(self.PartTable[k + 2]) and (k/2 == math.floor(k/2)) then
				constraint.Weld( V , self.PartTable[k + 2] , 0 , 0 , 0 , true )
			end
			if IsValid( V ) and IsValid(self) then
				constraint.NoCollide( V , self , 0 , 0 )
			end
		end
		if IsValid(self.PartTable[1]) and IsValid(self.PartTable[ C ]) then
			constraint.Weld( self.PartTable[1] , self.PartTable[ C ] , 0 , 0 , 0 , true )
		end
	end
end

function ENT:CalcPanelModel( PartNum )

	local Part = self.PartTable[ PartNum ]
	
	if Part.PartData.TC == "R" and Part.PartData.Inv then
		Part.PartData.AT = {0,1,1,0}
	end
	
	local function RotateAT( r )
		for i = 1 , r do
			table.insert( Part.PartData.AT , Part.PartData.AT[1] )
			table.remove( Part.PartData.AT , 1 )
		end
	end
	--Rotating the part access table.----------------
	if Part.PartData.TC ~= "X" then
		RotateAT( Part.PartData.Yaw / 90 )
	end
	------------------------
	
	--Adds any new open access points to the model access table.------------------
	for k,v in ipairs( Part.PartData.AT ) do
		if v > self.SystemTable.ModelAccessTable[k] then
			self.SystemTable.ModelAccessTable[k] = v
		end
	end
	
	self.SystemTable.MATSum = self.SystemTable.ModelAccessTable[1] + self.SystemTable.ModelAccessTable[2] + self.SystemTable.ModelAccessTable[3] + self.SystemTable.ModelAccessTable[4]
	DMT = PT[self.Entity.Set][self.Size[1]].Panels
	local function SetLiftModel( n )
		self.SystemTable.Panel = DMT[ n ]
		self:SetModel( self.SystemTable.Panel.Model )
	end
	local S = self.SystemTable.MATSum
	local T = self.SystemTable.ModelAccessTable
	
	--Using the model access table to work out the model and rotation of the elevator panel.-----------------
	if S == 4 then
		SetLiftModel( 1 )
		self.SystemTable.AngleYawOffset = 0
	elseif S == 1 then 
		SetLiftModel( 5 )
		self.SystemTable.AngleYawOffset = ((T[4] * 90) + (T[3] * 180) + (T[2] * 270) )
	elseif S == 3 then 
		SetLiftModel( 2 )
		self.SystemTable.AngleYawOffset = (((T[1] - 1) * -90) + ((T[4] - 1) * -180) + ((T[3] - 1) * -270))
	elseif S == 2 then 
		if T[1] == T[3] then
			SetLiftModel( 3 )
			self.SystemTable.AngleYawOffset = (T[2] * 90)
		elseif T[1] == T[2] or T[2] == T[3] then
			SetLiftModel( 4 )
			if T[1] == 1 then
				self.SystemTable.AngleYawOffset =  (T[2] * -90) % 360
			elseif T[3] == 1 then
				self.SystemTable.AngleYawOffset =  ((T[4] * 90) + (T[2] * 180)) % 360
			end
		end
	end
	------------------------------------------------
end

function ENT:MakeWire( bAdjust ) --Adds the appropriate wire inputs.

	if(not WireAddon) then return end
	
	self.SBEP_WireInputsTable = {}
	self.SBEP_WireInputsTable[1] = "FloorNum"
	for k,v in ipairs( self.FloorTable ) do
		table.insert( self.SBEP_WireInputsTable , ( "Floor "..tostring(k) ) )
	end
	table.insert( self.SBEP_WireInputsTable , ( "Hold" ) )
	table.insert( self.SBEP_WireInputsTable , ( "Speed" ) )
	if bAdjust then
		self.Inputs = Wire_AdjustInputs(self.Entity, self.SBEP_WireInputsTable )
	else
		self.Inputs = Wire_CreateInputs(self.Entity, self.SBEP_WireInputsTable)
	end
	
	self.Outputs = WireLib.CreateOutputs(self.Entity,{"Floor","Holding"})
end

function ENT:TriggerInput(k,v)

	if k == "FloorNum" then
		self:AddCallFloorNum( v )
	end
	
	for i = 1, self:GetFloorCount() do
		if k == ("Floor "..tostring(i)) and v > 0 then
			self:AddCallFloorNum( i )
		end
	end
	
	if k == "Hold" and v > 0 then
		if self.SystemTable.StartSound then self.SystemTable.StartSound:Stop() end
		if self.SystemTable.MoveSound then self.SystemTable.MoveSound:Stop() end
		if self.SystemTable.MusicSound then self.SystemTable.MusicSound:FadeOut(0.2) end
		if self.SystemTable.StopSound then
			self.SystemTable.StopSound:Stop()
			self.SystemTable.StopSound:Play()
		end
		util.ScreenShake( self:GetPos(), 5, 5, 2, 300 )	
		self:AddHoldDelay( 4 )
	end
	if k == "Speed" then
		self.Speed = math.Clamp(v, 0, 18)
	end
end

function ENT:CreateSounds()
	local StartSound = Soundfonts[self.Soundfont].StartSound
	local MoveSound = Soundfonts[self.Soundfont].MoveSound
	local StopSound = Soundfonts[self.Soundfont].StopSound
	local MusicSound = self.MusicPath
	if StartSound then 
		self.SystemTable.StartSound = CreateSound(self, StartSound) 
		self.SystemTable.StartSound:Stop()
		else
		self.SystemTable.StartSound = nil
	end
	if MoveSound then 
		self.SystemTable.MoveSound = CreateSound(self, MoveSound) 
		self.SystemTable.MoveSound:Stop()
		else 
		self.SystemTable.MoveSound = nil
	end
	if self.Music and 
		MusicSound then
		self.SystemTable.MusicSound = CreateSound(self, MusicSound) 
		self.SystemTable.MusicSound:Stop()
		else
		self.SystemTable.MusicSound = nil
	end
	if StopSound then 
		self.SystemTable.StopSound = CreateSound(self, StopSound) 
		self.SystemTable.StopSound:Stop()
		else
		self.SystemTable.StopSound = nil
	end
end

function ENT:AddCallFloorNum( FN )
	FN = math.Clamp( math.Round( FN ), 1, self:GetFloorCount() )
	self.StartPart = self:GetFloorNum()
	if !self.CallFloorTable then self.CallFloorTable = {} end
	if !table.HasValue( self.CallFloorTable , FN ) then
		table.insert( self.CallFloorTable , FN )
	end
end

function ENT:FloorToPartNum( fn )
	for n,Part in ipairs( self.PartTable ) do
		if Part.PartData.SD.MultiFloorTable then
			for k,F in ipairs( Part.PartData.FN ) do
				if F == fn then return Part.PartData.PN end
			end
		else
			if Part.PartData.FN == fn then return Part.PartData.PN end
		end
	end
	return nil
end

function ENT:PartToFloorNum( pn )
	return self.PartTable[ pn ].FN
end

function ENT:GetFloorNum()
	return self.CallFloorTable[1]
end

function ENT:PreEntityCopy()
	local DI = {}
	DI.Set = self.Entity.Set
		DI.SystemTable  = self.SystemTable
		DI.FloorTable  = self.FloorTable
		DI.Increment = self.Increment
		DI.Soundfont = self.Soundfont
		DI.UsableElev = self.UsableElev
		DI.Music = self.Music
		DI.MusicPath = self.MusicPath
		DI.PartTable = {}
			for n,Part in pairs( self.PartTable ) do
				DI.PartTable[n] = Part:EntIndex()
			end
		if self.SystemTable.UseHatches then
			DI.HDT = {}
			for k,v in pairs( self.HatchTable ) do
				DI.HDT[k]		= {}
				DI.HDT[k].Index = v:EntIndex()
				DI.HDT[k].HatchData 	= v.HatchData
			end
		end
	if WireAddon then
		DI.WireData = WireLib.BuildDupeInfo( self.Entity )
	end
	duplicator.StoreEntityModifier(self, "SBEPLS", DI)
end
duplicator.RegisterEntityModifier( "SBEPLS" , function() end)

function ENT:PostEntityPaste(pl, Ent, CreatedEntities)

	local DT = Ent.EntityMods.SBEPLS
	self.Entity.Set = DT.Set
	self.SystemTable			= DT.SystemTable
	self.FloorTable			= DT.FloorTable
	self.Increment		= DT.Increment
	self.UsableElev		= DT.UsableElev
	self.Soundfont = DT.Soundfont
	self.Music = DT.Music
	self.MusicPath = DT.MusicPath
	for n = 1, #DT.PartTable do
		self.PartTable[n] 	= CreatedEntities[DT.PartTable[n]]
	end
	
	if self.SystemTable.UseHatches then
		self.HatchTable = {}
		for n, H in ipairs( DT.HDT ) do
			self.HatchTable[n] 				= CreatedEntities[H.Index]
			self.HatchTable[n].HatchData			= H.HatchData
		end
	end
	
	self:MakeWire()
	
	if(Ent.EntityMods and DT.WireData and WireAddon) then
		WireLib.ApplyDupeInfo( pl, Ent, DT.WireData, function(id) return CreatedEntities[id] end)
	end
	
	--self:RefreshParts( 1 )
	self.Entity:GetPhysicsObject():EnableMotion( true )
	self.LiftActive = 1
	self:AddCallFloorNum( 1 )
	self:CreateSounds()
end
function LiftSystemRemoved(ent)
		if ent:GetClass() == "sbep_elev_system" then
			if ent.SystemTable.StartSound then ent.SystemTable.StartSound:Stop() end
			if ent.SystemTable.MoveSound then ent.SystemTable.MoveSound:Stop() end
			if ent.SystemTable.MusicSound then ent.SystemTable.MusicSound:Stop() end
			if ent.SystemTable.StopSound then ent.SystemTable.StopSound:Stop() end
		end
end

hook.Add("EntityRemoved", "LiftSystemRemoved", LiftSystemRemoved) 