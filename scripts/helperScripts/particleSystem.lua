local particleSystem={allowParticles=true}

local debugStmt=require "scripts.helperScripts.printDebugStmt"
local toast=require "scripts.helperScripts.toast"

local particleSystem_mt={__index=particleSystem}--particle system metatable

local myMath={
	atan2=math.atan2,
	abs=math.abs,
	deg=math.deg,
	rad=math.rad,
	random=math.random,
	pi=math.pi,
	floor=math.floor,
	pow=math.pow,
	cos=math.cos,
	sin=math.sin,
	exp=math.exp,
	sqrt=math.sqrt,
	round=math.round,
	huge=math.huge,
}
--------------------------------
--Descriptions and requirements: NOTE: all variance values are added/ subtracted from the base value thereby treating the base as mean
--------------------------------
--Name: optional paramter that can assist with debugging 
--x, xVar are the mean xPosition and the possible offset range to the left or right of that position. Similarly for y and yVar
--particlePath is a table that contains file paths to all particles that are available for use in this emitter. Any of the available particles will be selected at random.
--emissionRate specifies the rate of emission for particles and hence governs their volume. IMP: rate that exceeds FPS will not work
--count indicates the number of particles that will be emitted at once. This is necessary sometimes for things like radial emissions. Default value is 1
--startScale and startScaleVar are the minimum ABSOLUTE scale at the start and the variance to that scale that is allowed. 
--endScale and endScaleVar are the minimum ABSOLUTE scale at the end and the variance to that scale that is allowed. 
--life and lifeVar are the minimum duration for any particle and the variance which can be added or subtracted
--angle is the mean Angle and angleVar is the rotation that can be added or subtracted from it. IN DEGREES
--vX and vY are the velocities in px/s that will be applied. Supply negative values if needed in order to change direction.
--vXVar and vYVar, like other "vars" are used to provide an automated +/- offset around the mean values of vx and vy
--shouldFadeOut is a flag that will cause the particle to fade out entirely over its lifetime. Note that if colorVarEnd is supplied, this parameter will not work and colours (incl alpha)should be provided explicitly
--startColor is an rgba table. if no value is supplied, the standard alpha of image will be regarded as 1 and the default image colour is used
--colorVarStart is a single table that can be nested with any number of tables with rgba combinations to be used for randomisation of colour at the time of start. Alpha is supported
--colorVarEnd is a single table that can be nested with any number of tables with rgba combinations to be used for randomisation of colour at the time of end. Alpha is supported
--colorVarStart sample: colorVarStart={}; colorVarStart[1]={r= ,b= ,g= ,a= ,}; colorVarStart[2]={r= ,b= ,g= ,a= ,} etc.
--angularV is the speed in degrees/s that can be optionally supplied. If counterClockwise motion is needed, supply a negative value. Direction is NOT randomised
--isRadial is an optional flag that can be passed. If this is true, particle will always be oriented in the direction of their net velocity. Other settings such as algularV etc will be ignored. 
--gravity is positive y-gravity in px/s^2
--forceSingleEmission is a flag that can be raised for one-off emitters to force one blast of emitted particles. For these emitters, it is best to set emission rate to a safely high value
--highPerformanceMode can be set to true. This will make the emitter run in half framerate for improved performance
--------------------------------To make experimentation easier, instead of passing arguments, a data table with KVpairs can be passed in
function particleSystem.new(data)
	local newParticle={
		name=data.name,
		x=data.x,
		y=data.y,
		xVar=data.xVar,
		yVar=data.yVar,
		displayGroup=data.displayGroup,
		particlePath=data.particlePath,
		emissionRate=data.emissionRate,
		count=data.count,
		startScale=data.startScale,
		startScaleVar=data.startScaleVar,
		endScale=data.endScale,
		endScaleVar=data.endScaleVar,
		life=data.life,
		lifeVar=data.lifeVar,
		angle=data.angle,
		angleVar=data.angleVar,
		isRadial=data.isRadial,
		vX=data.vX,
		vXVar=data.vXVar,
		vY=data.vY,
		vYVar=data.vYVar,
		shouldFadeOut=data.shouldFadeOut,
		startColor=data.startColor,
		colorVarStart=data.colorVarStart,
		colorVarEnd=data.colorVarEnd,
		angularV=data.angularV,
		gravity=data.gravity,
		forceSingleEmission=false,--turning this on for any emitter will only force a single emission, irrespective of count, isPaused, emissionRate etc 
		-------------
		imageTable={},--actual particles will be contained here
		isPaused=true,--the particle object will be paused by default and needs to be explicitly started by turning off this flag
		---------other parameters for internal use, timeKeeping etc:
		emissionTimer=0,
		emissionTimeLimit=0,
		--define a system that can be used to block updation of individual emitters
		highPerformanceMode=data.highPerformanceMode,--can be specified at the time of defining the emitter
		skipUpdation=false,-- can be used as a toggle to skip every alternate update call
		previousDT=0,-- needed to ensure that accurate updates are made in the event the last one was skipped. Used as a compensation value that is added to current dt
		bypassPostProcess=data.bypassPostProcess--this flag can be raised to prevent post processing from being applied in other parts of the code
	}
	--check for nil values that were not passed in the table and assign defaults
	if(newParticle.name==nil)then
		newParticle.name="nil"
	end	
	if(newParticle.x==nil)then
		newParticle.x=0
	end	
	if(newParticle.y==nil)then
		newParticle.y=0
	end	
	if(newParticle.xVar==nil)then
		newParticle.xVar=0	
	end	
	if(newParticle.yVar==nil)then
		newParticle.yVar=0
	end	
	if(newParticle.displayGroup==nil)then
		newParticle.displayGroup=display.newGroup( )
		toast.showToast("ParticleSystem: display group missing")
	end	
	if(newParticle.particlePath==nil)then
		newParticle.particlePath=nil	
	end	
	if(newParticle.emissionRate==nil)then
		newParticle.emissionRate=0
	end	
	if(newParticle.count==nil)then
		newParticle.count=1
	end		
	if(newParticle.startScale==nil)then
		newParticle.startScale=1
	end	
	if(newParticle.startScaleVar==nil)then
		newParticle.startScaleVar=0	
	end	
	if(newParticle.endScale==nil)then
		newParticle.endScale=newParticle.startScale--if no endScale was specified, it should take up the same value as start scale
	end	
	if(newParticle.endScaleVar==nil)then
		newParticle.endScaleVar=0
	end		
	if(newParticle.life==nil)then
		newParticle.life=0	
	end	
	if(newParticle.lifeVar==nil)then
		newParticle.lifeVar=0
	end		
	if(newParticle.angle==nil)then
		newParticle.angle=0	
	end	
	if(newParticle.angleVar==nil)then
		newParticle.angleVar=0
	end	
	if(newParticle.isRadial==nil)then
		newParticle.isRadial=false
	end		
	if(newParticle.vX==nil)then
		newParticle.vX=0	
	end	
	if(newParticle.vXVar==nil)then
		newParticle.vXVar=0	
	end	
	if(newParticle.vY==nil)then
		newParticle.vY=0	
	end	
	if(newParticle.vYVar==nil)then
		newParticle.vYVar=0	
	end	
	if(newParticle.shouldFadeOut==nil)then
		newParticle.shouldFadeOut=false
	end	
	if(newParticle.startColor==nil)then
		newParticle.startColor={r=1,g=1,b=1,a=1}
	end	
	if(newParticle.colorVarStart==nil)then
		newParticle.colorVarStart={}
	end	
	if(newParticle.colorVarEnd==nil)then
		newParticle.colorVarEnd={}
	end	
	if(newParticle.angularV==nil)then
		newParticle.angularV=0	
	end
	if(newParticle.gravity==nil)then
		newParticle.gravity=0	
	end
	if(newParticle.highPerformanceMode==nil)then
		newParticle.highPerformanceMode=false
	end

	--initialise the time gap and timers that will control the emission of particles
	newParticle.emissionTimeLimit=1/newParticle.emissionRate
	newParticle.emissionTimer=newParticle.emissionTimeLimit

	return setmetatable(newParticle,particleSystem_mt)
