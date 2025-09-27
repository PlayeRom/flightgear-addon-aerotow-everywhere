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
# AboutDialog class to display about info.
#
var AboutDialog = {
    #
    # Constructor.
    #
    # @return hash
    #
    new: func() {
        var me = { parents: [
            AboutDialog,
            Dialog.new(width: 300, height: 400, title: "About Aerotow Everywhere Add-on"),
        ] };

        var dialogParent = me.parents[1];
        dialogParent.setChild(me, AboutDialog); # Let the parent know who their child is.
        dialogParent.setPositionOnCenter();

        me._vbox.addSpacing(10);

        me._vbox.addItem(me._getLabel(g_Addon.name));
        me._vbox.addItem(me._getLabel(sprintf("version %s", g_Addon.version.str())));
        me._vbox.addItem(me._getLabel("September 15, 2025"));
        me._vbox.addStretch(1);
        me._vbox.addItem(me._getLabel("Written by:"));

        foreach (var author; g_Addon.authors) {
            me._vbox.addItem(me._getLabel(author.name));
        }

        me._vbox.addStretch(1);

        me._vbox.addItem(me._getButton("Open GitHub Website", func {
            Utils.openBrowser({ "url": g_Addon.codeRepositoryUrl });
        }));

        me._vbox.addStretch(1);

        var buttonBoxClose = me._drawBottomBar("Close", func { me._window.hide(); });
        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBoxClose);
        me._vbox.addSpacing(10);

        return me;
    },

    #
    # Destructor.
    #
    # @return void
    #
    del: func() {
        call(Dialog.del, [], me);
    },

    #
    # @param  string  text  Label text.
    # @param  bool  wordWrap  If true then text will be wrapped.
    # @return ghost  Label widget.
    #
    _getLabel: func(text, wordWrap = false) {
        var label = canvas.gui.widgets.Label.new(me._group, canvas.style, {wordWrap: wordWrap})
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
        return canvas.gui.widgets.Button.new(me._group, canvas.style, {})
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

        var btnClose = canvas.gui.widgets.Button.new(me._group, canvas.style, {})
            .setText(label)
            .setFixedSize(75, 26)
            .listen("clicked", callback);

        buttonBox.addStretch(1);
        buttonBox.addItem(btnClose);
        buttonBox.addStretch(1);

        return buttonBox;
    },
};
