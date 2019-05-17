# MessengerAnalyze.jl
Analyzes Facebook messenger conversation between two people.
Takes conversations between two people and produces a plots. Messages per month, messages per person per month, day-week-hour analysis. Month-week of day.


Download your Facebook archive. This is detailed at the following link. Choose the JSON download option.
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
using TimeZones
```

To extract your messaging data, run
```
your_data=extract_conversations("<path-to-your-folder>",  tz"<your-timezone>")
```
To run analysis, you can extract two types of plots. One type of plot allows you to visualize messaging over a period of time. You can choose to aggregate over months, weeks, days (weeks seem somewhat less noisy). You can choose daily average or total messages as a plotting option.
```
daily_messaging_plot(your_data,"username1","username2", DateTime(2015,10,1), DateTime(2016,6,1), Dates.Week,DailyAverage)
```
An example of this plot can be seen between in my conversation with my wife.
<img src="./images/total_messageing_CH_BH.svg" alt="Brent and Chloe daily averages" class="center">

Another kind of plot is a 2D histogram of messaging versus hours and day of week. 
```
hours_vs_week_plot(your_data,"username1","username2", DateTime(2015,10,1),DateTime(2016,6,1))
```
An example of this plot can also be found in my conversation with my wife. You can see most of our messaging when we are married occurs when we are apart during the work day.
<img src="./images/married_schedule_CH_BH.svg" alt="Brent and Chloe weekly messaging while married" class="center">

## Topic extraction