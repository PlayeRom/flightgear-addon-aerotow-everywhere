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
# Constants
#
var ADDON = addons.getAddon("org.flightgear.addons.Aerotow");
var ADDON_NODE_PATH = ADDON.node.getPath();
var FILENAME_SCENARIO = "aerotown-addon.xml";
var FILENAME_FLIGHTPLAN = "aerotown-addon-flightplan.xml";
var PATH_SCENARIO = ADDON.storagePath ~ "/" ~ FILENAME_SCENARIO;
var PATH_FLIGHTPLAN = ADDON.storagePath ~ "/AI/FlightPlans/" ~ FILENAME_FLIGHTPLAN;
var SCENARIO_ID = "aerotow_addon";
var SCENARIO_NAME = "Aerotow Add-on";
var SCENARIO_DESC = "This scenario starts the towing plane at the airport where the pilot with the glider is located. Use Ctrl-o to hook the plane.";
var MAX_ROUTE_WAYPOINT = 10;
var DISTANCE_DETERMINANT = 1000; # meters

#
# Global variables
#
var g_wptCount = 0;
var g_isScenarioLoaded = 0;
var g_fpFileHandler = nil; # Handler for wrire flight plan to file
var g_coord = nil; # Coordinates for flight plan
var g_heading = nil; # AI plane heading
var g_altitude = nil; # AI plane altitude
var g_towListeners = [];

#
# Initialize thermal module
#
var init = func () {
    # Listener for ai-model property triggered when the user select a tow aircraft from add-on menu
    append(g_towListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/ai-model", func () {
        restartAerotow();
    }));

    append(g_towListeners, setlistener("/sim/presets/longitude-deg", func () {
        # User change airport/runway
        initialFlightPlan();
    }));

    initialFlightPlan();

    # Set listener for aerotow combo box value in route dialog for recalculate altitude change
    append(g_towListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/route/ai-model", func () {
        calculateAltChangeAndTotals();
    }));

    # Set listeners for distance fields for calculate altitude change
    for (var i = 0; i < MAX_ROUTE_WAYPOINT; i = i + 1) {
        append(g_towListeners, setlistener(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ i ~ "]/distance-m", func (node) {
            calculateAltChangeAndTotals();
        }));
    }
}

#
# Calculate total distance and altitude and put in to property tree
#
var calculateAltChangeAndTotals = func () {
    var totalDistance = 0.0;
    var totalAlt = 0.0;
    var isEnd = 0;

    var isRouteMode = 1;
    var perf = getAircraftPerformance(isRouteMode);

    for (var i = 0; i < MAX_ROUTE_WAYPOINT; i = i + 1) {
        var distance = getprop(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ i ~ "]/distance-m");
        var altChange = getAltChange(perf.vs, distance);
        setprop(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ i ~ "]/alt-change-agl-ft", altChange);

        if (!isEnd) {
            if (distance > 0.0) {
                totalDistance = totalDistance + distance;
                totalAlt = totalAlt + altChange;
            }
            else {
                isEnd = 1;
            }
        }
    }

    setprop(ADDON_NODE_PATH ~ "/addon-devel/route/total/distance", totalDistance);
    setprop(ADDON_NODE_PATH ~ "/addon-devel/route/total/alt", totalAlt);
}

#
# Uninitialize thermal module
#
var uninit = func () {
    foreach (var listener; g_towListeners) {
        removelistener(listener);
    }
}

#
# Function for restart AI scenario with delay when the sound has to stop.
#
# Return 1 on successful, otherwise 0.
#
var restartAerotow = func () {
    messages.displayOk("Aerotow in the way");

    # Stop playing engine sound
    setprop(ADDON_NODE_PATH ~ "/addon-devel/sound/enable", 0);

    # Wait a second for the engine sound to turn off
    var timer = maketimer(1, func () {
        unloadScenario();
    });
    timer.singleShot = 1;
    timer.start();
}

#
# Unload scenario and start a new one
#
var unloadScenario = func () {
    if (g_isScenarioLoaded) {
        var args = props.Node.new({ "name": SCENARIO_ID });
        if (fgcommand("unload-scenario", args)) {
            g_isScenarioLoaded = 0;
        }
    }

    # Start aerotow with delay to avoid duplicate engine sound playing
    var timer = maketimer(1, func () {
        startAerotow();
    });
    timer.singleShot = 1;
    timer.start();
}

