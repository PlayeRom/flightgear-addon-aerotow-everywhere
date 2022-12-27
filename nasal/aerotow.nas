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
# Class Aerotow for enable and disable scenario with aerotow aircraft.
#
var Aerotow = {
    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @return me
    #
    new: func(addon) {
        var obj = { parents: [Aerotow] };

        obj.addon = addon;
        obj.addonNodePath = addon.node.getPath();
        obj.listeners = [];

        obj.message  = Message.new();
        obj.thermal  = Thermal.new(addon, obj.message);
        obj.scenario = Scenario.new(addon, obj.message);

        # Listener for ai-model property triggered when the user select a tow aircraft from add-on menu
        append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/ai-model", func () {
            obj.restartAerotow();
        }));

        return obj;
    },

    #
    # Uninitialize aerotow module
    #
    # @return void
    #
    del: func() {
        me.thermal.del();
        me.scenario.del();

        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Function for restart AI scenario with delay when the sound has to stop.
    #
    # @return void
    #
    restartAerotow: func() {
        me.message.success("Aerotow on the way");

        # Stop playing engine sound
        setprop(me.addonNodePath ~ "/addon-devel/sound/enable", false);

        # Wait a second for the engine sound to turn off
        Timer.new().singleShot(1, me, func () {
            me.unloadScenario();
        });
    },

    #
    # Unload scenario and start a new one
    #
    # @return void
    #
    unloadScenario: func() {
        if (!me.scenario.unload()) {
            return;
        }

        # Start aerotow with delay to avoid duplicate engine sound playing
        Timer.new().singleShot(1, me, func () {
            me.startAerotow();
        });
    },

    #
    # Main function to prepare AI scenario and run it.
    #
    # @return bool - Return true on successful, otherwise false.
    #
    startAerotow: func() {
        if (!me.scenario.unload()) {
            return false;
        }

        if (!me.scenario.generateXml()) {
            return false;
        }

        return me.scenario.load();
    },

    #
    # Function for unload our AI scenario.
    #
    # @return bool - Return true on successful, otherwise false.
    #
    stopAerotow: func() {
        var withMessages = true;
        return me.scenario.unload(withMessages);
    },
};
