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
# Parent class of Aircraft
#
var Aircraft = {
    #
    # Constants
    #
    DISTANCE_DETERMINANT: 1000, # meters

    #
    # Constructor
    #
    # vs - vertical speed in ft per DISTANCE_DETERMINANT m
    # seed - take-off speed
    # speedLimit - max speed
    # rolling - factor for rolling
    # minRwyLength - minimum runway length required, in meters
    # name - full name of aircraft used in route dialog
    # nameMenuCall - short name of aircraft for call a plane from menu
    # modelPath - Path to the aircraft model
    #
    new: func (vs, speed, speedLimit, rolling, minRwyLength, name, nameMenuCall, modelPath) {
        var obj = { parents: [Aircraft] };

        obj.vs           = vs;
        obj.speed        = speed;
        obj.speedLimit   = speedLimit;
        obj.rolling      = rolling;
        obj.minRwyLength = minRwyLength;
        obj.name         = name;
        obj.nameMenuCall = nameMenuCall;
        obj.modelPath    = modelPath;

        return obj;
    },

    #
    # Check that given name match to aircraft name
    #
    # name - Name of aircraft to check.
    #
    # Return 1 when match, otherwise 0.
    #
    isModelName: func (name) {
        return name == me.name or name == me.nameMenuCall;
    },

    #
    # Return how much the altitide increases for a given vertical speed and distance
    #
    # distance - distance in meters
    #
    getAltChange: func (distance) {
        return me.vs * (distance / Aircraft.DISTANCE_DETERMINANT);
    },

    #
    # Return selected Aircraft object
    #
    # addon - Addon object
    # isRouteMode - Use 1 to get the plane for the "Aerotow Route" dialog,
    #               use 0 (default) for call the airplane for towing.
    #
    getSelected: func (addon, isRouteMode = 0) {
        var name = Aircraft.getSelectedAircraftName(addon, isRouteMode);
        foreach (var aircraft; g_Aircrafts) {
            if (aircraft.isModelName(name)) {
                return aircraft;
            }
        }

        # Fist as default
        return g_Aircrafts[0];
    },

    #
    # Return name of selected aircraft. Possible values depend of isRouteMode: "Cub", "DR400", "c182".
    #
    #
    # addon - Addon object
    # isRouteMode - Use 1 to get the plane for the "Aerotow Route" dialog,
    #               use 0 (default) for call the airplane for towing.
    #
    getSelectedAircraftName: func (addon, isRouteMode = 0) {
        if (isRouteMode) {
            return getprop(addon.node.getPath() ~ "/addon-devel/route/ai-model") or g_Aircrafts[0].name;
        }

        return getprop(addon.node.getPath() ~ "/addon-devel/ai-model") or g_Aircrafts[0].nameMenuCall;
    },
};

#
# Cub
# Cruise Speed 61 kt
# Max Speed 106 kt
# Approach speed 44-52 kt
# Stall speed 33 kt
#
var AircraftCub = {
    #
    # Constructor
    #
    new: func () {
        return {
            parents:      [Aircraft],
            vs:           200,
            speed:        55,
            speedLimit:   60,
            rolling:      1,
            minRwyLength: 280,
            name:         "Piper J3 Cub",
            nameMenuCall: "Cub",
            modelPath:    "Aircraft/Aerotow/Cub/Models/Cub-ai.xml",
        };
    },
};

#
# Robin DR 400
# Cruise Speed 134 kt
# Max speeed 166 kt
# Stall speed 51 kt
# Rate of climb: 825 ft/min
#
var AircraftRobin = {
    #
    # Constructor
    #
    new: func () {
        return {
            parents:      [Aircraft],
            vs:           285,
            speed:        70,
            speedLimit:   75,
            rolling:      2,
            minRwyLength: 470,
            name:         "Robin DR400",
            nameMenuCall: "DR400",
            modelPath:    "Aircraft/Aerotow/DR400/Models/dr400-ai.xml",
        };
    },
};

#
# Cessna 182
# Cruise Speed 145 kt
# Max speeed 175 kt
# Stall speed 50 kt
# Best climb: 924 ft/min
#
var AircraftC182 = {
    new: func () {
        return {
            parents:      [Aircraft],
            vs:           295,
            speed:        75,
            speedLimit:   80,
            rolling:      2.2,
            minRwyLength: 508,
            name:         "Cessna 182",
            nameMenuCall: "c182",
            modelPath:    "Aircraft/Aerotow/c182/Models/c182-ai.xml",
        };
    },
};

#
# Douglas C-47
# Cruise Speed 152 kt
# Max speeed 199 kt
# Stall speed 57 kt
# Best climb: 1052 ft/min
#
var AircraftC47 = {
    new: func () {
        return {
            parents:      [Aircraft],
            vs:           310,
            speed:        85,
            speedLimit:   90,
            rolling:      2.2,
            minRwyLength: 508,
            name:         "Douglas C-47",
            nameMenuCall: "C47",
            modelPath:    "Aircraft/Aerotow/C-47/Models/c-47-ai.xml",
        };
    },
};

# Create Aircraft objects
var g_Aircrafts = [
    AircraftCub.new(),
    AircraftRobin.new(),
    AircraftC182.new(),
    AircraftC47.new(),
];
