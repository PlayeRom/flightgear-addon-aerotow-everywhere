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
# Parent class of Aircraft.
#
var Aircraft = {
    #
    # Constants
    #
    DISTANCE_DETERMINANT: 1000, # meters

    #
    # Constructor.
    #
    # @param  double  vs  Vertical speed in ft per DISTANCE_DETERMINANT m.
    # @param  double  seed  Take-off speed.
    # @param  double  speedLimit  Max speed.
    # @param  double  rolling  Factor for rolling.
    # @param  double  minRwyLength  Minimum runway length required, in meters.
    # @param  double  minFinalLegDist  Minimum distance for final leg in meters (for landing).
    # @param  string  name  Full name of aircraft used in route dialog.
    # @param  string  nameMenuCall  Short name of aircraft for call a plane from menu.
    # @param  string  modelPath  Path to the aircraft model.
    # @return hash
    #
    new: func(vs, speed, speedLimit, rolling, minRwyLength, minFinalLegDist, name, nameMenuCall, modelPath) {
        return {
            parents        : [Aircraft],
            vs             : vs,
            speed          : speed,
            speedLimit     : speedLimit,
            rolling        : rolling,
            minRwyLength   : minRwyLength,
            minFinalLegDist: minFinalLegDist,
            name           : name,
            nameMenuCall   : nameMenuCall,
            modelPath      : modelPath,
        };
    },

    #
    # Check that given name match to aircraft name.
    #
    # @param  string  name  Name of aircraft to check.
    # @return bool  Return true when match, otherwise false.
    #
    isModelName: func(name) {
        return name == me.name or name == me.nameMenuCall;
    },

    #
    # Return how much the altitude increases for a given vertical speed and distance.
    #
    # @param  double  distance  Distance in meters.
    # @return double
    #
    getAltChange: func(distance) {
        return me.vs * (distance / Aircraft.DISTANCE_DETERMINANT);
    },

    #
    # Return selected Aircraft object.
    #
    # @param  bool  isRouteMode  Use true to get the plane for the "Aerotow Route" dialog,
    #                            use false (default) for call the airplane for towing.
    # @return Aircraft
    #
    getSelected: func(isRouteMode = false) {
        var name = Aircraft._getSelectedAircraftName(isRouteMode);
        foreach (var aircraft; g_Aircraft) {
            if (aircraft.isModelName(name)) {
                return aircraft;
            }
        }

        # Fist as default
        return g_Aircraft[0];
    },

    #
    # Return name of selected aircraft. Possible values depend of isRouteMode: "Cub", "DR400", "c182".
    #
    #
    # @param  bool  isRouteMode  Use true to get the plane for the "Aerotow Route" dialog,
    #                            use false (default) for call the airplane for towing.
    # @return string
    #
    _getSelectedAircraftName: func(isRouteMode) {
        if (isRouteMode) {
            return getprop(g_Addon.node.getPath() ~ "/addon-devel/route/ai-model") or g_Aircraft[0].name;
        }

        return getprop(g_Addon.node.getPath() ~ "/addon-devel/ai-model") or g_Aircraft[0].nameMenuCall;
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
    # @return hash
    #
    new: func() {
        return {
            parents:         [Aircraft],
            vs:              200,
            speed:           55,
            speedLimit:      60,
            rolling:         1,
            minRwyLength:    280,
            minFinalLegDist: 5000,
            name:            "Piper J3 Cub",
            nameMenuCall:    "Cub",
            modelPath:       "Aircraft/Aerotow/Cub/Models/Cub-ai.xml",
        };
    },
};

#
# Robin DR 400
# Cruise Speed 134 kt
# Max speed 166 kt
# Stall speed 51 kt
# Rate of climb: 825 ft/min
#
var AircraftRobin = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents:         [Aircraft],
            vs:              285,
            speed:           70,
            speedLimit:      75,
            rolling:         2,
            minRwyLength:    470,
            minFinalLegDist: 5400,
            name:            "Robin DR400",
            nameMenuCall:    "DR400",
            modelPath:       "Aircraft/Aerotow/DR400/Models/dr400-ai.xml",
        };
    },
};

#
# Cessna 182
# Cruise Speed 145 kt
# Max speed 175 kt
# Stall speed 50 kt
# Best climb: 924 ft/min
#
var AircraftC182 = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents:         [Aircraft],
            vs:              295,
            speed:           75,
            speedLimit:      80,
            rolling:         2.2,
            minRwyLength:    508,
            minFinalLegDist: 5500,
            name:            "Cessna 182",
            nameMenuCall:    "c182",
            modelPath:       "Aircraft/Aerotow/c182/Models/c182-ai.xml",
        };
    },
};

#
# Douglas C-47
# Cruise Speed 152 kt
# Max speed 199 kt
# Stall speed 57 kt
# Best climb: 1052 ft/min
#
var AircraftC47 = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents:         [Aircraft],
            vs:              70,
            speed:           130,
            speedLimit:      160,
            rolling:         2.2,
            minRwyLength:    1100,
            minFinalLegDist: 6000,
            name:            "Douglas C-47",
            nameMenuCall:    "C47",
            modelPath:       "Aircraft/Aerotow/C-47/Models/c-47-ai.xml",
        };
    },
};

#
# Handley Page Halifax
# Cruise Speed 184 kt
# Max speed 224 kt
# Stall speed 57 kt ?
# Best climb: 750 ft/min
# Takeoff speed 1100-1400
#
var AircraftHalifax = {
    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        return {
            parents:         [Aircraft],
            vs:              70,
            speed:           160,
            speedLimit:      160,
            rolling:         2.2,
            minRwyLength:    1100,
            minFinalLegDist: 6000,
            name:            "Handley Page Halifax",
            nameMenuCall:    "Halifax",
            modelPath:       "Aircraft/Aerotow/Halifax/Models/halifax-ai.xml",
        };
    },
};

# Create Aircraft objects
var g_Aircraft = [
    AircraftCub.new(),
    AircraftRobin.new(),
    AircraftC182.new(),
    AircraftC47.new(),
    AircraftHalifax.new(),
];
