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

        obj._vbox.addItem(obj._getButton("Open GitHub Website", func {
            Utils.openBrowser({ url: g_Addon.codeRepositoryUrl });
        }));

        obj._vbox.addStretch(1);

        var buttonBoxClose = obj._drawBottomBar("Close", func { obj.hide(); });
        obj._vbox.addSpacing(10);
        obj._vbox.addItem(buttonBoxClose);
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
        var label = canvas.gui.widgets.Label.new(parent: me._group, cfg: { wordWrap: wordWrap })
            .setText(text);

        label.setTextAlign("center");

        return label;
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
    _drawBottomBar: func(label, callback) {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me._group)
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
