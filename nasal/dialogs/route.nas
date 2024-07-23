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
# Class for handle Route Dialog
#
var RouteDialog = {
    #
    # Constants
    #
    ROUTE_SAVES_DIR: "route-saves",
    MAX_ROUTE_WAYPOINTS: 10,

    #
    # Constructor
    #
    # @param hash addon - addons.Addon object
    # @param hash message - Message object
    # @return me
    #
    new: func(addon, message) {
        var obj = { parents: [RouteDialog] };

        obj.addon = addon;
        obj.message = message;
        obj.addonNodePath = addon.node.getPath();

        obj.savePath = addon.storagePath ~ "/" ~ RouteDialog.ROUTE_SAVES_DIR;
        obj.listeners = [];

        # Set listener for aerotow combo box value in route dialog for recalculate altitude change
        append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/route/ai-model", func () {
            obj.calculateAltChangeAndTotals();
        }));

        # Set listener for Max altitude AGL value in route dialog for recalculate altitude change
        append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl", func () {
            obj.calculateAltChangeAndTotals();
        }));

        # Set listeners for distance fields for calculate altitude change
        for (var i = 0; i < RouteDialog.MAX_ROUTE_WAYPOINTS; i += 1) {
            append(obj.listeners, setlistener(obj.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/distance-m", func () {
                obj.calculateAltChangeAndTotals();
            }));
        }

        return obj;
    },

    #
    # Destructor
    #
    # @return void
    #
    del: func() {
        foreach (var listener; me.listeners) {
            removelistener(listener);
        }
    },

    #
    # Calculate total distance and altitude and put in to property tree
    #
    # @return void
    #
    calculateAltChangeAndTotals: func() {
        var totalDistance = 0.0;
        var totalAlt = 0.0;
        var isEnd = false;
        var isAltLimit = false;

        var isRouteMode = true;
        var aircraft = Aircraft.getSelected(me.addon, isRouteMode);

        # 0 means without altitude limits
        var maxAltAgl = getprop(me.addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl") or 0;

        for (var i = 0; i < RouteDialog.MAX_ROUTE_WAYPOINTS; i += 1) {
            var distance = getprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/distance-m") or 0;

            # If we have reached the altitude limit, the altitude no longer changes (0)
            var altChange = isAltLimit ? 0 : aircraft.getAltChange(distance);
            if (maxAltAgl > 0 and altChange > 0 and totalAlt + altChange > maxAltAgl) {
                # We will exceed the altitude limit, so set the altChange to the altitude limit
                # and set isAltLimit flag that the limit is reached.
                altChange = maxAltAgl - totalAlt;
                isAltLimit = true;
            }

            setprop(me.addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/alt-change-agl-ft", altChange);

            if (!isEnd) {
                if (distance > 0.0) {
                    totalDistance += distance;
                    totalAlt += altChange;
                }
                else {
                    isEnd = true;
                }
            }
        }

        setprop(me.addonNodePath ~ "/addon-devel/route/total/distance", totalDistance);
        setprop(me.addonNodePath ~ "/addon-devel/route/total/alt", totalAlt);
    },

    #
    # Save route with description to the XML file.
    #
    # @return void
    #
    save: func() {
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
    # @return void
    #
    load: func() {
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
    # @param func callback
    # @param string title
    # @param string button
    # @return void
    #
    openFileSelector: func(callback, title, button) {
        var fileSelector = gui.FileSelector.new(callback, title, button, ["*.xml"], me.savePath, "route.xml");
        fileSelector.open();
    },
};
