#
# Aerotow Everywhere - Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# Aerotow Everywhere is an Open Source project and it is licensed
# under the GNU Public License v3 (GPLv3)
#

#
# RouteAerotowDialog class to enter route.
#
var RouteAerotowDialog = {
    #
    # Constants:
    #
    PADDING: 10,
    MAX_ROUTE_WAYPOINTS: 10,
    ROUTE_SAVES_DIR: "route-saves",

    #
    # Constructor.
    #
    # @param  hash  scenario
    # @return hash
    #
    new: func(scenario) {
        var me = {
            parents: [
                RouteAerotowDialog,
                PersistentDialog.new(
                    width: 450,
                    height: 768,
                    title: "Add Thermal",
                ),
            ],
            _scenario: scenario,
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, RouteAerotowDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        me._addonNodePath = g_Addon.node.getPath();
        me._savePath = g_Addon.storagePath ~ "/" ~ RouteAerotowDialog.ROUTE_SAVES_DIR;

        me._bindings = {};

        me._buildLayout();

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._altChangeLabels.clear();

        me._parentDialog.del();
    },

    #
    # @return void
    #
    _buildLayout: func() {
        me._vbox.addSpacing(RouteAerotowDialog.PADDING);
        me._vbox.addItem(me._buildLayoutTopDesc());
        me._vbox.addStretch(1);
        me._vbox.addItem(me._buildLayoutAircraft());
        me._vbox.addStretch(1);
        me._vbox.addItem(me._buildLayoutGrid());
        me._vbox.addStretch(1);
        me._vbox.addItem(me._buildLayoutRouteDescLabel());
        me._vbox.addItem(me._buildLayoutRouteDescInput());
        me._vbox.addStretch(1);
        me._vbox.addSpacing(RouteAerotowDialog.PADDING);
        me._vbox.addItem(me._buildLayoutButtons());
        me._vbox.addSpacing(RouteAerotowDialog.PADDING);
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutTopDesc: func() {
        var vBox = canvas.VBoxLayout.new();
        vBox.addItem(me._getLabel("Here you can change the default flight path of the tow plane.", true));
        vBox.addItem(me._getLabel("You cannot change the initial point, the AI plane always takes-off in front of the runway you are on.", true));
        vBox.addSpacing(10);
        vBox.addItem(me._getLabel("A distance with a value of 0 terminates the flight plan.", true));

        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(vBox);
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        return hBox;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutAircraftComboBox: func() {
        var comboBox = canvas.gui.widgets.ComboBox.new(me._group);
        if (Utils.tryCatch(func { typeof(comboBox.createItem) == "func"; }, [])) {
            # For next addMenuItem is deprecated
            #                   label,          value
            comboBox.createItem("Piper J3 Cub", "Piper J3 Cub");
            comboBox.createItem("Robin DR400",  "Robin DR400");
            comboBox.createItem("Cessna 182",   "Cessna 182");
            comboBox.createItem("Douglas C-47", "Douglas C-47");
            comboBox.createItem("Halifax",      "Handley Page Halifax");
        } else {
            # for 2024.1
            #                    label,          value
            comboBox.addMenuItem("Piper J3 Cub", "Piper J3 Cub");
            comboBox.addMenuItem("Robin DR400",  "Robin DR400");
            comboBox.addMenuItem("Cessna 182",   "Cessna 182");
            comboBox.addMenuItem("Douglas C-47", "Douglas C-47");
            comboBox.addMenuItem("Halifax",      "Handley Page Halifax");
        }
        comboBox.setFixedSize(140, 28);
        comboBox.setSelectedByValue(getprop(me._addonNodePath ~ "/addon-devel/route/ai-model"));
        comboBox.listen("selected-item-changed", func(e) {
            setprop(me._addonNodePath ~ "/addon-devel/route/ai-model", e.detail.value);
            me.calculateAltChangeAndTotals();
        });

        return comboBox;
    },

    #
    # @return ghost  Input text widget.
    #
    _buildLayoutMaxAltitude: func() {
        var lineEditMaxAlt = canvas.gui.widgets.LineEdit.new(me._group)
            .setFixedSize(80, 28)
            .setText(sprintf("%.0f", getprop(me._addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl")))
            .listen("text-changed", func(e) {
                setprop(me._addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl", num(e.detail.text));
                me.calculateAltChangeAndTotals();
            });

        me._bindWidgetWithProp("/addon-devel/route/wpts/max-alt-agl", lineEditMaxAlt, "%.0f");

        return lineEditMaxAlt;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutAircraft: func() {
        var aircraft = me._buildLayoutAircraftComboBox();
        var maxAlt = me._buildLayoutMaxAltitude();

        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(me._getLabel("Aerotow:"));
        hBox.addItem(aircraft, 1);
        hBox.addStretch(1);
        hBox.addItem(me._getLabel("Max alt (AGL):"));
        hBox.addItem(maxAlt);
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        return hBox;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutGrid: func() {
        var grid = canvas.GridLayout.new();

        var row = 0;
        grid.addItem(me._getLabel("Initial Heading (°)"), 0, row);
        grid.addItem(me._getLabel("Distance (m)"), 1, row);
        grid.addItem(me._getLabel("Alt change (AGL)"), 2, row);

        var initHdgLabel  = me._getLabel(sprintf("%.2f°",   getprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/heading-change")));
        var initDistLabel = me._getLabel(sprintf("%.0f m",  getprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/distance-m")));
        var initAltLabel  = me._getLabel(sprintf("%.0f ft", getprop(me._addonNodePath ~ "/addon-devel/route/init-wpt/alt-change-agl-ft")));

        me._bindWidgetWithProp("/addon-devel/route/init-wpt/heading-change", initHdgLabel, "%.2f°");
        me._bindWidgetWithProp("/addon-devel/route/init-wpt/distance-m", initDistLabel, "%.0f m");
        me._bindWidgetWithProp("/addon-devel/route/init-wpt/alt-change-agl-ft", initAltLabel, "%.0f ft");

        row += 1;
        grid.addItem(initHdgLabel, 0, row);
        grid.addItem(initDistLabel, 1, row);
        grid.addItem(initAltLabel, 2, row);

        row += 1;
        grid.addItem(me._getLabel("Heading change (°)"), 0, row);
        grid.addItem(me._getLabel("Distance (m)"), 1, row);
        grid.addItem(me._getLabel("Alt change (AGL)"), 2, row);

        me._altChangeLabels = std.Vector.new();
        for (var i = 0; i < 10; i += 1) {
            row += 1;
            me._altChangeLabels.append(me._createGridRow(grid, row, i));
        }

        var totalLabel = me._getLabel("Total:");
        totalLabel.setTextAlign("right");

        me._totalDistanceLabel = me._getLabel(sprintf("%.0f m", getprop(me._addonNodePath ~ "/addon-devel/route/total/distance")));
        me._totalAltitudeLabel = me._getLabel(sprintf("%.0f ft", getprop(me._addonNodePath ~ "/addon-devel/route/total/alt")));

        me._bindWidgetWithProp("/addon-devel/route/total/distance", me._totalDistanceLabel, "%.0f m");
        me._bindWidgetWithProp("/addon-devel/route/total/alt", me._totalAltitudeLabel, "%.0f ft");

        row += 1;
        grid.addItem(totalLabel, 0, row);
        grid.addItem(me._totalDistanceLabel, 1, row);
        grid.addItem(me._totalAltitudeLabel, 2, row);

        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(grid);
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        return hBox;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutRouteDescLabel: func() {
        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(me._getLabel("Description:"));
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        return hBox;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutRouteDescInput: func() {
        var editDesc = canvas.gui.widgets.LineEdit.new(me._group)
            .setText(getprop(me._addonNodePath ~ "/addon-devel/route/wpts/description"))
            .listen("text-changed", func(e) {
                setprop(me._addonNodePath ~ "/addon-devel/route/wpts/description", e.detail.text);
            });

        me._bindWidgetWithProp("/addon-devel/route/wpts/description", editDesc, "%s");

        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(editDesc, 1);
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        return hBox;
    },

    #
    # @return ghost  Horizontal box layout.
    #
    _buildLayoutButtons: func() {
        var buttonOk = me._getButton("OK", func { me.hide(); });
        var buttonDefault = me._getButton("Default", func {
            me._scenario.initialFlightPlan();
            me.calculateAltChangeAndTotals();
            me._updateTextWidgets();
        });
        var buttonSave = me._getButton("Save...", func { me.save(); });
        var buttonLoad = me._getButton("Load...", func { me.load(); });

        var hBox = canvas.HBoxLayout.new();
        hBox.addStretch(1);
        hBox.addItem(buttonOk);
        hBox.addItem(buttonDefault);
        hBox.addItem(buttonSave);
        hBox.addItem(buttonLoad);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # @param  string  prop
    # @param  ghost  widget
    # @param  string  format
    # @return void
    #
    _bindWidgetWithProp: func(prop, widget, format) {
        me._bindings[me._addonNodePath ~ prop] = {
            widget: widget,
            format: format,
        };
    },

    #
    # Create one grid row.
    #
    # @param  ghost  grid  Grid layout widget.
    # @param  int  gridRow  Row index.
    # @param  string  index  Label text.
    # @return ghost  Widget for alt change label.
    #
    _createGridRow: func(grid, gridRow, index) {
        var editHeading = canvas.gui.widgets.LineEdit.new(me._group)
            # .setFixedSize(80, 28)
            .setText(sprintf("%.0f", getprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/heading-change")))
            .listen("text-changed", func(e) {
                setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/heading-change", num(e.detail.text));
            });

        var editDistance = canvas.gui.widgets.LineEdit.new(me._group)
            # .setFixedSize(80, 28)
            .setText(sprintf("%.0f", getprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/distance-m")))
            .listen("text-changed", func(e) {
                setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/distance-m", num(e.detail.text));
                me.calculateAltChangeAndTotals();
            });

        var altChangeLabel = me._getLabel(sprintf("%.0f ft", getprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ index ~ "]/alt-change-agl-ft")))
            .setFixedSize(200, 28);

        me._bindWidgetWithProp("/addon-devel/route/wpts/wpt[" ~ index ~ "]/heading-change", editHeading, "%.0f");
        me._bindWidgetWithProp("/addon-devel/route/wpts/wpt[" ~ index ~ "]/distance-m", editDistance, "%.0f");
        me._bindWidgetWithProp("/addon-devel/route/wpts/wpt[" ~ index ~ "]/alt-change-agl-ft", altChangeLabel, "%.0f ft");

        grid.addItem(editHeading, 0, gridRow);
        grid.addItem(editDistance, 1, gridRow);
        grid.addItem(altChangeLabel, 2, gridRow);

        return altChangeLabel;
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        return canvas.gui.widgets.Label.new(parent: me._group, cfg: { wordWrap: wordWrap })
            .setText(text);
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._group)
            .setText(text)
            .listen("clicked", callback);
    },

    #
    # Calculate total distance and altitude and put in to property tree.
    #
    # @return void
    #
    calculateAltChangeAndTotals: func() {
        var totalDistance = 0.0;
        var totalAlt = 0.0;
        var isEnd = false;
        var isAltLimit = false;

        var isRouteMode = true;
        var aircraft = Aircraft.getSelected(isRouteMode);

        # 0 means without altitude limits
        var maxAltAgl = num(getprop(me._addonNodePath ~ "/addon-devel/route/wpts/max-alt-agl") or 0);

        for (var i = 0; i < RouteAerotowDialog.MAX_ROUTE_WAYPOINTS; i += 1) {
            var distance = num(getprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/distance-m") or 0);

            # If we have reached the altitude limit, the altitude no longer changes (0)
            var altChange = isAltLimit ? 0 : aircraft.getAltChange(distance);
            if (maxAltAgl > 0 and altChange > 0 and totalAlt + altChange > maxAltAgl) {
                # We will exceed the altitude limit, so set the altChange to the altitude limit
                # and set isAltLimit flag that the limit is reached.
                altChange = maxAltAgl - totalAlt;
                isAltLimit = true;
            }

            setprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/alt-change-agl-ft", altChange);
            me._altChangeLabels.vector[i]
                .setText(sprintf("%.0f ft", getprop(me._addonNodePath ~ "/addon-devel/route/wpts/wpt[" ~ i ~ "]/alt-change-agl-ft")));

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

        setprop(me._addonNodePath ~ "/addon-devel/route/total/distance", totalDistance);
        setprop(me._addonNodePath ~ "/addon-devel/route/total/alt", totalAlt);

        me._totalDistanceLabel.setText(sprintf("%.0f m", totalDistance));
        me._totalAltitudeLabel.setText(sprintf("%.0f ft", totalAlt));
    },

    #
    # Save route with description to the XML file.
    #
    # @return void
    #
    save: func() {
        me._openFileSelector(
            func (node) {
                var nodeSave = props.globals.getNode(me._addonNodePath ~ "/addon-devel/route/wpts");
                if (io.write_properties(node.getValue(), nodeSave)) {
                    Message.success("The route has been saved");
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
        me._openFileSelector(
            func (node) {
                var nodeLoad = props.globals.getNode(me._addonNodePath ~ "/addon-devel/route/wpts");
                if (io.read_properties(node.getValue(), nodeLoad)) {
                    Message.success("The route has been loaded");
                }
            },
            "Load route",
            "Load"
        );
    },

    #
    # Open file selector dialog for save/load XML file with route.
    #
    # @param  func  callback
    # @param  string  title
    # @param  string  button
    # @return void
    #
    _openFileSelector: func(callback, title, button) {
        var fileSelector = gui.FileSelector.new(callback, title, button, ["*.xml"], me._savePath, "route.xml");
        fileSelector.open();
    },

    #
    # Set text from properties to widgets.
    #
    # @return void
    #
    _updateTextWidgets: func() {
        foreach (var key; keys(me._bindings)) {
            var item = me._bindings[key];
            item.widget.setText(sprintf(item.format, getprop(key)));
        }
    },
};
