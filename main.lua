function love.load()

    -- Random seed
    math.randomseed(os.time())

    -- Sprites table
    sprites = {}
    sprites.background = love.graphics.newImage("sprites/background.png")
    sprites.bullet = love.graphics.newImage("sprites/bullet.png")
    sprites.player = love.graphics.newImage("sprites/player.png")
    sprites.zombie = love.graphics.newImage("sprites/zombie.png")

    -- Player properties
    player = {}
    player.x = love.graphics.getWidth() / 2
    player.y = love.graphics.getHeight() / 2
    player.speed = 120
    player.state = 0

    gameFont = love.graphics.newFont("fonts/Jonkle.otf", 48)

    zombies = {}
    bullets = {}

    score = 0
    gameState = 1
    maxTime = 2
    timer = maxTime

    love.window.setTitle("Zombie Shooter")

end

function love.update(dt)
    if gameState == 2 then
        -- Player movement
        if love.keyboard.isDown("d") and player.x < love.graphics.getWidth() then
            player.x = player.x + player.speed * dt
        end

        if love.keyboard.isDown("a") and player.x > 0 then
            player.x = player.x - player.speed * dt
        end

        if love.keyboard.isDown("w") and player.y > 0 then
            player.y = player.y - player.speed * dt
        end

        if love.keyboard.isDown("s") and player.y < love.graphics.getHeight() then
            player.y = player.y + player.speed * dt
        end
    

        -- Move zombies toward the player
        for i,z in ipairs(zombies) do 
            z.x = z.x + (math.cos( zombiePlayerAngle(z) ) * z.speed * dt)
            z.y = z.y + (math.sin( zombiePlayerAngle(z) ) * z.speed * dt)

            -- When a zombie collides with the player
            if distanceBetween(z.x, z.y, player.x, player.y) < 30 and player.state == 0 then

                -- For the first collision set the player color to red, and increase player speed
                player.speed = 180
                player.state = 1
                z.dead = true

            -- Otherwise end the game and then prompt player to restart
            elseif distanceBetween(z.x, z.y, player.x, player.y) < 30 and player.state == 1 then

                for i,z in ipairs(zombies) do
                    zombies[i] = nil
                    gameState = 1
                    player.x = love.graphics.getWidth() / 2
                    player.y = love.graphics.getHeight() / 2
                end
            end
        end 

        -- Move the bullets toward the mouse pointer
        for i,b in ipairs(bullets) do
            b.x = b.x + (math.cos( b.direction ) * b.speed * dt)
            b.y = b.y + (math.sin( b.direction ) * b.speed * dt)
        end

        -- Remove bullets from the game
        -- When removing elements from a list, go in reverse to avoid issues
        for i=#bullets, 1, -1 do 
            local b = bullets[i]
            -- Check if bullet is past the bounds of the screen
            if b.x < 0 or b.y < 0 or b.x > love.graphics.getWidth() or b.y > love.graphics.getHeight() then
                table.remove(bullets, i)
            end
        end

        -- Collision between zombie and bullets
        for i,z in ipairs(zombies) do
            for j,b in ipairs(bullets) do
                if distanceBetween(z.x, z.y, b.x, b.y) < 20 then
                    z.dead = true
                    b.dead = true
                    score = score + 1
                end
            end
        end

        -- Remove dead zombies
        for i=#zombies, 1, -1 do
            local z = zombies[i]
            if z.dead == true then
                table.remove(zombies, i)
            end
        end

        -- Remove bullets on collision
        for i=#bullets, 1, -1 do
            local b = bullets[i]
            if b.dead == true then
                table.remove(bullets, i)
            end
        end
    end

    if gameState == 2 then
        -- Countdown
        timer = timer - dt
        -- Spawn a zombie, then reset the timer
        if timer <= 0 then
            spawnZombie()
            maxTime = 0.95 * maxTime
            timer = maxTime
        end
    end

end

function love.draw()
    
    -- Drawing background
    love.graphics.draw(sprites.background, 0, 0)

    if gameState == 1 then 
        love.graphics.setFont(gameFont)
        love.graphics.printf("Click anywhere to begin", 0, 75, love.graphics.getWidth(), "center")
    end

    -- Print score
    love.graphics.printf("Score: " .. score, 0, 0, love.graphics.getWidth(), "left")
    -- love.graphics.print(player.state, love.graphics.getWidth()/2, 0)

    -- If player has been hit, then change color
    if player.state == 1 then
        love.graphics.setColor(219/255, 90/255, 81/255)
    end
    -- Drawing the player sprite
    love.graphics.draw(sprites.player, player.x, player.y, playerMouseAngle(), nil, nil, sprites.player:getWidth() / 2, sprites.player:getHeight() / 2)

    -- Reset color for all other sprites
    love.graphics.setColor(1, 1, 1)

    -- For every zombie created, spawn randomly and rotate towards player
    for i,z in ipairs(zombies) do 
        love.graphics.draw(sprites.zombie, z.x, z.y, zombiePlayerAngle(z), nil, nil, sprites.zombie:getWidth() / 2, sprites.zombie:getHeight() / 2)
    end

    -- Drawing the bullet sprite
    for i,b in ipairs(bullets) do
        love.graphics.draw(sprites.bullet, b.x, b.y, nil, 0.25, nil, sprites.bullet:getWidth() / 2, sprites.bullet:getHeight() / 2)
    end

end

function love.keypressed( key )
    if key == "space" then
        spawnZombie()
    end
end

function love.mousepressed( x, y, button)
    if button == 1 and gameState == 2 then
        spawnBullet()
    elseif button == 1 and gameState == 1 then
        gameState = 2
        player.state = 0
        maxTime = 2
        timer = maxTime
        score = 0
    end
end

-- Angle player towards the mouse pointer
function playerMouseAngle()
    return math.atan2( player.y - love.mouse.getY(), player.x - love.mouse.getX() ) + math.pi
end

-- Angle zombie toward player
function zombiePlayerAngle(enemy)
    return math.atan2( player.y - enemy.y, player.x - enemy.x)
end

-- Create zombie objects
function spawnZombie()
    local zombie = {}

    local side = math.random(1, 4)

    -- Left side of the screen
    if side == 1 then
        zombie.x = -30
        zombie.y = math.random(0, love.graphics.getHeight())
    -- Right side of the screen
    elseif side == 2 then
        zombie.x = love.graphics.getWidth() + 30
        zombie.y = math.random(0, love.graphics.getHeight())
    -- Top of the screen
    elseif side == 3 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = -30
    -- Bottom of the screen
    elseif side == 4 then
        zombie.x = math.random(0, love.graphics.getWidth())
        zombie.y = love.graphics.getHeight() + 30
    end

    -- Random zombie spawn anywhere in the viewport
    -- zombie.x = math.random(0, love.graphics.getWidth())
    -- zombie.y = math.random(0, love.graphics.getHeight())
    zombie.speed = 60
    zombie.dead = false
    table.insert(zombies, zombie)
end

-- Spawn bullets
function spawnBullet()
    local bullet = {}
    bullet.x = player.x
    bullet.y = player.y
    bullet.speed = 500
    bullet.direction = playerMouseAngle()
    bullet.dead = false
    table.insert(bullets, bullet)
end

function distanceBetween(x1, y1, x2, y2)
    return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
end