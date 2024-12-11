
/**
 * Module tilemap.d
 * 
 * This module provides functionality for creating and rendering a 2D tilemap using SDL2. 
 * It includes utilities for manipulating individual tiles, rendering the tilemap, and interacting 
 * with tilesets for visual representation.
 */
module tilemap;

// Load the SDL2 library
import bindbc.sdl;

import resource_manager;

/**
 * The `DrawableTileMap` struct manages a 2D tilemap, supporting rendering and tile manipulation.
 * 
 * Members:
 * - `mMapXSize` (int): Number of tiles in the X dimension of the map.
 * - `mMapYSize` (int): Number of tiles in the Y dimension of the map.
 * - `mTileSet` (TileSet): The tileset used for rendering tiles.
 * - `mTiles` (int[][]): 2D array representing the tile IDs in the map.
 * 
 * Constructor:
 * ---
 * this(TileSet t, int zoomFactor);
 * ---
 * Initializes the tilemap with a tileset and zoom factor.
 * 
 * Methods:
 * - `Render`: Renders the entire tilemap using the specified renderer.
 * - `GetTileAt`: Retrieves the tile ID at a given coordinate.
 * - `RenderTileAt`: Renders a specific tile at a given coordinate.
 * - `ChangeTileAt`: Changes the tile ID at a given coordinate.
 */
struct DrawableTileMap
{
    /// Number of tiles in the X dimension of the map
    int mMapXSize = 40;

    /// Number of tiles in the Y dimension of the map
    int mMapYSize = 30;

    /// The tileset used for rendering tiles
    TileSet mTileSet;

    /// 2D array representing the tile IDs in the map
    int[][] mTiles;

    /**
     * Constructor for initializing the tilemap.
     *
     * Params:
     *   t (TileSet) – The TileSet to use for rendering tiles.
     *   zoomFactor (int) – The factor by which the tilemap is scaled.
     */
    this(TileSet t, int zoomFactor)
    {
        // Set our tilemap
        mTileSet = t;
        mMapXSize = 40 / zoomFactor;
        mMapYSize = 30 / zoomFactor;

        // Initialize the 2D dynamic array
        mTiles.length = mMapXSize; // Set the number of rows
        foreach (ref row; mTiles)
        {
            row.length = mMapYSize; // Set the number of columns for each row
        }

        // Set all tiles to 'default' tile
        for (int y = 0; y < mMapYSize; y++)
        {
            for (int x = 0; x < mMapXSize; x++)
            {
                if (y == 0)
                {
                    mTiles[x][y] = 33;
                }
                else if (y == mMapYSize - 1)
                {
                    mTiles[x][y] = 107;
                }
                else if (x == 0)
                {
                    mTiles[x][y] = 69;
                }
                else if (x == mMapXSize - 1)
                {
                    mTiles[x][y] = 71;
                }
                else
                {
                    // Default tile
                    mTiles[x][y] = 966;
                }
            }
        }

        // Adjust the corners
        mTiles[0][0] = 32;
        mTiles[mMapXSize - 1][0] = 34;
        mTiles[0][mMapYSize - 1] = 106;
        mTiles[mMapXSize - 1][mMapYSize - 1] = 108;
    }

    /**
     * Renders the tilemap to the given SDL renderer.
     *
     * Params:
     *   renderer (SDL_Renderer*) – The SDL_Renderer to render to.
     *   zoomFactor (int) – The zoom factor for rendering (default: 1).
     */
    void Render(SDL_Renderer* renderer, int zoomFactor = 1)
    {
        for (int y = 0; y < mMapYSize; y++)
        {
            for (int x = 0; x < mMapXSize; x++)
            {
                mTileSet.RenderTile(renderer, mTiles[x][y], x, y, zoomFactor);
            }
        }
    }

    /**
     * Retrieves the tile ID at a given local coordinate.
     *
     * Params:
     *   localX (int) – The X coordinate relative to the map.
     *   localY (int) – The Y coordinate relative to the map.
     *   zoomFactor (int) – The zoom factor of the map (default: 1).
     * Returns:
     *   int – The tile ID, or -1 if out of bounds.
     */
    int GetTileAt(int localX, int localY, int zoomFactor = 1)
    {
        int x = localX / (mTileSet.mTileSize * zoomFactor);
        int y = localY / (mTileSet.mTileSize * zoomFactor);

        if (x < 0 || y < 0 || x > mMapXSize - 1 || y > mMapYSize - 1)
        {
            // TODO: Perhaps log error?
            // Maybe throw an exception -- think if this is possible!
            // You decide the proper mechanism!
            return -1;
        }

        return mTiles[x][y];
    }

