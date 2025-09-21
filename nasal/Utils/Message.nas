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
# Class Message for display messages on the screen with read by speech synthesizer.
#
var Message = {
    #
    # Display given message as OK.
    #
    # @param  string  message  The text message to display on the screen and read by speech synthesizer.
    # @return void
    #
    success: func(message) {
        Message._display(message, "ok");
    },

    #
    # Display given message as an error.
    #
    # @param  string  message  The text message to display on the screen and read by speech synthesizer.
    # @return void
    #
    error: func(message) {
        Message._display(message, "error");
    },

    #
    # Display given message.
    #
    # @param  string  message  The text message to display on the screen and read by speech synthesizer.
    # @param  string  type  The type of message. It can take values as "ok" or "error".
    # @return void
    #
    _display: func(message, type) {
        # Print to console
        Log.alert(message);

        # Read the message by speech synthesizer
        props.globals.getNode("/sim/sound/voices/ai-plane").setValue(message);

        # Display message on the screen
        var durationInSec = int(size(message) / 12) + 3;
        var window = screen.window.new(nil, -40, 10, durationInSec);
        window.bg = [0.0, 0.0, 0.0, 0.40];

        window.fg = type == "error"
            ? [1.0, 0.0, 0.0, 1]
            : [0.0, 1.0, 0.0, 1];

        window.align = "center";
        window.write(message);
    },
};
