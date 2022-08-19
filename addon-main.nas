#
# Aerotow Everywhere - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2022 Roman Ludwicki
#
# Aerotow Everywhere is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

var unload = func(addon) {
    # This function is for addon development only. It is called on addon
    # reload. The addons system will replace setlistener() and maketimer() to
    # track this resources automatically for you.
    #
    # Listeners created with setlistener() will be removed automatically for you.
    # Timers created with maketimer() will have their stop() method called
    # automatically for you. You should NOT use settimer anymore, see wiki at
    # http://wiki.flightgear.org/Nasal_library#maketimer.28.29
    #
    # Other resources should be freed by adding the corresponding code here,
    # e.g. myCanvas.del();

    aerotow.uninit();
}

var main = func(addon) {
    print("Aerotow Everywhere add-on initialized from path ", addon.basePath);

    # Create $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow directory
    addon.createStorageDir();

    # Create /AI/FlightPlans/ directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
    # User has to add the path as --data=$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow
    # Then the FG will be able to read flight plan file
    var path = os.path.new(addon.storagePath ~ "/AI/FlightPlans/dummy-file.txt");
    path.create_dir();

    loadExtraNasalFiles(addon);

    aerotow.init(addon);
}

#
# Load extra Nasal files in main add-on directory
#
# addon - Addob object
#
var loadExtraNasalFiles = func (addon) {
    var modules = [
        "nasal/aircraft",
        "nasal/message",
        "nasal/dialogs/route",
        "nasal/dialogs/thermal",
        "nasal/flight-plan",
        "nasal/scenario",
        "aerotow",
    ];

    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (io.load_nasal(fileName, "aerotow")) {
            print("Aerotown Add-on module \"", scriptName, "\" loaded OK");
        }
    }
}
