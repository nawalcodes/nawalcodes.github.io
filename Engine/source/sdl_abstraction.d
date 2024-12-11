/**
 * Module sdl_abstraction
 *
 * Provides initialization and cleanup for SDL libraries, including SDL, SDL_image, and SDL_ttf.
 * Ensures the proper setup of required libraries before execution and cleans up resources on termination.
 * Handles platform-specific loading of SDL libraries and reports errors if initialization fails.
 */
module sdl_abstraction;

import std.stdio;
import std.string;

import bindbc.sdl;
import bindbc.sdl.image;
import bindbc.sdl.ttf;
import loader = bindbc.loader.sharedlib;

/**
 * Global variable for SDL support status.
 * Indicates the result of attempting to load the SDL library.
 */
const SDLSupport ret;

/**
 * Static constructor
 *
 * Initializes SDL, SDL_image, and SDL_ttf libraries. Ensures that the required 
 * libraries are successfully loaded and initialized. Handles platform-specific 
 * library loading and error reporting.
 * 
 * Platforms:
 *  - Windows: Loads `SDL2.dll`.
 *  - Mac (OSX): Loads SDL library using default paths.
 *  - Linux: Loads SDL library using default paths.
 * 
 * Error Handling:
 *  - Logs messages to the console if a library fails to load or initialize.
 */
shared static this()
{
    // Load the SDL libraries from bindbc-sdl on appropriate OS
    version (Windows)
    {
        writeln("Searching for SDL on Windows");
        ret = loadSDL("SDL2.dll");
    }
    version (OSX)
    {
        writeln("Searching for SDL on Mac");
        ret = loadSDL();
    }
    version (linux)
    {
        writeln("Searching for SDL on Linux");
        ret = loadSDL();
    }

    // Error if SDL cannot be loaded
    if (ret != sdlSupport)
    {
        writeln("error loading SDL library");
        foreach (info; loader.errors)
        {
            writeln(info.error, ':', info.message);
        }
    }
    if (ret == SDLSupport.noLibrary)
    {
        writeln("error no library found");
    }
    if (ret == SDLSupport.badLibrary)
    {
        writeln(
            "Error badLibrary, missing symbols, perhaps an older or very new version of SDL is causing the problem?");
    }

    // Initialize SDL
    if (SDL_Init(SDL_INIT_EVERYTHING) != 0)
    {
        writeln("SDL_Init: ", fromStringz(SDL_GetError()));
    }

    // Load SDL_image
    if (loadSDLImage() != sdlImageSupport)
    {
        // Handle error
        writeln("error loading SDL_Image library");
    }

    // Initialize PNG and JPEG loading
    int imgFlags = IMG_INIT_PNG | IMG_INIT_JPG;
    if (!(IMG_Init(imgFlags) & imgFlags))
    {
        printf("SDL_image could not initialize! SDL_image Error: %s\n", IMG_GetError());
    }

    // Load SDL_ttf
    if (loadSDLTTF() != sdlTTFSupport)
    {
        // Handle error
        writeln("error loading SDL_TTF library");
    }

    // Initialize SDL_ttf
    if (TTF_Init() == -1)
    {
        printf("SDL_ttf could not initialize! SDL_ttf Error: %s\n", TTF_GetError());
    }
}

/**
 * Static destructor
 *
 * Cleans up SDL resources at program termination. Ensures that SDL is 
 * properly terminated to avoid resource leaks.
 */
shared static ~this()
{
    // Quit SDL Application
    SDL_Quit();
    writeln("Ending application--good bye!");
}
