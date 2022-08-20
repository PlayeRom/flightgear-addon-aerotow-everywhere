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

var g_Aerotow = nil;

#
# Initialize Aerotow
#
# addon - Addon object
#
var init = func (addon) {
    g_Aerotow = Aerotow.new(addon);
}

#
# Uninitialize Aerotow
#
var uninit = func () {
    if (g_Aerotow) {
        g_Aerotow.del();
    }
}
