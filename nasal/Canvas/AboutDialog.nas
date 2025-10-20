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
# AboutDialog class to display about info.
#
var AboutDialog = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var obj = {
            parents: [
                AboutDialog,
                PersistentDialog.new(
                    width: 300,
                    height: 400,
                    title: "About Aerotow Everywhere Add-on",
                ),
            ],
        };

        call(PersistentDialog.setChild, [obj, AboutDialog], obj.parents[1]); # Let the parent know who their child is.
        call(PersistentDialog.setPositionOnCenter, [], obj.parents[1]);

        obj._widget = WidgetHelper.new(obj._group);

        obj._vbox.addSpacing(10);

        obj._vbox.addItem(obj._getLabel(g_Addon.name));
        obj._vbox.addItem(obj._getLabel(sprintf("version %s", g_Addon.version.str())));
        obj._vbox.addItem(obj._getLabel("September 15, 2025"));
        obj._vbox.addStretch(1);
        obj._vbox.addItem(obj._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            obj._vbox.addItem(obj._getLabel(author.name));
        }

        obj._vbox.addStretch(1);

        obj._vbox.addItem(obj._widget.getButton("Open GitHub Website", 200, func {
            Utils.openBrowser({ url: g_Addon.codeRepositoryUrl });
        }));

        obj._vbox.addStretch(1);

        obj._vbox.addSpacing(10);
        obj._vbox.addItem(obj._drawBottomBar());
        obj._vbox.addSpacing(10);

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
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        return me._widget.getLabel(text, wordWrap, "center");
    },

    #
    # @return ghost  HBoxLayout object with button.
    #
    _drawBottomBar: func() {
        var btnClose = me._widget.getButton("Close", 75, func me.hide());

        var hBox = canvas.HBoxLayout.new();
        hBox.addStretch(1);
        hBox.addItem(btnClose);
        hBox.addStretch(1);

        return hBox;
    },
};