end
local counter=0

---------------------------------
--for each emitter in the programme, the update function should be called explicitly
--NOTE: the OPTIONAL worldTranslate table is PROJECT-SPECIFIC (eg. in ForestRun). Specifiying these values can allow for relative motion to be applied to individual particles. 
function particleSystem:update(dt,worldTranslation)

	--only if the current emitter object is running in highPerformanceMode, decide if the execution needs to be skipped and make a record of the dt value for future use. 
	if(self.highPerformanceMode)then
		
		self.skipUpdation=not self.skipUpdation

		--if the current emitter's execution was to be skipped, save value of the deltaTime and skip the updation
		if(self.skipUpdation)then
			self.previousDT=dt
			return
		end

		dt=dt+self.previousDT
	end

	--don't add new particles if the particle object was paused by its owner or if the particleSystem was disabled entirely. If forceSingleEmission was on, particles will be spawned once
	if((not self.isPaused or self.forceSingleEmission) and particleSystem.allowParticles)then
		--incrment the emission timer when the particle effect is not paused
		self.emissionTimer=self.emissionTimer+dt
		
		--if a particle can now be spawned and enough time had passed, reset the timer
		if(self.emissionTimer>self.emissionTimeLimit)then
			self.emissionTimer=0

			--now fabricate as many particles as are required by the "count" parameter
			for i=1, self.count do
				local selector=myMath.random(7)-- a random  selector with 1-7 range
				local x
				--compute variation to be applied to x
				if(selector==1)then
					x=self.x-self.xVar*0.25
				elseif(selector==2)then
					x=self.x+self.xVar*0.25
				elseif(selector==3)then
					x=self.x-self.xVar*0.5
				elseif(selector==4)then
					x=self.x+self.xVar*0.5
				elseif(selector==5)then
					x=self.x-self.xVar
				elseif(selector==6)then
					x=self.x+self.xVar	
				elseif(selector==7)then
					x=self.x
				end	
				--for radial emitters, x and y variations cannot be respected
				if(self.isRadial)then
					x=self.x
				end

				--compute variation to be applied to y
				local selector=myMath.random(7)
				local y
				if(selector==1)then
					y=self.y-self.yVar*0.25
				elseif(selector==2)then
					y=self.y+self.yVar*0.25
				elseif(selector==3)then
					y=self.y-self.yVar*0.5
				elseif(selector==4)then
					y=self.y+self.yVar*0.5
				elseif(selector==5)then
					y=self.y-self.yVar
				elseif(selector==6)then
					y=self.y+self.yVar
				elseif(selector==7)then
					y=self.y
				end		
				--for radial emitters, x and y variations cannot be respected
				if(self.isRadial)then
					y=self.y
				end

				--make the image by picking one of the available path options at random, if a table was provided, else use the variable "particlePath" directly
				if(#self.particlePath>0)then
					local imagePath=self.particlePath[myMath.random(#self.particlePath)]
					self.imageTable[#self.imageTable+1]=display.newImg(self.displayGroup,imagePath,x,y,true) --make bypassDocDirectory flag true
					if(self.bypassPostProcess)then--this flag can be turned on to prevent post processing from being applied in other parts of the code
						self.imageTable[#self.imageTable].bypassPostProcess=true
					end
				else
					self.imageTable[#self.imageTable+1]=display.newImg(self.displayGroup,self.particlePath,x,y,true)--make bypassDocDirectory flag true
					if(self.bypassPostProcess)then
						self.imageTable[#self.imageTable].bypassPostProcess=true
					end
				end
				
				--compute variation to be applied to startScale
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable]:scale(self.startScale-self.startScaleVar*0.25,self.startScale-self.startScaleVar*0.25)
				elseif(selector==2)then
					self.imageTable[#self.imageTable]:scale(self.startScale-self.startScaleVar*0.5,self.startScale-self.startScaleVar*0.5)
				elseif(selector==3)then
					self.imageTable[#self.imageTable]:scale(self.startScale+self.startScaleVar*0.25,self.startScale+self.startScaleVar*0.25)
				elseif(selector==4)then
					self.imageTable[#self.imageTable]:scale(self.startScale+self.startScaleVar*0.5,self.startScale+self.startScaleVar*0.5)	
				elseif(selector==5)then
					self.imageTable[#self.imageTable]:scale(self.startScale+self.startScaleVar,self.startScale+self.startScaleVar)
				elseif(selector==6)then
					self.imageTable[#self.imageTable]:scale(self.startScale-self.startScaleVar,self.startScale-self.startScaleVar)		
				elseif(selector==7)then
					self.imageTable[#self.imageTable]:scale(self.startScale,self.startScale)
				end		

				--store a reference to the allocated startScale so that interpolation wrt to end scale can be done later
				self.imageTable[#self.imageTable].startScale=self.imageTable[#self.imageTable].xScale --note that x and y scales are same

				--assign a timer to the image to keep track of its life
				self.imageTable[#self.imageTable].timer=0
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable].timeLimit=self.life
				elseif(selector==2)then
					self.imageTable[#self.imageTable].timeLimit=self.life-self.lifeVar*0.25
				elseif(selector==3)then
					self.imageTable[#self.imageTable].timeLimit=self.life+self.lifeVar*0.25
				elseif(selector==4)then
					self.imageTable[#self.imageTable].timeLimit=self.life-self.lifeVar*0.5
				elseif(selector==5)then
					self.imageTable[#self.imageTable].timeLimit=self.life+self.lifeVar
				elseif(selector==6)then
					self.imageTable[#self.imageTable].timeLimit=self.life-self.lifeVar	
				elseif(selector==7)then
					self.imageTable[#self.imageTable].timeLimit=self.life+self.lifeVar*0.5
				end		

				--assign an endScale to this particular image based on the allowed values supplied
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable].endScale=self.endScale-self.endScaleVar*0.25
				elseif(selector==2)then
					self.imageTable[#self.imageTable].endScale=self.endScale+self.endScaleVar*0.25
				elseif(selector==3)then
					self.imageTable[#self.imageTable].endScale=self.endScale-self.endScaleVar*0.5
				elseif(selector==4)then
					self.imageTable[#self.imageTable].endScale=self.endScale+self.endScaleVar*0.5
				elseif(selector==5)then
					self.imageTable[#self.imageTable].endScale=self.endScale-self.endScaleVar
				elseif(selector==6)then
					self.imageTable[#self.imageTable].endScale=self.endScale+self.endScaleVar
				elseif(selector==7)then
					self.imageTable[#self.imageTable].endScale=self.endScale
				end		

				--if a table of multiple colours was provided under colorVarStart, pick and apply one of those colours at random, else, use the "color" param
				if(#self.colorVarStart>0)then
					local color=self.colorVarStart[myMath.random(#self.colorVarStart)]
					self.imageTable[#self.imageTable]:setFillColor( color.r,color.g ,color.b ,color.a )
					--at this stage, it is important that the self.startcolor parameter has a value that represents the initialised color of the particle:
					self.imageTable[#self.imageTable].startColor={r=color.r, g=color.g, b=color.b, a=color.a}
				else
					--set the fill colour. This is defaulted in the constructor to white and 1 alpha if no colour was explicitly supplied
					self.imageTable[#self.imageTable]:setFillColor( self.startColor.r,self.startColor.g ,self.startColor.b ,self.startColor.a )
					--at this stage, it is important that the self.startColor parameter has a value that represents the initialised color of the particle:
					self.imageTable[#self.imageTable].startColor={r=self.startColor.r, g=self.startColor.g, b=self.startColor.b, a=self.startColor.a}
				end

				--if a table of multiple colours was provided under colorVarEnd, assign a random color to be used as the actual end colour
				if(#self.colorVarEnd>0)then
					self.imageTable[#self.imageTable].finalColor=self.colorVarEnd[myMath.random(#self.colorVarEnd)]
				end

				--set a random angle based on specified parameters. Note that this is only the starting angle
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable].rotation=self.angle-self.angleVar*0.25
				elseif(selector==2)then
					self.imageTable[#self.imageTable].rotation=self.angle+self.angleVar*0.25
				elseif(selector==3)then
					self.imageTable[#self.imageTable].rotation=self.angle+self.angleVar*0.5
				elseif(selector==4)then
					self.imageTable[#self.imageTable].rotation=self.angle-self.angleVar*0.5
				elseif(selector==5)then
					self.imageTable[#self.imageTable].rotation=self.angle+self.angleVar
				elseif(selector==6)then
					self.imageTable[#self.imageTable].rotation=self.angle-self.angleVar
				elseif(selector==7)then
					self.imageTable[#self.imageTable].rotation=self.angle
				end	

				--set a random vX based on specified parameters. For radial emitters, the selector range is restricted so that there is always an offset selected around the based value
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable].vX=self.vX-self.vXVar*0.25
				elseif(selector==2)then
					self.imageTable[#self.imageTable].vX=self.vX+self.vXVar*0.25
				elseif(selector==3)then
					self.imageTable[#self.imageTable].vX=self.vX-self.vXVar*0.5
				elseif(selector==4)then
					self.imageTable[#self.imageTable].vX=self.vX+self.vXVar*0.5
				elseif(selector==5)then
					self.imageTable[#self.imageTable].vX=self.vX-self.vXVar
				elseif(selector==6)then
					self.imageTable[#self.imageTable].vX=self.vX+self.vXVar
				elseif(selector==7)then
					self.imageTable[#self.imageTable].vX=self.vX
				end	

				--set a random vY based on specified parameters. For radial emitters, the selector range is restricted so that there is always an offset selected around the based value
				local selector=myMath.random(7)
				if(selector==1)then
					self.imageTable[#self.imageTable].vY=self.vY-self.vYVar*0.25
				elseif(selector==2)then
					self.imageTable[#self.imageTable].vY=self.vY+self.vYVar*0.25
				elseif(selector==3)then
					self.imageTable[#self.imageTable].vY=self.vY-self.vYVar*0.5
				elseif(selector==4)then
					self.imageTable[#self.imageTable].vY=self.vY+self.vYVar*0.5
				elseif(selector==5)then
					self.imageTable[#self.imageTable].vY=self.vY-self.vYVar
				elseif(selector==6)then
					self.imageTable[#self.imageTable].vY=self.vY+self.vYVar
				elseif(selector==7)then
					self.imageTable[#self.imageTable].vY=self.vY
				end	
			end	
		end

		--if an emission was forced, set the emission timer to max value so that, dt related difference don't cause issues in future forced emissions. 
		if(self.forceSingleEmission)then
			self.forceSingleEmission=false-- always turn of the single emission flag after 1 successful emission
			self.emissionTimer=self.emissionTimeLimit
		end
	end

	--go over all the images and perform lifetime tasks like incrementing timers, changing scales, rotations, alpha values etc. 
	--NOTE that this is done even when the isPaused is true so that existing particles can be moved out
	for i=#self.imageTable, 1, -1  do
		--adjust scales based on lifeTime
		local scale=self.imageTable[i].startScale+(self.imageTable[i].endScale-self.imageTable[i].startScale)*(self.imageTable[i].timer/self.imageTable[i].timeLimit)
		--IMP: since scales are absolute in my system, :scale() cannot be used here	
		self.imageTable[i].xScale=scale
		self.imageTable[i].yScale=scale
		
		--adjust alpha based on lifeTime. NOTE-- equation assumes default alpha as 1 and that a final colour wasn't explicitly provided
		if(self.shouldFadeOut and self.imageTable[i].finalColor==nil)then
			self.imageTable[i].alpha=self.imageTable[i].startColor.a-(self.imageTable[i].timer/self.imageTable[i].timeLimit)
		end

		--if a finalColor was recorded, tween the start colour towards the final colour over the lifeTime
		if(self.imageTable[i].finalColor~=nil)then
			local r, g, b, a
			r=self.imageTable[i].startColor.r+(self.imageTable[i].finalColor.r-self.imageTable[i].startColor.r)*(self.imageTable[i].timer/self.imageTable[i].timeLimit)
			g=self.imageTable[i].startColor.g+(self.imageTable[i].finalColor.g-self.imageTable[i].startColor.g)*(self.imageTable[i].timer/self.imageTable[i].timeLimit)
			b=self.imageTable[i].startColor.b+(self.imageTable[i].finalColor.b-self.imageTable[i].startColor.b)*(self.imageTable[i].timer/self.imageTable[i].timeLimit)
			a=self.imageTable[i].startColor.a+(self.imageTable[i].finalColor.a-self.imageTable[i].startColor.a)*(self.imageTable[i].timer/self.imageTable[i].timeLimit)
			self.imageTable[i]:setFillColor( r,g,b,a)
		end

		--apply the angularV
		self.imageTable[i].rotation=self.imageTable[i].rotation+self.angularV*dt

		--before moving to application of vY and vX etc, check if gravity is present and amend vY accordingly.
		self.imageTable[i].vY=self.imageTable[i].vY+self.gravity*dt

		--apply the lateral and longitudinal velocities. If a non-nil worldTranslate was sent, then apply relativeMotion
		self.imageTable[i].x=self.imageTable[i].x+self.imageTable[i].vX*dt
		self.imageTable[i].y=self.imageTable[i].y+self.imageTable[i].vY*dt
		if(worldTranslation~=nil)then
			self.imageTable[i].x=self.imageTable[i].x-worldTranslation.x
			self.imageTable[i].y=self.imageTable[i].y-worldTranslation.y
		end

		--if the emitter was of the type "radial", its particles will be oriented in the direction of their movement. Compute the angle and set their rotation
		if(self.isRadial)then
			self.imageTable[i].rotation=myMath.deg(myMath.atan2(self.imageTable[i].vY,self.imageTable[i].vX))
		end

		--increment timers and remove images that are expired
		self.imageTable[i].timer=self.imageTable[i].timer+dt
		if (self.imageTable[i].timer>self.imageTable[i].timeLimit)then
			self.imageTable[i]:removeSelf()
			local obj=table.remove(self.imageTable,i)
			obj=nil
		end
	end

	-- debugStmt.print("particleSystem: size of image table for "..self.name.." is "..#self.imageTable)
end
---------------------------------

--While setting isPaused to true will anyway remove all remaining images, this function is more consistent with Corona's naming system and calling this will remove all images stored
--in the instance of particleSystem
function particleSystem:removeSelf()
	for i=#self.imageTable, 1, -1  do
		self.imageTable[i]:removeSelf()
		local obj=table.remove(self.imageTable,i)
		obj=nil
	end
end

return particleSystem
