ENT.Type			      = "anim"
ENT.Base                  = "base_gmodentity"
ENT.PrintName		      = "Elevator System"
ENT.Author			      = "Hysteria"
ENT.Category			  = "SBEP"

ENT.Spawnable			  = false
ENT.AdminSpawnable		  = false

ENT.Purpose 		      = ""

function ENT:SetupDataTables()

	self:NetworkVar( "Int", 1, "ActivePart" )
	self:NetworkVar( "Int", 2, "SBEP_LiftPartCount" )
	self:NetworkVar( "Bool", 2, "LiftActive" )
	-- self:DTVar( "Bool", 0, "On" );
	-- self:DTVar( "Vector", 0, "vecTrack" );
	-- self:DTVar( "Entity", 0, "entTrack" );

end


ENT.WireDebugName = "SBEP Elevator System"

hook.Add("SetupMove", "DoElevatorMovement", function(ply, mv, cmd)
	local ent = ply:GetGroundEntity()
	local tr = util.TraceLine({
		start = ply:WorldSpaceCenter(),
		endpos = ply:WorldSpaceCenter() - ply:GetUp() * 55,
		filter = function(ent) if ent:GetClass() == "sbep_elev_system" then return true else return false end end
	})
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "sbep_elev_system" then ent = tr.Entity end
	if IsValid(ent) and ent:GetClass() == "sbep_elev_system" then
		--ent.LastCurrentElevPos = ent.LastCurrentElevPos or ent:GetPos()
		--local vec = (ent:GetPos() - ent.LastCurrentElevPos)
		--if vec:Length() > 1 then
			--ply:SetGroundEntity(ent)
			mv:SetOrigin(tr.HitPos)
			--mv:SetVelocity(mv:GetVelocity() + vec)
		--end
	end
end)