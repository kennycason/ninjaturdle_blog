---
title: Tiled Map Collision
author: Kenny Cason
tags: game development, tiled, map, collision detection
---

After [Part 2](/posts/2017-04-02-prototype-ii.html) of our prototype, Mr. Turdle can jump, fall, and walk left and right. However, because we haven't covered map loading, Mr. Turdle's movement boundaries have been arbitrarily determined to be the edge of the screen. In this tutorial we will introduce the loading of a `Tiled` map and collision detection.

## Creating the Map 

First we are going to use `Aseprite` to create a tile sheet to use in our map. Next, within `Tiled`, we will create a single layer map to test collisions against.

The tile sheet is essentially a large sprite that will contain all the tiles we intend on using in our map. Each tile is 16x16 pixel section of the tile sheet. Our first sprite sheet looks something like:

<img src="/assets/images/content/tiled_tilesheet.png" width="400px"/>

My tile sheet has since accumulated a few more tiles. I recommend not spending too much time on the tiles as they are very likely to change as you flush out your game more. That said, do whatever makes you enjoy programming your game. I'm not going to lie, I am pretty proud of those previous two tiles. :)

<img src="/assets/images/content/tiled_tilesheet_full.png" width="500px"/>

Now time to fire up `Tiled`.

Lets create a 100x17 map with one layer. Name that layer "main". We will identify the layer by it's name in our code. Then begin filling it in with whatever design we want. The background (empty space) will contain no tiles. The reason being is that when we perform collision detection later we will be checking for the presence of tiles in the "main" layer that overlap with Mr. Turdle's hitbox.

A little bit of editing yields us with this beauty.

<img src="/assets/images/content/tiled_map_prototype.png" width="600px"/>

## Loading the Map

Fortunately, `LibGDX` does all the heavily lifting and provides classes for not only loading `Tiled` maps, but also rendering them. This can be down with two lines of code.

```{.java .numberLines startFrom="1"}
var map: TiledMap = TmxMapLoader().load("map/" + mapName + ".tmx")
var mapRenderer: TiledMapRenderer =
                  OrthogonalTiledMapRenderer(map, gameContext.batch)
```

For convenience the map and mapRenderer will be stored within our previously created `GameContext`. Rendering the map requires only a few lines of code added to the `GameScreen.render` loop.

```{.java .numberLines startFrom="1"}
// recalculates the projection and view matrix of this camera.
gameContext.camera.update()
// Prepare for rendering sprites, must be called before rendering.
gameContext.batch.begin()
// set normal camera.
gameContext.batch.projectionMatrix = gameContext.camera.combined

// make the map renderer aware of the camera.
gameContext.mapRenderer?.setView(gameContext.camera)
// render specific tile. rendering layer by layer allows render background
// and foreground layers separately.
val mainLayer = gameContext.map!!.layers["main"] as TiledMapTileLayer
gameContext.mapRenderer?.renderTileLayer(mainLayer)

// render and manage ninja entity.
gameContext.ninja.handle()
```

