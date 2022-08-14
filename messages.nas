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
# Display given message as OK.
#
# message - The text message to display on the screen and read by speech synthesizer.
#
var displayOk = func (message) {
    display(message, "ok");
}

#
# Display given message as an error.
#
# message - The text message to display on the screen and read by speech synthesizer.
#
var displayError = func (message) {
    display(message, "error");
}

#
# Display given message.
#
# message - The text message to display on the screen and read by speech synthesizer.
# type - The type of message. It can take values as "ok" or "error".
#
var display = func (message, type) {
    # Print to console
    print("Aerotow Everywhere add-on: " ~ message);

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
}
