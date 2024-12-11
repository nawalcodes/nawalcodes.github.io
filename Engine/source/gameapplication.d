/**
 * Module gameapplication.d
 * This module defines the `GameApplication` struct, which represents the main game application. 
 * It handles the game loop, input processing, rendering, and scene management. 
 * Additionally, it integrates an in-game menu and provides functionalities such as 
 * pausing, resuming, and switching between scenes.
 */
module gameapplication;
// Import D standard libraries
import std.stdio;
import std.string;
import std.conv;
import std.math;
import std.string : strip;
import std.regex : matchFirst;

// Third-party libraries
import bindbc.sdl;

// Import our SDL Abstraction
import sdl_abstraction;
import gameobject;
import factory;
import component;
import script;
import scene;
import sound;
import tilemap;
import menu;
import vec2;

/**
 * Represents the main application for running the game.
 * Manages initialization, input handling, game updates, rendering, and menu interactions.
 */
struct GameApplication
{
	/// The main SDL window for the game. 
	SDL_Window* mWindow = null;

	/// The SDL renderer for drawing game scenes.
	SDL_Renderer* mRenderer = null;

	/// Flag to control the main game loop.
	bool mGameIsRunning = true;

	/// Sound manager for handling music and sound effects.
	Sound mySound;

	/// Index of the current active scene.
	int scene = 0;

	/// Index of the previously active scene. 
	int prev_scene = 0;

	/// Total number of game levels.
	const int mLevels = 3;

	/// Dynamic array of game scenes.
	Scene!GameObject*[] myScenes;

	/// Array to store saved game scenes. 
	Scene!GameObject[mLevels] SavedScenes;

	/// Menu object for handling user interactions like pausing or starting the game.
	Menu mMenu;

	/// Dictionary for managing game data (e.g., IDs for game objects). 
	int[string] dict;

	/// Hierarchical tree structure to organize game objects.
	SceneTree!GameObject mGameObjects;

	/// The tileset used in the current scene.
	TileSet mTS;

	/// The drawable tile map for rendering tile-based levels.
	DrawableTileMap mDT;

	/**
	* Constructor: Initializes the game application.
	* 
	* Params:
	*  title = The title of the game window.
	* 
	* Initializes SDL, creates the game window and renderer, sets up the menu, 
	* and loads initial scenes.
	*/
	this(string title)
	{
		// Create SDL window and renderer
		mWindow = SDL_CreateWindow(title.toStringz, SDL_WINDOWPOS_UNDEFINED, SDL_WINDOWPOS_UNDEFINED, 640, 480, SDL_WINDOW_SHOWN);
		mRenderer = SDL_CreateRenderer(mWindow, -1, SDL_RENDERER_ACCELERATED);

		// Initialize menu
		mMenu = new Menu(
			mRenderer,
			&startGameImplementation,
			&toggleMusicImplementation,
			&pauseGameImplementation,
			&resumeGameImplementation
		);

		// Load scenes
		myScenes ~= new Scene!GameObject();
		int windowWidth, windowHeight;
		SDL_GetWindowSize(mWindow, &windowWidth, &windowHeight);
		mGameObjects = myScenes[scene].LoadPauseMenu(windowWidth, windowHeight, mRenderer);
		scene++;

		myScenes ~= new Scene!GameObject();
		mGameObjects = myScenes[scene].LoadScene(dict, scene, mRenderer);

		mTS = myScenes[scene].GetTileSet();
		mDT = myScenes[scene].GetDrawableTileMap();
	}

	/**
     	* Destructor: Cleans up resources used by the application.
     	* Frees the SDL renderer and window to prevent memory leaks.
     	*/
	~this()
	{
		SDL_DestroyRenderer(mRenderer);
		SDL_DestroyWindow(mWindow);
	}

