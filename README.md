# World-of-Parkour
World of Warcraft addon: Parkour puzzles throughout the world.

# Bugs

1. ~~Placing a point and reloading the UI reset the right click dropdown back to the tom tom default one.~~

# TODO

1. Course Creation Mode:
   1. Only allow Courses to be edited/created when in Course Creation Mode.
   2. Add ability to provide Hints on each point.
   3. When EXITING course creation mode:
      1. Make sure the user picked if they would like to save the course to Saved Courses.
   4. By default we save the active course to the current profile.

2. ~~Waypoints:~~
   1. ~~Make sure when a waypoint disappears, we point to the next waypoints in the course and not the closest waypoint.~~

3. Saving Courses:
   1. Show all saved courses.
   2. Saved courses will be Global state (Saved for the account.)
   3. Add ability to save the active courses
   4. Add ability to add details to the active course such as Title, Description, Author, Rules, etc...

4. Loading Courses:
   1. Allow 1 active course at a time.
   2. Load any of the saved courses into the active course.

5. Profiles:
   1. Add AceDBOptions (profile switching)

6. Slash Commands:
   1. Do we add slash commands using AceConfig or directly through Blizz API?
   2. What slash commands should be available?

7. GUI:
   1. GUI Should be a seperate window to the interface.
   2. Ability to enter in/out of course creation mode.
   3. See a list of all courses available to you.
   4. Course Creation Mode Disabled:
      1. Enable Create/Edit course buttons
   5. Course Creation Mode Enabled:
      1. Disable Create/Edit course buttons
      2. Add new tab that shows all course points with their details (hints, etc...)
         1. Ability to Add/remove points

8. Interface:
   1. Display reset buttons
   2. Button to show GUI and display slash command that shows GUI.

9.  Course sharing:
   3. Allow courses to be shared with a string
   4. Course serializer/deserializer

10. Reset Buttons:
    1.  Reset all saved courses (Should display a confirmation box)
    2.  Reset active course (Should display a confirmation box)
    3.  Reset addon to factory settings (Should display a confirmation box)
