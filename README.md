# MessengerAnalyze.jl
Analyzes Facebook messenger conversation between two people.
Takes conversations between two people and produces a plots. Messages per month, messages per person per month, day-week-hour analysis. Month-week of day.


Download your Facebook archive. This is detailed at the following link. 
https://www.facebook.com/help/131112897028467
Uncompress the archive in a convinent location.
Install julia, then run 
```
Pkg.clone("https://github.com/bhalonen/MessengerAnalyze.jl.git")
```
in the julia terminal.

Load the package with the following command.
```
using MessengerAnalyze
``

To extract your messaging data, run
```
your_data=extractFolder("<path-to-your-folder>")
```
To run analysis, you can extract two types of plots. One type of plot allows you to visualize messaging over a period of time. You can choose to aggregate over months, weeks, days (weeks seem somewhat less noisy). You can choose daily average or total messages as a plotting option.
```
dailyMessagingPlot(my_data,"username1","username2", DateTime(2015,10,1),DateTime(2016,6,1),Dates.Week,DailyAverage,pwd())
```
Another kind of plot is the user data functionality.