---
title: Prototype - Part I
author: Kenny Cason
tags: game development, prototype
---

The first step to developing anything large is to first build a simple prototype to get a feel for everything. I haven't developed anything seriously in LibGDX before. I have also never used Tiled for any large game. And to be perfectly honest, I would consider most of my previous attempts at a smooth platformer to be failures, or at best, incomplete.

This post is a bit long as it involves a lot of boiler plate.

## Project Skeleton

The first step for me was to get LibGDX setup. I won't go into details in setting up LibGDX as their [wiki](https://github.com/libgdx/libgdx/wiki/Project-Setup-Gradle) does a pretty good job at it. I only had a few problems with some of the resource paths not being configured correctly in the Gradle files, but that was easy enough to fix. There are also straight forward instructions for importing the project into IntelliJ. I do wish the project used Maven instead of Gradle, but that's a minor complaint. A friend of mine converted his project to use Maven, so it is possible. Also notable was that I only configured the Desktop application and disabled the Html, iOS, and Android applications.

My Desktop Launcher instantiates my class `GameScreen` which extends LibGDX's `Screen` class. I also scale the screen by 3, making each pixel actually drawn as 3x3. You can optionally scale this however you want. This is also the only part of our code that is Java, simply because I didn't feel like configuring the whole module for Kotlin, all for one small class.

```{.java .numberLines startFrom="1"}
public class DesktopLauncher {
    public static void main (final String[] arg) {
        final LwjglApplicationConfiguration config = new LwjglApplicationConfiguration();
        config.title = "Ninja Turdle";
        config.width = (int) (Constants.WIDTH * Constants.SCALE);
        config.height = (int) (Constants.HEIGHT * Constants.SCALE);
        new LwjglApplication(new NinjaTurdle(), config);
    }
}
```

My basic starting skeleton includes basic state time handling, a camera, and basic preparation of the render loop.
```{.java .numberLines startFrom="1"}
class GameScreen(private val gameContext: GameContext) : Screen {

    override fun show() {}

    override fun render(delta: Float) {
        // update timers
        gameContext.deltaTime = delta
        gameContext.totalTime += delta

        // clear the screen with a black background
        Gdx.gl.glClearColor(0f, 0f, 0.0f, 1f)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)

        gameContext.camera.update() // focus the camera (the camera currently doesn't move)

        gameContext.batch.begin()   // prepare to draw

        gameContext.batch.projectionMatrix = gameContext.camera.combined
        gameContext.ninja.handle()  // handle Mr. Ninja
        // place holder for other entity handling, for example:
        // gameContext.enemies.forEach(Enemy::handle)

        gameContext.batch.end()     // finish drawing
    }

    override fun resize(width: Int, height: Int) {}

    override fun pause() {}

    override fun resume() {}

    override fun hide() {}

    override fun dispose() {}

}
```
Looking at the above `GameScreen` code you will notice the use of the `GameContext` variable. This is an object that I pass around that contains common game state variables. Such variables will include the `Ninja` object, bullets, enemies, items, the currently loaded map, etc. Keeping them in this central place makes it easier to keep up with global state. While I'm aware of the evilness of global state, games are very stateful by nature. In general, I start out simple, and as the state grows more complicated, I abstract state into classes that better aide in state management. We will see more examples of this later. The `GameContext` class at this point looks something like:

```{.java .numberLines startFrom="1"}
class GameContext(val game: Game) {
    val batch = SpriteBatch()

    // this controller implementation will be designed in a future blog post.
    val controller = ControllerFactory.buildMultiController()

    // the time since the last render loop
    var deltaTime = 0f
    // the total time that has elapsed in the game
    var totalTime = 0f

    val camera = OrthographicCamera()
    val viewport: Viewport

    var ninja = Ninja(this) // we will define this below!
    var gameScreen = GameScreen(this)

    // placeholder for other entities
    // val enemies = Array<Enemy>()
    // var bullets = Array<Bullet>()

    init {
        // create a simple orthogonal camera (rectangle view, fixed depth)
        camera.setToOrtho(false, Constants.WIDTH, Constants.HEIGHT)
        camera.update()
        viewport = FitViewport(Constants.WIDTH, Constants.HEIGHT, camera)
    }

    fun timeSince(time: Float) = totalTime - time

}
```

