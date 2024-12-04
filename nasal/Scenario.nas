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
    # Constants
    #
    SCENARIO_ID:       "aerotow_addon",
    SCENARIO_NAME:     "Aerotow Add-on",
    SCENARIO_DESC:     "This scenario starts the towing plane at the airport where the pilot with the glider is located. Use Ctrl-o to hook the plane.",
    FILENAME_SCENARIO: "aerotow-addon.xml",

    #
    # Constructor
    #
    # @param hash message - Message object
    # @return me
    #
    new: func(message) {
        var obj = { parents: [Scenario] };

        obj.message = message;

        obj.addonNodePath = g_Addon.node.getPath();

        obj.listeners = [];
        obj.routeDialog = RouteDialog.new(message);
        obj.flightPlan = FlightPlan.new(message, obj.routeDialog);
        obj.isScenarioLoaded = false;
        obj.scenarioPath = g_Addon.storagePath ~ "/" ~ Scenario.FILENAME_SCENARIO;

        obj.flightPlan.initial();

        append(obj.listeners, setlistener("/sim/presets/longitude-deg", func () {
            # User change airport/runway
            obj.flightPlan.initial();
        }));

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.routeDialog.del();
        me.flightPlan.del();

        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Generate the XML file with the AI scenario.
    # The file will be stored to $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/aerotow-addon.xml.
    #
    # @return bool - Return true on successful, otherwise false
    #
    generateXml: func() {
        if (!me.flightPlan.generateXml()) {
            return false;
        }

        var scenarioXml = {
            "PropertyList": {
                "scenario": {
                    "name": Scenario.SCENARIO_NAME,
                    "description": Scenario.SCENARIO_DESC,
                    "entry": {
                        "callsign":   "FG-TOW",
                        "type":       "aircraft",
                        "class":      "aerotow-dragger",
                        "model":      Aircraft.getSelected().modelPath,
                        "flightplan": FlightPlan.FILENAME_FLIGHTPLAN,
                        "repeat":     true, # start again indefinitely, it will work if the aircraft stops on the ground
                    }
                }
            }
        };

        var node = props.Node.new(scenarioXml);
        io.writexml(me.scenarioPath, node);

        me.addScenarioToPropertyList();

        return true;
    },

    #
    # Add our new scenario to the "/sim/ai/scenarios" property list
    # so that FlightGear will be able to load it by "load-scenario" command.
    #
    # @return void
    #
    addScenarioToPropertyList: func() {
        if (!me.isAlreadyAdded()) {
            var scenarioData = {
                "name":        Scenario.SCENARIO_NAME,
                "id":          Scenario.SCENARIO_ID,
                "description": Scenario.SCENARIO_DESC,
                "path":        me.scenarioPath,
            };

            props.globals.getNode("/sim/ai/scenarios").addChild("scenario").setValues(scenarioData);
        }
    },

    #
    # @return bool - Return true if scenario is already added to "/sim/ai/scenarios" property list, otherwise return false.
    #
    isAlreadyAdded: func() {
        foreach (var scenario; props.globals.getNode("/sim/ai/scenarios").getChildren("scenario")) {
            var id = scenario.getChild("id");
            if (id != nil and id.getValue() == Scenario.SCENARIO_ID) {
                return true;
            }
        }

        return false;
    },

    #
    # Load scenario
    #
    # @return bool - Return true on successful, otherwise false.
    #
    load: func() {
        var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
        if (fgcommand("load-scenario", args)) {
            me.isScenarioLoaded = true;
            me.message.success("Let's fly!");

            # Enable engine sound
            setprop(me.addonNodePath ~ "/addon-devel/sound/enable", true);
            return true;
        }

        me.message.error("Tow failed!");
        return false;
    },

    #
    # Unload scenario
    #
    # @param bool withMessages - Set true to display messages.
    # @return bool - Return true on successful, otherwise false.
    #
    unload: func(withMessages = false) {
        if (me.isScenarioLoaded) {
            var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
            if (fgcommand("unload-scenario", args)) {
                me.isScenarioLoaded = false;

                if (withMessages) {
                    me.message.success("Aerotow disabled");
                }
                return true;
            }

            if (withMessages) {
                me.message.error("Aerotow disable failed");
            }
            return false;
        }

        if (withMessages) {
            me.message.success("Aerotow already disabled");
        }
        return true;
    },
};