	/**
     	* Handles user input events.
     	* Processes SDL events for quitting, interacting with the menu, 
     	* and controlling game objects (keyboard and mouse inputs).
     	*/
	void Input()
	{
		SDL_Event event;
		while (SDL_PollEvent(&event))
		{
			if (event.type == SDL_QUIT)
			{
				mGameIsRunning = false;
			}

			// Pass input to the menu if active
			mMenu.HandleInput(event);
			if (mMenu.isMenuActive)
				return;

			// Game input handling
			if (event.type == SDL_KEYDOWN)
			{
				switch (event.key.keysym.sym)
				{
				case SDLK_p:
					// Pause menu toggle
					if (scene == 0)
					{
						scene = prev_scene;
						mMenu.isMenuActive = false;
					}
					else
					{
						prev_scene = scene;
						scene = 0;
						mMenu.isMenuActive = true;
					}
					mGameObjects = myScenes[scene].mScene;
					mTS = myScenes[scene].GetTileSet();
					mDT = myScenes[scene].GetDrawableTileMap();
					break;
				default:
					break;
				}
			}

			// Detect mouse button clicks and print the location
			if (event.type == SDL_MOUSEBUTTONDOWN)
			{
				// writeln("Mouse clicked at (", event.button.x, ", ", event.button.y, ")");
				// writeln(mDT.GetTileAt(event.button.x,event.button.y,mZoomFactor));
				// writeln(mDT.ChangeTileAt(event.button.x,event.button.y,mZoomFactor));
				// myScenes[scene].ChangeTileAt(event.button.x,event.button.y);
				Coin coin = cast(Coin) MakeCoin("Coin");
				coin.SetPosition(event.button.x, event.button.y);
				mGameObjects.mRoot.AddChild(coin);
			}

			auto children = mGameObjects.GetChildren();
			foreach (child; children)
				child.GetData().Input(event);
		}
	}

	/**
     	* Updates the game state.
     	* Applies logic to game objects, handles collisions, and processes interactions
     	* between the player and other objects in the scene.
     	*/
	void Update()
	{
		if (mMenu.isMenuActive)
			return; // Skip update when the menu is active

		auto children = mGameObjects.GetChildren();
		foreach (child; children)
			child.GetData().Update(mDT, myScenes[scene].GetZoom());

		Player p1 = cast(Player) mGameObjects.FindNodeByID(dict["Player"]).GetData();
		foreach (child; children)
		{
			if (child.GetData().GetName() == "Enemy")
			{
				if (p1.IsColliding(child.GetData()))
				{
					if (p1.isStomp(child.GetData()))
					{
						mGameObjects.mRoot.RemoveChildByID(child.mNodeID);
						auto total = cast(Score) mGameObjects.FindNodeByID(dict["Score"]).GetData();
						total.IncrementScore(100);
					}
					else
						mGameIsRunning = false;
				}
			}

			if (child.GetData().GetName() == "Coin")
			{
				if (p1.IsColliding(child.GetData()))
				{
					mGameObjects.mRoot.RemoveChildByID(child.mNodeID);
					auto total = cast(Score) mGameObjects.FindNodeByID(dict["Score"]).GetData();
					total.IncrementScore(10);
				}
			}
		}

	}

	/**
     	* Renders the current game state.
     	* Draws the current scene, game objects, and the menu (if active) on the screen.
     	*/
	void Render()
	{
		SDL_SetRenderDrawColor(mRenderer, 100, 190, 255, SDL_ALPHA_OPAQUE);
		SDL_RenderClear(mRenderer);

		if (mMenu.isMenuActive)
		{
			mMenu.Render();
		}
		else
		{
			mDT.Render(mRenderer, myScenes[scene].GetZoom());
			auto children = mGameObjects.GetChildren();
			foreach (child; children)
				child.GetData().Render(mRenderer);
		}

		SDL_RenderPresent(mRenderer);
	}

	/**
    	* Executes the main game loop.
     	* Continuously processes input, updates the game state, and renders the scene.
     	*/
	void RunLoop()
	{
		while (mGameIsRunning)
		{
			Input();
			Update();
			Render();
			SDL_Delay(17); // Cap to ~60 FPS
		}
	}

