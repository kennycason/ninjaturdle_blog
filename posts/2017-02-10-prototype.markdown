---
title: Prototype
author: Kenny Cason
tags: game development, prototype
---

## Project Skeleton

The first step to developing anything large is to first build a simple prototype to get a feel for everything. I haven't developed anything seriously in LibGDX before. I have also never seriously used Tiled for any large game. And to be perfectly honest, I would consider most of my previous attempts at a smooth platformer to be failures, or at best, incomplete.

The first step for me was to get LibGDX setup. I won't go into details in setting up LibGDX as their [wiki](https://github.com/libgdx/libgdx/wiki/Project-Setup-Gradle) does a pretty good job at it. I only had a few problems with some of the resource paths not being configured correctly in the gradle files, but that was easy enough to fix. There are also straight forward instructions for importing the project into IntelliJ. I do wish the project used Maven instead of gradle, but that's a minor complaint. Another friend actually converted his project to use Maven, so it is possible. Also notable was that I only configured the Desktop application and disabled the Html, iOS, and Android applications.

My Desktop Launcher instantiates my class `GameScreen` which extends LibGDX's Screen class. My basic starting skeleton includes basic state time handling, a camera, and basic preparation of the render loop.
```{.java .numberLines startFrom="1"}
class GameScreen(private val gameContext: GameContext) : Screen {

    override fun show() {}

    override fun render(delta: Float) {
        gameContext.deltaTime = delta
        gameContext.totalTime += delta

        Gdx.gl.glClearColor(0f, 0f, 0.0f, 1f)
        Gdx.gl.glClear(GL20.GL_COLOR_BUFFER_BIT)

        gameContext.camera.update()

        gameContext.batch.begin()
        gameContext.batch.projectionMatrix = gameContext.camera.combined
        gameContext.ninja.handle()
        gameContext.batch.end()
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

    val controller = Controllers.getControllers().get(0)

    var deltaTime = 0f
    var totalTime = 0f

    val camera = OrthographicCamera()
    val viewport: Viewport

    var ninja = Ninja(this) // we will define this below!
    var gameScreen = GameScreen(this)

    init {
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

We can instead do the check once:
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

I know that later in my game I will not be working with raw Textures. I will have to deal with simple static sprites as well as animated sprites. Later it will also be convenient have a common class to put common sprite/entity related properties. I'll create a simple interface and implementation.
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

    val sprite: Sprite
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

One final step before creating our `Ninja` class is to created an abstract `Entity` class. Essentially everything in the game will eventually extend `Entity`.
```{.java .numberLines startFrom="1"}
abstract class Entity(val gameContext: GameContext,
                      val position: Vector2 = Vector2(),
                      val velocity: Vector2  = Vector2(),
                      val acceleration: Vector2  = Vector2(),
                      val hitbox: Rectangle = Rectangle(),
                      var faceState: FaceState = FaceState.RIGHT,
                      var motionState: MotionState = MotionState.STANDING) {

    var active: Boolean = true

    fun overlaps(entity: Entity): Boolean {
        return hitbox.overlaps(entity.hitbox)
    }

    fun setPosition(position: Vector2) {
        setPosition(position.x, position.y)
    }

    open fun setPosition(x: Float, y: Float) {
        position.set(x, y)
        hitbox.setPosition(position)
    }

    open fun handle() {
        lifeTime += gameContext.deltaTime
    }

    fun timeSince(time: Float) = lifeTime - time

}
```

We are at last finally able to create our `Ninja` class. :)

```{.java .numberLines startFrom="1"}
class Ninja(gameContext: GameContext) : Entity(gameContext) {

    private val standingRight = SimpleSprite(
            texture = Textures.Ninja.STANDING_RIGHT)
    private val standingLeft = AnimatedSprite(
            texture = Textures.Ninja.STANDING_RIGHT,
            flipHorizontal = true)

    init {
        hitbox.width = 24 - 6f
        hitbox.height = 26f
        state.faceState = FaceState.RIGHT
    }

    override fun handle() {
        super.handle()

        if (gameContext.deltaTime <= 0f) { return }

        draw()
        handleInput()
        handleHorizontalMovement()

        // set position
        setPosition(
                position.x + velocity.x,
                position.y + velocity.y)
    }

    private fun draw() {
        if (!active) { return }

        when (state.faceState) {
            FaceState.RIGHT -> standingRight.draw(gameContext, position)
            FaceState.LEFT -> standingLeft.draw(gameContext, position)
        }
    }

    private fun handleInput() {
        if (!active) { return }

        val controller = gameContext.controller

        if (ccontroller.getButton(Keys.A)) {
            acceleration.x = -(Constants.BASE_WALK_ACCELERATION + speed)

        } else if (ccontroller.getButton(Keys.D)) {
            acceleration.x = (Constants.BASE_WALK_ACCELERATION + speed)

        } else {
            acceleration.x = 0.0f
        }
    }

    private fun handleHorizontalMovement() {
        // horizontal movements
        velocity.x *= Constants.HORIZONTAL_DAMPING // friction
        velocity.x += acceleration.x * gameContext.deltaTime

        // no need to handle collisions if not moving
        if (Math.abs(velocity.x) < 0.1) {
            velocity.x = 0f
            return
        }
        // place holder for future collision detection
    }

    override fun setPosition(x: Float, y: Float) {
        position.x = x
        position.y = y
        hitbox.x = x + 3
        hitbox.y = y
    }

}
```
