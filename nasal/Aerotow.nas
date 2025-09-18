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
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [Aerotow] };

        me._addonNodePath = g_Addon.node.getPath();
        me._listeners = Listeners.new();

        me._message  = Message.new();
        me._thermal  = Thermal.new(me._message);
        me._scenario = Scenario.new(me._message);

        # Listener for ai-model property triggered when the user select a tow aircraft from add-on menu
        me._listeners.add(me._addonNodePath ~ "/addon-devel/ai-model", func () {
            me._restartAerotow();
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
        me._thermal.del();
        me._scenario.del();
    },

    #
    # Function for restart AI scenario with delay when the sound has to stop.
    #
    # @return void
    #
    _restartAerotow: func() {
        me._message.success("Aerotow on the way");

        # Stop playing engine sound
        setprop(me._addonNodePath ~ "/addon-devel/sound/enable", false);

        # Wait a second for the engine sound to turn off
        Timer.singleShot(1, me, func () {
            me._unloadScenario();
        });
    },

    #
    # Unload scenario and start a new one.
    #
    # @return void
    #
    _unloadScenario: func() {
        if (!me._scenario.unload()) {
            return;
        }

        # Start aerotow with delay to avoid duplicate engine sound playing
        Timer.singleShot(1, me, func () {
            me._startAerotow();
        });
    },

    #
    # Main function to prepare AI scenario and run it.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    _startAerotow: func() {
        if (!me._scenario.unload()) {
            return false;
        }

        if (!me._scenario.generateXml()) {
            return false;
        }

        return me._scenario.load();
    },

    #
    # Function for unload our AI scenario.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    stopAerotow: func() {
        var withMessages = true;
        return me._scenario.unload(withMessages);
    },
};
