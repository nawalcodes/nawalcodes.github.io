/**
 * Module component
 * This module contains definitions and implementations for various components
 * used within the game engine, including textures, colliders, lasers, and input handling.
 * It provides the base functionality to create, update, and render game components.
 */
module component;

// Import standard and third-party libraries
import std.stdio;
import std.math;
import vec2;
import bindbc.sdl;
import resource_manager;

/**
 * Enumeration defining the types of components available in the game engine.
 */
enum ComponentType {
    TEXTURE,           /// Represents a texture component.
    CIRCLE_COLLIDER,   /// Represents a circular collider component.
    LASER,             /// Represents a laser component.
    TEXT,              /// Represents a text component.
    INPUT              /// Represents an input handling component.
}

/**
 * Interface for all components in the game engine.
 * Defines the basic structure for components with Update and Render methods.
 */
interface IComponent{
    /**
     * Updates the state of the component.
     */
    void Update();

    /**
     * Renders the component using the specified SDL renderer.
     *
     * Params:
     *  renderer = Pointer to the SDL renderer.
     */
    void Render(SDL_Renderer* renderer);
}

/**
 * Structure representing an individual frame in an animation sequence.
 */
struct Frame {
    SDL_Rect mRect;        /// Rectangle defining the frame's position and size.
    float mElapsedTime;    /// Time elapsed for this frame in the animation.
}

/**
 * Class representing a texture component.
 * This component manages textures and their animations.
 */
class ComponentTexture : IComponent{
    bool isAnimated = false; 		///< Flag to determine if the texture is animated.
    Frame[] mFrames;         		///< Collection of frames for animation.
    long[][string] mFrameNumbers; 	///< Animation sequence defined by frame names.

    string mCurrentAnimationName = null; ///< Name of the currently playing animation.
    long mCurrentFramePlaying;          ///< Index of the current frame being played.
    long mLastFrameInSequence; 		///< Index of the last frame for the current sequence.
    long mstart_time = 0;               ///< Start time for the current animation frame.

    SDL_Renderer* mRenderer = null; 	///< Pointer to the SDL renderer.
    SDL_Texture*  mTexture = null;	///< Pointer to the SDL texture.
    SDL_Rect mRectangle;        	///< Rectangle defining the texture's position and size.
    string mBMPFilePath = null;		///< String consisting of the BMP file path. 

    /// Rotation flags
    int rotate = 0;
    int rotation = 0;

    /**
    * Constructor of the component.
    * Params:
    *  owner (size_t) = Owner of the component
    */ 
    this(size_t owner){
        mOwner = owner;
    }
    /**
    * Destructor of the component.
    */
    ~this(){
        ResourceManager.GetInstance().UnloadTextureResource(mBMPFilePath);
        mTexture = null;
    }

    /**
     * Updates the texture component state.
     * Handles animation updates by incrementing frame indices based on elapsed time.
     */
    override void Update(){
        // Note: The 'cast' is so I can get the address and verify we
        //       have different components
  //      writeln("\tUpdating Texture: ",cast(void*)this);
    }

    /**
     * Sets direction for animation. 
     *
     * Params:
     *  dir = String containing the direction of animation. 
     */
    void Set_Direction(string dir){
        // initialize new looping seq if in new direction
        assert(isAnimated, "Need to Load Frames before setting direction");
        if (dir != mCurrentAnimationName) {
            mCurrentAnimationName = dir;
            mCurrentFramePlaying = 0;
            mLastFrameInSequence = mFrameNumbers[dir].length - 1;
        }

    }

    /**
     * Renders the texture component using the provided SDL renderer.
     *
     * Params:
     *  renderer = Pointer to the SDL renderer.
     */
    void Render(SDL_Renderer* renderer){
        // mRenderer = renderer;
        // SDL_RenderCopy(renderer, mTexture, null, &mRectangle);

        if (isAnimated){
            // display frame
            auto frame = mFrames[mFrameNumbers[mCurrentAnimationName][mCurrentFramePlaying]];
            auto rect = frame.mRect;
            // Copy a texture (or portion of a texture) to another
            // portion of video memory (i.e. a 2D grid of texels 
            // which span the width and height of the window)
            SDL_RenderCopy(renderer, mTexture, &rect, &mRectangle);
	    // following game loop pattern for fixed time step and variable rendering
	    // update to next frame
            if(frame.mElapsedTime < SDL_GetTicks() - mstart_time){
                mCurrentFramePlaying++;
                mstart_time = SDL_GetTicks();
		// restart frame sequence if last frame reached
                if (mCurrentFramePlaying > mLastFrameInSequence)
                {
                    mCurrentFramePlaying = 0;
                }
            }
        } else if (rotate != 0) {
	    // if there is rotation involved, increment rotation flags
            rotation += rotate;
            SDL_Point center = SDL_Point(mRectangle.w / 2, mRectangle.h / 2);
            SDL_RenderCopyEx(renderer, mTexture, null, &mRectangle, rotation, &center, SDL_RendererFlip.SDL_FLIP_NONE);        
        } else {
            SDL_RenderCopy(renderer, mTexture, null, &mRectangle);
        }

    }

