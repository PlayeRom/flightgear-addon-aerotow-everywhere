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

io.include("Loader.nas");

#
# Main add-on function.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var main = func(addon) {
    logprint(LOG_ALERT, addon.name, " Add-on initialized from path ", addon.basePath);

    Loader.new(addon).load(addon.basePath, "aerotow");

    aerotow.Bootstrap.init(addon);
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
    aerotow.Log.print("unload");
    aerotow.Bootstrap.uninit();
};
