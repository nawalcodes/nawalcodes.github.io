/**
 * Module: gameobject
 * 
 * This module defines the GameObject class and related functionality. It includes initialization of
 * random generators, management of game objects, and integration with various systems like SDL and
 * custom components.
 */
module gameobject;

import std.random;
import core.atomic : atomicOp; // Import atomic operations
import std.string;
import bindbc.sdl;
import component;
import script;
import std.stdio;

import resource_manager;
import sound;
import tilemap;

/**
 * Random number generator instance used for game object operations.
 */
Random rnd;

/// Static initializer to seed the random number generator.
shared static this()
{
    rnd = Random(42);
}

/**
 * Class: GameObject
 * 
 * Represents a game object within the engine. Provides mechanisms for naming,
 * component management, and lifecycle handling.
 */
class GameObject
{
    /**
     * Constructor: this
     * 
     * Initializes a new GameObject with a specified name.
     * 
     * Params:
     *   name = The name of the game object. Must be non-empty.
     */
    this(string name)
    {
        assert(name.length > 0);
        mName = name;
        // Atomic increment of number of game objects
        sGameObjectCount.atomicOp!"+="(1);
        mID = sGameObjectCount;
    }

    /**
     * Destructor
     * 
     * Cleans up resources used by the game object.
     */
    ~this()
    {
    }

    /**
     * Getter function for getting a name. 
     */
    string GetName() const
    {
        return mName;
    }

    /**
     * Getter function for getting an ID. 
     */
    size_t GetID() const
    {
        return mID;
    }

    /**
     * Handles user input events.
     * Processes SDL events for quitting, interacting with the menu, 
     * and controlling game objects (keyboard and mouse inputs).
     */
    void Input()
    {
    }

    /**
     * Handles user input events.
     * Processes SDL events for quitting, interacting with the menu, 
     * and controlling game objects (keyboard and mouse inputs).
     *
     * Params:
     *   event = one event caused by the user within the gameplay. 
     */
    void Input(SDL_Event event)
    {
    }

    /**
     * Updates the game state.
     * Applies logic to game objects, handles collisions, and processes interactions
     * between the player and other objects in the scene.
     */
    void Update()
    {
    }

    /**
     * Updates the game state.
     * Applies logic to game objects, handles collisions, and processes interactions
     * between the player and other objects in the scene.
     *
     * Params:
     *   event = one event caused by the user within the gameplay. 
     */
    void Update(DrawableTileMap dt, int zoomFactor)
    {
    }

    /**
     * Renders the current game state.
     * Draws the current scene, game objects, and the menu (if active) on the screen.
     */
    void Render()
    {
    }

    void Render(SDL_Renderer* renderer)
    {
        foreach (comp; mComponents)
            comp.Render(renderer);
    }

    IComponent GetComponent(ComponentType type)
    {
        return type in mComponents ? mComponents[type] : null;
    }

    IComponent GetScriptComponent(ScriptComponentType type)
    {
        return type in mScripts ? mScripts[type] : null;
    }

    void AddScriptComponent(ScriptComponentType type, IComponent component)
    {
        mScripts[type] = component;
    }

    void AddComponent(ComponentType T)(IComponent component)
    {
        mComponents[T] = component;
    }

protected:
    IComponent[ComponentType] mComponents;
    IComponent[ScriptComponentType] mScripts;

private:
    string mName;
    size_t mID;
    static shared size_t sGameObjectCount = 0;
}

class Enemy : GameObject
{
    SDL_Rect mRectangle;
    int xDirection;
    ANIMATION_STATE mAnimationState = ANIMATION_STATE.STOP;

    // List to hold active laser
    ComponentLaser mLaser;
    int counter;

    // for death animation
    bool mDead = false;
    string mImageFile = "./assets/images/cobra.bmp";
    string mJSONFile = "./assets/images/cobra.json";

    this()
    {
        super("Enemy"); // Call to base class constructor

        mRectangle.x = 50;
        mRectangle.y = 50;
        mRectangle.w = 30;
        mRectangle.h = 32;
        xDirection = 10;

        mLaser = null;
    }

    ~this()
    {
        // causes segfault???????????????????
        // SDL_DestroyTexture(mTexture);
        // ComponentTexture texture = cast(ComponentTexture)this.GetComponent(ComponentType.TEXTURE);
        // texture.destroy();
    }

    override void Update()
    {
        mRectangle.x += xDirection;
        ComponentColliderCircle comp = cast(ComponentColliderCircle) this.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        comp.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2);
        comp.Update();

