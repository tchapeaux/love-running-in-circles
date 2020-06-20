--[[
Running in Circles
A LÖVEly (and never-ending) game by Altom
]]--

--[[
TO DO :
	- Balancing (lots of it !)
	- Better Graphics (particle, title, walking animation, player hit, etc)
]]--

function love.load()
 -- Settings --------------------
 planetRadius_max = 200 -- px
 xDumCir = -220 -- px -- -220
 xCurCir = 300 -- px -- 300
 xNexCir = 750 -- px -- 750
 
 speedJumpH = 250 -- px/s
 tJumpMax = 1 -- s
 playerSpeedWalk = 1 -- rad/s
 playerSpeedRun = 3
 playerSpeedJump = 0.5
 
 diffAster = -1 -- difficulty from which asteroids start spawning (can be < 0)
 deltaDiff = 2 -- 1 new asteroids spawn every deltaDiff
 radiusAster = 10
 xInitAster = 1000 -- position max where asteroids start ( > 800 + radiusAster)
 
 starCount = 100
 ---------------------------------
 
 --love.graphics.setColorMode("replace")
 math.randomseed(os.time())
 math.random();math.random(); -- Pour le fun
 background = love.graphics.newImage("res/background.png")
 title = love.graphics.newImage("res/zeTitle.png")
 pic_star = love.graphics.newImage("res/distant_star.png")
 planet = love.graphics.newImage("res/planet.png")
 player = love.graphics.newImage("res/player_2.png")
 player_fire = love.graphics.newImage("res/player_2_fire.png")
 part_star = love.graphics.newImage("res/uglyStar.png")
 bgm_main = love.audio.newSource("res/bgm_main_2.ogg", "stream") ; bgm_main:setLooping(true) ; bgm_main:setVolume(0.5)
 fx_boing = love.audio.newSource("res/boing.ogg", "static") ; fx_boing:setVolume(0.5)
 fx_pop = love.audio.newSource("res/popouille.ogg", "static") ; fx_pop:setVolume(2)
 fx_pop2 = love.audio.newSource("res/popaille.ogg", "static") ; fx_pop2:setVolume(3)
 
 playerSize = player:getHeight()
 playerw = player:getWidth()
 jumpH = 0
 tJump = 0
 playerSpeedRatio = playerSpeedWalk / playerSpeedJump
 
 difficulty = 0
 
 canJump = true
 isJumping = false
 
 planetRadius_min = ((xNexCir - xCurCir - speedJumpH*tJumpMax - playerSize)/2) + 50
 planetRadius_maxAdjusted = planetRadius_max
 
 canCol = true
 planets = {}
 planetPos = {}
 theCheat = false
 
 local dPlanet = {}
	dPlanet['radius'] = math.random(planetRadius_min, planetRadius_maxAdjusted)
	dPlanet['xC'] = xDumCir
	dPlanet['yC'] = math.random(100 + dPlanet['radius'], 500 - dPlanet['radius'])
	dPlanet['color'] = 0
 table.insert(planets, dPlanet) 
 table.insert(planetPos, xDumCir)
 
 local cPlanet = {}
	cPlanet['radius'] = math.random(planetRadius_min, planetRadius_maxAdjusted)
	cPlanet['xC'] = xCurCir
	cPlanet['yC'] = math.random(100 + cPlanet['radius'], 500 - cPlanet['radius'])
	cPlanet['color'] = 0
 table.insert(planets, cPlanet)
 table.insert(planetPos, xCurCir)
 
 local nPlanet = {}
	nPlanet['radius'] = math.random(planetRadius_min, planetRadius_maxAdjusted)
	nPlanet['xC'] = xNexCir
	nPlanet['yC'] = math.random(100 + nPlanet['radius'], 500 - nPlanet['radius'])
	nPlanet['color'] = 0
 table.insert(planets, nPlanet)
 table.insert(planetPos, xNexCir)

 asteroids = {} -- Empty at first
 explosions = {} -- idem
	
 randomStars = {}
 for i = 1, starCount do
	local iStar = {}
	newRandomStar(iStar, "new")
	table.insert(randomStars, iStar)
 end
 
 
 FPS = 1
 min_FPS = 100
 playerAngle = -math.pi/2 -- pour commencer au Nord de la planète
 
 timeKey = 10
 
 love.audio.play(bgm_main)
