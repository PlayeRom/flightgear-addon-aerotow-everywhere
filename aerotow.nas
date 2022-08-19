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
# Aerotow object
#
var Aerotow = {
    #
    # Constructor
    #
    # addon - Addon object
    #
    new: func (addon) {
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
    del: func () {
        me.thermal.del();

        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Function for restart AI scenario with delay when the sound has to stop.
    #
    # Return 1 on successful, otherwise 0.
    #
    restartAerotow: func () {
        me.message.success("Aerotow in the way");

        # Stop playing engine sound
        setprop(me.addonNodePath ~ "/addon-devel/sound/enable", 0);

        # Wait a second for the engine sound to turn off
        var timer = maketimer(1, func () {
            me.unloadScenario();
        });
        timer.singleShot = 1;
        timer.start();
    },

    #
    # Unload scenario and start a new one
    #
    unloadScenario: func () {
        if (!me.scenario.unload()) {
            return;
        }

        # Start aerotow with delay to avoid duplicate engine sound playing
        var timer = maketimer(1, func () {
            me.startAerotow();
        });
        timer.singleShot = 1;
        timer.start();
    },

    #
    # Main function to prepare AI scenario and run it.
    #
    # Return 1 on successful, otherwise 0.
    #
    startAerotow: func () {
        if (!me.scenario.unload()) {
            return 0;
        }

        if (!me.scenario.generateXml()) {
            return 0;
        }

        return me.scenario.load();
    },

    #
    # Function for unload our AI scenario.
    #
    # Return 1 on successful, otherwise 0.
    #
    stopAerotow: func () {
        var withMessages = 1;
        return me.scenario.unload(withMessages);
    },
};

var g_Aerotow = nil;

#
# Initialize Aerotow
#
# addon - Addon object
#
var init = func (addon) {
    g_Aerotow = Aerotow.new(addon);
}

#
# Uninitialize Aerotow
#
var uninit = func () {
    if (g_Aerotow) {
        g_Aerotow.del();
    }
}
