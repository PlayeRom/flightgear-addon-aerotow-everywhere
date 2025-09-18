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
# Class FlightPlan for crate and save as XML file the flight plan for AI scenario.
#
var FlightPlan = {
    #
    # Constants:
    #
    FILENAME_FLIGHTPLAN: "aerotow-addon-flightplan.xml",
    MAX_RUNWAY_DISTANCE: 100, # meters

    #
    # Constructor.
    #
    # @param  hash  message  Message object.
    # @param  hash  routeDialog  RouteDialog object.
    # @return hash
    #
    new: func(message, routeDialog) {
        var me = {
            parents     : [FlightPlan],
            _message    : message,
            _routeDialog: routeDialog,
        };

        me._flightPlanWriter = FlightPlanWriter.new();

        me._addonNodePath = g_Addon.node.getPath();

        me._coord    = nil; # Coordinates for flight plan
        me._heading  = nil; # AI plane heading
        me._altitude = nil; # AI plane altitude

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        me._flightPlanWriter.del();
    },

    #
    # Get initial location of glider.
    #
    # @return hash|nil  Return object with "lat", "lon" and "heading" or nil when failed.
    #
    _getLocation: func() {
        var icao = getprop("/sim/airport/closest-airport-id");
        if (icao == nil or icao == "") {
            me._message.error("Airport code cannot be obtained.");
            return nil;
        }

        # Find nearest runway threshold
        var airport = airportinfo(icao);
        if (airport == nil) {
            me._message.error("An airport with the code " ~ icao ~ " cannot be found.");
            return nil;
        }

        var gliderCoord = geo.aircraft_position();

        var rwyResult = me._findRunway(airport, gliderCoord);

        if (rwyResult.distance > FlightPlan.MAX_RUNWAY_DISTANCE) {
            # The runway is too far away, we assume a bush start
            return {
                "type"     : "bush",
                "lat"      : gliderCoord.lat(),
                "lon"      : gliderCoord.lon(),
                "heading"  : getprop("/orientation/heading-deg"),
                "elevation": me._getElevationInFt(gliderCoord),
            };
        }

        # We have a runway

        var minRwyLength = Aircraft.getSelected().minRwyLength;
        if (rwyResult.runway.length < minRwyLength) {
            me._message.error(
                "This runway is too short. Please choose a longer one than " ~ minRwyLength ~ " m "
                ~ "(" ~ math.round(minRwyLength * globals.M2FT) ~ " ft)."
            );
            return nil;
        }

        return {
            "type"     : "runway",
            "lat"      : rwyResult.runway.lat,
            "lon"      : rwyResult.runway.lon,
            "heading"  : rwyResult.runway.heading,
            "elevation": me._getElevationInFt(
                geo.Coord.new().set_latlon(rwyResult.runway.lat, rwyResult.runway.lon)
            ),
            "length"   : rwyResult.runway.length,
        };
    },

    #
    # Find nearest runway for given airport.
    #
    # @param  ghost  airport
    # @param  hash  gliderCoord  The geo.Coord object.
    # @return hash  Return hash with distance to nearest runway threshold and runway object itself.
    #
    _findRunway: func(airport, gliderCoord) {
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
    # Initialize flight plan and set it to property tree.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    initial: func() {
        var location = me._getLocation();
        if (location == nil) {
            return false;
        }

        var aircraft = Aircraft.getSelected();

        var isGliderPos = false;
        me._initAircraftVariable(location, isGliderPos);

        # Max altitude without limits
        setprop(me._addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl", 0);

        # initial readonly waypoint
        setprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/heading-change", me._heading);
        setprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/distance-m", 100);
        setprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/alt-change-agl-ft", aircraft.vs / 10);

        # in air
        var wptData = [
            {"hdgChange": 0,   "dist": 5000, "altChange": aircraft.vs * 5},
            {"hdgChange": -90, "dist": 1000, "altChange": aircraft.vs},
            {"hdgChange": -90, "dist": 6000, "altChange": aircraft.vs * 6},
            {"hdgChange": -90, "dist": 1500, "altChange": aircraft.vs * 1.5},
            {"hdgChange": -90, "dist": 6000, "altChange": aircraft.vs * 6},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
            {"hdgChange": 0,   "dist": 0,    "altChange": 0},
        ];

        # Default route
        # ^ - airport with heading direction to north
        # 1 - 1st waypoint
        # 2 - 2nd waypoint, etc.
        #
        #     2 . . 1   5
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     .   .
        #     .     ^   .
        #     .         .
        #     .         .
        #     3 . . . . 4

        var index = 0;
        foreach (var wpt; wptData) {
            setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/heading-change",    wpt.hdgChange);
            setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/distance-m",        wpt.dist);
            setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/alt-change-agl-ft", wpt.altChange);

            index += 1;
        }

        me._routeDialog.calculateAltChangeAndTotals();

        setprop(me._addonNodePath ~ "/addon-devel/route/wpts/description", "Default route around the start location");

        return true;
    },

    #
    # Generate the XML file with the flight plane for our plane for AI scenario.
    # The file will be stored to $FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/AI/FlightPlans/aerotow-addon-flightplan.xml.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    generateXml: func() {
        var location = me._getLocation();
        if (location == nil) {
            return false;
        }

        me._flightPlanWriter.open();

        var aircraft = Aircraft.getSelected();

        var isGliderPos = true;
        me._initAircraftVariable(location, isGliderPos);

        # Start at 2 o'clock from the glider...
        # Initial ktas must be >= 1.0
        me._addWptGround({"shift": {"hdgChange": 60, "dist": 25, "altChange": 0}, "ktas": 5}); # 1

        # Reset coord and heading
        isGliderPos = false;
        me._initAircraftVariable(location, isGliderPos);

        var gliderOffsetM = me._getGliderOffsetFromRunwayThreshold(location);

        # ... and line up with the runway
        me._addWptGround({"shift": {"hdgChange": 0, "dist": me._getInitialDistance() + gliderOffsetM, "altChange": 0}, "ktas": 2.5}); # 2

        # Rolling
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10,                    "altChange": 0}, "ktas": 5}); # 3
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 20,                    "altChange": 0}, "ktas": 5}); # 4
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 20,                    "altChange": 0}, "ktas": aircraft.speed / 6}); # 5
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10,                    "altChange": 0}, "ktas": aircraft.speed / 5}); # 6
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 4}); # 7
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 3.5}); # 8
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 3}); # 9
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 2.5}); # 10
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 2}); # 11
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 1.75}); # 12
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 1.5}); # 13
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed / 1.25}); # 14
        me._addWptGround({"shift": {"hdgChange": 0, "dist": 10 * aircraft.rolling, "altChange": 0}, "ktas": aircraft.speed}); # 15

        # Take-off
        me._addWptAir({   "shift": {"hdgChange": 0, "dist": 100 * aircraft.rolling, "elevation": 3}, "ktas": aircraft.speed * 1.05}); # 16
        me._addWptAir({   "shift": {"hdgChange": 0, "dist": 100,     "altChange": aircraft.vs / 10}, "ktas": aircraft.speed * 1.025}); # 17


        # 0 means without altitude limits
        var maxAltAgl = getprop(me._addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl") or 0;
        var totalAlt = 0.0;
        var isAltLimit = false;

        # Add waypoints according to user settings
        var speedInc = 1.0;
        foreach (var wptNode; props.globals.getNode(me._addonNodePath ~ "/addon-devel/route/wpts").getChildren("wpt")) {
            var distance = wptNode.getChild("distance-m").getValue();
            if (distance <= 0.0) {
                break;
            }

            var hdgChange = wptNode.getChild("heading-change").getValue();

            # If we have reached the altitude limit, the altitude no longer changes (0)
            var altChange = isAltLimit ? 0 : aircraft.getAltChange(distance);
            if (maxAltAgl > 0 and altChange > 0 and totalAlt + altChange > maxAltAgl) {
                # We will exceed the altitude limit, so set the altChange to the altitude limit
                # and set isAltLimit flag that the limit is reached.
                altChange = maxAltAgl - totalAlt;
                isAltLimit = true;
            }

            speedInc += ((distance / Aircraft.DISTANCE_DETERMINANT) * 0.025);
            var ktas = aircraft.speed * speedInc;
            if (ktas > aircraft.speedLimit) {
                ktas = aircraft.speedLimit;
            }

            totalAlt += altChange;

            me._addWptAir({"shift": {"hdgChange": hdgChange, "dist": distance, "altChange": altChange}, "ktas": ktas});
        }

        # Back to airport if possible
        if (location.type == "runway") {
            # Add extra near waypoint to keep plane in whole designed track
            me._addWptAir({"shift": {"hdgChange": hdgChange, "dist": 100, "altChange": altChange}, "ktas": ktas});

            var coordRwyThreshold = geo.Coord.new().set_latlon(location.lat, location.lon);

            # Check distance to runway threshold
            var distanceToThreshold = me._coord.distance_to(coordRwyThreshold);

            # Reset variables
            me._heading = location.heading; # runway heading
            me._coord = coordRwyThreshold;

            # Move to the left of the runway threshold
            me._heading = globals.geo.normdeg(me._heading - 90);
            me._coord.apply_course_distance(me._heading, 1000);

            # Add a waypoint to the left of the runway + 3000 m to the middle of length
            # Descend as far as you can to max elevation + 3000 ft
            var halfRwyLength = location.length / 2;
            var altAgl = me._altitude - location.elevation;
            var elevation = altAgl - (aircraft.getAltChange(distanceToThreshold) * 2);
            if (elevation < 3000) {
                elevation = 3000;
            }
            me._addWptAir({"shift": {"hdgChange": 90, "dist": halfRwyLength, "elevation": elevation}, "ktas": aircraft.speed});

            # Fly downwind away of threshold, how far depend of the altitude
            var desiredElevation = 1400;
            var distance = (((elevation - desiredElevation) / (aircraft.vs * 2)) * 1000);
            if (distance < aircraft.minFinalLegDist) {
                distance = aircraft.minFinalLegDist;
            }
            me._addWptAir({"shift": {"hdgChange": -180, "dist": halfRwyLength + distance, "elevation": desiredElevation}, "ktas": aircraft.speed});

            # Turn to base leg
            me._addWptAir({"shift": {"hdgChange": -90, "dist": 1000, "elevation": 1000}, "ktas": aircraft.speed, "flapsDown": true});

            # Reset variables
            me._coord = geo.Coord.new().set_latlon(location.lat, location.lon); # runway threshold

            # Turn on final
            me._addWptAir({
                "coord"    : me._coord,
                "crossAt"  : location.elevation + 10,
                "ktas"     : aircraft.speed * 0.75,
                "flapsDown": true,
                "gearDown" : true,
            });

            # Reset variables
            me._heading = location.heading;

            # Flare
            me._addWptAir({
                "shift"    : {"hdgChange": 0, "dist": 100, "elevation": 10},
                "ktas"     : aircraft.speed * 0.7,
                "flapsDown": true,
                "gearDown" : true,
            });

            # Touchdown
            me._addWptGround({"shift": {"hdgChange": 0, "dist": 200, "elevation": 0}, "ktas": aircraft.speed * 0.6});

            # Break
            me._addWptGround({"shift": {"hdgChange": 0, "dist": 200, "elevation": 0}, "ktas": aircraft.speed * 0.4});

            # Slow down to 5 kt
            me._addWptGround({"shift": {"hdgChange": 0, "dist": 50, "elevation": 0}, "ktas": 5});

            # Turn right out of runway and full stop
            me._addWptEnd({"shift": {"hdgChange": 90, "dist": 100, "elevation": 0}, "ktas": 0, "onGround": true});
        }
        else {
            me._addWptEnd();
        }

        me._flightPlanWriter.close();

        return true;
    },

    #
    # Get initial distance AI plane from the glider that the tow is nearly tautened.
    #
    # @return double  Return distance in meters.
    #
    _getInitialDistance: func() {
        var ropeLengthM = getprop("/sim/hitches/aerotow/tow/length") or 60;
        var tautenRelative = 0.68;
        return ropeLengthM * tautenRelative;
    },

    #
    # Initialize AI aircraft variable.
    #
    # @param  hash  location  Object of location from which the glider start.
    # @param  bool  isGliderPos  Pass true for set AI aircraft's coordinates as glider position,
    #                            false set coordinates as runway threshold.
    # @return void
    #
    _initAircraftVariable: func(location, isGliderPos) {
        var gliderCoord = geo.aircraft_position();

        # Set coordinates as glider position or runway threshold
        me._coord = isGliderPos
            ? gliderCoord
            : geo.Coord.new().set_latlon(location.lat, location.lon);

        # Set airplane heading as runway or glider heading
        me._heading = location.heading;

        # Set AI airplane altitude as glider altitude (assumed it's on the ground).
        # It is more accurate than airport.elevation.
        me._altitude = gliderCoord.alt() * globals.M2FT;
    },

    #
    # Get distance from glider to runway threshold e.g. in case that the user taxi from the runway threshold.
    #
    # @param  hash  location  Object of location from which the glider start.
    # @return double  Return the distance in metres, of the glider's displacement from the runway threshold.
    #
    _getGliderOffsetFromRunwayThreshold: func(location) {
        if (location.type == "runway") {
            var gliderCoord = geo.aircraft_position();
            var rwyThreshold = geo.Coord.new().set_latlon(location.lat, location.lon);

            return rwyThreshold.distance_to(gliderCoord);
        }

        # We are not on the runway, return 0 distance
        return 0;
    },

    #
    # Add new waypoint on ground.
    #
    # @param  hash  wptData  Object with waypoint data.
    # @return void
    #
    _addWptGround: func(wptData) {
        wptData.onGround = true;
        me._addWpt(wptData);
    },

    #
    # Add new waypoint in air.
    #
    # @param  hash  wptData  Object with waypoint data.
    # @return void
    #
    _addWptAir: func(wptData) {
        if (contains(wptData, "onGround")) {
            wptData.onGround = nil;
        }

        me._addWpt(wptData);
    },

    #
    # Add "WAIT" waypoint.
    #
    # @param  double  sec  Number of seconds for wait.
    # @return void
    #
    _addWptWait: func(sec) {
        me._addWpt({"waitSec": sec});
    },

    #
    # Add "END" waypoint with optional waypoint data
    #
    # @param  hash|nil  wptData  Object with waypoint data.
    # @return void
    #
    _addWptEnd: func(wptData = nil) {
        if (wptData == nil) {
            wptData = {};
        }

        wptData.name = "END";

        me._addWpt(wptData);
    },

    #
    # Add new waypoint with given waypoint data.
    #
    # @param hash wptData = {
    #     hash shift: { - Optionally hash with data to calculate next coordinates (lat, lon) and altitude of waypoint
    #         hdgChange - How the aircraft's heading supposed to change? 0 - keep the same heading.
    #         dist      - Distance in meters to calculate next waypoint coordinates.
    #         altChange - How the aircraft's altitude is supposed to change? 0 - keep the same altitude.
    #         elevation - Set aircraft altitude as current terrain elevation + given value in feet.
    #                     It's best to use for the first point in the air to avoid the plane collapsing into
    #                     the ground in a bumpy airport.
    #     },
    #     hash coord     - The geo.Coord object, required if shift is not given
    #     double crossAt - Altitude in feet, required if shift is not given
    #     double ktas    - True airspeed in knots, required
    #     bool onGround  - If true then set on ground, otherwise set in air
    #     bool flapsDown - If true then set flaps down, otherwise set flaps up
    #     bool gearDown  - If true then set gear down, otherwise set gear up
    #     double waitSec - Number of seconds for WIAT waypoint
    # }
    # @return void
    #
    _addWpt: func(wptData) {
        if (contains(wptData, "shift")) {
            me._shiftWpt(wptData.shift);

            # Set coord and crossAt updated by _shiftWpt()
            wptData.coord   = me._coord;
            wptData.crossAt = me._altitude;
        }

        var wpt = Waypoint.new().setHashData(wptData);

        me._flightPlanWriter.write(wpt);
    },

    #
    # Calculate heading, coordinates and altitude from data in wptShift hash.
    #
    # @param  hash  wptShift  Object with data.
    # @return void
    #
    _shiftWpt: func(wptShift) {
        if (!contains(wptShift, "hdgChange")) {
            die("ERROR aerotow add-on: missing 'hdgChange' for computeWptShift");
        }

        if (!contains(wptShift, "dist")) {
            die("ERROR aerotow add-on: missing 'dist' for computeWptShift");
        }

        # Shift heading and coordinates
        me._heading = globals.geo.normdeg(me._heading + wptShift.hdgChange);
        me._coord.apply_course_distance(me._heading, wptShift.dist);

        if (contains(wptShift, "elevation")) {
            # Set the altitude as the elevation for coordinates of the point plus the given elevation
            me._altitude = me._getElevationInFt(me._coord) + wptShift.elevation;
            return;
        }

        if (contains(wptShift, "altChange")) {
            # Change altitude by given altChange
            me._altitude += wptShift.altChange;
        }
    },

    #
    # Get elevation of given coordinates in feet.
    #
    # @param  hash  coord  The geo.Coord object.
    # @return double
    #
    _getElevationInFt: func(coord) {
        if (coord == nil) {
            return nil;
        }

        return geo.elevation(coord.lat(), coord.lon()) * globals.M2FT;
    },
};
