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
# Class for hande Route Dialog
#
var RouteDialog = {
    #
    # Constants
    #
    ROUTE_SAVES_DIR: "route-saves",

    #
    # Constructor
    #
    # addon - Addon object
    #
    new: func (addon, message) {
        var obj = { parents: [RouteDialog] };

        obj.addon = addon;
        obj.message = message;
        obj.addonNodePath = addon.node.getPath();

        obj.savePath = addon.storagePath ~ "/" ~ RouteDialog.ROUTE_SAVES_DIR;
        obj.maxRouteWaypoints = 10;
        obj.listeners = [];

        # Set listener for aerotow combo box value in route dialog for recalculate altitude change
        append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/route/ai-model", func () {
            obj.calculateAltChangeAndTotals();
        }));

        # Set listeners for distance fields for calculate altitude change
        for (var i = 0; i < obj.maxRouteWaypoints; i += 1) {
            append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/distance-m", func () {
                obj.calculateAltChangeAndTotals();
            }));
        }

        return obj;
    },

    #
    # Destructor
    #
    del: func () {
        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Calculate total distance and altitude and put in to property tree
    #
    calculateAltChangeAndTotals: func () {
        var totalDistance = 0.0;
        var totalAlt = 0.0;
        var isEnd = 0;

        var isRouteMode = 1;
        var aircraft = Aircraft.getSelected(me.addon, isRouteMode);

        for (var i = 0; i < me.maxRouteWaypoints; i += 1) {
            var distance = getprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/distance-m");
            if (distance == nil) {
                break;
            }

            var altChange = aircraft.getAltChange(distance);
            setprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/alt-change-agl-ft", altChange);

            if (!isEnd) {
                if (distance > 0.0) {
                    totalDistance += distance;
                    totalAlt += altChange;
                }
                else {
                    isEnd = 1;
                }
            }
        }

        setprop(me.addonNodePath ~ "/addon-devel/route/total/distance", totalDistance);
        setprop(me.addonNodePath ~ "/addon-devel/route/total/alt", totalAlt);
    },

    #
    # Save route with description to the XML file.
    #
    save: func () {
        me.openFileSelector(
            func (node) {
                var nodeSave = props.globals.getNode(me.addonNodePath ~ "/addon-devel/route/wpts");
                if (io.write_properties(node.getValue(), nodeSave)) {
                    me.message.success("The route has been saved");
                }
            },
            "Save route",
            "Save"
        );
    },

    #
    # Load route with description from the XML file.
    #
    load: func () {
        me.openFileSelector(
            func (node) {
                var nodeLoad = props.globals.getNode(me.addonNodePath ~ "/addon-devel/route/wpts");
                if (io.read_properties(node.getValue(), nodeLoad)) {
                    me.message.success("The route has been loaded");
                }
            },
            "Load route",
            "Load"
        );
    },

    #
    # Open file selector dialog for save/load XML file with route.
    #
    openFileSelector: func (callback, title, button) {
        var fileSelector = gui.FileSelector.new(callback, title, button, ["*.xml"], me.savePath, "route.xml");
        fileSelector.open();
    },
};
