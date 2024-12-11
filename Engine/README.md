## Add any additional notes here

*your additional notes, or things TA's and instructors should know*

## Game/Engine Publicity

**Project Website**: *please edit the project website with a link here* (See part 3)

## Compilation Instructions

*Please edit if there are any special build instructions beyond running `python3 build.py`*

## Project Hieararchy

In the future, other engineers may take on our project, so we have to keep it organized given the following requirements below. Forming some good organization habits now will help us later on when our project grows as well. These are the required files you should have 

### ./Engine Directory Organization

- Docs 
    - Source Code Documentation
- **assets**
    - **fonts**: Files containing typeface specifications. 
    - **images**: All images including sprite sheets, tiles and tile maps, in various formats (JSON, BMP, PNG, etc.) are contained in this directory. 
    - **sounds**: All audio files are kept here. The audio used in our game is open-source and public domain.
- **gui**: Contains files for the graphical user interface. 
- **math**
    - **source**: Contains a math library from a previous assignment. 
    - Covers unary and binary operators, as well as combined operators.
    - Additional operations include scalar multiplication and division, reflection, dot product, normalization, magnitude, slope, distance, and angular unit conversions. 
- **source**
    - Main code for the game engine.
- include
    - header files(.h and .hpp files)
- lib
    - libraries (.so, .dll, .a, .dylib files). Note this is a good place to put SDL
- bin
    - This is the directory where your built executable(.exe for windows, .app for Mac, or a.out for Linux) and any additional generated files are put after each build.
- EngineBuild (Optional)
    - You may optionally put a .zip to you final deliverable. One should be able to copy and paste this directory, and only this directory onto another machine and be able to run the game. This is optional because for this course we will be building your projects from source. However, in the game industry it is useful to always have a build of a game ready for testers, thus a game project hieararchy would likely have this directory in a repo or other storage medium.
- ThirdParty
    - Code that you have not written if any.

