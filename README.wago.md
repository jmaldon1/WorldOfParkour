# WorldofParkour
World of Warcraft addon: Parkour puzzles throughout the world.

# Features

* Many built in courses to challenge your parkour skills.
* Easily create parkour courses anywhere around World of Warcraft.
* Share courses with friends.
* Uses TomTom waypoints to easily show the course points.

# Known Issues

* **DO NOT right-click the Crazy Waypoint Arrow that TomTom provides and use any of those options.** It can easily bug out your course run or creation.
* TomTom seems to not always want to clear points even when you are standing on them. So if this occurs, just right click the point on the minimap and press `Complete point` to manually complete it.


# Quick Start

To open WorldOfParkour, type `/wop` or `/parkour` into your chat and hit enter.

# How to Run a Course

Simply pick a course from either the `Your Courses` tab or the `Official Courses` tab and set it as the `Active Course`.

# Course Creation

## GIF

![course creation](https://github.com/jmaldon1/WorldOfParkour/raw/main/docs/media/course_creation.gif "Course Creation")

## Written instructions

1. Click `New course`.
2. Click `Set As Active Course`.
3. Click the `edit` tab.
4. Click `Edit Course`.
5. Enter the details of your course.
6. Run your course and as you progress through, click `Add point` to put down a marker at your current position.
7. Add `hints` to your points if you'd like.
8. Use the [Tips & Tricks](Tips_&_Tricks) section to see some ways to make adding points super simple during your parkour runs.

# Course Sharing

## Sharing a Course

Press the `Show sharable course string` toggle. Copy and paste the string to your friends.

![course share](https://github.com/jmaldon1/WorldOfParkour/raw/main/docs/media/show_course_share.png "Course Share")

## Importing a Course

Press the `Your Courses` tab and paste the course string into the `Import course` input box.

![course import](https://github.com/jmaldon1/WorldOfParkour/raw/main/docs/media/import_course_share.png "Course Import")


# Commands

1. `/wop` or `/parkour` to open the WorldOfParkour UI.

2. `/wopsetpoint`: Set the next point for the course. Equivalent to pressing `Add Point` in the UI.
   1. Example:

   ```
    Points: [1, 2, 3, 4, 5]
    /wopsetpoint
    Points: [1, 2, 3, 4, 5, 6]
                            ^
                            This is the new point.
   ```

3. `/wopsetpointafter`: Set a point after another existing point in the course. Equivalent to pressing `Add point after` or `Add point to beginning` in the UI. 
   1. `args`
      1. `Index[number]`: Index of the point to add another point after.
   2. Example: 
    
    ```
    Points: [1, 2, 3, 4, 5]
    /wopsetpointafter 2
    Points: [1, 2, 3, 4, 5, 6]
                   ^
                   This is the new point.
    ```

# Tips & Tricks

* Create a macro with `/wopsetpoint` and add it to your action bar to quickly add points to a course without opening the WorldOfParkour UI.
  * _(NOTE: You need to be editing the course for `/wopsetpoint` to work.)_.
* Hints for each point can be seen by right clicking the minimap point icon and clicking `Show hint`.
* **Good practice:** Say the starting location of the course in the description.
  * Why? If the user is in a different world than the first waypoint, the user will not see a waypoint arrow appear on their screen.