    /**
     * Renders a tile at the specified local coordinate.
     *
     * Params:
     *   localX (int) – The X coordinate.
     *   localY (int) – The Y coordinate.
     *   zoomFactor (int) – The zoom factor (default: 1).
     */
    void RenderTileAt(int localX, int localY, int zoomFactor = 1)
    {
        int x = localX / (mTileSet.mTileSize * zoomFactor);
        int y = localY / (mTileSet.mTileSize * zoomFactor);

        if (x < 0 || y < 0 || x > mMapXSize - 1 || y > mMapYSize - 1)
        {
            // TODO: Perhaps log error?
            // Maybe throw an exception -- think if this is possible!
            // You decide the proper mechanism!
            // return -1;
        }

        mTileSet.RenderTileRect(mTiles[x][y], x, y, zoomFactor);

        // return mTiles[x][y]; 
    }
     /**
     * Changes the tile ID at a given local coordinate.
     *
     * Params:
     *   localX (int) – The X coordinate relative to the map.
     *   localY (int) – The Y coordinate relative to the map.
     *   zoomFactor (int) – The zoom factor of the map (default: 1).
     *   tile (int) – The new tile ID to set (default: 747).
     * Returns:
     *   int – The updated tile ID, or -1 if out of bounds.
     */
    int ChangeTileAt(int localX, int localY, int zoomFactor = 1, int tile = 747)
    {
        int x = localX / (mTileSet.mTileSize * zoomFactor);
        int y = localY / (mTileSet.mTileSize * zoomFactor);

        if (x < 0 || y < 0 || x > mMapXSize - 1 || y > mMapYSize - 1)
        {
            // TODO: Perhaps log error?
            // Maybe throw an exception -- think if this is possible!
            // You decide the proper mechanism!
            return -1;
        }

        mTiles[x][y] = tile;
        return mTiles[x][y];
    }

}

/**
 * The `TileSet` struct handles loading and rendering individual tiles from a texture atlas.
 * 
 * Members:
 * - `mTileSet` (SDL_Rect[]): Array of rectangles representing individual tiles in the texture.
 * - `mTexture` (SDL_Texture*): Texture loaded onto the GPU.
 * - `mTileSize` (int): Size of each tile (assumed square).
 * - `mXTiles` (int): Number of tiles in the X dimension of the tilemap.
 * - `mYTiles` (int): Number of tiles in the Y dimension of the tilemap.
 * - `mRenderer` (SDL_Renderer*): Renderer for debugging or operations.
 * 
 * Constructor:
 * ---
 * this(SDL_Renderer* renderer, string filepath, int tileSize, int xTiles, int yTiles);
 * ---
 * Initializes the tileset with the given renderer, file path, tile size, and dimensions.
 * 
 * Methods:
 * - `ViewTiles`: Previews the tileset by displaying tiles in sequence.
 * - `TileSetSelector`: Identifies which tile the mouse is over.
 * - `RenderTile`: Renders a specific tile from the tileset.
 * - `RenderTileRect`: Renders a tile with a rectangle outline.
 */
struct TileSet
{
    /// Array of rectangles representing individual tiles in the texture
    SDL_Rect[] mTileSet;

    /// Texture loaded onto the GPU
    SDL_Texture* mTexture;

    /// Size of each tile (assumed square)
    int mTileSize;

    /// Number of tiles in the X dimension of the tilemap
    int mXTiles;

    /// Number of tiles in the Y dimension of the tilemap
    int mYTiles;

    /// Renderer for debugging or operations
    SDL_Renderer* mRenderer;

    /**
     * Constructor for the TileSet struct.
     *
     * Params:
     *   renderer (SDL_Renderer*) – The SDL_Renderer for rendering operations.
     *   filepath (string) – Path to the bitmap file containing the tilemap.
     *   tileSize (int) – The size of each tile in pixels.
     *   xTiles (int) – Number of tiles in the X dimension.
     *   yTiles (int) – Number of tiles in the Y dimension.
     */
    this(SDL_Renderer* renderer, string filepath, int tileSize, int xTiles, int yTiles)
    {
        mTileSize = tileSize;
        mXTiles = xTiles;
        mYTiles = yTiles;

        // Load the bitmap surface
        SDL_Surface* myTestImage = SDL_LoadBMP(filepath.ptr);
        // Create a texture from the surface
        mTexture = SDL_CreateTextureFromSurface(renderer, myTestImage);
        // Done with the bitmap surface pixels after we create the texture, we have
        // effectively updated memory to GPU texture.
        SDL_FreeSurface(myTestImage);
        mRenderer = renderer;

        // Populate a series of rectangles with individual tiles
        for (int y = 0; y < yTiles; y++)
        {
            for (int x = 0; x < xTiles; x++)
            {
                SDL_Rect rect;
                rect.x = x * tileSize;
                rect.y = y * tileSize;
                rect.w = tileSize;
                rect.h = tileSize;

                mTileSet ~= rect;
            }
        }
    }

