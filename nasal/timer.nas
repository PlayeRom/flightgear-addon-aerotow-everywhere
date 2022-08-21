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
# Class Timer for wrapping maketimer() function.
#
var Timer = {
    #
    # Constructor
    #
    new: func () {
        return { parents: [Timer] };
    },

    #
    # Run timer as single shot
    #
    # delaySec - Delay in seconds for execute timer's callback.
    # self - Specifying what any "me" references in the function being called will refer to.
    # callback - Function to be called after given delay.
    #
    # Return timer handler object
    #
    singleShot: func (delaySec, self, callback) {
        var timer = maketimer(delaySec, self, func () {
            callback();
        });
        timer.singleShot = 1;
        timer.start();

        return timer;
    },
};
