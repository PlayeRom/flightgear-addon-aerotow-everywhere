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
# Flight Plan object
#
var FlightPlan = {
    #
    # Constants
    #
    FILENAME_FLIGHTPLAN: "aerotown-addon-flightplan.xml",
    MAX_RUNWAY_DISTANCE: 100, # meters

    #
    # Constructor
    #
    # addon - Addon object
    # message - Message object
    # routeDialog - RouteDialog object
    #
    new: func (addon, message, routeDialog) {
        var obj = { parents: [FlightPlan] };

        obj.addon            = addon;
        obj.message          = message;
        obj.routeDialog      = routeDialog;
        obj.flightPlanWriter = FlightPlanWriter.new(addon);

        obj.addonNodePath = addon.node.getPath();

        obj.wptCount      = 0;
        obj.coord         = nil; # Coordinates for flight plan
        obj.heading       = nil; # AI plane heading
        obj.altitude      = nil; # AI plane altitude

        return obj;
    },

    #
    # Get inital location of glider.
    #
    # Return object with "lat", "lon" and 'heading".
    #
    getLocation: func () {
        var icao = getprop("/sim/airport/closest-airport-id");
        if (icao == nil or icao == "") {
            me.message.error("Airport code cannot be obtained.");
            return nil;
        }

        # Find nearest runway threshold
        var airport = airportinfo(icao);
        if (airport == nil) {
            me.message.error("An airport with the code " ~ icao ~ " cannot be found.");
            return nil;
        }

        var gliderCoord = geo.aircraft_position();

        var rwyResult = me.findRunway(airport, gliderCoord);

        if (rwyResult.distance > FlightPlan.MAX_RUNWAY_DISTANCE) {
            # The runway is too far away, we assume a bush start
            return {
                "type"    : "bush",
                "lat"     : gliderCoord.lat(),
                "lon"     : gliderCoord.lon(),
                "heading" : getprop("/orientation/heading-deg"),
            };
        }

        # We have a runway

        var minRwyLength = Aircraft.getSelected(me.addon).minRwyLength;
        if (rwyResult.runway.length < minRwyLength) {
            me.message.error(
                "This runway is too short. Please choose a longer one than " ~ minRwyLength ~ " m "
                ~ "(" ~ math.round(minRwyLength * globals.M2FT) ~ " ft)."
            );
            return nil;
        }

        return {
            "type"    : "runway",
            "lat"     : rwyResult.runway.lat,
            "lon"     : rwyResult.runway.lon,
            "heading" : rwyResult.runway.heading,
        }
    },

    #
    # Find nearest runway for given airport
    #
    # Return hash with distance to nearest runway threshold and runway object itself.
    #
    findRunway: func (airport, gliderCoord) {
        var result = {
            "runway"   : nil,
            "distance" : 999999999,
        };

        foreach (var runwayName; keys(airport.runways)) {
            var runway = airport.runways[runwayName];
            var rwyThreshold = geo.Coord.new().set_latlon(runway.lat, runway.lon);

            var distanceToThreshold = rwyThreshold.distance_to(gliderCoord);
            if (distanceToThreshold < result.distance) {
                result.runway = runway;
                result.distance = distanceToThreshold;
            }
        }

        return result;
    },

    #
    # Initialize flight plan and set it to property tree
    #
    # Return 1 on successful, otherwise 0.
    #
    initial: func () {
        var location = me.getLocation();
        if (location == nil) {
            return 0;
        }

        var aircraft = Aircraft.getSelected(me.addon);

        var isGliderPos = 0;
        me.initAircraftVariable(location, isGliderPos);

        # inittial readonly waypoint
        setprop(me.addonNodePath ~ "/addon-devel/route/init-wpt/heading-change", me.heading);
        setprop(me.addonNodePath ~ "/addon-devel/route/init-wpt/distance-m", 100);
        setprop(me.addonNodePath ~ "/addon-devel/route/init-wpt/alt-change-agl-ft", aircraft.vs / 10);

        # in air
        var wptData = [
            {"hdgChange": 0,   "dist": 5000, "altChange": aircraft.vs * 5},
            {"hdgChange": -90, "dist": 1000, "altChange": aircraft.vs},
            {"hdgChange": -90, "dist": 1000, "altChange": aircraft.vs},
            {"hdgChange": 0,   "dist": 5000, "altChange": aircraft.vs * 5},
            {"hdgChange": -90, "dist": 1500, "altChange": aircraft.vs * 1.5},
            {"hdgChange": -90, "dist": 1000, "altChange": aircraft.vs},
            {"hdgChange": 0,   "dist": 5000, "altChange": aircraft.vs * 5},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
        ];

        # Default route
        # ^ - airport with heading direction to north
        # 1 - 1st waypoint
        # 2 - 2nd waypoint, etc.
        #
        #     2 . . 1   7
        #     .     .   .
        #     .     .   .
        #     3     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     ^   6
        #     .         .
        #     .         .
        #     4 . . . . 5

        var index = 0;
        foreach (var wpt; wptData) {
            setprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/heading-change",    wpt.hdgChange);
            setprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/distance-m",        wpt.dist);
            setprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/alt-change-agl-ft", wpt.altChange);

            index += 1;
        }

        me.routeDialog.calculateAltChangeAndTotals();

        setprop(me.addonNodePath ~ "/addon-devel/route/wpts/description", "Default route around the start location");

        return 1;
    },

    #
    # Generate the XML file with the flight plane for our plane for AI scenario.
    # The file will be stored to $Fobj.HOME/Export/aerotown-addon-flightplan.xml.
    #
    # Return 1 on successful, otherwise 0.
    #
    generateXml: func () {
        me.wptCount = 0;

        var location = me.getLocation();
        if (location == nil) {
            return 0;
        }

        me.flightPlanWriter.open();

        var aircraft = Aircraft.getSelected(me.addon);

        var isGliderPos = 1;
        me.initAircraftVariable(location, isGliderPos);

        # Start at 2 o'clock from the glider...
        # Inital ktas must be >= 1.0
        me.addWptGround({"hdgChange": 60, "dist": 25}, {"altChange": 0, "ktas": 5});

        # Reset coord and heading
        isGliderPos = 0;
        me.initAircraftVariable(location, isGliderPos);

        var gliderOffsetM = me.getGliderOffsetFromRunwayThreshold(location);

        # ... and line up with the runway
        me.addWptGround({"hdgChange": 0, "dist": 30 + gliderOffsetM}, {"altChange": 0, "ktas": 2.5});

        # Rolling
        me.addWptGround({"hdgChange": 0, "dist": 10}, {"altChange": 0, "ktas": 5});
        me.addWptGround({"hdgChange": 0, "dist": 20}, {"altChange": 0, "ktas": 5});
        me.addWptGround({"hdgChange": 0, "dist": 20}, {"altChange": 0, "ktas": aircraft.speed / 6});
        me.addWptGround({"hdgChange": 0, "dist": 10}, {"altChange": 0, "ktas": aircraft.speed / 5});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 4});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 3.5});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 3});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 2.5});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 2});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 1.75});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 1.5});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed / 1.25});
        me.addWptGround({"hdgChange": 0, "dist": 10 * aircraft.rolling}, {"altChange": 0, "ktas": aircraft.speed});

        # Take-off
        me.addWptAir({"hdgChange": 0,   "dist": 100 * aircraft.rolling}, {"elevationPlus": 3, "ktas": aircraft.speed * 1.05});
        me.addWptAir({"hdgChange": 0,   "dist": 100}, {"altChange": aircraft.vs / 10, "ktas": aircraft.speed * 1.025});

        var speedInc = 1.0;
        foreach (var wptNode; props.globals.getNode(me.addonNodePath ~ "/addon-devel/route/wpts").getChildren("wpt")) {
            var dist = wptNode.getChild("distance-m").getValue();
            if (dist <= 0.0) {
                break;
            }

            var hdgChange = wptNode.getChild("heading-change").getValue();
            var altChange = aircraft.getAltChange(dist);

            speedInc += ((dist / Aircraft.DISTANCE_DETERMINANT) * 0.025);
            var ktas = aircraft.speed * speedInc;
            if (ktas > aircraft.speedLimit) {
                ktas = aircraft.speedLimit;
            }

            me.addWptAir({"hdgChange": hdgChange, "dist": dist}, {"altChange": altChange, "ktas": ktas});
        }

        me.addWptEnd();

        me.flightPlanWriter.close();

        return 1;
    },

    #
    # Initialize AI aircraft variable
    #
    # location - Object of location from which the glider start.
    # isGliderPos - Pass 1 for set AI aircraft's coordinates as glider position, 0 set coordinates as runway threshold.
    #
    initAircraftVariable: func (location, isGliderPos = 1) {
        var gliderCoord = geo.aircraft_position();

        # Set coordinates as glider position or runway threshold
        me.coord = isGliderPos
            ? gliderCoord
            : geo.Coord.new().set_latlon(location.lat, location.lon);

        # Set airplane heading as runway or glider heading
        me.heading = location.heading;

        # Set AI airplane altitude as glider altitude (assumed it's on the ground).
        # It is more accurate than airport.elevation.
        me.altitude = gliderCoord.alt() * globals.M2FT;
    },

    #
    # Get distance from glider to runway threshold e.g. in case that the user taxi from the runway threshold
    #
    # location - Object of location from which the glider start.
    # Return the distance in metres, of the glider's displacement from the runway threshold.
    #
    getGliderOffsetFromRunwayThreshold: func (location) {
        if (location.type == "runway") {
            var gliderCoord = geo.aircraft_position();
            var rwyThreshold = geo.Coord.new().set_latlon(location.lat, location.lon);

            return rwyThreshold.distance_to(gliderCoord);
        }

        # We are not on runway
        return 0;
    },

    #
    # Add new waypoint on ground
    #
    # coordOffset - Hash for calculate next coordinates (lat, lon), with following fields:
    # {
    #     hdgChange - How the aircraft's heading supposed to change? 0 - keep the same heading.
    #     dis - Distance in meters to calculate next waypoint coordinates.
    # }
    # performance - Hash with following fields:
    # {
    #     altChange - How the aircraft's altitude is supposed to change? 0 - keep the same altitude.
    #     ktas - True air speed of AI plane at the waypoint.
    # }
    #
    addWptGround: func (coordOffset, performance) {
        me.wrireWpt(nil, coordOffset, performance, "ground");
    },

    #
    # Add new waypoint in air
    #
    addWptAir: func (coordOffset, performance) {
        me.wrireWpt(nil, coordOffset, performance, "air");
    },

    #
    # Add "WAIT" waypoint
    #
    # sec - Number of seconds for wait
    #
    addWptWait: func (sec) {
        me.wrireWpt("WAIT", {}, {}, nil, sec);
    },

    #
    # Add "END" waypoint
    #
    addWptEnd: func () {
        me.wrireWpt("END", {}, {});
    },

    #
    # Write waypoint to flight plan file
    #
    # name - The name of waypoint
    # coordOffset.hdgChange - How the aircraft's heading supposed to change?
    # coordOffset.dist - Distance in meters to calculate next waypoint coordinates
    # performance.altChange - How the aircraft's altitude is supposed to change?
    # performance.elevationPlus - Set aircraft altitude as current terrain elevation + given value in feets.
    #                             It's best to use for the first point in the air to avoid the plane collapsing into
    #                             the ground in a bumpy airport
    # performance.ktas - True air speed of AI plane at the waypoint
    # groundAir - Allowed value: "ground or "air". The "ground" means that AI plane is on the ground, "air" - in air
    # sec - Number of seconds for "WAIT" waypoint
    #
    wrireWpt: func (
        name,
        coordOffset,
        performance,
        groundAir = nil,
        sec = nil
    ) {
        var coord = nil;
        if (contains(coordOffset, "hdgChange") and contains(coordOffset, "dist")) {
            me.heading += coordOffset.hdgChange;
            if (me.heading < 0) {
                me.heading += 360;
            }

            if (me.heading > 360) {
                me.heading -= 360;
            }

            me.coord.apply_course_distance(me.heading, coordOffset.dist);
            coord = me.coord;
        }

        var alt = nil;
        if (coord != nil and contains(performance, "elevationPlus")) {
            var elevation = geo.elevation(coord.lat(), coord.lon());
            me.altitude = elevation == nil
                ? me.altitude + performance.elevationPlus
                : elevation * globals.M2FT + performance.elevationPlus;
            alt = me.altitude;
        }
        else if (contains(performance, "altChange")) {
            me.altitude += performance.altChange;
            alt = me.altitude;
        }

        var ktas = contains(performance, "ktas") ? performance.ktas : nil;

        name = name == nil ? me.wptCount : name;
        me.flightPlanWriter.write(name, coord, alt, ktas, groundAir, sec);

        me.wptCount += 1;
    },
};