For more details I recommend instead reading the LibGDX wiki on handling [Tiled Maps](https://github.com/libgdx/libgdx/wiki/Tile-maps). If you got very creative and added animated tiles, don't forget to call `AnimatedTiledMapTile.updateAnimationBaseTime()` before rending your map.

## Collision Detection with Tiled

The next step is to update our collision detection logic to test when Mr. Turdle collides with our map. Most tutorials will say to fetch the collision layer and test each tile to see if it collides. This is rarely needed and worst case is very inefficient. Particularly when we have hundreds of active entities on the screen all needing to perform collision detection, or large map, or both.

The alternative is that we will only test tiles that are likely collide with Mr. Turdle. For example, if Mr. Turdle, is falling, there is no need to detect tiles above him. Similarly, If he is walking to the right, there is no need to test tiles to the left. These minor optimizations greatly speed up collision detection.

Additionally, to further improve collision detection performance I follow a few rules:

1. Whenever possible, use simple rectangle collision.
2. For entities that have complex shapes. Use multiple rectangles.
3. If rectangles aren't good enough, consider a triangle or circle or other simple polygon.
4. While I find it hard to imagine a hitbox that you can't simulate with a square, triangle, and circle, if you absolutely insist on complex polygons, consider using Ray Casting for determining overlap.
5. Finally, and only if you can not avoid it, use pixel-perfect collision. And even then, first perform rectangle collision. This is because pixel-perfect collision is very expensive.

We will be using Rectangle collision in these examples, and everywhere possible unless explained otherwise.

An example of what our updated `testDown()` function looks like after integrating our `Tiled` map.

```{.java .numberLines startFrom="1"}
// return the tile that has the closed y-distance AND collied.
// the entity's velocity is considered
fun testDown(entity: Entity): Collided? {
    // get our currently loaded map from the game context
    val tiledMap = gameContext.map!!
    // get our collision layer (name it whatever you want)
    val layer = tiledMap.layers.get("main") as TiledMapTileLayer

    // simulate entity movement increase entity position by velocity
    // we use a new rectangle so that we don't have to "undo" movements
    val entityHitbox = Rectangle()
    entityHitbox.set(entity.hitbox)
    entityHitbox.y += entity.velocity.y

    // iterate such that you are searching by column to check tiles
    // most likely to collide with first
    val startX = (entityHitbox.x / Constants.TILE_DIM).toInt() - 2
    val endX = ((entityHitbox.x + entity.hitbox.width)
                                   / Constants.TILE_DIM).toInt() + 2
    val startY = (entityHitbox.y / Constants.TILE_DIM).toInt() + 1
    val endY = (entityHitbox.y / Constants.TILE_DIM).toInt() - 2

    // by iterating this way we are guaranteed the first hit is the closest
    for (y in startY downTo endY) {
        for (x in startX .. endX) {
            val cell = layer.getCell(x, y) ?: continue
            // create a rectangle to test collision against.
            // another place we will likely convert to use object pools.
            val tile = Rectangle()
            tile.set(x * Constants.TILE_DIM, y * Constants.TILE_DIM,
                Constants.TILE_DIM, Constants.TILE_DIM)

            if (entity.overlaps(tile)) {
                return Collided(tile, cell)
            }
        }
    }
    return null
}
```

The above is a pretty large, but you can see how to generally expand this to test in all directions. The biggest immediate drawback I have with the above code is that there is a lot of object creation going on. We can solve that later with [Object Pools](https://github.com/libgdx/libgdx/wiki/Memory-management). However, I personally would not bother with it for now unless you are already familiar with object pooling, or just feel like doing it "right" from the beginning. My general approach is to add in object pools when needed. Object pools do add in extra complexity as you have to be sure to free objects, which also means you have to be careful of lingering object references. My `CollisionChecker` class uses object pools liberally since there is a lot of rectangle generation going on as this is a heavily used class.

The next issue is that the collision only works for rectangular tiles. We will need to get a bit more creative when we add slopes or different sized tiles. The general idea for slopes is to treat them as literal algebraic lines. With this in mind, it is now easy to calculate where to place your entity on the line. Hint: It's your favorite equation from Algebra I, [`y = mx + b`](https://en.wikipedia.org/wiki/Linear_equation#Two_variables)!

We are also going to create one more helper function to aid in falling. There is one special case with falling. After falling we want the entity to stop right on top of the tile. This means that in a `Grounded` state, Ninja will never be colliding with a tile; he will instead reside one pixel immediately above the ground tile. With our current setup this would result in Mr. Ninja continually falling, resetting `landTime` variables, and in general causing state transition pain as it bounces back and forth between `Falling` and `Grounded` states. This is easy to solve by modifying our `testDown` function to test one pixel below the entity like:

```{.java .numberLines startFrom="1"}
entityHitbox.y += entity.velocity.y - 1
```

We will name our convenience function `CollisionChecker.fall()`. This class will constantly check if the entity should fall, and handle the transition between `Falling`/`Grounded` states in a smooth manner.
```{.java .numberLines startFrom="1"}
fun fall(entity: Entity) {
    val collided = testDown(entity)
    if (collided != null) {
        // if the entity wasn't already ground, set land time
        if (entity.gravityState != GravityState.GROUNDED) {
            entity.landTime = entity.totalTime
        }
        entity.gravityState = GravityState.GROUNDED
        locateToTopOfTile(entity, collided)
        entity.velocity.y = 0.0f
    }
    else {
        entity.gravityState = GravityState.FALLING
        entity.fallTime = entity.totalTime
    }
}
```

We can now finally update our `Ninja.handleFalling()` function to handle when Mr. Ninja should fall. This significantly cleans up our `handleFalling()` code as the complex collision detection logic is pushed into a dedicated class.

```{.java .numberLines startFrom="1"}
private fun handleFalling() {
    // vertical movements
    if (gravityState !== GravityState.GROUNDED) {
        velocity.y += Constants.GRAVITY * gameContext.deltaTime
    }

    if (gravityState == GravityState.JUMPING) { return }

    // don't fall too fast
    if (velocity.y < Constants.TERMINAL_VELOCITY) {
        velocity.y = Constants.TERMINAL_VELOCITY
    }

    // don't move horizontally as much when falling
    if (gravityState == GravityState.FALLING) {
        velocity.x *= Constants.HORIZONTAL_FALLING_DAMPING
    }

    // fall if needed <- NEW
    collisionChecker.fall(this)
}
```

In previous sections we hadn't added horizontal collision detection but it is handled very similarly by adding a `testLeft()` and `testRight()` function to the `CollisoinChecker` class. The only real modification are the x/y ranges we will check, and the ordering of which we check the tiles. Recall that we want to test the tiles the entity is most likely to encounter first. An example of `testLeft()` is below.

```{.java .numberLines startFrom="1"}
// return the tile that has the closed x-distance AND collied.
// the entity's velocity is considered
fun testLeft(entity: Entity): Collided? {
    val tiledMap = gameContext.map!!
    val layer = tiledMap.layers.get(layer) as TiledMapTileLayer

    // simulate entity movement increase entity position by velocity
    val entityHitbox = Rectangle()
    entityHitbox.set(entity.hitbox)
    entityHitbox.x += entity.velocity.x

    // iterate such that you are searching by column
    val startX = (entityHitbox.x / Constants.TILE_DIM).toInt() + 1
    val endX = (entityHitbox.x / Constants.TILE_DIM).toInt() - 2
    val startY = (entityHitbox.y / Constants.TILE_DIM).toInt() - 2
    val endY = ((entityHitbox.y + entity.hitbox.height)
                                  / Constants.TILE_DIM).toInt() + 2

    // by iterating this way we are guaranteed the first hit is the closest
    for (x in startX downTo endX) {
        for (y in startY..endY) {
            val cell = layer.getCell(x, y) ?: continue

            val collided = overlaps(entityHitbox, x, y, cell)
            if (collided != null) { return collided }
        }
    }
    return null
}
```

<img src="/assets/images/content/tiled_map_integration.png" width="500px"/>

## Conclusion

With the addition of the above code, Mr. Ninja now has the ability to jump, fall and move around within a `Tiled` Map. However, there is still one large problem. The map does not scroll!

The next section will cover smooth camera scrolling in Ninja Turdle.