    /// Function for coverting degrees to rotation increments
    void SetRotate(int deg){
        rotate = deg;
    }

    /// Returns the rotation value for a particular frame 
    int GetRotation(){
        return rotation;
    }

    /// Setting rectangle
    void SetRectangle(SDL_Rect rect){
        mRectangle = rect;
    }

    /// Setter function for texture
    void SetTexture(SDL_Renderer *renderer, string BMPFilePath, string jsonFilePath = null){
        // only SetTexture on file/image change
        if(mBMPFilePath != BMPFilePath)
        {
            mBMPFilePath = BMPFilePath;

            // load in surface if necessary 
            auto rm = ResourceManager.GetInstance();
            if (rm.LoadSurfaceResource(mBMPFilePath) is null) {
                import std.string : toStringz;
                rm.AddSurfaceResource(mBMPFilePath, SDL_LoadBMP(mBMPFilePath.toStringz()));

                // add new texture
                rm.AddTextureResource(mBMPFilePath, SDL_CreateTextureFromSurface(renderer, rm.LoadSurfaceResource(mBMPFilePath)));
                // mTextures[mBMPFilePath].texture = SDL_CreateTextureFromSurface(renderer, LoadSurfaceResource(mBMPFilePath));
                rm.UnloadSurfaceResource(mBMPFilePath);
                mTexture = rm.LoadTextureResource(renderer, BMPFilePath);
            }

            if (jsonFilePath != null) {
                Load(jsonFilePath);
            }
        }
    }


    /// Perhaps useful to have a 'load' or parse function
    void Load(string filename){

        if (isAnimated == true) return;

            import std.json;
            import std.file;
            import std.algorithm;

            // Read in a file from arguments
            auto myFile = File(filename, "r");

            // Grab all of the json data and concatenate
            auto jsonFileContents = myFile.byLine.joiner("\n");

            // Parse our full result
            auto j=parseJSON(jsonFileContents);

            // create the different frames, store in mFrames
            auto width = j["format"]["width"].get!int;
            auto height = j["format"]["height"].get!int;
            auto tileWidth = j["format"]["tileWidth"].get!int;
            auto tileHeight = j["format"]["tileHeight"].get!int;
            auto rows =  height / tileHeight;
            auto cols =  width / tileWidth;

            foreach(row; 0..rows) {
                foreach(col; 0..cols) {
                    SDL_Rect rect;
                    rect.x = col * tileWidth;
                    rect.y = row * tileHeight;
                    rect.w = tileWidth;
                    rect.h = tileHeight;

                    Frame frame;
                    frame.mRect = rect;
                    frame.mElapsedTime = 100; 

                    mFrames ~= frame;
                }
            }

            // store the frames in the correct sequences
            foreach(mvType, movement; j["frames"].object) {
                long[] mvmt;
                foreach(num; movement.array) {
                    mvmt ~= num.get!long;
                }  
                mFrameNumbers[mvType] = mvmt;
            }

            isAnimated = true;
    }


    private:
    size_t mOwner;
    uint mWidth, mHeight;
}

class ComponentText : IComponent {
    // Component class dealing with text styles and fonts 
    size_t mOwner;

    // Rectangle is where we will represent the shape
    int mFontSize;
    TTF_Font* mFont;
    string mFontFile;
    SDL_Rect mRectangle;
    SDL_Texture* mFontTexture;
    char[] mText;
    SDL_Color mColor;


    this(size_t owner) {
        mOwner = owner;
    }

    ~this(){
        TTF_CloseFont(mFont);
        ResourceManager.GetInstance().UnloadTextureResource(mFontFile);
        mFontTexture = null;
    }