#
# Main function to prepare AI scenario and run it.
#
# Return 1 on successful, otherwise 0.
#
var startAerotow = func () {
    var args = props.Node.new({ "name": SCENARIO_ID });

    if (g_isScenarioLoaded) {
        if (fgcommand("unload-scenario", args)) {
            g_isScenarioLoaded = 0;
        }
    }

    generateScenarioXml();

    if (!generateFlightPlanXml()) {
        return 0;
    }

    if (fgcommand("load-scenario", args)) {
        g_isScenarioLoaded = 1;
        messages.displayOk("Let's fly!");

        setprop(ADDON_NODE_PATH ~ "/addon-devel/sound/enable", 1);
        return 1;
    }

    messages.displayError("Tow failed!");
    return 0;
}

#
# Function for unload our AI scenario.
#
# Return 1 on successful, otherwise 0.
#
var stopAerotow = func () {
    if (g_isScenarioLoaded) {
        var args = props.Node.new({ "name": SCENARIO_ID });
        if (fgcommand("unload-scenario", args)) {
            g_isScenarioLoaded = 0;

            messages.displayOk("Aerotown disabled");
            return 1;
        }

        messages.displayError("Aerotown disable failed");
        return 0;
    }

    messages.displayOk("Aerotown already disabled");
    return 1
}

#
# Generate the XML file with the AI scenario.
# The file will be stored to $FG_HOME/Export/aerotown-addon.xml.
#
var generateScenarioXml = func () {
    var scenarioXml = {
        "PropertyList": {
            "scenario": {
                "name": SCENARIO_NAME,
                "description": SCENARIO_DESC,
                "entry": {
                    "callsign":   "FG-TOW",
                    "type":       "aircraft",
                    "class":      "aerotow-dragger",
                    "model":      "Aircraft/Aerotow/Cub/Models/Cub-ai.xml", # default Cub
                    "flightplan": FILENAME_FLIGHTPLAN,
                    "repeat":     1,
                }
            }
        }
    };

    var aiModel = getSelectedAircraft();
    if (aiModel == "DR400") {
        scenarioXml.PropertyList.scenario.entry.model = "Aircraft/Aerotow/DR400/Models/dr400-ai.xml";
    }
    else if (aiModel == "c182") {
        scenarioXml.PropertyList.scenario.entry.model = "Aircraft/Aerotow/c182/Models/c182-ai.xml";
    }

    var node = props.Node.new(scenarioXml);
    io.writexml(PATH_SCENARIO, node);

    addScenarioToPropertyList();
}

#
# Add our new scenario to the "/sim/ai/scenarios" property list
# so that FlightGear will be able to load it by "load-scenario" command.
#
var addScenarioToPropertyList = func () {
    if (!isScenarioAdded()) {
        var scenarioData = {
            "name":        SCENARIO_NAME,
            "id":          SCENARIO_ID,
            "description": SCENARIO_DESC,
            "path":        PATH_SCENARIO,
        };

        props.globals.getNode("/sim/ai/scenarios").addChild("scenario").setValues(scenarioData);
    }
}

#
# Return 1 if scenario is already added to "/sim/ai/scenarios" property list, otherwise return 0.
#
var isScenarioAdded = func () {
    foreach (var scenario; props.globals.getNode("/sim/ai/scenarios").getChildren("scenario")) {
        var id = scenario.getChild("id");
        if (id != nil and id.getValue() == SCENARIO_ID) {
            return 1;
        }
    }

    return 0;
}

#
# Return name of selected aircraft. Possible values depend of isRouteMode: "Cub", "DR400", "c182".
#
# isRouteMode - use 1 to get the plane for the "Aerotow Route" dialog, use 0 (default) for call the airplane for towing
#
var getSelectedAircraft = func (isRouteMode = 0) {
    if (isRouteMode) {
        return getprop(ADDON_NODE_PATH ~ "/addon-devel/route/ai-model") or "Piper J3 Cub";
    }

    return getprop(ADDON_NODE_PATH ~ "/addon-devel/ai-model") or "Cub";
}

