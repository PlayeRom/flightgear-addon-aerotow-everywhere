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
        var obj = {
            parents: [
                ThermalDialog,
                PersistentDialog.new(
                    width: 450,
                    height: 250,
                    title: "Add Thermal",
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, ThermalDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._addonNodePath = g_Addon.node.getPath();

        obj._distanceM = getprop(obj._addonNodePath ~ "/addon-devel/add-thermal/distance-m") or 300;
        obj._strengthFps = getprop(obj._addonNodePath ~ "/addon-devel/add-thermal/strength-fps") or 16.0;
        obj._diameterFt = getprop(obj._addonNodePath ~ "/addon-devel/add-thermal/diameter-ft") or 4000;
        obj._heightMsl = getprop(obj._addonNodePath ~ "/addon-devel/add-thermal/height-msl") or 9000;

        obj._vbox.addSpacing(me.PADDING);

        var hBoxDesc = canvas.HBoxLayout.new();
        hBoxDesc.addSpacing(me.PADDING);
        hBoxDesc.addItem(obj._getLabel("This option allows the thermal to be placed at the distance designated below in front of the glider along with other parameters.", true));
        hBoxDesc.addSpacing(me.PADDING);

        obj._vbox.addItem(hBoxDesc);

        obj._vbox.addStretch(1);

        var grid = canvas.GridLayout.new();

        var editValue = sprintf("%d", obj._distanceM);
        var unitFormat = "m (%.02f NM)";
        var unitLabel = sprintf(unitFormat, obj._distanceM *  globals.M2NM);
        obj._createGridRow(grid, 0, "Distance in front of the glider", editValue, unitLabel, func(e, unitWidget) {
            obj._distanceM = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, obj._distanceM *  globals.M2NM));
        });

        editValue = sprintf("%.2f", obj._strengthFps);
        unitFormat = "ft/s (%.2f m/s)";
        unitLabel = sprintf(unitFormat, obj._strengthFps * globals.FPS2KT * globals.KT2MPS);
        obj._createGridRow(grid, 1, "Strength", editValue, unitLabel, func(e, unitWidget) {
            obj._strengthFps = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, obj._strengthFps * globals.FPS2KT * globals.KT2MPS));
        });

        editValue = sprintf("%d", obj._diameterFt);
        unitFormat = "ft (%.0f m)";
        unitLabel = sprintf(unitFormat, obj._diameterFt * globals.FT2M);
        obj._createGridRow(grid, 2, "Diameter", editValue, unitLabel, func(e, unitWidget) {
            obj._diameterFt = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, obj._diameterFt * globals.FT2M));
        });

        editValue = sprintf("%d", obj._heightMsl);
        unitFormat = "ft (%.0f m)";
        unitLabel = sprintf(unitFormat, obj._heightMsl * globals.FT2M);
        obj._createGridRow(grid, 3, "Height MSL", editValue, unitLabel, func(e, unitWidget) {
            obj._heightMsl = num(e.detail.text);
            unitWidget.setText(sprintf(unitFormat, obj._heightMsl * globals.FT2M));
        });

        var hBoxGrid = canvas.HBoxLayout.new();
        hBoxGrid.addSpacing(me.PADDING);
        hBoxGrid.addItem(grid);
        hBoxGrid.addSpacing(me.PADDING);

        obj._vbox.addItem(hBoxGrid);

        obj._vbox.addStretch(1);

        var buttonAdd = obj._getButton("Add thermal", func {
            obj._addThermal();
            obj.hide();
        });
        var buttonCancel = obj._getButton("Cancel", func { obj.hide(); });

        var hBoxBtns = canvas.HBoxLayout.new();
        hBoxBtns.addStretch(1);
        hBoxBtns.addItem(buttonAdd);
        hBoxBtns.addItem(buttonCancel);
        hBoxBtns.addStretch(1);

        obj._vbox.addSpacing(me.PADDING);
        obj._vbox.addItem(hBoxBtns);
        obj._vbox.addSpacing(me.PADDING);

        return obj;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        call(PersistentDialog.del, [], me);
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

        var editWidget = canvas.gui.widgets.LineEdit.new(me._group)
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