        EnemyScriptLaser laser = cast(EnemyScriptLaser) this.GetScriptComponent(
            ScriptComponentType.LASER);

        if (laser is null)
        {
            // fire laser 10% of the time
            import std.random;
            import std.datetime;

            auto seed = Random(cast(uint)(Clock.currTime().toUnixTime() * 1000) + cast(uint) GetID());
            int randomNumber = uniform(1, 11, seed);
            if (randomNumber == 7)
            {
                FireLaser();
            }
        }
        else
        {

            laser.Update(); // Update laser
            if (laser.ShouldDelete())
            {
                laser.destroy();
                mScripts.remove(ScriptComponentType.LASER); // Remove from mScripts to avoid segmentation fault
            }
        }
    }

    override void Update(DrawableTileMap dt, int zoomFactor)
    {
        // Horizontal movement and wall collision
        if (xDirection > 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "right"))
            {
                mRectangle.x += xDirection / 10;
                mAnimationState = ANIMATION_STATE.RIGHT;
            }
            else
            {
                xDirection *= -1;
                mRectangle.x += xDirection / 10;
                mAnimationState = ANIMATION_STATE.LEFT;
            }
        }
        else if (xDirection < 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "left"))
            {
                mRectangle.x += xDirection / 10;
                mAnimationState = ANIMATION_STATE.LEFT;
            }
            else
            {
                xDirection *= -1;
                mRectangle.x += xDirection / 10;
                mAnimationState = ANIMATION_STATE.RIGHT;
            }
        }
        if (mRectangle.x > 620 - mRectangle.w / 2)
            mRectangle.x = 620 - mRectangle.w / 2; // hit right wall
        else if (mRectangle.x < 0)
            mRectangle.x = 0; // hit left wall
        ComponentColliderCircle comp = cast(ComponentColliderCircle) this.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        comp.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2);
        comp.Update();

        EnemyScriptLaser laser = cast(EnemyScriptLaser) this.GetScriptComponent(
            ScriptComponentType.LASER);

        if (laser is null)
        {
            // fire laser 10% of the time
            import std.random;
            import std.datetime;

            auto seed = Random(cast(uint)(Clock.currTime().toUnixTime() * 1000) + cast(uint) GetID());
            int randomNumber = uniform(1, 11, seed);
            if (randomNumber == 7)
            {
                FireLaser();
            }
        }
        else
        {

            laser.Update(); // Update laser
            if (laser.ShouldDelete())
            {
                laser.destroy();
                mScripts.remove(ScriptComponentType.LASER); // Remove from mScripts to avoid segmentation fault
            }
        }
    }

    // bool wall_collision()
    // {
    //     return (mRectangle.x > 620 - mRectangle.w / 2 || mRectangle.x < 0);
    // }

    bool TileCollision(DrawableTileMap dt, int zoom, SDL_Rect playerRect, string dir)
    {
        auto tilesz = dt.mTileSet.mTileSize;
        switch (dir)
        {
        case "up":
            foreach (i; 1 .. playerRect.w / tilesz)
                if (dt.GetTileAt(playerRect.x + i * tilesz, playerRect.y, zoom) != 966)
                    return true;
            return false;

        case "down":
            foreach (i; 1 .. playerRect.w / tilesz)
                if (dt.GetTileAt(playerRect.x + i * tilesz, playerRect.y + playerRect.h, zoom) != 966)
                    return true;
            return false;

        case "left":
            foreach (i; 1 .. playerRect.h / tilesz)
                if (dt.GetTileAt(playerRect.x, playerRect.y + i * tilesz, zoom) != 966)
                    return true;
            return false;

        case "right":
            foreach (i; 1 .. playerRect.h / tilesz)
                if (dt.GetTileAt(playerRect.x + playerRect.w, playerRect.y + i * tilesz, zoom) != 966)
                    return true;
            return false;

        default:
            return false;
        }

    }

    void change_dir()
    {
        xDirection *= -1;
    }

    override void Render(SDL_Renderer* renderer)
    {
        // ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        // texture.SetRectangle(mRectangle);
        // texture.SetTexture(renderer, mImageFile);
        // texture.Render(renderer);

        ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        texture.SetRectangle(mRectangle);
        texture.SetTexture(renderer, mImageFile);
        texture.Load(mJSONFile);
        if (mAnimationState == ANIMATION_STATE.LEFT)
            texture.Set_Direction("walkLeft");
        else if (mAnimationState == ANIMATION_STATE.RIGHT)
            texture.Set_Direction("walkRight");
        else if (mAnimationState == ANIMATION_STATE.UP)
            texture.Set_Direction("walkUp");
        else if (mAnimationState == ANIMATION_STATE.DOWN)
            texture.Set_Direction("walkDown");
        else if (mAnimationState == ANIMATION_STATE.STOP)
            texture.Set_Direction("Stop");
        else if (mAnimationState == ANIMATION_STATE.STOPLEFT)
            texture.Set_Direction("StopLeft");
        else if (mAnimationState == ANIMATION_STATE.STOPRIGHT)
            texture.Set_Direction("StopRight");
        else if (mAnimationState == ANIMATION_STATE.STOPUP)
            texture.Set_Direction("StopUp");
        else if (mAnimationState == ANIMATION_STATE.STOPDOWN)
            texture.Set_Direction("StopDown");
        texture.Render(renderer);

        if (mDead == false)
        {
            EnemyScriptLaser laser = cast(EnemyScriptLaser) this.GetScriptComponent(
                ScriptComponentType.LASER);
            if (laser !is null)
            {
                laser.Render(renderer);
            }
        }
    }

    void FireLaser()
    {
        // Create a new laser and set its position to the enemy's position
        if (cast(EnemyScriptLaser) this.GetScriptComponent(ScriptComponentType.LASER) is null)
        {
            auto laser = new EnemyScriptLaser(this.GetID());
            this.AddScriptComponent(ScriptComponentType.LASER, laser);
            laser.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y); // Center the laser
        }
    }

    void SetPosition(int x, int y)
    {
        mRectangle.x = x;
        mRectangle.y = y;
    }

    int[2] GetPosition()
    {
        return [mRectangle.x, mRectangle.y];
    }

    void SetEnemyImage(string filename)
    {
        mImageFile = filename;
    }

    void SetEnemyJSON(string filename)
    {
        mJSONFile = filename;
    }
}

