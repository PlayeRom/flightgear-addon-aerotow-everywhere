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

#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_ALERT, addon.name, " Add-on initialized from path ", addon.basePath);

    loadExtraNasalFiles(addon);

    createDirectories(addon);

    aerotow.init(addon);
};

#
# Load extra Nasal files in main add-on directory.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var loadExtraNasalFiles = func(addon) {
    var modules = [
        "nasal/Utils/Listeners",
        "nasal/Utils/Log",
        "nasal/Utils/Message",
        "nasal/Utils/Timer",
        "nasal/Aircraft",
        "nasal/Dialogs/RouteDialog",
        "nasal/Dialogs/Thermal",
        "nasal/FlightPlan",
        "nasal/Scenario",
        "nasal/IO/Waypoint",
        "nasal/IO/FlightPlanWriter",
        "nasal/Aerotow",
        "Aerotow",
    ];

    foreach (var scriptName; modules) {
        var fileName = addon.basePath ~ "/" ~ scriptName ~ ".nas";

        if (!io.load_nasal(fileName, "aerotow")) {
            logprint(LOG_ALERT, addon.name, " Add-on module \"", scriptName, "\" loading failed");
        }
    }
};

#
# Create all needed directories.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var createDirectories = func(addon) {
    # Create $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow directory
    addon.createStorageDir();

    # Create /AI/FlightPlans/ directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
    # User has to add the path as --data=$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow
    # Then the FG will be able to read flight plan file
    var path = os.path.new(addon.storagePath ~ "/AI/FlightPlans/dummy-file.txt");
    path.create_dir();

    # Create /route-saves directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
    path = os.path.new(addon.storagePath ~ "/" ~ aerotow.RouteDialog.ROUTE_SAVES_DIR ~ "/dummy-file.txt");
    path.create_dir();
};

#
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
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    aerotow.uninit();
};
