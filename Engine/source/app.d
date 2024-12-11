/// Entry point for the application.
/// 
/// This program initializes the GUI in a separate thread and runs the main 
/// game application loop. The GUI and game application run concurrently, 
/// allowing for a graphical user interface alongside the game's main logic.
/// 
/// Run the program with: `dub`
module main;

import gameapplication;
import gui;
import std.concurrency: spawn;

/**
 * Entry point to the program.
 * 
 * Params:
 *     args = Command-line arguments passed to the application.
 */
void main(string[] args)
{
    /// Duplicate the command-line arguments to create an immutable copy.
    immutable string[] args2 = args.dup;

    /// Spawn a separate thread to run the GUI.
    spawn(&RunGUI, args2);

    /// Initialize and run the main game application.
    GameApplication app = GameApplication("D SDL Application");
    app.RunLoop();
}