class Player : GameObject
{
    SDL_Rect mRectangle;
    int xDirection = 0;
    int yDirection = 0;
    ComponentControls mCtrls;
    int mGravity = 0;
    // enum ANIMATION_STATE
    // {
    //     LEFT,
    //     RIGHT,
    //     DOWN,
    //     UP,
    //     STOP,
    //     STOPLEFT,
    //     STOPRIGHT,
    //     STOPUP,
    //     STOPDOWN
    // };
    ANIMATION_STATE mAnimationState = ANIMATION_STATE.STOP;

    Sound mySound;

    // List to hold active lasers
    ComponentLaser mLaser;

    string mImageFile = "./assets/images/cobra.bmp";
    string mJSONFile = "./assets/images/cobra.json";

    // for testing tiles
    // DrawableTileMap mDT;
    // int mZoom;

    this()
    {
        super("Player"); // Call to base class constructor

        mRectangle.x = 50;
        mRectangle.y = 50;
        mRectangle.w = 50;
        mRectangle.h = 50;

        mCtrls = new ComponentArrows(GetID());

        // ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        // texture.SetRectangle(mRectangle);
        // texture.Load("./assets/images/test.json");

        mLaser = null;

        // Create Sound
        mySound = Sound("./assets/sounds/collide.wav");
        mySound.SetupDevice();
    }

    ~this()
    {
        // SDL_DestroyTexture(mTexture);
        ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        texture.destroy();
    }

    override void Input(SDL_Event event)
    {
        mCtrls.ArrowInput(event, xDirection, yDirection, mAnimationState);
        if (event.type == SDL_KEYDOWN)
        {
            switch (event.key.keysym.sym)
            {
            case SDLK_SPACE: // Check for space bar press

                switch (mAnimationState)
                {
                case ANIMATION_STATE.LEFT, ANIMATION_STATE.STOPLEFT:
                    FireLaser("left");
                    break;
                case ANIMATION_STATE.RIGHT, ANIMATION_STATE.STOPRIGHT:
                    FireLaser("right");
                    break;
                case ANIMATION_STATE.UP, ANIMATION_STATE.STOPUP:
                    FireLaser("up");
                    break;
                case ANIMATION_STATE.DOWN, ANIMATION_STATE.STOPDOWN:
                    FireLaser("down");
                    break;
                default:
                    FireLaser();
                    break;
                }

                mySound.PlaySound(); // Play the sound when space is pressed
                break;
            default:
                break;
            }
        }
    }

