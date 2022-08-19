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
# Scenario object
#
var Scenario = {
    #
    # Constants
    #
    SCENARIO_ID:         "aerotow_addon",
    SCENARIO_NAME:       "Aerotow Add-on",
    SCENARIO_DESC:       "This scenario starts the towing plane at the airport where the pilot with the glider is located. Use Ctrl-o to hook the plane.",
    FILENAME_SCENARIO:   "aerotown-addon.xml",

    #
    # Constructor
    #
    # addon - Addon object
    # message - Message object
    #
    new: func (addon, message) {
        var obj = { parents: [Scenario] };

        obj.addon = addon;
        obj.message = message;

        obj.addonNodePath = addon.node.getPath();

        obj.listeners = [];
        obj.routeDialog = RouteDialog.new(addon);
        obj.flightPlan = FlightPlan.new(addon, message, obj.routeDialog);
        obj.isScenarioLoaded = 0;
        obj.scenarioPath = addon.storagePath ~ "/" ~ Scenario.FILENAME_SCENARIO;

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
    del: func () {
        me.routeDialog.del();

        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Generate the XML file with the AI scenario.
    # The file will be stored to $FG_HOME/Export/aerotown-addon.xml.
    #
    generateXml: func () {
        if (!me.flightPlan.generateXml()) {
            return 0;
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
                        "model":      Aircraft.getSelected(me.addon).modelPath,
                        "flightplan": FlightPlan.FILENAME_FLIGHTPLAN,
                        "repeat":     1,
                    }
                }
            }
        };

        var node = props.Node.new(scenarioXml);
        io.writexml(me.scenarioPath, node);

        me.addScenarioToPropertyList();

        return 1;
    },

    #
    # Add our new scenario to the "/sim/ai/scenarios" property list
    # so that FlightGear will be able to load it by "load-scenario" command.
    #
    addScenarioToPropertyList: func () {
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
    # Return 1 if scenario is already added to "/sim/ai/scenarios" property list, otherwise return 0.
    #
    isAlreadyAdded: func () {
        foreach (var scenario; props.globals.getNode("/sim/ai/scenarios").getChildren("scenario")) {
            var id = scenario.getChild("id");
            if (id != nil and id.getValue() == Scenario.SCENARIO_ID) {
                return 1;
            }
        }

        return 0;
    },

    #
    # Load scenario
    #
    # Return 1 on successful, otherwise 0.
    #
    load: func () {
        var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
        if (fgcommand("load-scenario", args)) {
            me.isScenarioLoaded = 1;
            me.message.success("Let's fly!");

            # Enable engine sound
            setprop(me.addonNodePath ~ "/addon-devel/sound/enable", 1);
            return 1;
        }

        me.message.error("Tow failed!");
        return 0;
    },

    #
    # Unload scenario
    #
    # withMessages - Set 1 to display messages.
    #
    # Return 1 on successful, otherwise 0.
    #
    unload: func (withMessages = 0) {
        if (me.isScenarioLoaded) {
            var args = props.Node.new({ "name": Scenario.SCENARIO_ID });
            if (fgcommand("unload-scenario", args)) {
                me.isScenarioLoaded = 0;

                if (withMessages) {
                    me.message.success("Aerotown disabled");
                }
                return 1;
            }

            if (withMessages) {
                me.message.error("Aerotown disable failed");
            }
            return 0;
        }

        if (withMessages) {
            me.message.success("Aerotown already disabled");
        }
        return 1;
    },
};
