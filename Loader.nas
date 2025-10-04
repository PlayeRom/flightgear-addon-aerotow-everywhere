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
# A class for automatically loading Nasal files.
#
var Loader = {
    #
    # Constructor.
    #
    # @param  ghost  addon  The addons.Addon object.
    # @return hash
    #
    new: func(addon) {
        var me = {
            parents: [Loader],
            _addon: addon,
        };

        me._excludedForLevel0 = std.Vector.new([
            "addon-main.nas",
            "Loader.nas",
        ]);

        return me;
    },

    #
    # Search for ".nas" files recursively and load them.
    #
    # @param  string  path  Starts as base path of add-on.
    # @param  string  namespace  Namespace of add-on.
    # @param  int  level  Starts from 0, each subsequent subdirectory gets level + 1.
    # @return void
    #
    load: func(path, namespace, level = 0) {
        var entries = globals.directory(path);

        foreach (var entry; entries) {
            if ((level == 0 and me._excludedForLevel0.contains(entry))
                or entry == "."
                or entry == ".."
            ) {
                continue;
            }

            var fullPath = os.path.new(path);
            fullPath.append(entry);

            if (fullPath.isFile() and fullPath.lower_extension == "nas") {
                logprint(LOG_WARN, level, ". ", namespace, " -> ", fullPath.realpath);
                io.load_nasal(fullPath.realpath, namespace);
                continue;
            }

            if (level == 0 and !string.imatch(entry, "nasal")) {
                # At level 0 we are only interested in the "nasal" directory.
                continue;
            }

            if (!fullPath.isDir()) {
                continue;
            }

            if (me._isDirInPath("Widgets", fullPath)) me.load(fullPath.realpath, "canvas",  level + 1);
            else                                      me.load(fullPath.realpath, namespace, level + 1);
        }
    },

    #
    # Returns true if expectedDirName is the last part of the fullPath,
    # or if expectedDirName is contained in the current path.
    #
    # @param  string  expectedDirName  The expected directory name, which means the namespace should change.
    # @param  ghost  fullPath  Current full path as os.path object.
    # @return bool
    #
    _isDirInPath: func(expectedDirName, fullPath) {
        return string.imatch(fullPath.file, expectedDirName)
            or string.imatch(fullPath.realpath, me._addon.basePath ~ "/*/" ~ expectedDirName ~ "/*");
    },
};
