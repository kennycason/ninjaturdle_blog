---
title: Prototype - Part II - Jumping & Falling
author: Kenny Cason
tags: game development, prototype, jumping, falling
---

After [Part I](/posts/2017-03-26-prototype.html) of our prototype, all we have is a sprite that can walk back and forth. At least we can be happy that it has smooth acceleration and deceleration. With that said, it would be a rather boring game if we couldn't jump and fall. Those are the two topics we will cover in this section.

## Falling

Similar to our handling of horizontal movement covered in the previous post, we will indirectly change Mr. Ninja's vertical position by first setting his `acceleration.y` variable. Then acceleration will be added to velocity, and velocity will be added to position. This is to give the appearance of smooth acceleration, opposed to jerky motion transitions caused by directly modifying a velocity variable.

The first step to programming falling is to determine whether or not Mr. Ninja, or any other entity *should* fall. In other words, Mr. Ninja doesn't start falling until there is no ground below him. After we implement jumping, Mr. Ninja will also begin falling once he has reached the peek of his jump or hits a ceiling.

At this point in our prototype we will avoid going too far into the weeds in collision detection with a tiled map. Instead we will just define a simple `CollisionChecker` implementation with a few functions. A function to test whether Mr. Ninja hit a ceiling when jumping, and a function to test if Mr. Ninja is standing on the ground or not. To determine whether or not Mr. Ninja hits a ceiling we will check if `position.y` is greater than or equal to a specified y-value. Similarly, we will test whether or not `position.y` is less than or equal to a specified y-value to determine if we collided with the ground. For example, the ceiling may be placed at y = 200, and the ground at y = 0.

Before starting the collision checker, there are a few details I think are worth pointing out.

1. When checking for collision in any direction, it's convenient to test for where the entity *will* travel, as opposed to where the entity currently is. This means when falling, we will first add the current velocity to Mr. Ninja's position, and then test for collision.
2. When Mr. Ninja is `Grounded`, he will actually be one pixel *above* the ground. Mr. Ninja's `velocity.y` and `acceleration.y` will both be zero. What this means is that vertical collision detection will trigger Mr. Ninja to immediately begin falling as he will not be colliding with the ground. Adding a special check to test one pixel below Mr. Ninja when in `Grounded` state can easily resolve this problem.
3. Instead of our collision detector returning simple boolean values for collision, it will also return information about what the entity collided with. For now it will just return the ceiling or floors y-value. However, when we introduce our Tiled map, it will return the actual tile that the entity collided with. This is **very** useful for making post-collision decisions based on the tile's position.

```{.java .numberLines startFrom="1"}
class CollisionChecker(private val gameContext: GameContext,
                       private val groundLevel: Float = 0.0f,
                       private val ceilingLevel: Float = 200.0f) {

    // test whether or not we collide with the ground
    fun testDown(entity: Entity): Float? {
        // temporarily translate entity's y position
        entity.position.y += entity.velocity.y

        // check to see if entity is below our fixed ground level
        val collided: Boolean = entity.position.y <= groundLevel

        // undo previous translation
        entity.position.y -= entity.velocity.y

        // we didn't return anything, so don't return a collided object.
        if (!collided) { return null }
        return groundLevel
    }

    fun testOneBelow(entity: Entity): Float? {
        // similar to testDown() except we will only translate position.y
        // by 1.0f instead of by entity.velocity.y
    }


    // test whether or not we collide with the ceiling
    fun testUp(entity: Entity): Float? {
        // temporarily translate entity's y position
        entity.position.y += entity.velocity.y

        // check to see if entity is below our fixed ground level
        val collided: Boolean =
                entity.position.y + entity.hitbox.height >= ceilingLevel

        // undo previous translation
        entity.position.y -= entity.velocity.y

        // we didn't return anything, so don't return a collided object.
        if (!collided) { return null }
        return ceilingLevel
    }

}
```

This simple class provides a good start for handling basic collision detection and helps us ensure we have a standard and generic way to handle this behavior. This is ideal as most entities will use this logic frequently. Later this class will grow to handle horizontal collision detection as well via `testLeft()` and `testRight()` functions.

Testing specific directions becomes more relevant when we introduce full blown tiled map collision. The reason is because if you know the direction you are testing collisions in, you can optimally select subset of tiles to check for collision. For example, if an entity is falling, there shouldn't be any reason to check tiles above the entity.

Our next step is to hook the `CollisionChecker` into our previously constructed `Ninja` class and implement basic falling logic. When the game starts, Mr. Ninja will start somewhere mid screen, and fall to the ground, located at y = 0. i.e. the bottom of the screen. Within the `Ninja` class we will add the `handleFalling()` function. We will also update our `Ninja.handle()` function to call `handleFalling()` immediately after `handleHorizontalMovement()`.

