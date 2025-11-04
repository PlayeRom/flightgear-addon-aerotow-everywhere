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
                '/framework/nasal/Canvas/BaseDialogs/Dialog.nas',
                '/framework/nasal/Canvas/BaseDialogs/PersistentDialog.nas',
                '/framework/nasal/Canvas/BaseDialogs/TransientDialog.nas',
            ];
        })
        .hookOnInit(func {
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

            g_Aerotow = Aerotow.new();
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
};