#
# Get airport an runway hash where the glider is located.
#
# Return hash with "airport" and "runway", otherwise nil.
#
var getAirportAndRunway = func () {
    var icao = getprop("/sim/airport/closest-airport-id");
    if (icao == nil) {
        messages.displayError("Airport code cannot be obtained.");
        return nil;
    }

    var runwayName = getprop("/sim/atc/runway");
    if (runwayName == nil) {
        messages.displayError("Runway name cannot be obtained.");
        return nil;
    }

    var airport = airportinfo(icao);

    if (!contains(airport.runways, runwayName)) {
        messages.displayError("The " ~ icao ~" airport does not have runway " ~ runwayName);
        return nil;
    }

    var runway = airport.runways[runwayName];

    var minRwyLength = getMinRunwayLength();
    if (runway.length < minRwyLength) {
        messages.displayError(
            "This runway is too short. Please choose a longer one than " ~ minRwyLength ~ " m "
            ~ "(" ~ math.round(minRwyLength * globals.M2FT) ~ " ft)."
        );
        return nil;
    }

    return {
        "airport": airport,
        "runway": runway,
    };
}

#
# Initialize flight plan and set it to property tree
#
# Return 1 on successful, otherwise 0.
#
var initialFlightPlan = func () {
    var location = getAirportAndRunway();
    if (location == nil) {
        return 0;
    }

    var perf = getAircraftPerformance();

    initAircraftVariable(location.airport, location.runway, 0);

    # inittial readonly waypoint
    setprop(ADDON_NODE_PATH ~ "/addon-devel/route/init-wpt/heading-change", g_heading);
    setprop(ADDON_NODE_PATH ~ "/addon-devel/route/init-wpt/distance-m", 100);
    setprop(ADDON_NODE_PATH ~ "/addon-devel/route/init-wpt/alt-change-agl-ft", perf.vs / 10);

    # in air
    var wptData = [
        {"hdgChange": 0,   "dist": 5000, "altChange": perf.vs * 5},
        {"hdgChange": -90, "dist": 1000, "altChange": perf.vs},
        {"hdgChange": -90, "dist": 1000, "altChange": perf.vs},
        {"hdgChange": 0,   "dist": 5000, "altChange": perf.vs * 5},
        {"hdgChange": -90, "dist": 1500, "altChange": perf.vs * 1.5},
        {"hdgChange": -90, "dist": 1000, "altChange": perf.vs},
        {"hdgChange": 0,   "dist": 5000, "altChange": perf.vs * 5},
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
        setprop(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ index ~ "]/heading-change",    wpt.hdgChange);
        setprop(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ index ~ "]/distance-m",        wpt.dist);
        setprop(ADDON_NODE_PATH ~ "/addon-devel/route/wpt[" ~ index ~ "]/alt-change-agl-ft", wpt.altChange);

        index = index + 1;
    }

    calculateAltChangeAndTotals();

    return 1;
}

