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
# Utils static methods.
#
var Utils = {
    #
    # Open URL or path in the system browser or file explorer.
    #
    # @param  hash  params  Parameters for open-browser command, can be "path" or "url".
    # @return void
    #
    openBrowser: func(params) {
        fgcommand("open-browser", props.Node.new(params));
    },

    #
    # @param  func  function
    # @param  vector  params  Vector of function params.
    # @param  hash  obj  Function context.
    # @return bool  Return true if given function was called without errors (die).
    #
    tryCatch: func(function, params, obj = nil) {
        var errors = [];
        call(function, params, obj, nil, errors);

        return !size(errors);
    },
};