    void Load(char[] label,int x, int y, int text_sz){
		mRectangle.x = x;
		mRectangle.y = y;
        mFontSize = text_sz;
        mText = label;
        mFontFile = "./assets/fonts/Montserrat-Regular.ttf";
        mFont = AdjustFontToFit(mText, mFontFile, text_sz, mRectangle);
        mColor = SDL_Color(255,255,255);
    }

    void Update() {

    }

    void Update(string text){
        // close old text
        if (mFont !is null) {
            TTF_CloseFont(mFont);
            ResourceManager.GetInstance().UnloadTextureResource(cast(string)mFontFile ~ cast(string)mText);
            mFontTexture = null;
        }

        // update to new text
        mText = cast(char[]) text;
        mFont = AdjustFontToFit(mText, "./assets/fonts/Montserrat-Regular.ttf", mFontSize, mRectangle);
        if (mFont == null){
            writeln("error loading in font");
        }
    }

    void Render(SDL_Renderer* renderer){ 
        if (mFontTexture is null){
            import std.string : toStringz;
            SDL_Surface* surfaceText = TTF_RenderText_Solid(mFont, mText.toStringz(), mColor);
            ResourceManager.GetInstance().AddTextureResource(cast(string)mFontFile ~ cast(string)mText, SDL_CreateTextureFromSurface(renderer, surfaceText));
            SDL_FreeSurface(surfaceText);
            mFontTexture = ResourceManager.GetInstance().LoadTextureResource(renderer, cast(string)mFontFile ~ cast(string)mText);
        }

        // draw text
        SDL_RenderCopy(renderer, mFontTexture, null,&mRectangle);
    }

    // adjust the rectangle based on the desired font size
    TTF_Font* AdjustFontToFit(char[] text, string fontPath, int fontSize, ref SDL_Rect targetRect) {
        import std.string;
		TTF_Font* font = null;

        font = TTF_OpenFont(fontPath.toStringz(), fontSize);
        if (font is null) {
            writeln("Error loading font: ", TTF_GetError().fromStringz());
            return null;
        }

        int textWidth, textHeight;
        TTF_SizeText(font, text.toStringz(), &targetRect.w, &targetRect.h);

		return font;
	}

    // center's text to center of window
    void CenterText(int windowWidth, int windowHeight){
        import std.string;
        int textWidth, textHeight;
        TTF_SizeText(mFont, mText.toStringz(), &textWidth, &textHeight);

        // Center text based on height and width
        mRectangle.x = (windowWidth - textWidth) / 2;
        mRectangle.y = (windowHeight - textHeight) / 2;
    }
}

/**
 * Class: ComponentLaser
 * 
 * Represents a laser component within the game, responsible for movement, rendering, and collision detection.
 * Implements the IComponent interface.
 * 
 * Fields:
 * - mOwner: Identifier of the owning entity.
 * - mWidth: Width of the laser rectangle.
 * - mHeight: Height of the laser rectangle.
 * - x, y: Position of the laser.
 * - mColliding: Collision state of the laser.
 * - mDirection: Direction vector of the laser’s movement.
 * - mVelocity: Speed of the laser’s movement.
 * - mShouldDelete: Flag indicating whether the laser should be deleted.
 * - mCollider: Circular collider for detecting collisions.
 * 
 * Methods:
 * - Update: Updates the laser’s position and collision state.
 * - Render: Renders the laser rectangle and optional collider for debugging.
 * - SetPosition: Sets the position of the laser.
 * - SetDirection: Sets the movement direction of the laser.
 * - ShouldDelete: Checks if the laser should be deleted.
 * - SetOwner: Assigns the owner of the laser to prevent friendly fire.
 */
class ComponentLaser : IComponent {
    size_t mOwner;
    float mWidth; // Width of the rectangle
    float mHeight; // Height of the rectangle
    float x, y;
    bool mColliding = false;
    Vec2f mDirection;
    float mVelocity; // Speed of upward movement
    bool mShouldDelete = false; // Flag to mark for deletion

    // Create an instance of ComponentColliderCircle for collision detection
    ComponentColliderCircle mCollider;

    this(size_t owner = 0) {
        mOwner = owner;
        mWidth = 7.0f; // Set desired width
        mHeight = 15.0f; // Set desired height
        x = 0; // Initialize position
        y = 0; // Initialize position
        mDirection = Vec2f(0, -1); // Initial direction (upwards)
        mVelocity = 5; // Set the upward velocity
        mCollider = new ComponentColliderCircle(owner); // Initialize the collider
        mCollider.SetPosition(x + mWidth / 2, y + mHeight / 2); // Center collider in the rectangle
        mCollider.SetDimensions(5);
    }