#
# Generate the XML file with the flight plane for our plane for AI scenario.
# The file will be stored to $FG_HOME/Export/aerotown-addon-flightplan.xml.
#
# Return 1 on successful, otherwise 0.
#
var generateFlightPlanXml = func () {
    g_wptCount = 0;

    var location = getAirportAndRunway();
    if (location == nil) {
        return 0;
    }

    g_fpFileHandler = io.open(PATH_FLIGHTPLAN, "w");
    io.write(
        g_fpFileHandler,
        "<?xml version=\"1.0\"?>\n\n" ~
        "<!-- This file is generated automatically by the Aerotow Everywhere add-on -->\n\n" ~
        "<PropertyList>\n" ~
        "    <flightplan>\n"
    );

    var perf = getAircraftPerformance();

    initAircraftVariable(location.airport, location.runway, 1);

    # Start at 2 o'clock from the glider...
    # Inital ktas must be >= 1.0
    addWptGround({"hdgChange": 60, "dist": 25}, {"altChange": 0, "ktas": 5});

    # Reset coord and heading
    initAircraftVariable(location.airport, location.runway, 0);

    var gliderOffsetM = getGliderOffsetFromRunwayThreshold(location.runway);

    # ... and line up with the runway
    addWptGround({"hdgChange": 0, "dist": 30 + gliderOffsetM}, {"altChange": 0, "ktas": 2.5});

    # Rolling
    addWptGround({"hdgChange": 0, "dist": 10}, {"altChange": 0, "ktas": 5});
    addWptGround({"hdgChange": 0, "dist": 20}, {"altChange": 0, "ktas": 5});
    addWptGround({"hdgChange": 0, "dist": 20}, {"altChange": 0, "ktas": perf.speed / 6});
    addWptGround({"hdgChange": 0, "dist": 10}, {"altChange": 0, "ktas": perf.speed / 5});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 4});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 3.5});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 3});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 2.5});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 2});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 1.75});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 1.5});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed / 1.25});
    addWptGround({"hdgChange": 0, "dist": 10 * perf.rolling}, {"altChange": 0, "ktas": perf.speed});

    # Takeof
    addWptAir({"hdgChange": 0,   "dist": 100 * perf.rolling}, {"elevationPlus": 3, "ktas": perf.speed * 1.05});
    addWptAir({"hdgChange": 0,   "dist": 100}, {"altChange": perf.vs / 10, "ktas": perf.speed * 1.025});

    var speedInc = 1.0;
    foreach (var wptNode; props.globals.getNode(ADDON_NODE_PATH ~ "/addon-devel/route").getChildren("wpt")) {
        var dist = wptNode.getChild("distance-m").getValue();
        if (dist <= 0.0) {
            break;
        }

        var hdgChange = wptNode.getChild("heading-change").getValue();
        var altChange = getAltChange(perf.vs, dist);

        speedInc = speedInc + ((dist / DISTANCE_DETERMINANT) * 0.025);
        var ktas = perf.speed * speedInc;
        if (ktas > perf.speedLimit) {
            ktas = perf.speedLimit;
        }

        addWptAir({"hdgChange": hdgChange, "dist": dist}, {"altChange": altChange, "ktas": ktas});
    }

    addWptEnd();

    io.write(
        g_fpFileHandler,
        "    </flightplan>\n" ~
        "</PropertyList>\n\n"
    );
    io.close(g_fpFileHandler);

    return 1;
}

#
# Return hash with "vs", "speed", "rolling".
#
var getAircraftPerformance = func (isRouteMode = 0) {
    # Cub
    # Cruise Speed 61 kt
    # Max Speed 106 kt
    # Approach speed 44-52 kt
    # Stall speed 33 kt

    # Robin DR 400
    # Cruise Speed 134 kt
    # Max speeed 166 kt
    # Stall speed 51 kt
    # Rate of climb: 825 ft/min

    # Cessna 182
    # Cruise Speed 145 kt
    # Max speeed 175 kt
    # Stall speed 50 kt
    # Best climb: 924 ft/min

    var aiModel = getSelectedAircraft(isRouteMode);
    if (aiModel == "DR400" or aiModel == "Robin DR400") {
        return {
            "vs":         285, # ft per DISTANCE_DETERMINANT m
            "speed":      70,
            "speedLimit": 75,
            "rolling":    2,
        };
    }

    if (aiModel == "c182" or aiModel == "Cessna 182") {
        return {
            "vs":         295, # ft per DISTANCE_DETERMINANT m
            "speed":      75,
            "speedLimit": 80,
            "rolling":    2.2,
        };
    }

    # Cub
    return {
        "vs":         200, # ft per DISTANCE_DETERMINANT m
        "speed":      55,
        "speedLimit": 60,
        "rolling":    1,
    };
}

#
# Return how much the altitide increases for a given vertical speed and distance
#
# vs - vertical speed for DISTANCE_DETERMINANT m
# distance - distance in meters
#
var getAltChange = func (vs, distance) {
    return vs * (distance / DISTANCE_DETERMINANT);
}

#
# Initialize AI aircraft variable
#
# airport - Object from airportinfo().
# runway - Object of runway from which the glider start.
# isGliderPos - Pass 1 for set AI aircraft's coordinates as glider position, 0 set coordinates as runway threshold.
#
var initAircraftVariable = func (airport, runway, isGliderPos = 1) {
    var gliderCoord = geo.aircraft_position();

    # Set coordinates as glider position or runway threshold
    g_coord = isGliderPos
        ? gliderCoord
        : geo.Coord.new().set_latlon(runway.lat, runway.lon);

    # Set airplane heading as runway heading
    g_heading = runway.heading;

    # Set AI airplane altitude as glider altitude (assumed it's on the ground).
    # It is more accurate than airport.elevation.
    g_altitude = gliderCoord.alt() * globals.M2FT;
}

