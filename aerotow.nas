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
var addon = addons.getAddon("org.flightgear.addons.Aerotow");
var FILENAME_SCENARIO = "aerotown-addon.xml";
var FILENAME_FLIGHTPLAN = "aerotown-addon-flightplan.xml";
var PATH_SCENARIO = addon.storagePath ~ "/" ~ FILENAME_SCENARIO;
var PATH_FLIGHTPLAN = addon.storagePath ~ "/AI/FlightPlans/" ~ FILENAME_FLIGHTPLAN;
var SCENARIO_ID = "aerotow_addon";
var SCENARIO_NAME = "Aerotow Add-on";
var SCENARIO_DESC = "This scenario starts the towing plane at the airport where the pilot with the glider is located. Use Ctrl-o to hook the plane.";

#
# Global variables
#
var g_wptCount = 0;
var g_isScenarioLoaded = 0;
var g_fpFileHandler = nil; # Handler for wrire flight plan to file
var g_coord = nil; # Coordinates for flight plan
var g_heading = nil; # AI plane heading
var g_altitude = nil; # AI plane altitude

#
# Main function to prepare AI scenario and run it.
#
# Return 1 on successful, otherwise 0.
#
var startAerotow = func () {
    var args = props.Node.new({ "name": SCENARIO_ID });
    if (g_isScenarioLoaded) {
        fgcommand("unload-scenario", args);
    }

    generateScenarioXml();

    if (!generateFlightPlanXml()) {
        return 0;
    }

    if (fgcommand("load-scenario", args)) {
        g_isScenarioLoaded = 1;
        messages.displayOk("Let's fly!");
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
                    "model":      "Aircraft/Cub/Models/Cub-ai.xml", # default Cub
                    "flightplan": FILENAME_FLIGHTPLAN,
                    "repeat":     1,
                }
            }
        }
    };

    var aiModel = getSelectedAircraft();
    if (aiModel == "DR400") {
        scenarioXml.PropertyList.scenario.entry.model = "Aircraft/DR400/Models/dr400-ai.xml";
    }
    else if (aiModel == "c182") {
        scenarioXml.PropertyList.scenario.entry.model = "Aircraft/c182/Models/c182-ai.xml";
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
# Return name of selected aircraft. Possible values: "Cub", "DR400", "c182".
#
var getSelectedAircraft = func () {
    return getprop("/addons/by-id/org.flightgear.addons.Aerotow/addon-devel/ai-model") or "Cub";
}

#
# Generate the XML file with the flight plane for our plane for AI scenario.
# The file will be stored to $FG_HOME/Export/aerotown-addon-flightplan.xml.
#
# Return 1 on successful, otherwise 0.
#
var generateFlightPlanXml = func () {
    g_wptCount = 0;

    var icao = getprop("/sim/airport/closest-airport-id");
    if (icao == nil) {
        messages.displayError("Airport code cannot be obtained.");
        return 0;
    }

    var runwayName = getprop("/sim/atc/runway");
    if (runwayName == nil) {
        messages.displayError("Runway name cannot be obtained.");
        return 0;
    }

    var airport = airportinfo(icao);
    var runway = airport.runways[runwayName];

    var minRwyLength = getMinRunwayLength();
    if (runway.length < minRwyLength) {
        messages.displayError(
            "This runway is too short. Please choose a longer one than " ~ minRwyLength ~ " m "
            ~ "(" ~ math.round(minRwyLength * M2FT) ~ " ft)."
        );
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

    initAircraftVariable(airport, runway, 1);

    # Start at 2 o'clock from the glider...
    # Inital ktas must be >= 1.0
    addWptGround({"hdgChange": 60, "dist": 25}, {"altChange": 0, "ktas": 5});

    # Reset coord and heading
    initAircraftVariable(airport, runway, 0);

    var gliderOffsetM = getGliderOffsetFromRunwayThreshold(runway);

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
    addWptAir({"hdgChange": 0,   "dist": 100 * perf.rolling}, {"altChange": 3, "ktas": perf.speed * 1.05});
    addWptAir({"hdgChange": 0,   "dist": 100}, {"altChange": perf.vs / 10, "ktas": perf.speed * 1.025});

    # Circle around airport
    addWptAir({"hdgChange": 0,   "dist": 500},  {"altChange": perf.vs / 1.5, "ktas": perf.speed});
    addWptAir({"hdgChange": 0,   "dist": 500},  {"altChange": perf.vs / 1.7, "ktas": perf.speed});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.025});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.05});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.075});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.1});
    addWptAir({"hdgChange": -90, "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.125}); # crosswind leg
    addWptAir({"hdgChange": -90, "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.15}); # downwind leg
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.175});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.2});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.225});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.25});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.275});
    addWptAir({"hdgChange": -90, "dist": 500},  {"altChange": perf.vs / 2,   "ktas": perf.speed * 1.25}); # base leg
    addWptAir({"hdgChange": 0,   "dist": 500},  {"altChange": perf.vs / 2,   "ktas": perf.speed * 1.275});
    addWptAir({"hdgChange": 0,   "dist": 500},  {"altChange": perf.vs / 2,   "ktas": perf.speed * 1.3});
    addWptAir({"hdgChange": -90, "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.3}); # final leg
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.325});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.35});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.375});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.4});
    addWptAir({"hdgChange": 0,   "dist": 1000}, {"altChange": perf.vs,       "ktas": perf.speed * 1.425});

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
var getAircraftPerformance = func () {
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

    var aiModel = getSelectedAircraft();
    if (aiModel == "DR400") {
        return {
            "vs":      285, # ft per 1000 m
            "speed":   70,
            "rolling": 2,
        };
    }
    
    if (aiModel == "c182") {
        return {
            "vs":      295, # ft per 1000 m
            "speed":   75,
            "rolling": 2.2,
        };
    }

    # Cub
    return {
        "vs":      200, # ft per 1000 m
        "speed":   55,
        "rolling": 1,
    };
}

