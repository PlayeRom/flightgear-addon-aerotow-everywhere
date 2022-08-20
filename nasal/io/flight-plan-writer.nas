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
# Object for write flight plan to the XML file
#
var FlightPlanWriter = {
    #
    # Constructor
    #
    # addon - Addon object
    #
    new: func (addon) {
        var obj = { parents: [FlightPlanWriter] };

        obj.fpFileHandler = nil; # Handler for wrire flight plan to file
        obj.flightPlanPath = addon.storagePath ~ "/AI/FlightPlans/" ~ FlightPlan.FILENAME_FLIGHTPLAN;

        return obj;
    },

    #
    # Open XML file to wrire flight plan
    #
    open: func () {
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
    # name - Name of waypoint. Special names are: "WAIT", "END".
    # coord - The Coord object
    # alt - Altitude AMSL of AI plane
    # ktas - True air speed of AI plane
    # groundAir - Allowe value: "ground or "air". The "ground" means that AI plane is on the ground, "air" - in air
    # sec - Number of seconds for "WAIT" waypoint
    #
    write: func (name, coord = nil, alt = nil, ktas = nil, groundAir = nil, sec = nil) {
        if (!me.fpFileHandler) {
            return;
        }

        var str = "        <wpt>\n"
                ~ "            <name>" ~ name ~ "</name>\n";

        if (coord != nil) {
            str ~= "            <lat>" ~ coord.lat() ~ "</lat>\n";
            str ~= "            <lon>" ~ coord.lon() ~ "</lon>\n";
            str ~= "            <!--\n"
                 ~ "                 " ~ coord.lat() ~ "," ~ coord.lon() ~ "\n"
                 ~ "            -->\n";
        }

        if (alt != nil) {
            # str ~= "            <alt>" ~ alt ~ "</alt>\n";
            str ~= "            <crossat>" ~ alt ~ "</crossat>\n";
        }

        if (ktas != nil) {
            str ~= "            <ktas>" ~ ktas ~ "</ktas>\n";
        }

        if (groundAir != nil) {
            var onGround = groundAir == "ground" ? "true" : "false";
            str ~= "            <on-ground>" ~ onGround ~ "</on-ground>\n";
        }

        if (sec != nil) {
            str ~= "            <time-sec>" ~ sec ~ "</time-sec>\n";
        }

        str ~= "        </wpt>\n";

        io.write(me.fpFileHandler, str);
    },

    #
    # Close XML file with flight plan
    #
    close: func () {
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