#
# Get distance from glider to runway threshold e.g. in case that the user taxi from the runway threshold
#
# runway - Object of runway from which the glider start
# Return the distance in metres, of the glider's displacement from the runway threshold.
#
var getGliderOffsetFromRunwayThreshold = func (runway) {
    var gliderCoord = geo.aircraft_position();
    var rwyThreshold = geo.Coord.new().set_latlon(runway.lat, runway.lon);

    return rwyThreshold.distance_to(gliderCoord);
}

#
# Get the minimum runway length required, in meters
#
var getMinRunwayLength = func () {
    var aiModel = getSelectedAircraft();
    if (aiModel == "DR400") {
        return 470;
    }

    if (aiModel == "c182") {
        return 508;
    }

    return 280;
}

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
var addWptGround = func (coordOffset, performance) {
    wrireWpt(nil, coordOffset, performance, "ground");
}

#
# Add new waypoint in air
#
var addWptAir = func (coordOffset, performance) {
    wrireWpt(nil, coordOffset, performance, "air");
}

#
# Add "WAIT" waypoint
#
# sec - Number of seconds for wait
#
var addWptWait = func (sec) {
    wrireWpt("WAIT", {}, {}, nil, sec);
}

#
# Add "END" waypoint
#
var addWptEnd = func () {
    wrireWpt("END", {}, {});
}

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
var wrireWpt = func (
    name,
    coordOffset,
    performance,
    groundAir = nil,
    sec = nil
) {
    var coord = nil;
    if (contains(coordOffset, "hdgChange") and contains(coordOffset, "dist")) {
        g_heading = g_heading + coordOffset.hdgChange;
        if (g_heading < 0) {
            g_heading = 360 + g_heading;
        }

        if (g_heading > 360) {
            g_heading = g_heading - 360;
        }

        g_coord.apply_course_distance(g_heading, coordOffset.dist);
        coord = g_coord;
    }

    var alt = nil;
    if (coord != nil and contains(performance, "elevationPlus")) {
        var elevation = geo.elevation(coord.lat(), coord.lon());
        if (elevation == nil) {
            g_altitude = g_altitude + performance.elevationPlus;
        }
        else {
            g_altitude = elevation * globals.M2FT + performance.elevationPlus;
        }
        alt = g_altitude;
    }
    else if (contains(performance, "altChange")) {
        g_altitude = g_altitude + performance.altChange;
        alt = g_altitude;
    }

    var ktas = contains(performance, "ktas") ? performance.ktas : nil;

    name = name == nil ? g_wptCount : name;
    var data = getWptString(name, coord, alt, ktas, groundAir, sec);

    io.write(g_fpFileHandler, data);

    g_wptCount = g_wptCount + 1;
}

#
# Get single waypoint data as a string.
#
# name - Name of waypoint. Special names are: "WAIT", "END".
# coord - The Coord object
# alt - Altitude AMSL of AI plane
# ktas - True air speed of AI plane
# groundAir - Allowe value: "ground or "air". The "ground" means that AI plane is on the ground, "air" - in air
# sec - Number of seconds for "WAIT" waypoint
#
var getWptString = func (name, coord = nil, alt = nil, ktas = nil, groundAir = nil, sec = nil) {
    var str = "        <wpt>\n"
            ~ "            <name>" ~ name ~ "</name>\n";

    if (coord != nil) {
        str = str ~ "            <lat>" ~ coord.lat() ~ "</lat>\n";
        str = str ~ "            <lon>" ~ coord.lon() ~ "</lon>\n";
        str = str ~ "            <!-- " ~ coord.lat() ~ "," ~ coord.lon() ~ " -->\n";
    }

    if (alt != nil) {
        # str = str ~ "            <alt>" ~ alt ~ "</alt>\n";
        str = str ~ "            <crossat>" ~ alt ~ "</crossat>\n";
    }

    if (ktas != nil) {
        str = str ~ "            <ktas>" ~ ktas ~ "</ktas>\n";
    }

    if (groundAir != nil) {
        var onGround = groundAir == "ground" ? "true" : "false";
        str = str ~ "            <on-ground>" ~ onGround ~ "</on-ground>\n";
    }

    if (sec != nil) {
        str = str ~ "            <time-sec>" ~ sec ~ "</time-sec>\n";
    }

    return str ~ "        </wpt>\n";
}