    override void Update()
    {
        mRectangle.x += xDirection;
        if (mRectangle.x > 620 - mRectangle.w / 2)
        { // hit right wall
            mRectangle.x = 620 - mRectangle.w / 2;
        }
        else if (mRectangle.x < 0)
        { // hit left wall
            mRectangle.x = 0;
        }

        mRectangle.y += yDirection;
        if (mRectangle.y > 620 - mRectangle.h / 2)
        { // hit upper wall
            mRectangle.y = 620 - mRectangle.h / 2;
        }
        else if (mRectangle.y < 0)
        { // hit lower wall
            mRectangle.y = 0;
        }

        ComponentColliderCircle comp = cast(ComponentColliderCircle) this.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        comp.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2);
        comp.Update();

        PlayerScriptLaser laser = cast(PlayerScriptLaser) this.GetScriptComponent(
            ScriptComponentType.LASER);
        if (laser !is null)
        {
            laser.Update(); // Update laser
            if (laser.ShouldDelete())
            {
                laser.destroy();
                mScripts.remove(ScriptComponentType.LASER); // Remove from mScripts to avoid segmentation fault
            }
        }

    }

    override void Update(DrawableTileMap dt, int zoomFactor)
    {
        // // Check if it's legal to move in any direction
        // mDT = dt;
        // mZoom = zoomFactor;

        // Horizontal movement and wall collision
        if (xDirection > 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "right"))
                mRectangle.x += xDirection / 10;
            // mAnimationState = ANIMATION_STATE.RIGHT;
        }
        else if (xDirection < 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "left"))
                mRectangle.x += xDirection / 10;
            // mAnimationState = ANIMATION_STATE.LEFT;
        }
        if (mRectangle.x > 620 - mRectangle.w / 2)
            mRectangle.x = 620 - mRectangle.w / 2; // hit right wall
        else if (mRectangle.x < 0)
            mRectangle.x = 0; // hit left wall

        // Vertical movement and wall collision
        yDirection += mGravity;
        if (yDirection < 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "up"))
                mRectangle.y += yDirection / 10;
            // mAnimationState = ANIMATION_STATE.UP;
        }
        else if (yDirection > 0)
        {
            if (!TileCollision(dt, zoomFactor, mRectangle, "down"))
                mRectangle.y += yDirection / 10;
            else
                yDirection = 0;
            // mAnimationState = ANIMATION_STATE.DOWN;
        }
        if (mRectangle.y > 620 - mRectangle.h / 2)
            mRectangle.y = 620 - mRectangle.h / 2; // hit lower wall
        else if (mRectangle.y < 0)
            mRectangle.y = 0; // hit upper wall

        // Update collider position
        ComponentColliderCircle comp = cast(ComponentColliderCircle) this.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        if (comp !is null)
        {
            comp.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2);
            comp.SetDimensions(mRectangle.w / 2);
            comp.Update();
        }

        // Update laser script if applicable
        PlayerScriptLaser laser = cast(PlayerScriptLaser) this.GetScriptComponent(
            ScriptComponentType.LASER);
        if (laser !is null)
        {
            laser.Update(); // Update laser
            if (laser.ShouldDelete())
            {
                laser.destroy();
                mScripts.remove(ScriptComponentType.LASER); // Remove from mScripts to avoid segmentation fault
            }
        }
    }

    override void Render(SDL_Renderer* renderer)
    {
        // SDL_RenderCopy(renderer, mTexture, null, &mRectangle);
        ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        texture.SetRectangle(mRectangle);
        texture.SetTexture(renderer, mImageFile);
        texture.Load(mJSONFile);
        if (mAnimationState == ANIMATION_STATE.LEFT)
            texture.Set_Direction("walkLeft");
        else if (mAnimationState == ANIMATION_STATE.RIGHT)
            texture.Set_Direction("walkRight");
        else if (mAnimationState == ANIMATION_STATE.UP)
            texture.Set_Direction("walkUp");
        else if (mAnimationState == ANIMATION_STATE.DOWN)
            texture.Set_Direction("walkDown");
        else if (mAnimationState == ANIMATION_STATE.STOP)
            texture.Set_Direction("Stop");
        else if (mAnimationState == ANIMATION_STATE.STOPLEFT)
            texture.Set_Direction("StopLeft");
        else if (mAnimationState == ANIMATION_STATE.STOPRIGHT)
            texture.Set_Direction("StopRight");
        else if (mAnimationState == ANIMATION_STATE.STOPUP)
            texture.Set_Direction("StopUp");
        else if (mAnimationState == ANIMATION_STATE.STOPDOWN)
            texture.Set_Direction("StopDown");
        texture.Render(renderer);

        // // SDL_Rect square;
        // square.x = cast(int) mRectangle.x;
        // square.y = cast(int) mRectangle.y;
        // square.w = mRectangle.w; // Width of the square
        // square.h = mRectangle.h; // Height of the square

        // // Set the square color (e.g., green)
        // SDL_SetRenderDrawColor(renderer, 0, 255, 0, 255);

        // // Draw the square
        // SDL_RenderDrawRect(renderer, &square);

        // Render tiles that it is interacting with
        // RenderNearTiles(renderer, mDT, mRectangle);

        // ComponentColliderCircle circle = cast(ComponentColliderCircle)this.GetComponent(ComponentType.CIRCLE_COLLIDER);
        // circle.Render(renderer);

        PlayerScriptLaser laser = cast(PlayerScriptLaser) this.GetScriptComponent(
            ScriptComponentType.LASER);
        if (laser !is null)
        {
            laser.Render(renderer);
        }
    }

    bool IsColliding(GameObject go)
    {
        ComponentColliderCircle circ = cast(ComponentColliderCircle) go.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        ComponentColliderCircle p1_circ = cast(ComponentColliderCircle) GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        if (circ.IsColliding(p1_circ))
        {
            return true;
        }
        return false;
    }

    bool isStomp(GameObject go)
    {
        auto enemy = cast(Enemy) go;
        if (enemy is null)
            return false;

        auto pos = enemy.GetPosition();
        // writeln("enemy: ", pos[1],  " - player: ", mRectangle.y + mRectangle.h/2, " ", mRectangle.x - mRectangle.w);

        // Check if the enemy is within the horizontal range of the player
        if (pos[0] < mRectangle.x + mRectangle.w && pos[0] > mRectangle.x - mRectangle.w &&
             // Check if the enemy is below the player
            pos[1] > mRectangle.y + mRectangle.h / 2)
        {
            return true;
        }
        return false;
    }

    bool TileCollision(DrawableTileMap dt, int zoom, SDL_Rect playerRect, string dir)
    {
        auto tilesz = dt.mTileSet.mTileSize;
        switch (dir)
        {
        case "up":
            foreach (i; 1 .. playerRect.w / tilesz)
                if (dt.GetTileAt(playerRect.x + i * tilesz, playerRect.y, zoom) != 966)
                    return true;
            return false;

        case "down":
            foreach (i; 1 .. playerRect.w / tilesz)
                if (dt.GetTileAt(playerRect.x + i * tilesz, playerRect.y + playerRect.h, zoom) != 966)
                    return true;
            return false;

        case "left":
            foreach (i; 1 .. playerRect.h / tilesz)
                if (dt.GetTileAt(playerRect.x, playerRect.y + i * tilesz, zoom) != 966)
                    return true;
            return false;

        case "right":
            foreach (i; 1 .. playerRect.h / tilesz)
                if (dt.GetTileAt(playerRect.x + playerRect.w, playerRect.y + i * tilesz, zoom) != 966)
                    return true;
            return false;

        default:
            return false;
        }

    }

    void SetJump()
    {
        mCtrls = new JumpArrows(GetID());
        mGravity = 2;
    }

    void FireLaser()
    {
        // Create a new laser and set its position to the player's position
        if (cast(PlayerScriptLaser) this.GetScriptComponent(ScriptComponentType.LASER) is null)
        {
            auto laser = new PlayerScriptLaser(this.GetID());
            this.AddScriptComponent(ScriptComponentType.LASER, laser);
            laser.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2); // Center the laser
        }
    }

    void FireLaser(string dir)
    {
        // Create a new laser and set its position to the player's position
        if (cast(PlayerScriptLaser) this.GetScriptComponent(ScriptComponentType.LASER) is null)
        {
            auto laser = new PlayerScriptLaser(this.GetID());
            laser.SetDirection(dir);
            this.AddScriptComponent(ScriptComponentType.LASER, laser);
            laser.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y); // Center the laser
        }
    }

    void SetPosition(int x, int y)
    {
        mRectangle.x = x;
        mRectangle.y = y;
    }

    int[2] GetPosition()
    {
        return [mRectangle.x, mRectangle.y];
    }

    void SetImage(string filename)
    {
        mImageFile = filename;
    }

    void SetJSON(string filename)
    {
        mJSONFile = filename;
    }
}