	/**
     	* Callback for starting the game from the menu.
     	* 
    	* Params:
     	*  level = The level to start, as a string (e.g., "Level 1").
     	*/
	void startGameImplementation(string level)
	{
		writeln("Starting ", level);

		// Use regex to extract the numeric part of the string
		auto match = level.matchFirst(r"\d+"); // Match one or more digits
		if (!match.empty)
		{
			int levelNumber = to!int(match[0]); // Convert the first match to an integer
			writeln("Parsed Level Number: ", levelNumber);
			// Add logic to initialize and transition to the selected level
		}
		else
		{
			writeln("Error: Could not parse level number from input: ", level);
		}
	}

	/**
     	* Callback for toggling the game music.
     	*/
	void toggleMusicImplementation()
	{
		writeln("Toggling music");
		// Implement music toggling logic
	}

	/**
     	* Callback for pausing the game.
     	* Activates the menu and switches to the menu scene.
     	*/
	void pauseGameImplementation()
	{
		writeln("Pausing game");
		mMenu.isMenuActive = true;
		prev_scene = scene;
		scene = 0; // Set to menu scene
		mGameObjects = myScenes[scene].mScene;
		mTS = myScenes[scene].GetTileSet();
		mDT = myScenes[scene].GetDrawableTileMap();
	}

	/**
     	* Callback for resuming the game.
     	* Deactivates the menu and returns to the previous scene.
     	*/
	void resumeGameImplementation()
	{
		writeln("Resuming game");
		mMenu.isMenuActive = false;
		if (prev_scene != 0)
			scene = prev_scene; // Resume previous scene (or start level 1)
		else
			scene = 1;
		mGameObjects = myScenes[scene].mScene;
		mTS = myScenes[scene].GetTileSet();
		mDT = myScenes[scene].GetDrawableTileMap();
	}

	// import std.file;
	// import std.json;
	// import std.exception;

	// Scene!GameObject Save(Scene!GameObject scene, int level) {
	// 	auto jsonData = sceneToJson(scene); // Convert scene to JSON
	// 	string fileName = "scene_" ~ to!string(level) ~ ".json";
	// 	write(fileName, jsonData.toString()); // Save JSON to a file
	// 	SavedScenes[level - 1] = scene;
	// 	return scene;
	// }

	// JsonValue sceneToJson(Scene!GameObject scene) {
	// 	JsonValue json;
	// 	// Serialize scene properties (e.g., GameObjects, positions, states, etc.)
	// 	// Example structure:
	// 	json["objects"] = JsonArray(scene.getObjects().map!(o => objectToJson(o)).array);
	// 	return json;
	// }

	// JsonValue objectToJson(GameObject obj) {
	// 	JsonValue json;
	// 	json["id"] = obj.id;
	// 	json["type"] = obj.type;
	// 	json["x"] = obj.position.x;
	// 	json["y"] = obj.position.y;
	// 	json["state"] = obj.state;
	// 	return json;
	// }

	// Scene!GameObject jsonToScene(string jsonContent) {
	// 	JsonValue json = parseJSON(jsonContent);
	// 	auto scene = Scene!GameObject();
	// 	foreach (objectJson; json["objects"].array) {
	// 		auto obj = jsonToObject(objectJson);
	// 		scene.addObject(obj);
	// 	}
	// 	return scene;
	// }

	// GameObject jsonToObject(JsonValue json) {
	// 	auto obj = GameObject(json["id"].str, json["type"].str);
	// 	obj.position.x = json["x"].integer;
	// 	obj.position.y = json["y"].integer;
	// 	obj.state = json["state"].str;
	// 	return obj;
	// }

	// Scene!GameObject LoadLevel(int level) {
	// 	string fileName = "scene_" ~ to!string(level) ~ ".json";
	// 	if (exists(fileName)) {
	// 		string jsonContent = readText(fileName); // Read JSON file
	// 		SavedScenes[level - 1] = jsonToScene(jsonContent); // Deserialize JSON back into a Scene object
	// 	} else {
	// 		enforce(SavedScenes[level - 1] !is null, "No saved scene found for level " ~ to!string(level));
	// 	}
	// 	return SavedScenes[level - 1];
	// }

}
