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

        me._excludedForLevel0 = [
            "addon-main.nas",
            "Loader.nas",
        ];

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
            if (entry == "." or entry == ".." or (level == 0 and contains(me._excludedForLevel0, entry))) {
                continue;
            }

            var fullPath = path ~ "/" ~ entry;

            if (io.is_regular_file(fullPath) and me._getExtension(entry) == ".NAS") {
                logprint(LOG_WARN, level, ". ", namespace, " -> ", fullPath);
                io.load_nasal(fullPath, namespace);
                continue;
            }

            if (level == 0 and !string.imatch(entry, "nasal")) {
                # At level 0 we are only interested in the "nasal" directory.
                continue;
            }

            if (!io.is_directory(fullPath)) {
                continue;
            }

               if (me._isNamespaceChange(entry, fullPath, "Widgets")) me.load(fullPath, "canvas", level + 1);
            elsif (me._isNamespaceChange(entry, fullPath, "Dev"))     me.load(fullPath, "dev", level + 1);
            else                                                      me.load(fullPath, namespace, level + 1);
        }
    },

    #
    # Get last 4 characters from file name as upper case.
    #
    # @param  string  fileName
    # @return string|nil
    #
    _getExtension: func(fileName) {
        var length = size(fileName);
        if (length <= 4) {
            return nil;
        }

        return string.uc(substr(fileName, length - 4));
    },

    #
    # Returns true if expectedDirName is the current directory, or if expectedDirName is contained in the current path.
    #
    # @param  string  dirName   Single current directory name.
    # @param  string  fullPath  Current full path.
    # @param  string  expectedDirName  The expected directory name, which means the namespace should change.
    # @return bool
    #
    _isNamespaceChange: func(dirName, fullPath, expectedDirName) {
        return string.imatch(dirName, expectedDirName)
            or string.imatch(fullPath, me._addon.basePath ~ "/*/" ~ expectedDirName ~ "/*");
    },
};
