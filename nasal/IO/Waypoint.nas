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
    # Constructor.
    #
    # @return me
    #
    new: func() {
        var me = { parents: [Waypoint] };

        me.name      = nil; # Name of waypoint. Special names are: "WAIT", "END".
        me.coord     = nil; # geo.Coord object
        me.alt       = nil; # Altitude AMSL in feet
        me.crossAt   = nil; # Altitude AMSL in feet
        me.ktas      = nil; # True airspeed in knots
        me.onGround  = nil; # If true then on the ground, otherwise in air
        me.flapsDown = nil; # If true then flaps down, otherwise up
        me.gearDown  = nil; # If true then gear down, otherwise up
        me.waitSec   = nil; # Number of seconds for "WAIT" waypoint

        return me;
    },

    #
    # Set name of waypoint.
    #
    # @param  string  name  Name of waypoint.
    # @return me
    #
    setName: func(name) {
        me.name = name;

        return me;
    },

    #
    # Set coordinates of waypoint.
    #
    # @param  hash coord  The geo.Coord object.
    # @return me
    #
    _setCoord: func(coord) {
        me.coord = coord;

        return me;
    },

    #
    # Set altitude in feet of waypoint
    #
    # @param  double  alt  Altitude in feet.
    # @return me
    #
    _setAlt: func(alt) {
        me.alt = alt;

        return me;
    },

    #
    # Set altitude in feet of waypoint as cross at.
    #
    # @param  double  alt  Altitude in feet.
    # @return me
    #
    setCrossAt: func(crossAt) {
        me.crossAt = crossAt;

        return me;
    },

    #
    # Set true airspeed in knots for waypoint.
    #
    # @param  double  ktas  True airspeed in knots.
    # @return me
    #
    _setKtas: func(ktas) {
        me.ktas = ktas;

        return me;
    },

    #
    # Set waypoint on the ground.
    #
    # @return me
    #
    _setOnGround: func() {
        me.onGround = true;

        return me;
    },

    #
    # Set flaps down.
    #
    # @return me
    #
    _setFlapsDown: func() {
        me.flapsDown = true;

        return me;
    },

    #
    # Set gear down.
    #
    # @return me
    #
    _setGearDown: func() {
        me.gearDown = true;

        return me;
    },

    #
    # Set number of seconds for WAIT waypoint. This force to use "WAIT" name.
    #
    # @param  double  waitSec  Number of seconds.
    # @return me
    #
    _setWaitSec: func(waitSec) {
        me.setName("WAIT"); # force WAIT name
        me.waitSec = waitSec;

        return me;
    },

    #
    # Set all waypoint data from given hash object.
    #
    # @param  hash  wptData
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
            me._setCoord(wptData.coord);
        }

        if (contains(wptData, "crossAt")) {
            me.setCrossAt(wptData.crossAt);
        }

        if (contains(wptData, "alt")) {
            me._setAlt(wptData.alt);
        }

        if (contains(wptData, "ktas")) {
            me._setKtas(wptData.ktas);
        }

        if (contains(wptData, "onGround") and wptData.onGround) {
            me._setOnGround();
        }

        if (contains(wptData, "flapsDown") and wptData.flapsDown) {
            me._setFlapsDown();
        }

        if (contains(wptData, "gearDown") and wptData.gearDown) {
            me._setGearDown();
        }

        if (contains(wptData, "waitSec")) {
            me._setWaitSec(wptData.waitSec);
        }

        return me;
    },
};
