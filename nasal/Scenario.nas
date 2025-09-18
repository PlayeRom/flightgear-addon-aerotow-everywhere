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
# Class Scenario for create AI scenario XML file and attach it to scenario property list for load it.
#
var Scenario = {
    #
    # Constants.
    #
    SCENARIO_ID      : "aerotow_addon",
    SCENARIO_NAME    : "Aerotow Add-on",
    SCENARIO_DESC    : "This scenario starts the towing plane at the airport where the pilot with the glider is located. Use Ctrl-o to hook the plane.",
    FILENAME_SCENARIO: "aerotow-addon.xml",

    #
    # Constructor
    #
    # @param  hash  message  Message object.
    # @return hash
    #
    new: func(message) {
        var me = {
            parents : [Scenario],
            _message: message,
        };

        me._addonNodePath = g_Addon.node.getPath();

        me._listeners = Listeners.new();
        me._routeDialog = RouteDialog.new(message);
        me._flightPlan = FlightPlan.new(message, me._routeDialog);
        me._isScenarioLoaded = false;
        me._scenarioPath = g_Addon.storagePath ~ "/" ~ Scenario.FILENAME_SCENARIO;

        me._flightPlan.initial();

        me._listeners.add("/sim/presets/longitude-deg", func () {
            # User change airport/runway
            me._flightPlan.initial();
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
        me._routeDialog.del();
        me._flightPlan.del();
    },

    #
    # Generate the XML file with the AI scenario.
    # The file will be stored to $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/aerotow-addon.xml.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    generateXml: func() {
        if (!me._flightPlan.generateXml()) {
            return false;
        }

        var scenarioXml = {
            "PropertyList": {
                "scenario": {
                    "name"       : Scenario.SCENARIO_NAME,
                    "description": Scenario.SCENARIO_DESC,
                    "entry": {
                        "callsign"  : "FG-TOW",
                        "type"      : "aircraft",
                        "class"     : "aerotow-dragger",
                        "model"     : Aircraft.getSelected().modelPath,
                        "flightplan": FlightPlan.FILENAME_FLIGHTPLAN,
                        "repeat"    : true, # start again indefinitely, it will work if the aircraft stops on the ground
                    }
                }
            }
        };

        var node = props.Node.new(scenarioXml);
        io.writexml(me._scenarioPath, node);

        me._addScenarioToPropertyList();

        return true;
    },

    #
    # Add our new scenario to the "/sim/ai/scenarios" property list
    # so that FlightGear will be able to load it by "load-scenario" command.
    #
    # @return void
    #
    _addScenarioToPropertyList: func() {
        if (!me._isAlreadyAdded()) {
            var scenarioData = {
                "name"       : Scenario.SCENARIO_NAME,
                "id"         : Scenario.SCENARIO_ID,
                "description": Scenario.SCENARIO_DESC,
                "path"       : me._scenarioPath,
            };

            props.globals.getNode("/sim/ai/scenarios").addChild("scenario").setValues(scenarioData);
        }
    },

    #
    # @return bool  Return true if scenario is already added to "/sim/ai/scenarios" property list, otherwise return false.
    #
    _isAlreadyAdded: func() {
        foreach (var scenario; props.globals.getNode("/sim/ai/scenarios").getChildren("scenario")) {
            var id = scenario.getChild("id");
            if (id != nil and id.getValue() == Scenario.SCENARIO_ID) {
                return true;
            }
        }

        return false;
    },

    #
    # Load scenario.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    load: func() {
        var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
        if (fgcommand("load-scenario", args)) {
            me._isScenarioLoaded = true;
            me._message.success("Let's fly!");

            # Enable engine sound
            setprop(me._addonNodePath ~ "/addon-devel/sound/enable", true);
            return true;
        }

        me._message.error("Tow failed!");
        return false;
    },

    #
    # Unload scenario.
    #
    # @param  bool  withMessages  Set true to display messages.
    # @return bool  Return true on successful, otherwise false.
    #
    unload: func(withMessages = false) {
        if (me._isScenarioLoaded) {
            var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
            if (fgcommand("unload-scenario", args)) {
                me._isScenarioLoaded = false;

                if (withMessages) {
                    me._message.success("Aerotow disabled");
                }
                return true;
            }

            if (withMessages) {
                me._message.error("Aerotow disable failed");
            }
            return false;
        }

        if (withMessages) {
            me._message.success("Aerotow already disabled");
        }
        return true;
    },
};
