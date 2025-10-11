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
# TowRopeConfigDialog class.
#
var TowRopeConfigDialog = {
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
                TowRopeConfigDialog,
                PersistentDialog.new(
                    width: 710,
                    height: 200,
                    title: "Towrope Configuration",
                ),
            ],
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, TowRopeConfigDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        me._ropeLengthNode       = props.globals.getNode("/sim/hitches/aerotow/tow/length");
        me._ropeBreakForceNode   = props.globals.getNode("/sim/hitches/aerotow/tow/break-force");
        me._ropeElasticConstNode = props.globals.getNode("/sim/hitches/aerotow/tow/elastic-constant");
        me._ropeDiameterNode     = props.globals.getNode("/sim/hitches/aerotow/rope/rope-diameter-mm");
        me._ropeWeightNode       = props.globals.getNode("/sim/hitches/aerotow/tow/weight-per-m-kg-m");

        me._widgets = {
            length: {
                label : me._getLabel("Towrope Length", "right"),
                value : me._getLabel("m", "right", 75, 26),
                min   : me._getLabel("20 m", "right"),
                max   : me._getLabel("200 m", "left"),
                slider: me._getSlider(min: 20, max: 200, step: 5, callback: func(e) {
                    var value = e.detail.value;
                    me._widgets["length"].value.setText(sprintf("%.0f m", value));
                    me._ropeLengthNode.setDoubleValue(value);
                }),
            },
            breakForce: {
                label : me._getLabel("Weak Link Break Force", "right"),
                value : me._getLabel("N", "right", 75, 26),
                min   : me._getLabel("100 N", "right"),
                max   : me._getLabel("100,000 N", "left"),
                slider: me._getSlider(min: 100, max: 100000, step: 100, callback: func(e) {
                    var value = e.detail.value;
                    me._widgets["breakForce"].value.setText(sprintf("%.0f N", value));
                    me._ropeBreakForceNode.setDoubleValue(value);
                }),
            },
            elastic: {
                label : me._getLabel("Towrope Elastic Constant", "right"),
                value : me._getLabel("N", "right", 75, 26),
                min   : me._getLabel("0 N", "right"),
                max   : me._getLabel("1,500,000 N", "left"),
                slider: me._getSlider(min: 0, max: 1500000, step: 200, callback: func(e) {
                    var value = e.detail.value;
                    me._widgets["elastic"].value.setText(sprintf("%.0f N", value));
                    me._ropeElasticConstNode.setDoubleValue(value);
                }),
            },
            diameter: {
                label : me._getLabel("Towrope Diameter", "right"),
                value : me._getLabel("mm", "right", 75, 26),
                min   : me._getLabel("0 mm", "right"),
                max   : me._getLabel("50 mm", "left"),
                slider: me._getSlider(min: 0, max: 50, step: 1, callback: func(e) {
                    var value = e.detail.value;
                    me._widgets["diameter"].value.setText(sprintf("%.0f mm", value));
                    me._ropeDiameterNode.setDoubleValue(value);
                }),
            },
            weight: {
                label : me._getLabel("Towrope Weight per Meter", "right"),
                value : me._getLabel("kg/m", "right", 75, 26),
                min   : me._getLabel("0 kg/m", "right"),
                max   : me._getLabel("1 kg/m", "left"),
                slider: me._getSlider(min: 0, max: 100, step: 1, callback: func(e) {
                    # TODO: FIXME: It should be set to min: 0, max: 1, step: 0.01,
                    # but for some reason with these settings the slider goes crazy
                    # and steps by 1. That's why I use a conversion of 100.
                    var value = e.detail.value / 100;
                    me._widgets["weight"].value.setText(sprintf("%.2f kg/m", value));
                    me._ropeWeightNode.setDoubleValue(value);
                }),
            },
        };

        me._rowNames = [
            "length",
            "breakForce",
            "elastic",
            "diameter",
            "weight",
        ];

        me._setSliderValues();

        me._buildLayout();

        me._listeners = Listeners.new();
        me._addListeners();

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._listeners.del();

        call(PersistentDialog.del, [], me);
    },

    #
    # @return void
    #
    _buildLayout: func() {
        var grid = canvas.GridLayout.new();

        forindex (var row; me._rowNames) {
            var name = me._rowNames[row];

            grid.addItem(me._widgets[name].label, 0, row);
            grid.addItem(me._widgets[name].value, 1, row);
            grid.addItem(me._widgets[name].min, 2, row);
            grid.addItem(me._widgets[name].slider, 3, row);
            grid.addItem(me._widgets[name].max, 4, row);
        }

        var hBox = canvas.HBoxLayout.new();
        hBox.addSpacing(RouteAerotowDialog.PADDING);
        hBox.addItem(grid);
        hBox.addSpacing(RouteAerotowDialog.PADDING);

        me._vbox.addSpacing(TowRopeConfigDialog.PADDING);
        me._vbox.addItem(hBox);
        me._vbox.addStretch(1);

        me._vbox.addSpacing(RouteAerotowDialog.PADDING);
        me._vbox.addItem(me._drawBottomBar());
        me._vbox.addSpacing(RouteAerotowDialog.PADDING);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, align = "center", width = nil, height = nil, wordWrap = false) {
        var label = canvas.gui.widgets.Label.new(parent: me._group, cfg: { wordWrap: wordWrap })
            .setText(text);

        label.setTextAlign(align);

        if (width != nil and height != nil) {
            label.setFixedSize(width, height);
        }

        return label;
    },

    #
    # Get Slider widget.
    #
    # @param  double  min  Min slider value.
    # @param  double  max  Max slider value.
    # @param  double  step  Slider step.
    # @param  func  callback  Callback function on value change.
    # @return ghost  Slider widget.
    #
    _getSlider: func(min, max, step, callback) {
        var slider = canvas.gui.widgets.Slider.new(parent: me._group, cfg: {
            "min-value" : min,
            "max-value" : max,
            "tick-step" : step,
            "page-size" : 0.0,
        });

        slider.setFixedSize(300, 26);
        slider.listen("value-changed", callback);

        return slider;
    },

    #
    # @param  string  text  Label of button.
    # @param  func  callback  Function which will be executed after click the button.
    # @return ghost  Button widget.
    #
    _getButton: func(text, callback) {
        return canvas.gui.widgets.Button.new(me._group)
            .setText(text)
            .setFixedSize(200, 26)
            .listen("clicked", callback);
    },

    #
    # @param  string  label  Label of button.
    # @param  func  callback  function which will be executed after click the button.
    # @return ghost  HBoxLayout object with button.
    #
    _drawBottomBar: func() {
        var okBtn = canvas.gui.widgets.Button.new(me._group)
            .setText("OK")
            .setFixedSize(75, 26)
            .listen("clicked", func me.hide());

        var defaultBtn = canvas.gui.widgets.Button.new(me._group)
            .setText("Default")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                me._setDefaultValues();
            });

        var hBox = canvas.HBoxLayout.new();
        hBox.addStretch(1);
        hBox.addItem(okBtn);
        hBox.addItem(defaultBtn);
        hBox.addStretch(1);

        return hBox;
    },

    #
    # Add listeners.
    #
    # @return void
    #
    _addListeners: func() {
        me._listeners.add(
            node: me._ropeLengthNode,
            code: func {
                me._widgets["length"].slider.setValue(me._ropeLengthNode.getValue());
            },
            type: Listeners.ON_CHANGE_ONLY,
        );

        me._listeners.add(
            node: me._ropeBreakForceNode,
            code: func {
                me._widgets["breakForce"].slider.setValue(me._ropeBreakForceNode.getValue());
            },
            type: Listeners.ON_CHANGE_ONLY,
        );

        me._listeners.add(
            node: me._ropeElasticConstNode,
            code: func {
                me._widgets["elastic"].slider.setValue(me._ropeElasticConstNode.getValue());
            },
            type: Listeners.ON_CHANGE_ONLY,
        );

        me._listeners.add(
            node: me._ropeDiameterNode,
            code: func {
                me._widgets["diameter"].slider.setValue(me._ropeDiameterNode.getValue());
            },
            type: Listeners.ON_CHANGE_ONLY,
        );

        me._listeners.add(
            node: me._ropeWeightNode,
            code: func {
                me._widgets["weight"].slider.setValue(me._ropeWeightNode.getValue() * 100);
            },
            type: Listeners.ON_CHANGE_ONLY,
        );
    },

    #
    # Set default rope values.
    #
    # @return void
    #
    _setDefaultValues: func() {
        me._ropeLengthNode.setDoubleValue(60.0);          # hitch.nas 60.0
        me._ropeBreakForceNode.setDoubleValue(100000.0);  # hitch.nas 12345.0
        me._ropeElasticConstNode.setDoubleValue(10000.0); # hitch.nas 9111.0
        me._ropeDiameterNode.setDoubleValue(20);          # hitch.nas 20
        me._ropeWeightNode.setDoubleValue(0.35);          # hitch.nas 0.35

        me._setSliderValues();
    },

    #
    # Set values for all sliders.
    #
    # @return void
    #
    _setSliderValues: func() {
        me._widgets["length"].slider.setValue(me._ropeLengthNode.getValue());
        me._widgets["breakForce"].slider.setValue(me._ropeBreakForceNode.getValue());
        me._widgets["elastic"].slider.setValue(me._ropeElasticConstNode.getValue());
        me._widgets["diameter"].slider.setValue(me._ropeDiameterNode.getValue());
        me._widgets["weight"].slider.setValue(me._ropeWeightNode.getValue() * 100);
    },
};
