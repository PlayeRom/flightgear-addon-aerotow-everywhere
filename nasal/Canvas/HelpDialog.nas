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
# HelpDialog class to display help text
#
var HelpDialog = {
    #
    # Constants
    #
    WINDOW_WIDTH  : 700,
    WINDOW_HEIGHT : 420,
    PADDING       : 10,

    #
    # Constructor
    #
    # @return hash
    #
    new: func() {
        var me = {
            parents: [
                HelpDialog,
                PersistentDialog.new(
                    width   : HelpDialog.WINDOW_WIDTH,
                    height  : HelpDialog.WINDOW_HEIGHT,
                    title   : "Aerotow Everywhere Help",
                    resize  : true,
                    onResize: func(w, h) { me._onResize(w, h); }
                ),
            ],
        };

        me._parentDialog = me.parents[1];
        me._parentDialog.setChild(me, HelpDialog); # Let the parent know who their child is.
        me._parentDialog.setPositionOnCenter();

        var margins = {
            left   : HelpDialog.PADDING,
            top    : HelpDialog.PADDING,
            right  : 0,
            bottom : 0,
        };
        me._scrollData = ScrollAreaHelper.create(me._group, margins);

        me._vbox.addItem(me._scrollData, 1); # 2nd param = stretch

        me._scrollDataContent = ScrollAreaHelper.getContent(
            context  : me._scrollData,
            font     : "LiberationFonts/LiberationSans-Regular.ttf",
            fontSize : 16,
            alignment: "left-baseline"
        );

        me._helpTexts = std.Vector.new();
        me._propHelpText = props.globals.getNode(g_Addon.node.getPath() ~ "/addon-devel/help-text");

        me._reDrawTexts(x: 0, y: 0, maxWidth: HelpDialog.WINDOW_WIDTH - (HelpDialog.PADDING * 2));
        me._drawBottomBar();

        return me;
    },

    #
    # Destructor
    #
    # @return void
    # @override PersistentDialog
    #
    del: func() {
        me._parentDialog.del();
    },

    #
    # Resize callback from parent Dialog
    #
    # @param  int  width
    # @param  int  height
    # @return void
    #
    _onResize: func(width, height) {
        me._reDrawTexts(x: 0, y: 0, maxWidth: width - (HelpDialog.PADDING * 2));
    },

    #
    # @param  int  x
    # @param  int  y
    # @param  int|nil  maxWidth
    # @return void
    #
    _reDrawTexts: func(x, y, maxWidth = nil) {
        me._scrollDataContent.removeAllChildren();
        me._helpTexts.clear();

        foreach (var node; me._propHelpText.getChildren("paragraph")) {
            var isHeader = math.mod(node.getIndex(), 2) == 0;
            var text = me._scrollDataContent.createChild("text")
                .setText(node.getValue())
                .setTranslation(x, y)
                .setColor(canvas.style.getColor("text_color"))
                .setFontSize(isHeader ? 18 : 16)
                .setFont(isHeader
                    ? "LiberationFonts/LiberationSans-Bold.ttf"
                    : "LiberationFonts/LiberationSans-Regular.ttf"
                )
                .setAlignment("left-baseline");

            if (maxWidth != nil) {
                text.setMaxWidth(maxWidth);
            }

            y += text.getSize()[1] + 10;

            me._helpTexts.append(text);
        }
    },

    #
    # @return ghost  HBoxLayout object with button
    #
    _drawBottomBar: func() {
        var buttonBox = canvas.HBoxLayout.new();

        var btnClose = canvas.gui.widgets.Button.new(me._group)
            .setText("Close")
            .setFixedSize(75, 26)
            .listen("clicked", func {
                me.hide();
            });

        buttonBox.addItem(btnClose);

        me._vbox.addSpacing(10);
        me._vbox.addItem(buttonBox);
        me._vbox.addSpacing(10);

        return buttonBox;
    },
};
