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
    # Run timer as single shot.
    #
    # @param  double  delaySec  Delay in seconds for execute timer's callback.
    # @param  hash  self  Specifying what any "me" references in the function being called will refer to.
    # @param  func  callback  Function to be called after given delay.
    # @return ghost  Return timer object.
    #
    singleShot: func(delaySec, self, callback) {
        var timer = maketimer(delaySec, self, func () {
            callback();
        });
        timer.singleShot = true;
        timer.start();

        return timer;
    },
};