    /**
     * Previews the tileset by displaying tiles in sequence.
     *
     * Params:
     *   renderer (SDL_Renderer*) – The SDL_Renderer to render to.
     *   x (int) – X coordinate for rendering.
     *   y (int) – Y coordinate for rendering.
     *   zoomFactor (int) – The zoom factor (default: 1).
     */
    void ViewTiles(SDL_Renderer* renderer, int x, int y, int zoomFactor = 1)
    {
        import std.stdio;

        static int tilenum = 0;

        if (tilenum > mTileSet.length - 1)
        {
            tilenum = 0;
        }

        // Just a little helper for you to debug
        // You can omit this as necessary
        writeln("Showing tile number: ", tilenum);

        // Select a specific tile from our
        // tiemap texture, by offsetting correcting
        // into the tilemap
        SDL_Rect selection;
        selection = mTileSet[tilenum];

        // Draw a preview of the actual tile
        SDL_Rect rect;
        rect.x = x;
        rect.y = y;
        rect.w = mTileSize * zoomFactor;
        rect.h = mTileSize * zoomFactor;

        SDL_RenderCopy(renderer, mTexture, &selection, &rect);
        tilenum++;
    }

    /**
     * Identifies which tile the mouse is over.
     *
     * Params:
     *   renderer (SDL_Renderer*) – The SDL_Renderer to render to.
     */
    void TileSetSelector(SDL_Renderer* renderer)
    {
        import std.stdio;

        int mouseX, mouseY;
        int mask = SDL_GetMouseState(&mouseX, &mouseY);

        int xTileSelected = mouseX / mTileSize;
        int yTileSelected = mouseY / mTileSize;
        int tilenum = yTileSelected * mXTiles + xTileSelected;
        if (tilenum > mTileSet.length - 1)
        {
            return;
        }

        writeln("mouse  : ", mouseX, ",", mouseY);
        writeln("tile   : ", xTileSelected, ",", yTileSelected);
        writeln("tilenum: ", tilenum);

        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 255);

        // Tile to draw out on
        SDL_Rect rect = mTileSet[tilenum];

        // Copy tile to our renderer
        // Note: We need a rectangle that's the exact dimensions of the
        //       image in order for it to render appropriately.
        SDL_Rect tilemap;
        tilemap.x = 0;
        tilemap.y = 0;
        tilemap.w = mXTiles * mTileSize;
        tilemap.h = mYTiles * mTileSize;
        SDL_RenderCopy(renderer, mTexture, null, &tilemap);
        // Draw a rectangle
        SDL_RenderDrawRect(renderer, &rect);

    }

    /**
     * Renders a specific tile from the tileset.
     *
     * Params:
     *   renderer (SDL_Renderer*) – The SDL_Renderer to render to.
     *   tile (int) – The tile index to render.
     *   x (int) – X coordinate for rendering.
     *   y (int) – Y coordinate for rendering.
     *   zoomFactor (int) – The zoom factor (default: 1).
     */
    void RenderTile(SDL_Renderer* renderer, int tile, int x, int y, int zoomFactor = 1)
    {
        if (tile > mTileSet.length - 1)
        {
            // NOTE: Could use 'logger' here to log an error
            return;
        }

        // Select a specific tile from our
        // tiemap texture, by offsetting correcting
        // into the tilemap
        SDL_Rect selection = mTileSet[tile];

        // Tile to draw out on
        SDL_Rect rect;
        rect.x = mTileSize * x * zoomFactor;
        rect.y = mTileSize * y * zoomFactor;
        rect.w = mTileSize * zoomFactor;
        rect.h = mTileSize * zoomFactor;

        // Copy tile to our renderer
        SDL_RenderCopy(renderer, mTexture, &selection, &rect);
    }

    /**
     * Renders a specific tile with a rectangle outline.
     *
     * Params:
     *   tile (int) – The tile index to render.
     *   x (int) – X coordinate for rendering.
     *   y (int) – Y coordinate for rendering.
     *   zoomFactor (int) – The zoom factor (default: 1).
     */
    void RenderTileRect(int tile, int x, int y, int zoomFactor = 1)
    {
        if (tile > mTileSet.length - 1)
        {
            // NOTE: Could use 'logger' here to log an error
            return;
        }

        // Select a specific tile from our
        // tiemap texture, by offsetting correcting
        // into the tilemap
        SDL_Rect selection = mTileSet[tile];

        // Tile to draw out on
        SDL_Rect rect;
        rect.x = mTileSize * x * zoomFactor;
        rect.y = mTileSize * y * zoomFactor;
        rect.w = mTileSize * zoomFactor;
        rect.h = mTileSize * zoomFactor;

        // Copy tile to our renderer
        // Set the square color (e.g., red)
        SDL_SetRenderDrawColor(mRenderer, 255, 0, 0, 255);

        // Draw the outline of the square
        SDL_RenderDrawRect(mRenderer, &rect);
    }
}
