# "Aerotow Everywhere" - FlightGear add-on

This is an add-on designed to include an AI aircraft that will be able to tow a glider. The main idea is to be able to do this at any airport where you start with your glider.

## Installation

This add-on creates a flight plan in real-time based on the airport you are at. Unfortunately this causes a problem which you will have to solve manually by following the instructions below.
Namely, the flight plan for AI aircraft, by default, must be stored in the `$FG_ROOT/AI/FlightPlans/` directory. But for security reasons, Nasal scripts cannot save files to that directory, but can save e.g. to `$FG_HOME/Export/`. Therefore, the run-time created flight plan will just be saved to `$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow/AI/FlightPlans/`. The problem is that FlightGear does not know that it is supposed to look for the flight plan file in this location as well, so you have to tell it manually by using the `--data` command line option.

`$FG_HOME` is the FlightGear home path. It differs depending on the operating system.
Under Linux/macOS `$FG_HOME` is `/home/{username}/.fgfs/`.
Under Windows `$FG_HOME` is `C:\Users\{username}\AppData\Roaming\flightgear.org\`.
Where `{username}` is the name of the user logged into the operating system.

1. Download "Aerotow Everywhere" add-on and unzip it.
2. In Launcher go to "Add-ons" tab. Click "Add" button by "Add-on Module folders" section and select folder with unzipped "Aerotow Everywhere" add-on directory (or add command line options: `--addon=path`), and click "Fly!". After loading the simulator, a `$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow` directory should be created.
3. Close FlightGear for now.
4. In the file explorer of your operating system, find the directory `$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow`. This path must be added by the `--data` command line option, so it will be treated as an additional FGData directory. In Launcher go to "Settings" tab and in "Additionnal Setting" type for example on the Linux system: `--data=/home/{username}/.fgfs/Export/Addons/org.flightgear.addons.Aerotow` or on the Windows: `--data=C:\Users\{username}\AppData\Roaming\flightgear.org\Export\Addons\org.flightgear.addons.Aerotow`.
5. Run simulator again, now everything should be working.

## How to start?

Start FlightGear at any airport with your aircraft as a glider, such as ASK 21.

From the top menu, select `Aerotow Everywhere` -> `Call for Piper J3 Cub aircraft`, `Robin DR400` or `Cessna 182` (yes, you can choose from many aircrafts). The AI aircraft will appear to your right and align to the centreline of the runway in front of you. At this time you should hook up to the aircraft, most often by pressing the `Ctrl-o` key (check help of your glider). The AI aircraft will begin to accelerate and take off.

## How does the AI tow aircraft fly?

The tow plane always takes off in front of your runway and flies along the runway for 5 km, then turns back and flies downwind for 6 km, then turns back again and flies another 6 km. During this flight it is constantly gaining altitude. Then when it has completed the entire set route it simply turns right 90 degrees and flies at a constant altitude.

You can disconnect from the aircraft at any time, most often by pressing the `o` key.

## Menu of add-on

This add-on add a new item to main menu named "Aerotow Everywhere" with following items:

1. `Call for Piper J3 Cub aircraft` - load AI tow sceneraio with Piper J3 Cub. Possible altitude to reach ~3,600 ft.
2. `Call for Robin DR400 aircraft` - load AI tow sceneraio with Robin DR400. This aircraft has better performance and can take you to over 4,500 ft.
3. `Call for Cessna 182 aircraft` - load AI tow sceneraio with Cessna 182. This aircraft has little bit better performance than Robin.
4. `Disable tow aircraft` - unload AI tow sceneraio.
5. `Help` - display help dialog.
6. `About` - display about dialog with add-on information.

## Limitations

1. This add-on doesn't check if there are any obstacles in the AI aircraft's path, e.g. terrain, buildings, power lines, etc. Keep this in mind when choosing an airport.
2. Minimum FlightGear version: 2020.4.0 (dev/nightly). Because only nightly version is able to search for flight plans in additional FGData folders added by `--data` command line option.

## Troubleshotting

1. When I select `Aerotow Everywhere` -> `Call for Piper J3 Cub aircraft`, `Robin DR400` or `Cessana 182` from menu, I see "Let's fly!" message but nothing happened. The tow plane does not appear.

Probably you didn't include the `--data` command line option with the path where FlightGear should look for additional flight plan files for AI. Unfortunately, the simulator does not inform us that there was a problem with finding the flight plan file, so everything looks like it should work but does not.

For fix it, in the file explorer of your operating system, find the directory `$FG_HOME/Export/Addons/org.flightgear.addons.Aerotow`. This path must be added by the `--data` command line option, so it will be treated as an additional FGData directory where FlightGear will find the flight plan. In Launcher go to "Settings" tab and in "Additionnal Setting" type (on the Linux system):

```
--data=/home/{username}/.fgfs/Export/Addons/org.flightgear.addons.Aerotow
```

or on the Windows:

```
--data=C:\Users\{username}\AppData\Roaming\flightgear.org\Export\Addons\org.flightgear.addons.Aerotow
```

Run simulator again, now everything should be working.

## Authors

- Roman "PlayeRom" Ludwicki

## License

Aerotow Everywhere is an Open Source project and it is licensed under the GNU Public License v3 (GPLv3).