#
# Initialize AI aircraft variable
#
# isGliderPos - Pass 1 for set AI aircraft's coordinates as glider position, 0 set coordinates as runway threshold.
# airport - Object from airportinfo().
# runway - Object of runway from which the glider start.
#
var initAircraftVariable = func (airport, runway, isGliderPos = 1) {
    var gliderCood = geo.aircraft_position();

    # Set coordinates as glider position or runway threshold
    g_coord = isGliderPos 
        ? gliderCood
        : geo.Coord.new().set_latlon(runway.lat, runway.lon);

    # Set airplane heading as runway heading
    g_heading = runway.heading;

    # Set airplane altitude as airport elevation
    g_altitude = gliderCood.alt() * M2FT;
}

#
# Get distance from glider to runway threshold
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
    wrireWpt("WAIT", {"hdgChange": nil, "dist": nil}, {"altChange": nil, "ktas": nil}, nil, sec);
}

#
# Add "END" waypoint
#
var addWptEnd = func () {
    wrireWpt("END", {"hdgChange": nil, "dist": nil}, {"altChange": nil, "ktas": nil});
}

#
# Write waipoint to flight plan file
#
# name - The name of waypoint
# coordOffset.hdgChange - How the aircraft's heading supposed to change?
# coordOffset.dist - Distance in meters to calculate next waypoint coordinates
# performance.altChange - How the aircraft's altitude is supposed to change?
# performance.ktas - True air speed of AI plane at the waypoint
# groundAir - Allowe value: "ground or "air". The "ground" means that AI plane is on the ground, "air" - in air
# sec - Number of seconds for "WAIT" waypoint
#
var wrireWpt = func (
    name,
    coordOffset,
    performance,
    groundAir = nil,
    sec = nil
) {
    var localCoord = nil;
    if (coordOffset.hdgChange != nil and coordOffset.dist != nil) {
        g_heading = g_heading + coordOffset.hdgChange;
        if (g_heading < 0) {
            g_heading = 360 + g_heading;
        }

        if (g_heading > 360) {
            g_heading = g_heading - 360;
        }

        g_coord.apply_course_distance(g_heading, coordOffset.dist);
        localCoord = g_coord;
    }

    var localAlt = nil;
    if (performance.altChange != nil) {
        g_altitude = g_altitude + performance.altChange;
        localAlt = g_altitude;
    }

    name = name == nil ? g_wptCount : name;
    var data = getWptString(
        name,
        localCoord,
        localAlt,
        performance.ktas,
        groundAir,
        sec
    );

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
