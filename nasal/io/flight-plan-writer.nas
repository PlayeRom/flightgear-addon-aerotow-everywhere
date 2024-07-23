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
# Class FlightPlanWriter for write flight plan to the XML file
#
var FlightPlanWriter = {
    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @return me
    #
    new: func(addon) {
        var obj = { parents: [FlightPlanWriter] };

        obj.fpFileHandler = nil; # Handler for write flight plan to the file
        obj.flightPlanPath = addon.storagePath ~ "/AI/FlightPlans/" ~ FlightPlan.FILENAME_FLIGHTPLAN;
        obj.wptCount = 1;

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        me.close();
    },

    #
    # Open XML file to write flight plan
    #
    # @return void
    #
    open: func() {
        me.wptCount = 1;

        if (me.fpFileHandler) {
            io.close(me.fpFileHandler);
        }

        me.fpFileHandler = io.open(me.flightPlanPath, "w");

        if (me.fpFileHandler) {
            io.write(
                me.fpFileHandler,
                "<?xml version=\"1.0\"?>\n\n" ~
                "<!-- This file is generated automatically by the Aerotow Everywhere add-on -->\n\n" ~
                "<PropertyList>\n" ~
                "    <flightplan>\n"
            );
        }
    },

    #
    # Write single waypoint to XML file with flight plan
    #
    # @param hash wpt - Waypoint object
    # @return void
    #
    write: func(wpt) {
        if (!me.fpFileHandler) {
            return;
        }

        if (wpt.name == nil) {
            wpt.setName(me.wptCount);
        }

        var str = "        <wpt>\n"
                ~ "            <name>" ~ wpt.name ~ "</name>\n";

        if (wpt.coord != nil) {
            str ~= "            <lat>" ~ wpt.coord.lat() ~ "</lat>\n";
            str ~= "            <lon>" ~ wpt.coord.lon() ~ "</lon>\n";
            str ~= "            <!--\n"
                 ~ "                 " ~ wpt.coord.lat() ~ "," ~ wpt.coord.lon() ~ "\n"
                 ~ "            -->\n";
        }

        if (wpt.alt != nil) {
            str ~= "            <alt>" ~ wpt.alt ~ "</alt>\n";
        }

        if (wpt.crossAt != nil) {
            str ~= "            <crossat>" ~ wpt.crossAt ~ "</crossat>\n";
        }

        if (wpt.ktas != nil) {
            str ~= "            <ktas>" ~ wpt.ktas ~ "</ktas>\n";
        }

        if (wpt.onGround != nil) {
            str ~= "            <on-ground>" ~ (wpt.onGround ? "true" : "false") ~ "</on-ground>\n";
        }

        if (wpt.waitSec != nil) {
            str ~= "            <time-sec>" ~ wpt.waitSec ~ "</time-sec>\n";
        }

        if (wpt.flapsDown != nil) {
            str ~= "            <flaps-down>" ~ (wpt.flapsDown ? "true" : "false") ~ "</flaps-down>\n";
        }

        if (wpt.gearDown != nil) {
            str ~= "            <gear-down>" ~ (wpt.gearDown ? "true" : "false") ~ "</gear-down>\n";
        }

        str ~= "        </wpt>\n";

        io.write(me.fpFileHandler, str);

        me.wptCount += 1;
    },

    #
    # Close XML file with flight plan
    #
    # @return void
    #
    close: func() {
        if (me.fpFileHandler) {
            io.write(
                me.fpFileHandler,
                "    </flightplan>\n" ~
                "</PropertyList>\n\n"
            );

            io.close(me.fpFileHandler);
            me.fpFileHandler = nil;
        }
    },
};
