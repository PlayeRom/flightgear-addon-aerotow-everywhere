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
var ADDON = addons.getAddon("org.flightgear.addons.Aerotow");
var ADDON_NODE_PATH = ADDON.node.getPath();

#
# Variables
#
var g_thermalListeners = [];

#
# Initialize thermal module
#
var init = func () {
    # Listener for calculate distance from meters to nautical miles.
    append(g_thermalListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/distance-m", func (node) {
        setprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/distance-nm", node.getValue() * globals.M2NM);
    }));

    # Listener for calculate strength from ft/s to m/s.
    append(g_thermalListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/strength-fps", func (node) {
        setprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/strength-mps", node.getValue() * globals.FPS2KT * globals.KT2MPS);
    }));

    # Listener for calculate diameter from ft to m.
    append(g_thermalListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/diameter-ft", func (node) {
        setprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/diameter-m", node.getValue() * globals.FT2M);
    }));

    # Listener for calculate height from ft to m.
    append(g_thermalListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/height-msl", func (node) {
        setprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/height-msl-m", node.getValue() * globals.FT2M);
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
    var distance = getprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/distance-m") or 300;

    var position = geo.aircraft_position();
    position.apply_course_distance(heading, distance);

    # Get random layer from 1 to 4
    var layer = int(rand() * 4) + 1;

    var args = props.Node.new({
        "type":         "thermal",
        "model":        "Models/Weather/altocumulus_layer" ~ layer ~ ".xml",
        "latitude":     position.lat(),
        "longitude":    position.lon(),
        "strength-fps": getprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/strength-fps") or 16.0,
        "diameter-ft":  getprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/diameter-ft") or 4000,
        "height-msl":   getprop(ADDON_NODE_PATH ~ "/addon-devel/add-thermal/height-msl") or 9000,
        "search-order": "DATA_ONLY"
    });

    if (fgcommand("add-aiobject", args)) {
        messages.displayOk("The thermal has been added");
        return 1;
    }

    messages.displayError("Adding thermal failed");
    return 0;
}
