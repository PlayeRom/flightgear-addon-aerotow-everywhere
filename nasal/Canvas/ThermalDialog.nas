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
# ThermalDialog class to add thermal.
#
var ThermalDialog = {
    #
    # Constants:
    #
    PADDING: 10,

    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [
                ThermalDialog,
                PersistentDialog.new(
                    width: 450,
                    height: 250,
                    title: "Add Thermal",
                ),
            ],
        };

        var dialogParent = me.parents[1];
        dialogParent.setChild(me, ThermalDialog); # Let the parent know who their child is.
        dialogParent.setPositionOnCenter();

        me._addonNodePath = g_Addon.node.getPath();

        me._distanceM = getprop(me._addonNodePath ~ "/addon-devel/add-thermal/distance-m") or 300;
        me._strengthFps = getprop(me._addonNodePath ~ "/addon-devel/add-thermal/strength-fps") or 16.0;
        me._diameterFt = getprop(me._addonNodePath ~ "/addon-devel/add-thermal/diameter-ft") or 4000;
        me._heightMsl = getprop(me._addonNodePath ~ "/addon-devel/add-thermal/height-msl") or 9000;

        me._vbox.addSpacing(ThermalDialog.PADDING);

        var hBoxDesc = canvas.HBoxLayout.new();
        hBoxDesc.addSpacing(ThermalDialog.PADDING);
        hBoxDesc.addItem(me._getLabel("This option allows the thermal to be placed at the distance designated below in front of the glider along with other parameters.", true));
        hBoxDesc.addSpacing(ThermalDialog.PADDING);

        me._vbox.addItem(hBoxDesc);

        me._vbox.addStretch(1);

        var grid = canvas.GridLayout.new();

        var editValue = sprintf("%d", me._distanceM);
        var unitFormat = "m (%.02f NM)";
        var unitLabel = sprintf(unitFormat, me._distanceM *  globals.M2NM);
        me._createGridRow(grid, 0, "Distance in front of the glider", editValue, unitLabel, func(e, unitWidget) {
            me._distanceM = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, me._distanceM *  globals.M2NM));
        });

        editValue = sprintf("%.2f", me._strengthFps);
        unitFormat = "ft/s (%.2f m/s)";
        unitLabel = sprintf(unitFormat, me._strengthFps * globals.FPS2KT * globals.KT2MPS);
        me._createGridRow(grid, 1, "Strength", editValue, unitLabel, func(e, unitWidget) {
            me._strengthFps = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, me._strengthFps * globals.FPS2KT * globals.KT2MPS));
        });

        editValue = sprintf("%d", me._diameterFt);
        unitFormat = "ft (%.0f m)";
        unitLabel = sprintf(unitFormat, me._diameterFt * globals.FT2M);
        me._createGridRow(grid, 2, "Diameter", editValue, unitLabel, func(e, unitWidget) {
            me._diameterFt = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, me._diameterFt * globals.FT2M));
        });

        editValue = sprintf("%d", me._heightMsl);
        unitFormat = "ft (%.0f m)";
        unitLabel = sprintf(unitFormat, me._heightMsl * globals.FT2M);
        me._createGridRow(grid, 3, "Height MSL", editValue, unitLabel, func(e, unitWidget) {
            me._heightMsl = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, me._heightMsl * globals.FT2M));
        });

        var hBoxGrid = canvas.HBoxLayout.new();
        hBoxGrid.addSpacing(ThermalDialog.PADDING);
        hBoxGrid.addItem(grid);
        hBoxGrid.addSpacing(ThermalDialog.PADDING);

        me._vbox.addItem(hBoxGrid);

        me._vbox.addStretch(1);

        var buttonAdd = me._getButton("Add thermal", func {
            me._addThermal();
            me.hide();
        });
        var buttonCancel = me._getButton("Cancel", func { me.hide(); });

        var hBoxBtns = canvas.HBoxLayout.new();
        hBoxBtns.addStretch(1);
        hBoxBtns.addItem(buttonAdd);
        hBoxBtns.addItem(buttonCancel);
        hBoxBtns.addStretch(1);

        me._vbox.addSpacing(ThermalDialog.PADDING);
        me._vbox.addItem(hBoxBtns);
        me._vbox.addSpacing(ThermalDialog.PADDING);

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me.parents[1].del();
    },

    #
    # Create one grid row.
    #
    # @param  ghost  grid  Grid layout widget.
    # @param  int  row  Row index.
    # @param  string  label  Label text.
    # @param  string  editValue  Value for edit widget.
    # @param  string  unitLabel  Text for unit widget.
    # @param  func  callback  Callback function for text-changed in edit widget.
    # @return void
    #
    _createGridRow: func(grid, row, label, editValue, unitLabel, callback) {
        var labelWidget = me._getLabel(label);
        labelWidget.setTextAlign("right");

        var unitWidget = me._getLabel(unitLabel).setFixedSize(160, 28);

        var editWidget = canvas.gui.widgets.LineEdit.new(me._group, canvas.style, {})
            .setFixedSize(80, 28)
            .setText(editValue);

        editWidget.listen("text-changed", func(e) {
            callback(e, unitWidget);
        });

        grid.addItem(labelWidget, 0, row);
        grid.addItem(editWidget, 1, row);
        grid.addItem(unitWidget, 2, row);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        return canvas.gui.widgets.Label.new(me._group, canvas.style, {wordWrap: wordWrap})
            .setText(text);
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText(text)
            .listen("clicked", callback);
    },

    #
    # Add thermal 300 m before glider position.
    #
    # @return bool  Return true on successful, otherwise false.
    #
    _addThermal: func() {
        var heading = getprop("/orientation/heading-deg") or 0;
        var distance = me._distanceM;

        var position = geo.aircraft_position();
        position.apply_course_distance(heading, distance);

        # Get random layer from 1 to 4
        var layer = int(rand() * 4) + 1;

        var args = props.Node.new({
            "type":         "thermal",
            "model":        "Models/Weather/altocumulus_layer" ~ layer ~ ".xml",
            "latitude":     position.lat(),
            "longitude":    position.lon(),
            "strength-fps": me._strengthFps,
            "diameter-ft":  me._diameterFt,
            "height-msl":   me._heightMsl,
            "search-order": "DATA_ONLY"
        });

        if (fgcommand("add-aiobject", args)) {
            Message.success("The thermal has been added");
            return true;
        }

        Message.error("Adding thermal failed");
        return false;
    },
};
