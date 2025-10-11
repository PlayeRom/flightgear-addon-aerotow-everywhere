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

        # List of files that should not be loaded.
        me._excluded = std.Hash.new({
            "/addon-main.nas":,
            "/Loader.nas":,
        });

        me._fullPath = os.path.new();

        return me;
    },

    #
    # Search for ".nas" files recursively and load them.
    #
    # @param  string  path  Starts as base absolute path of add-on.
    # @param  string  namespace  Namespace of add-on.
    # @param  int  level  Starts from 0, each subsequent subdirectory gets level + 1.
    # @param  string  relPath  Relative path to the add-on's root directory.
    # @return void
    #
    load: func(path, namespace, level = 0, relPath = "") {
        var entries = directory(path);

        foreach (var entry; entries) {
            if (entry == "." or entry == "..") {
                continue;
            }

            var fullRelPath = relPath ~ "/" ~ entry;
            if (me._excluded.contains(fullRelPath)) {
                logprint(LOG_WARN, level, ". ", namespace, " excluded -> ", fullRelPath);
                continue;
            }

            me._fullPath.set(path);
            me._fullPath.append(entry);

            if (me._fullPath.isFile() and me._fullPath.lower_extension == "nas") {
                logprint(LOG_WARN, level, ". ", namespace, " -> ", me._fullPath.realpath);
                io.load_nasal(me._fullPath.realpath, namespace);
                continue;
            }

            if (level == 0 and !string.imatch(entry, "nasal")) {
                # At level 0 we are only interested in the "nasal" directory.
                continue;
            }

            if (!me._fullPath.isDir()) {
                continue;
            }

            if (me._isDirInPath("Widgets")) {
                me.load(me._fullPath.realpath, "canvas",  level + 1, fullRelPath);
            } else {
                me.load(me._fullPath.realpath, namespace, level + 1, fullRelPath);
            }
        }
    },

    #
    # Returns true if expectedDirName is the last part of the me._fullPath,
    # or if expectedDirName is contained in the current path.
    #
    # @param  string  expectedDirName  The expected directory name, which means the namespace should change.
    # @return bool
    #
    _isDirInPath: func(expectedDirName) {
        return string.imatch(me._fullPath.file, expectedDirName)
            or string.imatch(me._fullPath.realpath, me._addon.basePath ~ "/*/" ~ expectedDirName ~ "/*");
    },
};
