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
# MY_LOG_LEVEL is using in Log.print() to quickly change all logs visibility used in addon's namespace.
# Possible values: LOG_ALERT, LOG_WARN, LOG_INFO, LOG_DEBUG, LOG_BULK.
#
var MY_LOG_LEVEL = LOG_WARN;

#
# Global flag to enable dev mode.
# You can use this flag to condition on heavier logging that shouldn't be
# executed for the end user, but you want to keep it in your code for development
# purposes. This flag will be set to true automatically when you use an .env
# file with DEV_MODE=true.
#
var g_isDevMode = false;

#
# Global object of addons.Addon.
#
var g_Addon = nil;

#
# Global object of Aerotow.
#
var g_Aerotow = nil;

#
# Create objects from add-on namespace.
#
var Bootstrap = {
    #
    # Initialize objects from add-on namespace.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return void
    #
    init: func(addon) {
        g_Addon = addon;

        Bootstrap._initDevMode();
        Bootstrap._createDirectories();

        g_Aerotow = Aerotow.new();
    },

    #
    # Uninitialize addon's namespace
    #
    # @return void
    #
    uninit: func() {
        if (g_Aerotow) {
            g_Aerotow.del();
        }
    },

    #
    # Create all needed directories.
    #
    # @return void
    #
    _createDirectories: func() {
        # Create $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow directory
        g_Addon.createStorageDir();

        # Create /AI/FlightPlans/ directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
        # User has to add the path as --data=$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow
        # Then the FG will be able to read flight plan file
        var path = os.path.new(g_Addon.storagePath ~ "/AI/FlightPlans/dummy-file.txt");
        path.create_dir();

        # Create /route-saves directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
        path = os.path.new(g_Addon.storagePath ~ "/" ~ RouteDialog.ROUTE_SAVES_DIR ~ "/dummy-file.txt");
        path.create_dir();
    },

    #
    # Handle development mode (.env file).
    #
    # @return void
    #
    _initDevMode: func() {
        var env = DevEnv.new();

        var logLevel = env.getValue("MY_LOG_LEVEL");
        if (logLevel != nil) {
            MY_LOG_LEVEL = logLevel;
        }

        g_isDevMode = env.getBoolValue("DEV_MODE");

        if (g_isDevMode) {
            var reloadMenu = DevReloadMenu.new();

            env.getBoolValue("RELOAD_MENU")
                ? reloadMenu.addMenu()
                : reloadMenu.removeMenu();

            DevReloadMultiKey.addMultiKeyCmd(env.getValue("RELOAD_MULTIKEY_CMD"));
        }
    },
};
