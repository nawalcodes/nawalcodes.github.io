module gui;

import std.stdio;
import std.conv;

import gtk.MainWindow;
import gtk.Main;
import gtk.Widget;
import gtk.Button;
import gtk.Box;
import gtk.Fixed;
import gtk.Image;
import gtk.EventBox;
import gtk.TargetEntry;
import gdk.Pixbuf;
import gdk.DragContext;
import gtk.SelectionData;
import gdk.Event;

void QuitApp(){
    writeln("Terminating application");
    Main.quit();
}

import gtk.Main;
import gtk.Widget;
import gtk.EventBox;
import gtk.Image;
import gdk.Pixbuf;

Widget createDraggableAsset(string imagePath, int maxWidth = 64, int maxHeight = 64) {
    EventBox eventBox = new EventBox();

    // Load the image into a Pixbuf
    Pixbuf pixbuf = new Pixbuf(imagePath);

    // Get the original dimensions
    int originalWidth = pixbuf.getWidth();
    int originalHeight = pixbuf.getHeight();

    // Calculate the new dimensions while maintaining the aspect ratio
    double aspectRatio = cast(double) originalWidth / originalHeight;
    int newWidth = originalWidth;
    int newHeight = originalHeight;

    if (originalWidth > maxWidth || originalHeight > maxHeight) {
        if (aspectRatio > 1.0) {
            // Wider than tall, limit by width
            newWidth = maxWidth;
            newHeight = cast(int) (maxWidth / aspectRatio);
        } else {
            // Taller than wide, limit by height
            newHeight = maxHeight;
            newWidth = cast(int) (maxHeight * aspectRatio);
        }
    }

    // Scale the Pixbuf to the new dimensions
    pixbuf = pixbuf.scaleSimple(newWidth, newHeight, GdkInterpType.BILINEAR);

    // Create a GTK Image from the resized Pixbuf
    Image image = new Image(pixbuf);
    eventBox.add(image);

    // Set drag-and-drop properties
    TargetEntry[] targets = [new TargetEntry("STRING", 0, 0)];
    eventBox.dragSourceSet(GdkModifierType.BUTTON1_MASK, targets, GdkDragAction.COPY);

    eventBox.addOnDragDataGet((DragContext context, SelectionData selectionData, uint info, uint time, Widget widget) {
        selectionData.setText(imagePath, to!int(imagePath.length));
    });

    return eventBox;
}

Widget createDraggableCoin(string imagePath, int maxWidth = 64, int maxHeight = 64) {
    EventBox eventBox = new EventBox();

    // Load the image into a Pixbuf
    Pixbuf pixbuf = new Pixbuf(imagePath);
	Pixbuf firstFrame = pixbuf.newSubpixbuf(0, 0, 166, 166);

    // Get the original dimensions
    int originalWidth = firstFrame.getWidth();
    int originalHeight = firstFrame.getHeight();

    // Calculate the new dimensions while maintaining the aspect ratio
    double aspectRatio = cast(double) originalWidth / originalHeight;
    int newWidth = originalWidth;
    int newHeight = originalHeight;

    if (originalWidth > maxWidth || originalHeight > maxHeight) {
        if (aspectRatio > 1.0) {
            // Wider than tall, limit by width
            newWidth = maxWidth;
            newHeight = cast(int) (maxWidth / aspectRatio);
        } else {
            // Taller than wide, limit by height
            newHeight = maxHeight;
            newWidth = cast(int) (maxHeight * aspectRatio);
        }
    }

    // Scale the Pixbuf to the new dimensions
    pixbuf = firstFrame.scaleSimple(newWidth, newHeight, GdkInterpType.BILINEAR);

    // Create a GTK Image from the resized Pixbuf
    Image image = new Image(pixbuf);
    eventBox.add(image);

    // Set drag-and-drop properties
    TargetEntry[] targets = [new TargetEntry("STRING", 0, 0)];
    eventBox.dragSourceSet(GdkModifierType.BUTTON1_MASK, targets, GdkDragAction.COPY);

    eventBox.addOnDragDataGet((DragContext context, SelectionData selectionData, uint info, uint time, Widget widget) {
        selectionData.setText(imagePath, to!int(imagePath.length));
    });

    return eventBox;
}

void RunGUI(immutable string[] args)
{
    string[] args2 = args.dup;

    // Initialize GTK
    Main.init(args2);

    // Setup our window
    MainWindow myWindow = new MainWindow("GUI Engine Tools");
    myWindow.setDefaultSize(640,480);
    myWindow.move(100,120);

    // Delegate to call when we destroy our application
    myWindow.addOnDestroy(delegate void(Widget w) { QuitApp(); });

    // Create a vertical box to organize the window layout
    Box vbox = new Box(Orientation.VERTICAL, 10);

    // Create a horizontal box to hold the buttons
    Box hbox = new Box(Orientation.HORIZONTAL, 10);

    // Set a fixed height for the horizontal box
    hbox.setSizeRequest(-1, 50); 

    // Create and add Button 1
    Button button1 = new Button("Save");
    button1.addOnClicked(delegate void(Button b) {
        writeln("Button 1 clicked");
    });
    hbox.add(button1);

    // Create and add Button 2
    Button button2 = new Button("Load");
    button2.addOnClicked(delegate void(Button b) {
        writeln("Button 2 clicked");
    });
    hbox.add(button2);

    // Create and add Button 3
    Button button3 = new Button("Exit");
    button3.addOnClicked(delegate void(Button b) {
        writeln("Button 3 clicked");
    });
    hbox.add(button3);

	// Add buttons to vertical box
    vbox.add(hbox);

	// Create a box to hold image assets
    Box assetBox = new Box(Orientation.HORIZONTAL, 10);  // Horizontal box for images

    // Load and display images
    Widget asset1 = createDraggableAsset("./assets/images/circle.bmp");
    assetBox.add(asset1);

    Widget asset2 = createDraggableAsset("./assets/images/square.bmp");
    assetBox.add(asset2);

    Widget asset3 = createDraggableAsset("./assets/images/triangle.bmp");
    assetBox.add(asset3);

	Widget asset4 = createDraggableCoin("./assets/images/coins.bmp");
	assetBox.add(asset4);

    // Add the asset container to the vertical box
    vbox.add(assetBox);

    // Add vertical box to window
    myWindow.add(vbox);

    // Show the window and all its contents
    myWindow.showAll();

    // Run our main loop
    Main.run();
}
