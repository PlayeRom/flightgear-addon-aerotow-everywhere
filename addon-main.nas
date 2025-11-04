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

io.include('framework/nasal/Application.nas');

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
# Main add-on function.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_INFO, addon.name, ' Add-on initialized from path ', addon.basePath);

    Application
        .hookFilesExcludedFromLoading(func {
            return [
                '/framework/nasal/Canvas/BaseDialogs/TransientDialog.nas',
            ];
        })
        .hookOnInit(func {
            # Create $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow directory
            g_Addon.createStorageDir();

            # Create /AI/FlightPlans/ directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
            # User has to add the path as --data=$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow
            # Then the FG will be able to read flight plan file
            var path = os.path.new(g_Addon.storagePath ~ '/AI/FlightPlans/dummy-file.txt');
            path.create_dir();

            # Create /route-saves directory in $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/
            path = os.path.new(g_Addon.storagePath ~ '/' ~ RouteAerotowDialog.ROUTE_SAVES_DIR ~ '/dummy-file.txt');
            path.create_dir();
        })
        .hookOnInitCanvas(func {
            g_Aerotow = Aerotow.new();
            g_AddThermalDialog = ThermalDialog.new();
            g_TowRopeConfigDialog = TowRopeConfigDialog.new();
            g_HelpDialog = HelpDialog.new();
            g_AboutDialog = AboutDialog.new();
        })
        .create(addon, 'aerotowAddon');
};

#
# This function is for addon development only. It is called on addon reload. The addons system will replace
# setlistener() and maketimer() to track this resources automatically for you.
#
# Listeners created with setlistener() will be removed automatically for you. Timers created with maketimer() will have
# their stop() method called automatically for you. You should NOT use settimer anymore, see wiki at
# https://wiki.flightgear.org/Nasal_library#maketimer()
#
# Other resources should be freed by adding the corresponding code here, e.g. `myCanvas.del();`.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var unload = func(addon) {
    Log.print('unload');
    Application.unload();

    if (g_Aerotow != nil) {
        g_Aerotow.del();
    }

    if (g_AddThermalDialog != nil) {
        g_AddThermalDialog.del();
    }

    if (g_TowRopeConfigDialog != nil) {
        g_TowRopeConfigDialog.del();
    }

    if (g_HelpDialog != nil) {
        g_HelpDialog.del();
    }

    if (g_AboutDialog != nil) {
        g_AboutDialog.del();
    }
};
