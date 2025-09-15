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
# Global object of addons.Addon.
#
var g_Addon = nil;

#
# Global object of Aerotow.
#
var g_Aerotow = nil;

#
# Initialize Aerotow.
#
# @param  ghost  addon  The addons.Addon object.
# @return void
#
var init = func(addon) {
    g_Addon = addon;
    g_Aerotow = Aerotow.new();
};

#
# Uninitialize Aerotow.
#
# @return void
#
var uninit = func() {
    if (g_Aerotow) {
        g_Aerotow.del();
    }
};
