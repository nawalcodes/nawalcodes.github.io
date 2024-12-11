/**
 * Module sound
 *
 * Provides functionality to load, play, and stop sound files using SDL.
 * Handles audio device setup and manages resources to ensure proper playback and cleanup.
 */
module sound;

import sdl_abstraction;
import bindbc.sdl;
import std.stdio;
import std.string;

/**
 * Struct Sound
 *
 * A struct for managing sound playback. 
 * It provides methods to load audio files, start and stop audio playback, 
 * and set up audio devices using SDL.
 */
struct Sound
{
    /**
     * Constructor
     *
     * Initializes a Sound instance by loading an audio file.
     *
     * Params:
     *  filepath = The path to the audio file (in WAV format) to load.
     * 
     * Throws:
     *  RuntimeException if the audio file fails to load.
     */
    this(string filepath)
    {
        if (SDL_LoadWAV(filepath.toStringz, &m_audioSpec, &m_waveStart, &m_waveLength) == null)
        {
            // Error message if loading fails
            writeln("sound loading error: ", SDL_GetError());
        }
        else
        {
            // Success message
            // writeln("Sound file loaded:", filepath);
        }
    }

    /**
     * Destructor
     *
     * Frees the memory used for the WAV file and closes the associated audio device.
     */
    ~this()
    {
        SDL_FreeWAV(m_waveStart);
        SDL_CloseAudioDevice(m_device);
    }

    /**
     * Plays the loaded sound.
     *
     * Queues the audio data for playback and starts the audio device.
     */
    void PlaySound()
    {
        SDL_QueueAudio(m_device, m_waveStart, m_waveLength);
        SDL_PauseAudioDevice(m_device, 0);
    }

    /**
     * Stops the sound playback.
     *
     * Pauses the audio device to stop the playback.
     */
    void StopSound()
    {
        SDL_PauseAudioDevice(m_device, 1);
    }

    /**
     * Sets up the SDL audio device for playback.
     *
     * Opens an audio device with the specified audio specification.
     * 
     * Throws:
     *  RuntimeException if no suitable audio device is found.
     */
    void SetupDevice()
    {
        m_device = SDL_OpenAudioDevice(null, 0, &m_audioSpec, null, SDL_AUDIO_ALLOW_ANY_CHANGE);
        if (0 == m_device)
        {
            writeln("sound device error: ", SDL_GetError());
        }
    }

private:
    /**
     * ID for the sound (could be used for tracking).
     */
    int id;

    /**
     * SDL audio device used for playback.
     */
    SDL_AudioDeviceID m_device;

    /**
     * Audio specification of the loaded WAV file.
     */
    SDL_AudioSpec m_audioSpec;

    /**
     * Pointer to the start of the loaded WAV file data.
     */
    ubyte* m_waveStart;

    /**
     * Length of the loaded WAV file data in bytes.
     */
    uint m_waveLength;
}
