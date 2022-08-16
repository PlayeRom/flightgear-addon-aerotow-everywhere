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
# Constants
#
var addon = addons.getAddon("org.flightgear.addons.Aerotow");

#
# Variables
#
var g_thermalListeners = [];

#
# Initialize thermal module
#
var init = func () {
    append(g_thermalListeners, setlistener(addon.node.getPath() ~ "/addon-devel/add-thermal/distance-m", func () {
        setprop(
            addon.node.getPath() ~ "/addon-devel/add-thermal/distance-nm",
            getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/distance-m") * globals.M2NM
        );
    }));

    append(g_thermalListeners, setlistener(addon.node.getPath() ~ "/addon-devel/add-thermal/strength-fps", func () {
        setprop(
            addon.node.getPath() ~ "/addon-devel/add-thermal/strength-mps",
            getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/strength-fps") * globals.FPS2KT * globals.KT2MPS
        );
    }));

    append(g_thermalListeners, setlistener(addon.node.getPath() ~ "/addon-devel/add-thermal/diameter-ft", func () {
        setprop(
            addon.node.getPath() ~ "/addon-devel/add-thermal/diameter-m",
            getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/diameter-ft") * globals.FT2M
        );
    }));

    append(g_thermalListeners, setlistener(addon.node.getPath() ~ "/addon-devel/add-thermal/height-msl", func () {
        setprop(
            addon.node.getPath() ~ "/addon-devel/add-thermal/height-msl-m",
            getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/height-msl") * globals.FT2M
        );
    }));
}

#
# Uninitialize thermal module
#
var uninit = func () {
    foreach (var listener; g_thermalListeners) {
        removelistener(listener);
    }
}

#
# Add thermal 300 m before glider position.
#
# Return 1 on successful, otherwise 0.
#
var add = func () {
    var heading = getprop("/orientation/heading-deg") or 0;
    var distance = getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/distance-m") or 300;

    var position = geo.aircraft_position();
    position.apply_course_distance(heading, distance);

    # Get random layer from 1 do 4
    var layer = int(rand() * 4) + 1;

    var args = props.Node.new({
        "type":         "thermal",
        "model":        "Models/Weather/altocumulus_layer" ~ layer ~ ".xml",
        "latitude":     position.lat(),
        "longitude":    position.lon(),
        "strength-fps": getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/strength-fps") or 16.0,
        "diameter-ft":  getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/diameter-ft") or 4000,
        "height-msl":   getprop(addon.node.getPath() ~ "/addon-devel/add-thermal/height-msl") or 9000,
        "search-order": "DATA_ONLY"
    });

    if (fgcommand("add-aiobject", args)) {
        messages.displayOk("The thermal has been added");
        return 1;
    }

    messages.displayError("Adding thermal failed");
    return 0;
}
