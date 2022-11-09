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

From the top menu, select `Aerotow Everywhere` -> `Call for Piper J3 Cub aircraft`, `Robin DR400`,  `Cessna 182` or `Douglas C-47`. (Yes, you can choose from many aircrafts). The AI aircraft will appear to your right and align to the centreline of the runway in front of you. At this time you should hook up to the aircraft, most often by pressing the `Ctrl-o` key (check help of your glider). The AI aircraft will begin to accelerate and take off.

You can also take off in the bush. Then the tow plane will position itself in front of you (glider's course), so what heading you have is important. If you move away from the runway threshold further than 100 m, then the take-off of the tow plane will be as in the bush, i.e. according to the glider heading and not the runway.

## How does the AI tow aircraft fly by default?

The tow plane always takes off in front of your runway and flies along the runway for 5 km, then turns back and flies downwind for 6 km, then turns back again and flies another 6 km. During this flight it is constantly gaining altitude. Then, after having flown the entire given route, it lands at the airport from which it took off or when start in the bush turns in an unknown direction and flies at a constant altitude. If the aircraft lands at the airport, the scenario starts again, i.e. the aircraft respawn to take-off again.

You can disconnect from the aircraft at any time, most often by pressing the `o` key (check help of your glider).

```
Default route
^ - airport with heading direction to north
1 - 1st waypoint
2 - 2nd waypoint, etc.

    2 . . 1   5
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     .   .
    .     ^   .
    .         .
    .         .
    3 . . . . 4
```

## Menu of add-on

This add-on add a new item to main menu named `Aerotow Everywhere` with following items:

1. `Aerotow Route` - display the dialog for change aerotow route.
2. `Towrope Configuration` - display the dialog for change towrope parameters.
3. `Call for Piper J3 Cub aircraft` - load AI tow sceneraio with Piper J3 Cub.
4. `Call for Robin DR400 aircraft` - load AI tow sceneraio with Robin DR400. This aircraft has better performance and can take you higher then Piper Cub.
5. `Call for Cessna 182 aircraft` - load AI tow sceneraio with Cessna 182. This aircraft has little bit better performance than Robin.
6. `Call for Douglas C-47 aircraft` - load AI tow sceneraio with Douglas C-47.
7. `Disable tow aircraft` - unload AI tow sceneraio.
8. `Add thermal` - display the dialog for configuring and adding thermal.
9. `Help` - display help dialog.
10. `About` - display about dialog with add-on information.

## Aerotow Route

You can change the AI aircraft's default route, for this go to menu `Aerotow Everywhere` -> `Aerotow Route`.

### Aerotow aircraft

On the top of the "Aerotow Route" dialog you have selector to change aircraft type. It's only for calculate performance and display how the altitude will change.

### Max alt (AGL)

Here you can set limit of AGL altitude. 0 means without limits - the plane will always increase its altitude during its flight. AGL is always in terms of the place you are starting from.

### Route

Next you have initial heading, distance and altitude change. "Initial heading" depend of the runway where you are located. The aircraft will always take-off along the runway, a distance of 100 m, where it will gain 20 ft in altitude above the terrain. These parameters you cannot change unless you change the airport/runway.

Next you can see a table with fields where you can change values. Each row represents a single waypoint of flight plan of AI aircraft. For each waypoint you have following columns:

1. `Heading change (deg)` - information on how the heading of the aircraft should change in relation to the previous one. A value of `0` means no change, so continue with the same heading. And e.g. `-90` means a left turn of 90 degrees, `60` means a right turn of 60 degrees, etc.
2. `Distance (m)` - distance in meters from the previous waypoint to the present one.
3. `Alt change (AGL ft)` - information on how much the altitude on this leg of the route will increase (in feet above ground.) This information depend of selected airplane. AGL is always in terms of the place you are starting from (not the waypoint place).

If you enter a value less than or equal to `0` for `Distance (m)` field this means that here the route is end and the next rows will not be included to the flight plan.

You have a maximum of 10 waypoints to use, hope that's enough.

On the below of the dialog you can see a total amount of distance (in meters) and total altitude in feet above ground level.

### Buttons

1. `OK` - close the route dialog.
2. `Default` - set default waypoints (your changes will be lost.)

## Adding thermals

An additional feature of this add-on is the possibility of placing the thermals just in front of the glider. To do this, go to menu `Aerotow Everywhere` -> `Add thermal` where you can configure the following parameters:

1. `Distance` - the distance in metres at which the thermals will be placed in front of the gliders.
2. `Strength` - thermal strength in feet per second.
3. `Diameter` - diameter of thermal in feet.
4. `Height` - height of thermal in feet above mean sea level.

Click `Add thermal` button for add the thermal.

Many thanks to the FG forum user "wlbragg" for proposing and presenting a solution to this feature.

## Limitations

1. This add-on doesn't check if there are any obstacles in the AI aircraft's path, e.g. terrain, buildings, power lines, etc. Keep this in mind when choosing an airport or planning your route.
2. Minimum FlightGear version: 2020.4.0 (dev/nightly). Because only nightly version is able to search for flight plans in additional FGData folders added by `--data` command line option.

## Troubleshotting

1. When I select `Aerotow Everywhere` -> `Call for Piper J3 Cub aircraft`, `Robin DR400`, `Cessana 182` or `Douglas C-47` from menu, I see "Let's fly!" message but nothing happened. The tow plane does not appear.

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
