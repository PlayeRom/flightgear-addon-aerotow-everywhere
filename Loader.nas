#
# CanvasSkeleton Add-on for FlightGear
#
# Written and developer by Roman Ludwicki (PlayeRom, SP-ROM)
#
# Copyright (C) 2025 Roman Ludwicki
#
# This is an Open Source project and it is licensed
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
        var obj = {
            parents: [Loader],
            _addon: addon,
        };

        # List of files that should not be loaded.
        obj._excluded = std.Hash.new();
        obj._excludedByConfig();

        obj._fullPath = os.path.new();

        return obj;
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
                logprint(LOG_WARN, "Level: ", level, ". namespace: ", namespace, " excluded -> ", fullRelPath);
                continue;
            }

            me._fullPath.set(path);
            me._fullPath.append(entry);

            if (me._fullPath.isFile() and me._fullPath.lower_extension == "nas") {
                logprint(LOG_WARN, "Level: ", level, ". namespace: ", namespace, " -> ", fullRelPath);
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

            me.load(me._fullPath.realpath, me._getNamespace(namespace), level + 1, fullRelPath);
        }
    },

    #
    # Get namespace for load new directory.
    #
    # @param  string  currentNamespace
    # @return string
    #
    _getNamespace: func(currentNamespace) {
        return me._isDirInPath("Widgets")
            ? "canvas"
            : currentNamespace;
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

    #
    # @return void
    #
    _excludedByConfig: func() {
        if (!Config.dev.useEnvFile) {
            me._excluded.set("/nasal/Utils/Dev/DevEnv.nas", nil);
            me._excluded.set("/nasal/Utils/Dev/DevReloadMenu.nas", nil);
            me._excluded.set("/nasal/Utils/Dev/DevReloadMultiKey.nas", nil);
        }

        if (!Config.useVersionCheck.byGitTag) {
            me._excluded.set("/nasal/Utils/VersionCheck/GitTagVersionChecker.nas", nil);
            me._excluded.set("/nasal/Utils/VersionCheck/Base/JsonVersionChecker.nas", nil);
        }

        if (!Config.useVersionCheck.byMetaData) {
            me._excluded.set("/nasal/Utils/VersionCheck/MetaDataVersionChecker.nas", nil);
            me._excluded.set("/nasal/Utils/VersionCheck/Base/XmlVersionChecker.nas", nil);
        }

        foreach (var file; Config.excludedFiles) {
            me._excluded.set(file, nil);
        }
    },
};
