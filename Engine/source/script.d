/**
 * Module script.d
 * This module defines scriptable components that can be attached to game objects 
 * to provide dynamic behavior. Specifically, it includes scripts for handling 
 * player and enemy laser components. These scripts manage movement, collision 
 * detection, and cleanup of lasers that go off-screen.
 */
module script;

import std.stdio;
import component;

/**
 * Enum defining the types of scriptable components available in the game.
 */
enum ScriptComponentType
{
    LASER // Represents a laser component.
}

/**
 * Class representing the behavior of enemy laser components.
 * Inherits from `ComponentLaser`.
 */
class EnemyScriptLaser : ComponentLaser
{
    /**
     * Constructor: Initializes the enemy laser script.
     * 
     * Params:
     *  owner = The unique identifier of the owning game object.
     */
    this(size_t owner)
    {
        super(owner);
    }

    /**
     * Updates the state of the enemy laser.
     * Moves the laser upwards, updates its collider position, 
     * and marks it for deletion if it goes off-screen.
     */
    override void Update()
    {
        y += 1 * mVelocity; // Move the laser upwards.
        mCollider.SetPosition(x + mWidth / 2, y + mHeight / 2); // Update collider position.

        // Mark for deletion if off-screen.
        if ((y - mHeight > 640) || (y + mHeight < 0))
        {
            mShouldDelete = true;
        }
    }
}

/**
 * Class representing the behavior of player laser components.
 * Inherits from `ComponentLaser`.
 */
class PlayerScriptLaser : ComponentLaser
{
    /// Cartesian direction flags for laser movement.
    int mXdir = 0; ///< Horizontal direction (-1 for left, 1 for right).
    int mYdir = 0; ///< Vertical direction (-1 for up, 1 for down).

    /**
     * Constructor: Initializes the player laser script.
     * 
     * Params:
     *  owner = The unique identifier of the owning game object.
     */
    this(size_t owner)
    {
        super(owner);
    }

    /**
     * Sets the movement direction of the laser.
     * 
     * Params:
     *  dir = A string representing the direction ("left", "right", "up", or "down").
     */
    void SetDirection(string dir)
    {
        if (dir == "left")
        {
            mXdir = -1;
            auto tmp = mWidth;
            mWidth = mHeight;
            mHeight = tmp; // Adjust dimensions for horizontal movement.
        }
        else if (dir == "right")
        {
            mXdir = 1;
            auto tmp = mWidth;
            mWidth = mHeight;
            mHeight = tmp; // Adjust dimensions for horizontal movement.
        }
        else if (dir == "up")
        {
            mYdir = -1;
        }
        else if (dir == "down")
        {
            mYdir = 1;
        }
    }

    /**
     * Updates the state of the player laser.
     * Moves the laser based on direction flags, updates its collider position, 
     * and marks it for deletion if it goes off-screen.
     */
    override void Update()
    {
        y += mYdir * mVelocity; // Move vertically.
        x += mXdir * mVelocity; // Move horizontally.
        mCollider.SetPosition(x + mWidth / 2, y + mHeight / 2); // Update collider position.

        // Mark for deletion if off-screen.
        if ((y - mHeight > 640) || (y + mHeight < 0))
        {
            mShouldDelete = true;
        }
        if ((x - mWidth > 640) || (x + mWidth < 0))
        {
            mShouldDelete = true;
        }
    }
}

/**
 * Example of a generic scriptable component.
 * 
 * This component can be used to add custom behavior to game objects.
 * Uncomment and modify for testing or additional functionality.
 */
// class ScriptComponent : IComponent {
//     /**
//      * Updates the state of the script component.
//      */
//     void Update() {
//         writefln("ScriptComponent is updating");    
//     }
// }

/**
 * Example structure representing a game object.
 * 
 * Demonstrates how to integrate components and scripts.
 * Uncomment and modify as needed.
 */
// struct GameObject {
//     /**
//      * Updates the game object by updating its components and scripts.
//      */
//     void Update() {
//         foreach(c ; mComponents) {
//             c.Update(); ///< Update each component.
//         }
//         foreach(s ; mScripts) {
//             s.Update(); ///< Update each script.
//         }
//     }
//     
//     IComponent[ComponentTypes] mComponents; ///< Component types associated with the object.
//     ScriptComponent[] mScripts; ///< Array of scriptable components.
// }

/**
 * Example main function demonstrating script usage within a game loop.
 * Uncomment and modify to test functionality.
 */
// void main() {
//     GameObject player;
//     player.mScripts ~= new PlayerScript();    
// 
//     GameObject alien;
//     alien.mScripts ~= new AlienScript();    
// 
//     while(true) {
//         Thread.sleep(500.msecs);
//         player.Update();
//         alien.Update();
//     }
// }