end
--------------------------------------------------------------------------------------------
function love.update(dt)
 FPS = 1/dt
 min_FPS = math.min(FPS, min_FPS)
 timeKey = timeKey + dt
 
 -- Player walk
 if (not isJumping) then 
	if (love.keyboard.isDown("right")) then
		playerAngle = playerAngle + playerSpeedRun*dt
	else
		playerAngle = playerAngle + playerSpeedWalk*dt
	end
 else
	playerAngle = playerAngle + playerSpeedJump*dt
 end
 
 --
 if (playerAngle > math.pi*2) then
	playerAngle = playerAngle - math.pi*2
	difficulty = math.max(0, difficulty - 1)
 end
  
 -- Gestion du saut
 if (canJump and love.keyboard.isDown("up")) then
	jumpH = jumpH + speedJumpH*dt
	if not (isJumping) then love.audio.play(fx_boing) end
	isJumping = true	
 elseif (jumpH > 0) then
	jumpH = jumpH - speedJumpH*dt
	canJump = false
 elseif (jumpH <= 0 and isJumping) then
	jumpH = 0
	canJump = true
	isJumping = false
	tJump = 0
 end
 
 if (jumpH > 0) then
	if (not isJumping) then
		isJumping = true
	else
		tJump = tJump + dt
	end
 end
 if (tJump > tJumpMax) then
	canJump = false
	tJump = 0
 end
 
 -- Collision
 xCol = planets[2]['xC'] + (planets[2]['radius']+playerSize/2+jumpH)*math.cos(playerAngle)
 yCol = planets[2]['yC'] + (planets[2]['radius']+playerSize/2+jumpH)*math.sin(playerAngle)
 
	-- avec Planètes
 disCol = disPoints(xCol, yCol, planets[3]['xC'], planets[3]['yC'])
 if ((canCol and disCol <= planets[3]['radius'] + playerSize/2) or theCheat) then
	theCheat = false
	difficulty = difficulty + 1
	planetRadius_maxAdjusted = math.max(planetRadius_min, planetRadius_max - 4*difficulty)
	table.remove(planets, 1)
	planets[3] = newPlanet(1250)
	canCol = false
	if (yCol > planets[2]['yC']) then
		playerAngle = math.acos((xCol - planets[2]['xC'])/disCol) -- Maths !
	else
		playerAngle = -math.acos((xCol - planets[2]['xC'])/disCol)
	end
	jumpH = 0
 end
	-- avec Aster (+ gestions d'autres trucs)
 for i in ipairs(asteroids) do
 	asteroids[i]['p']:setPosition(asteroids[i]['x'], asteroids[i]['y'])
 	asteroids[i]['p']:update(dt) -- particle system
	disCol = disPoints(xCol, yCol, asteroids[i]['x'], asteroids[i]['y'])
	
	--col player/aster
	if (disCol <= radiusAster + playerSize/2) then
		if (not fx_pop:isPlaying()) then 
			love.audio.play(fx_pop)
		else
			love.audio.stop(fx_pop)
			love.audio.play(fx_pop2)
		end
		canJump = false
		isJumping = true -- petit truc de fourbe :p
		tJump = 0
		destroyAster(i)
	-- col planet/aster
	else
		disCol = disPoints(asteroids[i]['x'], asteroids[i]['y'], planets[2]['xC'], planets[2]['yC'])
		if (disCol < (planets[2]['radius'] + radiusAster)) then
			destroyAster(i)
		else
			disCol = disPoints(asteroids[i]['x'], asteroids[i]['y'], planets[3]['xC'], planets[3]['yC'])
			if (disCol < (planets[3]['radius'] + radiusAster)) then
				destroyAster(i)
			end
		end
	end
 end
 
 
 
 
 if (planetPos[1] < planets[1]['xC'] or planetPos[2] < planets[2]['xC'] or planetPos[3] < planets[3]['xC']) then -- Bouger l'ecran
 	-- Bouger planetes
 	for i = 1,3 do planets[i]['xC'] = planets[i]['xC'] - 10 end
	-- Bouger Aster
	for i in ipairs(asteroids) do
		asteroids[i]['x'] = asteroids[i]['x'] - 10
		-- la Position du ParticleSystem sera calquée dessus
	end
	-- Bouger Explosions
	for i in ipairs(explosions) do
		explosions[i]['offX'] = explosions[i]['offX'] - 10
	end
 	-- Bouger etoiles
 	for i = 1, starCount do
		randomStars[i]['x'] = randomStars[i]['x'] - 4 + randomStars[i]['v']
		if (randomStars[i]['x'] < -10) then
			newRandomStar(randomStars[i], "right")
		end
	end
 elseif(not canCol) then
 	canCol = true
 end
 
 -- Asteroids
 if (difficulty >= diffAster or #asteroids > 0) then
	
	local nbrAst = #asteroids  
	for ia in ipairs(asteroids) do
		asteroids[ia]['x'] = asteroids[ia]['x'] - asteroids[ia]['v']
		if (asteroids[ia]['x'] < -100) then
			table.remove(asteroids, ia) -- pas destroyAster ici
		end
	end
	
	if (nbrAst < (difficulty-diffAster)/deltaDiff) then
		local iAster = {}
		newAster(iAster)
	end
	
 end
 
 -- Explosions
 for i in ipairs(explosions) do
 	explosions[i]['p']:update(dt)
 end
 
end

 --------------------------------------------------------------------------------
 
function love.draw()
 love.graphics.setColor(1,1,1)

 -- Background
 love.graphics.draw(background, 0, 0)
 
 -- Stars
 for i = 1, starCount do
	love.graphics.draw(pic_star, randomStars[i]['x'], randomStars[i]['y'], 1/randomStars[i]['d'], 1/randomStars[i]['d'])
 end
 
  -- Asteroids + trail
 love.graphics.setColor(100 / 255,100 / 255 , 1)
 for i = 1, #asteroids do
	love.graphics.circle("fill", asteroids[i]['x'], asteroids[i]['y'], radiusAster)
	love.graphics.draw(asteroids[i]['p'], 0, 0)
 end
 
 -- Explosions
 for i in ipairs(explosions) do
 	if (explosions[i]['p']:getBufferSize() > 0) then
	 	love.graphics.draw(explosions[i]['p'], explosions[i]['offX'], explosions[i]['offY'])
	 else
	 	table.remove(explosions,i)
	 end
 end
 
  -- Three Planets
 for i = 1,3 do
	color_GB = math.max(255 - planets[i]['color']*10, 0)
	love.graphics.setColor(1,color_GB / 255,color_GB / 255)
	love.graphics.circle("fill", planets[i]['xC'], planets[i]['yC'], planets[i]['radius']-1, 50)
	love.graphics.draw(planet, planets[i]['xC'] - planets[i]['radius'], planets[i]['yC'] - planets[i]['radius'], 0, planets[i]['radius']/200, planets[i]['radius']/200)
 end
 
 -- Player
love.graphics.setColor(1,1,1)
 if (not isJumping) then
	love.graphics.draw(player, planets[2]['xC'] + (planets[2]['radius']+playerSize+jumpH)*math.cos(playerAngle),
                    planets[2]['yC'] + (planets[2]['radius']+playerSize+jumpH)*math.sin(playerAngle),
					playerAngle+math.pi/2, 1, 1,playerw/2)
 else
	love.graphics.draw(player_fire, planets[2]['xC'] + (planets[2]['radius']+playerSize+jumpH)*math.cos(playerAngle),
                    planets[2]['yC'] + (planets[2]['radius']+playerSize+jumpH)*math.sin(playerAngle),
					playerAngle+math.pi/2, 1, 1,playerw/2)
 end
 
 -- Title
 if (timeKey > 10) then
 		if (planets[2]['yC'] > 400) then
 			love.graphics.draw(title, 20, 50)
 		else
 			love.graphics.draw(title, 20, 350)
 		end
 end

					
 -- UI (need improving)
 love.graphics.print("Hold Up to Jump\nHold Right to Run\nPress Enter to cheat", 10, 20)
 if (love.audio.getVolume() == 1) then love.graphics.print("M - Toggle audio off", 10, 580)
 else love.graphics.print("M - Toggle audio on", 10, 580)
 end
 love.graphics.print("difficulty : "..difficulty, 680, 20)
 love.graphics.print("To infinity and beyond -->", 630, 580)
 
 -- For Debug
  love.graphics.print(planetRadius_min.." < planetRadius < "..planetRadius_maxAdjusted.."\n nbrAster : "..#asteroids.." | nbrExplo :"..#explosions, 500, 20)

 love.graphics.print("FPS : "..math.floor(FPS).." | min : "..math.floor(min_FPS), 0,0)
 end

function love.keypressed(k)
 if (k == "return") then
	theCheat = true
	-- difficulty = 0
 elseif (k == "m" or k == ";") then
	if (love.audio.getVolume() > 0) then
		love.audio.setVolume(0)
	else
		love.audio.setVolume(1)
	end
 elseif(k == "p") then
	love.audio.play(fx_pop)
 elseif (k == "escape") then
	love.event.quit(0)
 end
 
 timeKey = 0

end

function newRandomStar(star, mode) -- mode = "new", "left" or "right"
	if (mode == "new") then
		star['x'] = math.random(10,790)	
	elseif (mode == "left") then
		star['x'] = math.random(-20,10);
	else -- if (mode == "right")
		star['x'] = math.random(800, 820)
	end
	star['y'] = math.random(10,590)
	star['d'] = math.random(1,2)
	star['v'] = math.random(1,2)
end

function newPlanet(x)
 local iPlanet = {}
	iPlanet['radius'] = math.random(planetRadius_min, planetRadius_maxAdjusted)
	iPlanet['xC'] = x
	iPlanet['yC'] = math.random(250, 500 - iPlanet['radius'])
	iPlanet['color'] = difficulty
 return iPlanet
end

function newAster(aster)
	aster['x'] = math.random(800 + radiusAster, xInitAster)
	aster['y'] = math.random(10, planets[3]['yC']) -- balance FTW
	aster['v'] = math.random(1, 4)
	
	aster['p'] = love.graphics.newParticleSystem(part_star, 1000)
		 aster['p']:setEmissionRate(10)
		 aster['p']:setSpeed(200/(4-aster['v']))
		 aster['p']:setLinearAcceleration(0, 0, 0, 0)
		 aster['p']:setSizes(0.5, 1, 1)
		 aster['p']:setColors(200 / 255, 200 / 255, 1, 1, 100 / 255, 100 / 255, 1, 1)
		 aster['p']:setPosition(aster['x'], aster['y'])
		 aster['p']:setEmitterLifetime(-1)
		 aster['p']:setParticleLifetime(1)
		 aster['p']:setDirection(0)
		 aster['p']:setSpread(0.7) -- 40 degrees
		 aster['p']:setRadialAcceleration(0)
		 aster['p']:setTangentialAcceleration(0)
			
	table.insert(asteroids, aster)
end

function destroyAster(i)
	local newExplosion = {}
	newExplosion['p'] = love.graphics.newParticleSystem(part_star, 200)
	newExplosion['p']:setEmissionRate(500)
	newExplosion['p']:setSpeed(300)
	newExplosion['p']:setLinearAcceleration(0, 0, 0, 0)
	newExplosion['p']:setSizes(0.5, 1, 1)
	newExplosion['p']:setColors(200 / 255,200 / 255,1,1,100 / 255,100 / 255,1,100 / 255)
	newExplosion['p']:setPosition(asteroids[i]['x'], asteroids[i]['y'])
	newExplosion['p']:setEmitterLifetime(0.5)
	newExplosion['p']:setParticleLifetime(0.5)
	newExplosion['p']:setDirection(0)
	newExplosion['p']:setSpread(2*math.pi)
	newExplosion['p']:setRadialAcceleration(-800)
	newExplosion['p']:setTangentialAcceleration(500)
	
	newExplosion['offX'] = 0
	newExplosion['offY'] = 0
	table.insert(explosions, newExplosion)
	table.remove(asteroids, i)

end

function disPoints(x1, y1, x2, y2)
	return math.sqrt((x2-x1)*(x2-x1) + (y2 - y1)*(y2 - y1))
end