class Score : GameObject
{
    int mPoints;

    this()
    {
        super("Score"); // Call to base class constructor
        mPoints = 0;
    }

    ~this()
    {
        // SDL_DestroyTexture(mTexture);
        // ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        // texture.destroy();
    }

    override void Render(SDL_Renderer* renderer)
    {
        import std.conv;

        ComponentText text = cast(ComponentText) this.GetComponent(ComponentType.TEXT);
        if (text.mText != "SCORE: " ~ to!string(mPoints))
            text.Update("SCORE: " ~ to!string(mPoints));
        text.Render(renderer);
    }

    void SetScore(int points)
    {
        mPoints = points;
    }

    void IncrementScore(int increment)
    {
        mPoints += increment;
    }

    int GetScore()
    {
        return mPoints;
    }
}

class Coin : GameObject
{
    SDL_Rect mRectangle;

    string mImageFile = "./assets/images/coins.bmp";
    string mJSONFile = "./assets/images/coins.json";

    this()
    {
        super("Coin"); // Call to base class constructor

        mRectangle.x = 50;
        mRectangle.y = 50;
        mRectangle.w = 50;
        mRectangle.h = 50;
    }

    ~this()
    {
        // SDL_DestroyTexture(mTexture);
        ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        texture.destroy();
    }

