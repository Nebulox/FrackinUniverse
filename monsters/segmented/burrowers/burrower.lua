require "/scripts/vec2.lua"
require "/scripts/actions/animator.lua"

local monsterUpdate = update
--[[
function updateAngularVelocity(dt)
  local positionDiff = world.distance(self.lastPosition or mcontroller.position(), mcontroller.position())
  self.angularVelocity = -vec2.mag(positionDiff) / dt / self.ballRadius

  if positionDiff[1] > 0 then
    self.angularVelocity = -self.angularVelocity
  end
end

function updateRotationFrame(dt)
  self.angle = math.fmod(math.pi * 2 + self.angle + self.angularVelocity * dt, math.pi * 2)
  local rotationFrame = math.floor(self.angle / math.pi * self.ballFrames) % self.ballFrames
  if mcontroller.facingDirection() == -1 then
    rotationFrame = self.ballFrames - ( 1 + rotationFrame)
  end
  animator.setGlobalTag("rotationFrame", rotationFrame + 1)
end
]]

function burrowEffect(dt)

    self.burrowing = world.pointTileCollision(mcontroller.position(), {"Block"})

    if not self.burrowed == self.burrowing then 
	world.spawnProjectile(self.burrowBurstProjectile, mcontroller.position())
    	animator.burstParticleEmitter("groundBurstEmitter")
    	animator.setParticleEmitterActive("behindGroundEmitter", self.burrowing)
  	animator.setGlobalTag("groundState", self.burrowing and "below" or "above" )
    else  
	self.burrowTick = self.burrowTick - dt
	if self.burrowTick <= 0 then
	    world.spawnProjectile(self.burrowProjectile, mcontroller.position())
	    self.burrowTick = self.burrowTimer
	end
    end
    self.burrowed = self.burrowing
end

function twistEffect()
	self.twist = self.twist and self.twist or 0
	self.newTwist = vec2.angle(mcontroller.velocity())
	animator.rotateTransformationGroup("body", self.twist - self.newTwist)
	self.twist = self.newTwist
end

function update(dt)

	self.parent = self.parent and self.parent or config.getParameter("parent")
	--[[
	if not self.angularVelocity then
	  self.angularVelocity = 0
	  self.angle = 0
	  self.rotationFrame = 0
	  self.ballFrames = config.getParameter("frames")
	  self.ballRadius = config.getParameter("radius")
	end
	]]
	if not self.burrowTimer then
	  self.burrowProjectile = config.getParameter("burrowProjectile", "burrow")
	  self.burrowBurstProjectile = config.getParameter("burrowBurstProjectile", "burrowburst")
	  self.burrowTimer = config.getParameter("burrowTimer",0.25)
	  self.burrowTick = self.burrowTimer
	end
	if not self.followRadius then
	  self.parentRadius =  config.getParameter("parentRadius",1)
	  local segmentRadius = config.getParameter("radius",1)
	  self.followRadius =  segmentRadius + self.parentRadius
	  local movementSettings = config.getParameter("movementSettings")
	  self.flySpeed = movementSettings.flySpeed
	end
	
	self.monsterUpdate = self.monsterUpdate and self.monsterUpdate or monsterUpdate
	self.monsterUpdate(dt)	
	
	if world.entityExists(self.parent and self.parent or -1) then
		local distance 	= entity.distanceToEntity(self.parent)
		local angle 	= vec2.angle(distance)
		local magnitude = world.magnitude(mcontroller.position(),world.entityPosition(self.parent))
		self.tilt = self.tilt and self.tilt or angle
		if magnitude > self.followRadius * 2 then
			mcontroller.setPosition(world.entityPosition(self.parent))
		end
		if world.magnitude(mcontroller.position(),world.entityPosition(self.parent)) > self.followRadius then
		  mcontroller.controlApproachVelocityAlongAngle(angle, self.flySpeed + magnitude, 1500)
		  --[[animator.rotateTransformationGroup("body", self.tilt - angle)
		  self.tilt = angle
		  ]]
		twistEffect()
		else
		  mcontroller.setVelocity(vec2.approach(distance,world.entityPosition(self.parent),self.parentRadius))
		end
	end
	--[[
  	updateAngularVelocity(dt)
  	updateRotationFrame(dt)
  	self.lastPosition = mcontroller.position()
	]]
	burrowEffect(dt)
end