```{.java .numberLines startFrom="1"}
private fun handleFalling() {
    // if not grounded, always apply the acceleration due to gravity to the
    // vertical velocity. This is true for both falling and jumping.
    // also don't forget to scale it by the time between last frame.
    if (gravityState !== GravityState.GROUNDED) {
        velocity.y += Constants.GRAVITY * gameContext.deltaTime
    }

    // but, don't fall too fast
    if (velocity.y < Constants.TERMINAL_VELOCITY) {
        velocity.y = Constants.TERMINAL_VELOCITY
    }

    // don't move horizontally as much when falling. this is optional,
    // but many games do this to make falling feel more natural.
    if (gravityState == GravityState.FALLING) {
        velocity.x *= Constants.HORIZONTAL_FALLING_DAMPING
    }

    // check to see if we collided with anything below us.
    // if so, stop falling and relocate entity to the top of
    // whatever it collided with. in our case, it will be the top
    // of our line (at y = 0). when we introduce tiling it will be
    // tile.height + 1.
    val collided = testDown(entity)
    if (collided != null) {
        entity.gravityState = GravityState.GROUNDED
        // in our example, again, we'll just set the position.y to be right
        // above the line y = 0, i.e. y = 1
        setPosition(
               position.x,
               collided + 1)
        entity.velocity.y = 0.0f
        entity.landTime = entity.totalTime
    }

    // if the entity is standing, simply check one pixel below the entity to
    // ensure solid grounding.
    if (entity.gravityState == GravityState.GROUNDED) {
        val immediatelyBelow = testOneBelow(entity)
        if (immediatelyBelow == null) {
            entity.gravityState = GravityState.FALLING
            entity.fallTime = entity.totalTime
        }
    }

}
```

Reading through the above block of code you may notice two new variables. `fallTime` and `landTime`. These variables are convenient for controlling flow at later points in the game. For example, it is common practice not allow a player to jump too quickly after a previous jump. Additionally, Mr. Ninja's facial expressions actually change based on how long he has been falling.

In addition we added two new constants to our `Constants` class.
```{.java .numberLines startFrom="1"}
const val GRAVITY = -16f
const val TERMINAL_VELOCITY = -8f
```

## Jumping

After building the falling feature, building in jumping is only half the work, as half of jumping is actually falling back to the ground.

When deciding how to implement our jumping algorithm I wanted to be able to increase the height of your jump by holding the jump button down longer. A short tab, Mr. Ninja jumps low. Holding the button longer results in a higher jump. I also wanted the jump to gradually slow to a stop, before falling back to the ground. We can do this by continually slowing the vertical velocity when jumping, simulating gravity/air resistance. This results in smooth arches instead of "V" shaped or unnatural jumping patterns.

We are going to add another block of code in Mr. Ninja's `handleInput()` function where we previously added logic to move left and right.
```{.java .numberLines startFrom="1"}
if (controller.isPressed(GameControls.B)) {
    when (gravityState) {
        GravityState.GROUNDED -> {
            // as previously hinted at, we don't want the player to be able
            // to jump immediately after landing or it feels a bit strange.
            if (timeSince(landTime) >= JUMP_RECHARGE_TIME) {
                jumpTime = totalTime
                velocity.y = Constants.JUMP_FORCE
                gravityState = GravityState.JUMPING
            }
        }
        GravityState.JUMPING -> {
            // if still holding jump, keep adding jump force as the velocity
            // this is how we continue jumping higher when holding the jump
            // button. we only allow holding the button to contribute to the
            // jump for a short period of time.
            if (timeSince(jumpTime) < 0.2f) {
                velocity.y = Constants.JUMP_FORCE
            }
        }
        GravityState.FALLING -> {
            // with future power-ups, allow double jump. the easiest way
            // to time double jumps is to allow the double jump to start
            // only when falling. we will see examples of this later.
        }
    }
}
```

Now that we have initiated our jump, the next thing to do is to add a function named `handledJumping()` to handle vertical motion involved in jumping. We will call `handleJumping()` after we call `handleFalling()` within the `handle()` function.
```{.java .numberLines startFrom="1"}
private fun handleJumping() {
    // if player is not jumping, no need to proceed.
    if (gravityState != GravityState.JUMPING) { return }

    // slowly decrease our upward velocity
    velocity.y *= Constants.AIR_RESISTANCE

    // recall, collide will be the something above the player,
    // stop jumping and begin falling
    val collided = collisionChecker.testUp(this)
    if (collided != null) {
        gravityState = GravityState.FALLING
        // set the position to where the top of the entity is barely touching
        // the collided line.
        setPosition(position.x, collided - hitbox.height)
        velocity.y = 0.0f
        fallTime = totalTime
    }

    // arbitrarily decide a minimum vertical velocity before
    // beginning to fall.
    if (velocity.y < 0.2f) {
        gravityState = GravityState.FALLING
        velocity.y = 0.0f
        fallTime = totalTime
    }

}
```

In addition we added two new constants to our `Constants` class.
```{.java .numberLines startFrom="1"}
const val AIR_RESISTANCE = 0.93f
const val JUMP_FORCE = 4.7f
```

And one more constant I added to the `Ninja` class.
```{.java .numberLines startFrom="1"}
companion object {
    private val JUMP_RECHARGE_TIME = 0.1f
}
```

## Conclusion

- The above code will render a smooth jump that will either apex and smoothly begin to fall, or the entity will collide with the ceiling and begin to fall.
- Our collision checker is currently very primitive and is only checking if the entity falls below a certain "floor" line, or jumps above a "ceiling" line. In the next post we will upgrade our collision checker to collide with tiles loaded from a `Tiled` map.
- Any of the constants can be tweaked to achieve your desired feeling/style.

The next post will cover:

- Loading of `Tiled` maps
- Tiled map collision detection
