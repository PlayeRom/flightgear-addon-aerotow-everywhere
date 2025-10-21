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
# Global object of add thermal dialog.
#
var g_AddThermalDialog = nil;

#
# Global object of tow rope config dialog.
#
var g_TowRopeConfigDialog = nil;

#
# Global object of help dialog.
#
var g_HelpDialog = nil;

#
# Global object of about dialog.
#
var g_AboutDialog = nil;

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

        me._initDevMode();
        me._createDirectories();

        me._delayCanvasLoading(func {
            g_Aerotow = Aerotow.new();
            g_AddThermalDialog = ThermalDialog.new();
            g_TowRopeConfigDialog = TowRopeConfigDialog.new();
            g_HelpDialog = HelpDialog.new();
            g_AboutDialog = AboutDialog.new();
        });
    },

    #
    # Uninitialize object from add-on namespace.
    #
    # @return void
    #
    uninit: func() {
        if (g_Aerotow) {
            g_Aerotow.del();
        }

        if (g_AddThermalDialog) {
            g_AddThermalDialog.del();
        }

        if (g_TowRopeConfigDialog) {
            g_TowRopeConfigDialog.del();
        }

        if (g_HelpDialog) {
            g_HelpDialog.del();
        }

        if (g_AboutDialog) {
            g_AboutDialog.del();
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
        path = os.path.new(g_Addon.storagePath ~ "/" ~ RouteAerotowDialog.ROUTE_SAVES_DIR ~ "/dummy-file.txt");
        path.create_dir();
    },

    #
    # Delay loading the entire Canvas add-on to avoid damaging aircraft displays such as A320, A330. The point is that,
    # for example, the A320 hard-coded the texture index from /canvas/by-index/texture[15]. But this add-on may creates
    # its canvas textures earlier than the airplane, which will cause that at index 15 there will be no texture of some
    # display but the texture from the add-on. So thanks to this delay, the textures of the plane will be created first,
    # and then the textures of this add-on.
    #
    # @param  func  callback
    # @return void
    #
    _delayCanvasLoading: func(callback) {
        # Disable menu items responsible for launching persistent dialogs.
        var menu = MenuStateHandler.new();
        menu.toggleItems(false);

        Timer.singleShot(3, func() {
            callback();

            # Enable menu items responsible for launching persistent dialogs.
            menu.toggleItems(true);
        });
    },

    #
    # Handle development mode (.env file).
    #
    # @return void
    #
    _initDevMode: func() {
        if (!Config.dev.useEnvFile) {
            return;
        }

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

            DevMultiKeyCmd.new()
                .addReloadAddon(env.getValue("RELOAD_MULTIKEY_CMD"))
                .addRunTests(env.getValue("TEST_MULTIKEY_CMD"))
                .finish();
        }
    },
};
