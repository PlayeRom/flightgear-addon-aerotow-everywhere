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
# Class Waypoint represent the data of waypoint in the flight plan.
#
var Waypoint = {
    #
    # Constructor
    #
    # @return me
    #
    new: func() {
        var obj = { parents: [Waypoint] };

        obj.name      = nil; # Name of waypoint. Special names are: "WAIT", "END".
        obj.coord     = nil; # geo.Coord object
        obj.alt       = nil; # Altitude AMSL in feet
        obj.crossAt   = nil; # Altitude AMSL in feet
        obj.ktas      = nil; # True airspeed in knots
        obj.onGround  = nil; # If true then on the ground, otherwise in air
        obj.flapsDown = nil; # If true then flaps down, otherwise up
        obj.gearDown  = nil; # If true then gear down, otherwise up
        obj.waitSec   = nil; # Number of seconds for "WAIT" waypoint

        return obj;
    },

    #
    # Set name of waypoint
    #
    # @param string name - Name of waypoint
    # @return me
    #
    setName: func(name) {
        me.name = name;

        return me;
    },

    #
    # Set coordinates of waypoint
    #
    # @param hash coord - geo.Coord object
    # @return me
    #
    setCoord: func(coord) {
        me.coord = coord;

        return me;
    },

    #
    # Set altitude in feet of waypoint
    #
    # @param double alt - altitude in feet
    # @return me
    #
    setAlt: func(alt) {
        me.alt = alt;

        return me;
    },

    #
    # Set altitude in feet of waypoint as cross at
    #
    # @param double alt - altitude in feet
    # @return me
    #
    setCrossAt: func(crossAt) {
        me.crossAt = crossAt;

        return me;
    },

    #
    # Set true airspeed in knots for waypoint
    #
    # @param double ktas - true airspeed in knots
    # @return me
    #
    setKtas: func(ktas) {
        me.ktas = ktas;

        return me;
    },

    #
    # Set waypoint on the ground
    #
    # @return me
    #
    setOnGround: func() {
        me.onGround = true;

        return me;
    },

    #
    # Set flaps down
    #
    # @return me
    #
    setFlapsDown: func() {
        me.flapsDown = true;

        return me;
    },

    #
    # Set gear down
    #
    # @return me
    #
    setGearDown: func() {
        me.gearDown = true;

        return me;
    },

    #
    # Set number of seconds for WAIT waypoint. This force to use "WAIT" name.
    #
    # @param double waitSec - Number of seconds
    # @return me
    #
    setWaitSec: func(waitSec) {
        me.setName("WAIT"); # force WAIT name
        me.waitSec = waitSec;

        return me;
    },

    #
    # Set all waypoint data from given hash object
    #
    # @param hash wptData
    # @return me
    #
    setHashData: func(wptData) {
        if (wptData == nil) {
            return me;
        }

        if (contains(wptData, "name")) {
            me.setName(wptData.name);
        }

        if (contains(wptData, "coord")) {
            me.setCoord(wptData.coord);
        }

        if (contains(wptData, "crossAt")) {
            me.setCrossAt(wptData.crossAt);
        }

        if (contains(wptData, "alt")) {
            me.setAlt(wptData.alt);
        }

        if (contains(wptData, "ktas")) {
            me.setKtas(wptData.ktas);
        }

        if (contains(wptData, "onGround") and wptData.onGround) {
            me.setOnGround();
        }

        if (contains(wptData, "flapsDown") and wptData.flapsDown) {
            me.setFlapsDown();
        }

        if (contains(wptData, "gearDown") and wptData.gearDown) {
            me.setGearDown();
        }

        if (contains(wptData, "waitSec")) {
            me.setWaitSec(wptData.waitSec);
        }

        return me;
    },
};
