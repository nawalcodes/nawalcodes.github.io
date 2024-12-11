/// This module defines the `SceneTree` and `Scene` structures, along with utilities for
/// scene management and tree-based data organization. It also includes game-specific functionality.
module scene;

import std.stdio;
import std.range;
import std.string;
import std.conv;

// Third-party libraries
import bindbc.sdl;

// Import our SDL Abstraction
import sdl_abstraction;
import gameobject;
import factory;
import component;
import tilemap;

/**
 * Represents a generic node in a tree structure with templated data.
 * Each node can have multiple children, and its data type is defined by the user.
 * 
 * Params:
 *     T = The data type stored in the node.
 */
struct TreeNode(T)
{
    /// Array of child nodes.
    TreeNode!T[] mChildren;

    /// The depth level of this node within the tree.
    int mLevel;

    /// The ID of this node's parent.
    int mParentID;

    /// The unique ID of this node.
    int mNodeID;

    /// The data stored in this node.
    T mData;

    /**
     * Constructs a new TreeNode with the specified data.
     * 
     * Params:
     *     data = The data to be stored in the node.
     */
    this(T data)
    {
        static uniqueID = 9000;
        mData = data;
        mNodeID = ++uniqueID;
    }

    /// Returns the data stored in this node.
    T GetData()
    {
        return mData;
    }

    /**
     * Adds a child node with the specified data.
     * 
     * Params:
     *     data = The data for the new child node.
     * 
     * Returns:
     *     The unique ID of the newly added child node.
     */
    int AddChild(T data)
    {
        TreeNode!T t = TreeNode!T(data);
        t.mParentID = this.mNodeID;
        t.mLevel = this.mLevel + 1;
        mChildren ~= t;
        return t.mNodeID;
    }

    /**
     * Removes a child node by its ID.
     * 
     * Params:
     *     id = The unique ID of the child node to remove.
     * 
     * Returns:
     *     A pointer to the removed child node, or null if no matching node is found.
     */
    TreeNode!T* RemoveChildByID(int id)
    {
        foreach (i, ref child; mChildren)
        {
            if (child.mNodeID == id)
            {
                mChildren = mChildren[0 .. i] ~ mChildren[i + 1 .. $];
                return &child;
            }
        }
        return null;
    }

    /// Visualizes the tree structure starting from this node with indentation.
    void Visualize()
    {
        string indent;
        for (int i = 0; i < mLevel; i++)
        {
            indent ~= " ";
        }
        writeln(indent, mData, ": ", mNodeID);
    }
}

/**
 * Represents a tree structure with a single root node and traversal utilities.
 * 
 * Params:
 *     T = The data type stored in each node of the tree.
 */
struct SceneTree(T)
{
    /// Root node of the scene tree.
    TreeNode!T* mRoot;

    /// Traverses and visualizes the entire tree starting from the root.
    void Traverse()
    {
        TreeNode!T[] q;
        q ~= [*mRoot];
        for (TreeNode!T node; q.length > 0;)
        {
            node = q[0];
            node.Visualize();
            q = q[1 .. $];
            q = node.mChildren ~ q;
        }
    }

    /**
     * Sets the root of the tree.
     * 
     * Params:
     *     node = A pointer to the root node.
     */
    void SetRoot(TreeNode!T* node)
    {
        mRoot = node;
    }

    /// Returns all children of the root node.
    TreeNode!T[] GetChildren()
    {
        if (mRoot is null)
        {
            return [];
        }
        return mRoot.mChildren;
    }

    /**
     * Finds a node by its ID using breadth-first search.
     * 
     * Params:
     *     id = The unique ID of the node to find.
     * 
     * Returns:
     *     A pointer to the matching node, or null if not found.
     */
    TreeNode!T* FindNodeByID(int id)
    {
        if (mRoot is null)
            return null;

        TreeNode!T*[] queue = [mRoot];
        while (!queue.empty)
        {
            auto node = queue.front;
            queue = queue[1 .. $];

            if (node.mNodeID == id)
            {
                return node;
            }

            foreach (ref child; node.mChildren)
            {
                queue ~= &child;
            }
        }
        return null;
    }
}

/**
 * Represents a game scene, including its tilemap and objects.
 * 
 * Params:
 *     T = The type of game object used in the scene.
 */
struct Scene(T)
{
    /// The scene tree holding game objects.
    SceneTree!T mScene;

    /// The tileset used for the scene.
    TileSet mTS;

    /// The drawable tilemap for the scene.
    DrawableTileMap mDT;

    /// The zoom factor for the tilemap.
    int mZoomFactor = 1;