    void Update() {
        // Gradually move up
        y += mDirection.y * mVelocity; // Move in the upward direction
        mCollider.SetPosition(x + mWidth / 2, y + mHeight / 2); // Update collider position
        
        // Check if the laser goes off-screen
        if ((y - mHeight > 640) | (y + mHeight < 0)) { // Assuming the top of the screen is at y=0
            mShouldDelete = true; // Mark for deletion if off-screen
        }
    }

    void Render(SDL_Renderer* renderer) {
        // Set the render draw color for the outline
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, SDL_ALPHA_OPAQUE); // White outline
        
        // Draw the outline of the rectangle
        import std.conv;
        SDL_Rect outlineRect;
        outlineRect.x = to!int(x);
        outlineRect.y = to!int(y);
        outlineRect.w = to!int(mWidth);
        outlineRect.h = to!int(mHeight);
        SDL_RenderDrawRect(renderer, &outlineRect); // Draw the outline

        // Set the render draw color for the fill (transparent white)
        SDL_SetRenderDrawColor(renderer, 255, 255, 255, 128); // Transparent white fill

        // Fill the rectangle
        SDL_Rect fillRect;
        fillRect.x = to!int(x);
        fillRect.y = to!int(y);
        fillRect.w = to!int(mWidth);
        fillRect.h = to!int(mHeight);
        SDL_RenderFillRect(renderer, &fillRect); // Fill the rectangle

        // render the collider for debugging
        // mCollider.Render(renderer); // Render the collider if needed
    }

    void SetPosition(float x, float y) {
        this.x = x;
        this.y = y;
        mCollider.SetPosition(x + mWidth / 2, y + mHeight / 2); // Update collider position
    }

    void SetDirection(int d){
        mDirection = Vec2f(0, d); // Initial direction (upwards)
    }

    bool ShouldDelete() const {
        return mShouldDelete; // Getter to check if it should be deleted
    }

    void SetOwner(size_t owner) { // avoid friendly fire
        mCollider.mOwner = owner; 
        mOwner = owner;
    }
}

/**
 * Class: ComponentColliderCircle
 * 
 * Represents a circular collision component.
 * Implements the IComponent interface.
 * 
 * Fields:
 * - mOwner: Identifier of the owning entity.
 * - mRadius: Radius of the circle.
 * - x, y: Position of the circle.
 * - mColliding: Collision state.
 * - mDirection: Direction of movement.
 * 
 * Methods:
 * - Update: Updates the position of the circle.
 * - Render: Renders the circular collider for debugging.
 * - SetPosition: Sets the position of the circle.
 * - SetDimensions: Sets the radius of the circle.
 * - IsColliding: Checks for collision with another circular collider.
 */
class ComponentColliderCircle : IComponent{
    size_t mOwner;
    float mRadius; 
    float x,y;
	bool mColliding=false;	
	Vec2f mDirection;
	
	this(size_t owner){
        mOwner = owner;
        mRadius = 10.0f;
	}

	void Update(){
		x+= mDirection.x;
		y+= mDirection.y;
	}

	void Render(SDL_Renderer* renderer){
		// Set the render draw color based on the collision
		if(mColliding){
			SDL_SetRenderDrawColor(renderer,0,255,0,SDL_ALPHA_OPAQUE);
		}else{
			SDL_SetRenderDrawColor(renderer,255,0,0,SDL_ALPHA_OPAQUE);
		}

		for(float i=0; i < 360; i+=1){
				int xPos = cast(int)x+ cast(int)( mRadius*cos(i.DegreesToRadians) );
				int yPos = cast(int)y+ cast(int)( mRadius*sin(i.DegreesToRadians) );
				SDL_RenderDrawPoint(renderer,xPos,yPos);	
		}
	}

    void SetPosition(float x, float y){
        this.x = x;
        this.y = y;
    }

    void SetDimensions(float r){
        this.mRadius = r;
    }

	bool IsColliding(ref ComponentColliderCircle c){
        mColliding = false;
        if (mOwner != c.mOwner)
        {
            float distance = sqrt( (x-c.x)*(x-c.x) + (y-c.y)*(y-c.y));
            if( (c.mRadius + mRadius) > distance){
                mColliding = true;
            }
        }

		c.mColliding = mColliding;
		return mColliding;
	}
}

