module resource_manager;

import bindbc.sdl;
import std.string;

/**
 * Module: Resource Manager
 * 
 * This module defines and manages resources required for a game, such as images, surfaces, and textures.
 * It includes the implementation of structs for handling these resources and a ResourceManager struct 
 * to perform common actions like adding, loading, and unloading resources efficiently. 
 * 
 * The ResourceManager uses reference counting to ensure proper memory management of resources. 
 */

/// Struct representing an image resource
/// Contains the filename and pixel data of the image
struct Image
{
    /// Name of the image file
    string filename;
    
    /// Pixel data of the image
    ubyte[] pixels;
}

/// Struct representing a smart pointer
/// Manages a generic pointer with reference counting for memory management
struct SmartPointer
{
    /// Pointer to the data (initialized to null)
    void* ptr = null;
    
    /// Reference count for the pointer
    int refcount = 0;
}

/// Struct representing an SDL surface resource
/// Manages a pointer to an SDL_Surface and a reference count
struct Surface
{
    /// Pointer to the SDL surface (initialized to null)
    SDL_Surface* surface = null;
    
    /// Reference count for the surface
    int refcount = 0;
}

/// Struct representing an SDL texture resource
/// Manages a pointer to an SDL_Texture and a reference count
struct Texture
{
    /// Pointer to the SDL texture (initialized to null)
    SDL_Texture* texture = null;
    
    /// Reference count for the texture
    int refcount = 0;
}

/**
 * ResourceManager
 * 
 * This struct is a singleton that handles adding, loading, and unloading resources.
 * It ensures efficient management of resources through reference counting and provides 
 * a centralized interface for accessing game resources like images, surfaces, and textures.
 */
struct ResourceManager
{
    /**
     * Retrieves the singleton instance of the ResourceManager.
     * If the instance does not exist, it creates a new one.
     * 
     * @return A pointer to the singleton ResourceManager instance.
     */
    static ResourceManager* GetInstance()
    {
        if (mInstance is null)
        {
            mInstance = new ResourceManager();
        }
        return mInstance;
    }

    /**
     * Loads an image resource from the resource map.
     * 
     * @param filename The name of the image file.
     * @return A pointer to the Image resource, or null if not found.
     */
    static Image* LoadImageResource(string filename)
    {
        if (filename in mImageResourceMap)
        {
            return mImageResourceMap[filename];
        }
        else
        {
            return null; // null if image not found
        }
    }

    /**
     * Loads an SDL surface resource from the resource map.
     * 
     * @param filename The name of the surface resource.
     * @return A pointer to the SDL_Surface resource, or null if not found.
     */
    static SDL_Surface* LoadSurfaceResource(string filename)
    {
        if (filename !in mSurfaces)
        {
            return null; // Return null if surface not found
        }
        // Increment reference count 
        mSurfaces[filename].refcount++;
        return mSurfaces[filename].surface;
    }

    /**
     * Adds a new SDL surface resource to the resource map.
     * 
     * @param name The name of the surface resource.
     * @param surface A pointer to the SDL_Surface to add.
     */
    void AddSurfaceResource(string name, SDL_Surface* surface)
    {
        if (name !in mSurfaces)
        {
            mSurfaces[name] = new Surface;
            mSurfaces[name].surface = surface;
        }
    }

    /**
     * Unloads an SDL surface resource, freeing memory if no references remain.
     * 
     * @param filename The name of the surface resource to unload.
     */
    void UnloadSurfaceResource(string filename)
    {
        if (filename in mSurfaces)
        {
            // Decrement reference count
            mSurfaces[filename].refcount--;
            // If there are no references, destroy the surface from memory
            if (mSurfaces[filename].refcount < 1)
            {
                SDL_FreeSurface(mSurfaces[filename].surface);
                mSurfaces[filename].destroy();
                mSurfaces.remove(filename);
            }
        }
    }

    /**
     * Loads an SDL texture resource from the resource map.
     * 
     * @param renderer A pointer to the SDL_Renderer.
     * @param filename The name of the texture resource.
     * @return A pointer to the SDL_Texture resource, or null if not found.
     */
    static SDL_Texture* LoadTextureResource(SDL_Renderer* renderer, string filename)
    {
        if (filename !in mTextures)
        {
            return null; // Return null if texture not found
        }
        // Increment reference count
        mTextures[filename].refcount++;
        return mTextures[filename].texture;
    }

    /**
     * Adds a new SDL texture resource to the resource map.
     * 
     * @param name The name of the texture resource.
     * @param texture A pointer to the SDL_Texture to add.
     */
    void AddTextureResource(string name, SDL_Texture* texture)
    {
        if (name !in mTextures)
        {
            mTextures[name] = new Texture;
            mTextures[name].texture = texture;
        }
    }

    /**
     * Unloads an SDL texture resource, freeing memory if no references remain.
     * 
     * @param filename The name of the texture resource to unload.
     */
    void UnloadTextureResource(string filename)
    {
        if (filename in mTextures)
        {
            // Decrement reference count
            mTextures[filename].refcount--;
            if (mTextures[filename].refcount < 1)
            {
                // If there are no references, destroy the texture from memory
                SDL_DestroyTexture(mTextures[filename].texture);
                mTextures[filename].destroy();
                mTextures.remove(filename);
            }
        }
    }

private:
    /// Singleton instance of the ResourceManager
    static ResourceManager* mInstance;
    
    /// Map of image resources
    static Image*[string] mImageResourceMap;
    
    /// Map of surface resources
    static Surface*[string] mSurfaces;
    
    /// Map of texture resources
    static Texture*[string] mTextures;
}

/**
 * Example usage of ResourceManager:
 * 
 * void main()
 * {
 *     ResourceManager.GetInstance().LoadImageResource("myImage.bmp");
 * }
 */