## Building a Mr. Turdle

With the project setup complete, and the skeleton in place, it is time to write our `Ninja` class which will contain all the information about our protagonist, Mr. Turdle. However, before we start we must first build up all the components that will go into the `Ninja`.

I added a few state enums to keep up with some basic states. Below, I will highlight a couple sample states and how I use them.
```{.java .numberLines startFrom="1"}
/**
 * A state enum to keep track of which direction an Entity is facing.
 */
enum class FaceState {
    LEFT,
    RIGHT
}
```

```{.java .numberLines startFrom="1"}
/**
 * A state enum to keep track of discrete horizontal motion states.
 */
enum class MotionState {
    STANDING,
    WALKING,
    RUNNING
}
```

Enums are value for keeping track of entity states because they allow for simpler state management. For example, later when we want to check if the player is walking or standing, we don't have to repeatedly perform checks like:
```{.java .numberLines startFrom="1"}
if (Math.abs(velocity.x) > 0f) {
    // entity is walking
} else {
    // entity is standing
}
```

We can instead do the check once. This is particularly useful for more complex states.
```{.java .numberLines startFrom="1"}
if (Math.abs(velocity.x) > 0f) {
    state.motionState = motionState.WALKING
} else {
    state.motionState = motionState.STANDING
}
```

And then in future code we can simply use switch/where statements on the state enum and not worry about the details of what defines a specific state:
```{.java .numberLines startFrom="1"}
when (state.motionState) {
    GravityState.WALKING -> {
        // handle walking case
    }
    GravityState.STANDING -> {
        // handle standing case
    }
}
```

Next was to load the textures, for now I'm just going to directly load them into a Texture class as static instances. There are more advanced methods for managing Textures via the (https://github.com/libgdx/libgdx/wiki/Texture-packer)[`TexturePacker` and `TextureAtlas`]. However, this seems to be a bit invasive to my development, especially early on, and considering I haven't used it. I will re-investigate later. My Textures class is pretty simple:
```{.java .numberLines startFrom="1"}
object Textures {
    val TEXTURE_PATH = "sprite/"

    object Ninja {
        val STANDING_RIGHT = Texture(TEXTURE_PATH + "ninja/ninja.png")
    }

}
```

I know that later in my game I will not be working with raw Textures. I will have to deal with simple static sprites as well as animated sprites. It will also be convenient have a common class to put common sprite/entity related properties. Below is a simple interface and implementation.
```{.java .numberLines startFrom="1"}
interface MySprite {
    val width: Float
    val height: Float

    fun draw(gameContext: GameContext, position: Vector2)
    fun draw(gameContext: GameContext, x: Float, y: Float)
}
```

```{.java .numberLines startFrom="1"}
class SimpleSprite : MySprite {

    val sprite: Sprite // a LibGDX Sprite object
    override val width: Float
    override val height: Float

    constructor(texture: Texture,
                flipHorizontal: Boolean = false,
                flipVertical: Boolean = false) {
        sprite = Sprite(texture)
        sprite.setFlip(flipHorizontal, flipVertical)
        width = sprite.width
        height = sprite.height
    }

    override fun draw(gameContext: GameContext, x: Float, y: Float) {
        sprite.setPosition(x, y)
        sprite.draw(gameContext.batch)
    }

    override fun draw(gameContext: GameContext, position: Vector2) {
        draw(gameContext, position.x, position.y)
    }

}
```

One final step before creating our `Ninja` class is to created an abstract `Entity` class. Essentially everything in the game will extend `Entity`.
```{.java .numberLines startFrom="1"}
abstract class Entity(val gameContext: GameContext,
                      val position: Vector2 = Vector2(),
                      val velocity: Vector2  = Vector2(),
                      val acceleration: Vector2  = Vector2(),
                      var faceState: FaceState = FaceState.RIGHT,
                      var motionState: MotionState = MotionState.STANDING,
                      var active: Boolean = true) {

    open fun handle() {
        lifeTime += gameContext.deltaTime
    }

    fun timeSince(time: Float) = lifeTime - time

}
```