/**
 * Enum: ANIMATION_STATE
 * 
 * Defines the possible states for character animation.
 *
 */
enum ANIMATION_STATE
{
    LEFT,		/// Moving left.
    RIGHT,		/// Moving right.
    DOWN,		/// Moving down.
    UP,			/// Moving up. 
    STOP,		/// Stopped in a neutral position. 
    STOPLEFT,		/// Stopped while facing left. 
    STOPRIGHT,		/// Stopped while facing right. 
    STOPUP,		/// Stopped while facing up. 
    STOPDOWN		/// Stopped while facing down. 
};

/**
 * Interface: ComponentControls
 * 
 * Provides an interface for handling directional input via arrow keys.
 * 
 * Methods:
 * - ArrowInput: Processes SDL events to determine movement direction and animation state.
 */
interface ComponentControls {
    void ArrowInput (SDL_Event event, ref int xDirection, ref int yDirection, ref ANIMATION_STATE state);
}

/**
 * Class: ComponentArrows
 * 
 * Implements directional input handling using arrow keys. Updates movement directions and animation states.
 * 
 * Fields:
 * - mOwner: Identifier of the owning entity.
 * 
 * Methods:
 * - ArrowInput: Processes SDL events to set movement direction and animation state.
 */
class ComponentArrows : ComponentControls{
    ulong mOwner;
    this(ulong owner){
        mOwner = owner;
    }

    void ArrowInput(SDL_Event event, ref int xDirection, ref int yDirection, ref ANIMATION_STATE state)
    {
        if (event.type == SDL_KEYDOWN)
        {
            switch (event.key.keysym.sym)
            {
            case SDLK_LEFT:
                xDirection = -50;
                state = ANIMATION_STATE.LEFT;
                break;
            case SDLK_RIGHT:
                xDirection = 50;
                state = ANIMATION_STATE.RIGHT;
                break;
            case SDLK_UP:
                yDirection = -50;
                state = ANIMATION_STATE.UP;
                break;
            case SDLK_DOWN:
                yDirection = 50;
                state = ANIMATION_STATE.DOWN;
                break;
            default:
                break;
            }
        }

        if (event.type == SDL_KEYUP)
        {
            switch (event.key.keysym.sym)
            {
                case SDLK_LEFT:
                    state = ANIMATION_STATE.STOPLEFT;
                    break;
                case SDLK_RIGHT:
                    state = ANIMATION_STATE.STOPRIGHT;
                    break;
                case SDLK_UP:
                    state = ANIMATION_STATE.STOPUP;
                    break;
                case SDLK_DOWN:
                    state = ANIMATION_STATE.STOPDOWN;
                    break;
                default:
                    break;
            }
            xDirection = 0;
            yDirection = 0;
        }
    }
}

/**
 * Class: JumpArrows
 * 
 * Extends ComponentControls to handle jumping mechanics using the arrow keys.
 * 
 * Fields:
 * - mOwner: Identifier of the owning entity.
 * 
 * Methods:
 * - ArrowInput: Processes SDL events to determine movement and jump actions.
 */
class JumpArrows : ComponentControls {
    ulong mOwner;
    this(ulong owner){
        mOwner = owner;
    }

    void ArrowInput(SDL_Event event, ref int xDirection, ref int yDirection, ref ANIMATION_STATE state)
    {
        if (event.type == SDL_KEYDOWN)
        {
            switch (event.key.keysym.sym)
            {
            case SDLK_LEFT:
                xDirection = -50;
                state = ANIMATION_STATE.LEFT;
                break;
            case SDLK_RIGHT:
                xDirection = 50;
                state = ANIMATION_STATE.RIGHT;
                break;
            case SDLK_UP:
                if (yDirection == 0) yDirection = -50;
                break;
            case SDLK_DOWN:
                break;
            default:
                break;
            }
        }

        if (event.type == SDL_KEYUP)
        {
            switch (event.key.keysym.sym)
            {
                case SDLK_LEFT:
                    state = ANIMATION_STATE.STOPLEFT;
                    break;
                case SDLK_RIGHT:
                    state = ANIMATION_STATE.STOPRIGHT;
                    break;
                case SDLK_UP:
                    break;
                case SDLK_DOWN:
                    break;
                default:
                    break;
            }
            xDirection = 0;
        }
    }
}
