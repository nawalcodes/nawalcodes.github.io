/// Menu module for managing in-game menus.
///
/// The module contains a `Menu` class that manages a set of buttons,
/// rendering, input handling, and game-related actions such as starting
/// levels, pausing, resuming, and toggling music.
module menu;

import bindbc.sdl;
import std.string;
import component;
import gameobject;
import factory;

/// Class representing a game menu.
///
/// This class manages the rendering and input handling of menu buttons.
/// It provides functionality to start a game, toggle music, pause, and
/// resume the game based on user interactions.
class Menu
{
    /// Renderer for rendering menu components.
    SDL_Renderer* mRenderer;

    /// Array of buttons in the menu.
    GameObject[] mButtons;

    /// Flag indicating whether the menu is active.
    bool isMenuActive = true;

    /// Callback delegate for starting a game.
    void delegate(string) startGame;

    /// Callback delegate for toggling music.
    void delegate() toggleMusic;

    /// Callback delegate for pausing the game.
    void delegate() pauseGame;

    /// Callback delegate for resuming the game.
    void delegate() resumeGame;

    /// Constructor.
    ///
    /// Initializes the menu with a renderer and action callbacks.
    ///
    /// Params:
    ///     renderer = Pointer to the SDL renderer.
    ///     startGameCallback = Delegate for starting the game.
    ///     toggleMusicCallback = Delegate for toggling music.
    ///     pauseGameCallback = Delegate for pausing the game.
    ///     resumeGameCallback = Delegate for resuming the game.
    this(SDL_Renderer* renderer,
         void delegate(string) startGameCallback,
         void delegate() toggleMusicCallback,
         void delegate() pauseGameCallback,
         void delegate() resumeGameCallback)
    {
        mRenderer = renderer;
        startGame = startGameCallback;
        toggleMusic = toggleMusicCallback;
        pauseGame = pauseGameCallback;
        resumeGame = resumeGameCallback;

        // Initialize menu buttons.
        mButtons ~= CreateButton("Level 1", 100, 100);
        mButtons ~= CreateButton("Level 2", 100, 200);
        mButtons ~= CreateButton("Level 3", 100, 300);
        mButtons ~= CreateButton("Music: On", 400, 100);
        mButtons ~= CreateButton("Pause", 400, 200);
        mButtons ~= CreateButton("Resume", 400, 300);
    }

    /// Creates a button with a label and position.
    ///
    /// Params:
    ///     label = Text displayed on the button.
    ///     x = X-coordinate of the button.
    ///     y = Y-coordinate of the button.
    ///
    /// Returns:
    ///     A `GameObject` representing the button.
    GameObject CreateButton(string label, int x, int y)
    {
        auto button = MakeText("Button");
        auto textComponent = cast(ComponentText) button.GetComponent(ComponentType.TEXT);
        textComponent.Load(cast(char[]) label, x, y, 36);
        textComponent.mRectangle = SDL_Rect(x, y, 200, 50);
        return button;
    }

    /// Renders the menu and its buttons.
    void Render()
    {
        if (!isMenuActive)
            return;

        foreach (button; mButtons)
        {
            button.Render(mRenderer);
        }
    }

    /// Handles input events for the menu buttons.
    ///
    /// Params:
    ///     event = SDL event to process.
    void HandleInput(SDL_Event event)
    {
        if (!isMenuActive)
            return;

        if (event.type == SDL_MOUSEBUTTONDOWN)
        {
            foreach (button; mButtons)
            {
                auto textComponent = cast(ComponentText) button.GetComponent(ComponentType.TEXT);
                SDL_Rect rect = textComponent.mRectangle;
                if (event.button.x >= rect.x && event.button.x <= rect.x + rect.w &&
                    event.button.y >= rect.y && event.button.y <= rect.y + rect.h)
                {
                    OnButtonClick(cast(string) textComponent.mText);
                }
            }
        }
    }

    /// Handles button click actions.
    ///
    /// Params:
    ///     label = Label of the clicked button.
    void OnButtonClick(string label)
    {
        if (label.startsWith("Level"))
        {
            isMenuActive = false;
            startGame(label);
        }
        else if (label.startsWith("Music"))
        {
            toggleMusic();
        }
        else if (label == "Pause")
        {
            pauseGame();
        }
        else if (label == "Resume")
        {
            isMenuActive = false;
            resumeGame();
        }
    }
}
