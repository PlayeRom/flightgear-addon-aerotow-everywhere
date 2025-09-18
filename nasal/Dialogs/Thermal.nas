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
# Class Thermal for handle add new thermal.
#
var Thermal = {
    #
    # Constructor
    #
    # @param  hash  message  Message object.
    # @return hash
    #
    new: func(message) {
        var me = {
            parents : [Thermal],
            _message: message,
        };

        me._addonNodePath = g_Addon.node.getPath();
        me._listeners = Listeners.new();

        # Listener for calculate distance from meters to nautical miles.
        me._listeners.add(me._addonNodePath ~ "/addon-devel/add-thermal/distance-m", func (node) {
            setprop(me._addonNodePath ~ "/addon-devel/add-thermal/distance-nm", node.getValue() * globals.M2NM);
        });

        # Listener for calculate strength from ft/s to m/s.
        me._listeners.add(me._addonNodePath ~ "/addon-devel/add-thermal/strength-fps", func (node) {
            setprop(me._addonNodePath ~ "/addon-devel/add-thermal/strength-mps", node.getValue() * globals.FPS2KT * globals.KT2MPS);
        });

        # Listener for calculate diameter from ft to m.
        me._listeners.add(me._addonNodePath ~ "/addon-devel/add-thermal/diameter-ft", func (node) {
            setprop(me._addonNodePath ~ "/addon-devel/add-thermal/diameter-m", node.getValue() * globals.FT2M);
        });

        # Listener for calculate height from ft to m.
        me._listeners.add(me._addonNodePath ~ "/addon-devel/add-thermal/height-msl", func (node) {
            setprop(me._addonNodePath ~ "/addon-devel/add-thermal/height-msl-m", node.getValue() * globals.FT2M);
        });

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._listeners.del();
    },

    #
    # Add thermal 300 m before glider position.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    add: func() {
        var heading = getprop("/orientation/heading-deg") or 0;
        var distance = getprop(me._addonNodePath ~ "/addon-devel/add-thermal/distance-m") or 300;

        var position = geo.aircraft_position();
        position.apply_course_distance(heading, distance);

        # Get random layer from 1 to 4
        var layer = int(rand() * 4) + 1;

        var args = props.Node.new({
            "type":         "thermal",
            "model":        "Models/Weather/altocumulus_layer" ~ layer ~ ".xml",
            "latitude":     position.lat(),
            "longitude":    position.lon(),
            "strength-fps": getprop(me._addonNodePath ~ "/addon-devel/add-thermal/strength-fps") or 16.0,
            "diameter-ft":  getprop(me._addonNodePath ~ "/addon-devel/add-thermal/diameter-ft") or 4000,
            "height-msl":   getprop(me._addonNodePath ~ "/addon-devel/add-thermal/height-msl") or 9000,
            "search-order": "DATA_ONLY"
        });

        if (fgcommand("add-aiobject", args)) {
            me._message.success("The thermal has been added");
            return true;
        }

        me._message.error("Adding thermal failed");
        return false;
    },
};