The idea is that we will be able to iterate across our game entities and simply call the `handle()` function. The `handle()` will perform all actions that a particular entity should do during a time frame. This includes, moving, rendering, attacking, checking collisions, add new states to the `GameContext`, etc.

We are at last finally able to create our `Ninja` class. :)
```{.java .numberLines startFrom="1"}
class Ninja(gameContext: GameContext) : Entity(gameContext) {

    private val standingRight = SimpleSprite(
            texture = Textures.Ninja.STANDING_RIGHT)
    private val standingLeft = SimpleSprite(
            texture = Textures.Ninja.STANDING_RIGHT,
            flipHorizontal = true)

    init {
        state.faceState = FaceState.RIGHT
    }

    override fun handle() {
        super.handle()

        if (gameContext.deltaTime <= 0f) { return } // shouldn't happen

        draw()
        handleInput()
        handleHorizontalMovement()

        // this is outside the horizontal movement function because later we
        // will have vertical movement when we introduce jumping and falling.
        position.add(velocity)
    }

    private fun draw() {
        // note how we can cleanly use our state enums to determine which sprite to draw.
        when (state.faceState) {
            FaceState.RIGHT -> standingRight.draw(gameContext, position)
            FaceState.LEFT -> standingLeft.draw(gameContext, position)
        }
    }

    private fun handleInput() {
        val controller = gameContext.controller

        if (controller.isPressed(GameControls.DPAD_LEFT)) {
            acceleration.x = -Constants.BASE_WALK_ACCELERATION
            faceState = FaceState.LEFT
            motionState = MotionState.WALKING

        } else if (controller.isPressed(GameControls.DPAD_RIGHT)) {
            acceleration.x = Constants.BASE_WALK_ACCELERATION
            faceState = FaceState.RIGHT
            motionState = MotionState.WALKING

        } else {
            acceleration.x = 0.0f
        }
    }

    private fun handleHorizontalMovement() {
        // friction to gradually slow to a stop. this creates a better experience
        // than abrupt stops.
        velocity.x *= Constants.HORIZONTAL_DAMPING

        // because the time in between render loops can slightly vary, we want to
        // scale the acceleration by that amount. This will prevent choppy motions
        // during times where delta time jumps up and down.
        // we add the acceleration to velocity because this gives a smooth feeling
        // of acceleration like in Super Metroid or Super Mario World.
        velocity.x += acceleration.x * gameContext.deltaTime

        // no need to handle collisions if not moving
        if (Math.abs(velocity.x) < 0.1) {
            velocity.x = 0f
            motionState = MotionState.STANDING
            return
        }
        // place holder for future collision detection
    }

}
```

At this point we have introduced many constants. Below are some of their sample values. We are not currently using all the tile properties yet. However, in the next post when we implement the Tiled Map, we will use these values.
```{.java .numberLines startFrom="1"}
object Constants {
    const val BASE_WALK_ACCELERATION = 14f
    const val HORIZONTAL_DAMPING = 0.875f
    const val TILE_DIM = 16f
    const val TILES_HORIZONTAL = 18 // same dimensions as Super Metroid
    const val TILES_VERTICAL = 13
    const val WIDTH = TILE_DIM * TILES_HORIZONTAL
    const val HEIGHT = TILE_DIM * TILES_VERTICAL
    const val SCALE = 3f
}
```

## Conclusion

At this point we have the basic code for:

- DesktopLauncher entry point
- The basic game loop
- A simple sprite implementation
- A basic general purpose Entity class
- Demonstration of state management
- Smooth walking back and forth via "position = velocity + acceleration" and "damping"
- The camera is locked and only Mr. Ninja would move across the screen (left and right)

The next post will cover:
- loading of `Tiled` maps
- jumping
- falling
- collision detection

<img src="/images/ninja_large.png"/>