    /**
     * Loads the scene with predefined game objects.
     * 
     * Params:
     *     dict = A dictionary to store object IDs.
     *     scene = The scene identifier.
     *     renderer = The SDL renderer to use for drawing.
     * 
     * Returns:
     *     The populated scene tree.
     */
    SceneTree!GameObject LoadScene(ref int[string] dict, int scene, SDL_Renderer* renderer)
    {
        mTS = TileSet(renderer, "./assets/images/kenney_roguelike-modern-city/Tilemap/tilemap_packed.bmp", 16, 37, 28);
        mDT = DrawableTileMap(mTS, mZoomFactor);

        auto go = GameObjectFactory("root");
        auto root = new TreeNode!GameObject(go);
        mScene.SetRoot(root);

        Score score = cast(Score) MakeText("Score");
        ComponentText text = cast(ComponentText) score.GetComponent(ComponentType.TEXT);
        text.Load(cast(char[])("SCORE: " ~ to!string(score.GetScore())), 15, 10, 24);
        dict["Score"] = root.AddChild(score);

        Player player = cast(Player) MakePlayer("Player");
        player.SetPosition(50, 50);
        dict["Player"] = root.AddChild(player);

        Enemy enemy = cast(Enemy) MakeEnemy("Enemy");
        enemy.SetPosition(200, 200);
        dict["Enemy"] = root.AddChild(enemy);

        return mScene;
    }

    /// Returns the tileset for the scene.
    TileSet GetTileSet()
    {
        return mTS;
    }

    /// Returns the drawable tilemap for the scene.
    DrawableTileMap GetDrawableTileMap()
    {
        return mDT;
    }

    /// Returns the zoom factor for the tilemap.
    int GetZoom()
    {
        return mZoomFactor;
    }

    /**
     * Changes the tile at the specified coordinates.
     * 
     * Params:
     *     x = The x-coordinate of the tile.
     *     y = The y-coordinate of the tile.
     */
    void ChangeTileAt(int x, int y)
    {
        mDT.ChangeTileAt(x, y, mZoomFactor);
    }

    /**
     * Loads a pause menu scene.
     * 
     * Params:
     *     windowWidth = The width of the game window.
     *     windowHeight = The height of the game window.
     *     renderer = The SDL renderer to use for drawing.
     * 
     * Returns:
     *     The populated scene tree.
     */
    SceneTree!GameObject LoadPauseMenu(int windowWidth, int windowHeight, SDL_Renderer* renderer)
    {

        auto go = GameObjectFactory("root");
        auto root = new TreeNode!GameObject(go);
        mScene.SetRoot(root);

        // Create Text
        GameObject title = MakeText("title");
        ComponentText text = cast(ComponentText) title.GetComponent(ComponentType.TEXT);
        text.Load(cast(char[])("Pause Menu"), 0, 0, 72);
        text.CenterText(windowWidth, windowHeight);
        root.AddChild(title);

        return mScene;
    }
}

/// Unit test for verifying the functionality of the `SceneTree` and `TreeNode` implementations.
///
/// This test performs the following operations:
/// 1. **Instantiates** a `SceneTree` with the data type `int`.
/// 2. **Creates** a root node (`TreeNode` with the value 9000) and assigns it to the `SceneTree`.
/// 3. **Adds children** (1, 2, and 3) to the root node.
/// 4. **Retrieves a specific child** (the middle child, with value 2) and adds more children (4, 5, 6, and 7) to it.
/// 5. **Traverses the tree** to validate its structure and ensure all nodes are processed correctly.
///
/// Expected structure of the tree after all operations:
/// - Root: 9000
///   - Child 1: 1
///   - Child 2: 2
///     - Grandchild 1: 4
///     - Grandchild 2: 5
///     - Grandchild 3: 6
///     - Grandchild 4: 7
///   - Child 3: 3
///
/// Validation:
/// - The `Traverse` method is expected to process all nodes in the correct hierarchical order.
/// - The test ensures that the `SceneTree` and `TreeNode` functionalities, such as adding children and traversal, work as intended.
unittest
{
    SceneTree!int s; // Instantiate SceneTree with int data type
    auto n = new TreeNode!int(9000); // Instantiate TreeNode with int data
    s.SetRoot(n);

    n.AddChild(1);
    n.AddChild(2);
    n.AddChild(3);

    // Retrieve a child from our root and add more children
    TreeNode!int* middleChild = &n.mChildren[1];
    middleChild.AddChild(4);
    middleChild.AddChild(5);
    middleChild.AddChild(6);
    middleChild.AddChild(7);

    s.Traverse();

}