    override void Update(DrawableTileMap dt, int zoomFactor)
    {
        ComponentColliderCircle comp = cast(ComponentColliderCircle) this.GetComponent(
            ComponentType.CIRCLE_COLLIDER);
        comp.SetPosition(mRectangle.x + mRectangle.w / 2, mRectangle.y + mRectangle.h / 2);
        comp.Update();
    }

    override void Render(SDL_Renderer* renderer)
    {
        ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
        texture.SetRectangle(mRectangle);
        texture.SetTexture(renderer, mImageFile);
        texture.Load(mJSONFile);
        texture.Set_Direction("spinGold");
        texture.Render(renderer);

        // ComponentColliderCircle circle = cast(ComponentColliderCircle)this.GetComponent(ComponentType.CIRCLE_COLLIDER);
        // circle.Render(renderer);
    }

    void SetImage(string filename)
    {
        mImageFile = filename;
    }

    void SetJSON(string filename)
    {
        mJSONFile = filename;
    }

    void SetPosition(int x, int y)
    {
        mRectangle.x = x;
        mRectangle.y = y;
    }
}

// // For Testing
    // void RenderNearTiles(SDL_Renderer* renderer, DrawableTileMap dt, SDL_Rect rect){

    //     int tilesz = mDT.mTileSet.mTileSize;
    //     // Highlight top and bottom tiles
    //     foreach (i; 1 .. rect.w / tilesz) {
    //         // Top
    //         mDT.RenderTileAt(rect.x + i * tilesz, rect.y, mZoom);
    //         // Bottom
    //         mDT.RenderTileAt(rect.x + i * tilesz, rect.y + rect.h, mZoom);
    //     }

    //     // Highlight left and right tiles
    //     foreach (i; 1 .. rect.h / tilesz) {
    //         // Left
    //         mDT.RenderTileAt(rect.x, rect.y + i * tilesz, mZoom);
    //         // Right
    //         mDT.RenderTileAt(rect.x + rect.w, rect.y + i * tilesz, mZoom);
    //     }
    // }

// class Button : GameObject
// {
//     int mPoints;
//     SDL_Rect mRectangle;

//     this()
//     {
//         super("Score"); // Call to base class constructor
//         mPoints = 0;
//     }

//     ~this()
//     {
//         // SDL_DestroyTexture(mTexture);
//         ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
//         texture.destroy();
//     }

//     override void Render(SDL_Renderer* renderer)
//     {
//         ComponentTexture texture = cast(ComponentTexture) this.GetComponent(ComponentType.TEXTURE);
//         texture.Render(renderer);

//         import std.conv;
//         ComponentText text = cast(ComponentText) this.GetComponent(ComponentType.TEXT);
//         if (text.mText != "SCORE: " ~ to!string(mPoints))
//             text.Update("SCORE: " ~ to!string(mPoints));
//         text.Render(renderer);
//     }

//     void SetImageFile(string filename, int width, int height)
//     {
//         mPoints = points;
//     }

//     void SetPosition(int x, int y){
//         return;
//     }
// }
