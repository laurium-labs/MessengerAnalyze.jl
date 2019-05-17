module DateAnalysis
    import MessengerAnalyze 
    using MessengerAnalyze.Utils.DateOperations:getRangeOfDates
    using Query
    using DataFrames
    using Dates
    using TimeZones
    using Dates
    using Gadfly
    struct DateRangeAnalysis
        names::Tuple{AbstractString,AbstractString}
        beginAnalysis::DateTime
        endAnalysis::DateTime
    end
    function DateRangeAnalysis(config)
        DateRangeAnalysis((config["user-name-1"],config["user-name-2"]),DateTime(config["begin-date"]),DateTime(config["end-date"]))
    end

    function getYearMonth(dateTime::DateTime)
        return DateTime(Year(dateTime), Month(dateTime)) 
    end
    function monthYearsBetween(monthYearBegin::DateTime,monthYearEnd::DateTime)
        monthRange=Vector{DateTime}()
        currentMonth=monthYearBegin
        while currentMonth<=monthYearEnd
            push!(monthRange,currentMonth)
            currentMonth+=Month(1)
        end
        monthRange
    end
    function countMessagesInMonth(date::DateTime,names::Tuple{AbstractString,AbstractString},df::DataFrame)
        endTime =date+Month(1)
        MessagesInMonth =  @from message in df begin
                    @where date<=get(message.date)<endTime (message.senderName ==(names[1]|names[2]) && message.sendeeName ==(names[1]|names[2])  )
                    @select {message.date}
                    @collect DataFrame
        end
        return nrow(MessagesInMonth)
    end
    function producePlotMonthly(df::DataFrame, user1::AbstractString,user2::AbstractString,startDate::DateTime,endDate::DateTime)
        monthYearBegin = getYearMonth(startDate)
        monthYearEnd = getYearMonth(endDate)
        monthYearRange = monthYearsBetween(monthYearBegin,monthYearEnd)
        counts=map(date->countMessagesInMonth(date,(user1,user2),df),monthYearRange)
        labels=map(monthYearRange) do date
           monthabbr(date)*" "*string(Int64(year(date)))
        end
        
        plot(counts,xticks= (1:length(counts),labels),title="Monthly data",legend=false,yaxis="messages")
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Year})
        return DateTime(Year(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Month})
        return DateTime(Year(date),Month(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Week})
        return DateTime(Year(date),Month(date),Week(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Day})
        return DateTime(Year(date),Month(date),Week(date), Day(date)) 
    end 
    function getRoundedTime(date::DateTime,timeGradation::Type{Hour})
        return DateTime(Year(date),Month(date),Week(date), Day(date), Hour(date)) 
    end

    function messageBetweenPeopleOfInterest(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]|| senderName == names[2]) && (sendeeName==names[1] ||sendeeName ==names[2])
    end
    function countInDateBucket(date::DateTime,
                                names::Tuple{AbstractString,AbstractString},
                                df::DataFrame,
                                timeGradation::Type{dateType},
                                quantityDisplayed::Type{plotType}) where {dateType<:DatePeriod,plotType<:MessengerAnalyze.PlotType}
        dateEnd=date+timeGradation(1)
        MessagesInDate = @from message in df begin
                    @where date<=message.date<dateEnd && messageBetweenPeopleOfInterest(names, message.senderName, message.sendeeName)
                    @select {message.date}
                    @collect DataFrame
        end
        return nrow(MessagesInDate)/(quantityDisplayed==MessengerAnalyze.Total ? 1 : Dates.days(dateEnd-date))
    end


    function timeGroupingString(timeGradation::Type{dateType}) where dateType<:DatePeriod
        timeGradation==Year && return "Year"
        timeGradation==Month && return "Month"
        timeGradation==Week && return "Week"
        timeGradation==Day && return "Day"
    end
    function titleDailyPlot(user1::AbstractString,
                        user2::AbstractString,
                        timeGradation::Type{dateType},
                        quantityDisplayed::Type{plotType}) where {dateType<:DatePeriod, plotType<:MessengerAnalyze.PlotType}
        (quantityDisplayed==MessengerAnalyze.Total ? "Total messages " : "Average daily messages over a ")*
        timeGroupingString(timeGradation)*" between \n $user1 and $user2"
    end 
    function daily_messaging_plot(df::DataFrame, 
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                        timeGradation::Type{dateType},
                        quantityDisplayed::Type{plotType}) where {dateType<:DatePeriod, plotType<:MessengerAnalyze.PlotType}
        beginningTime=getRoundedTime(startDate,timeGradation)
        endTime = getRoundedTime(endDate,timeGradation)
        timeRange = getRangeOfDates(beginningTime,endTime,timeGradation)
        messagesInDateStep= map(date->countInDateBucket(date,(user1,user2),df,timeGradation,quantityDisplayed),timeRange)
        titlePlot=titleDailyPlot(user1,user2,timeGradation,quantityDisplayed)
        lineplot(timeRange,messagesInDateStep,titlePlot)
    end
    function lineplot(dates::Vector{DateTime},messagesInDateStep::Vector{real},titlePlot) where real<:Real
        df = DataFrame()
        df[:Dates]=dates
        df[:messageCount]=messagesInDateStep  
        plot(x=df[:Dates],y=df[:messageCount],Guide.title(titlePlot),Guide.xlabel(""),Guide.ylabel("messages"))
    end
    function dateToString(date::DateTime)
        string(monthabbr(Month(date).value))*"-"*string(Day(date).value)*"-"*string(Year(date).value)
    end
    function hourlyPlotTitle(user1::AbstractString,user2::AbstractString,startDate,endDate)
        "Hourly messaging between "*user1*" and "*user2*"\n from "*dateToString(startDate)*" to "*dateToString(endDate)
    end
    function messagesOfInterest(df::DataFrame,user1,user2,startDate,endDate)
        MessagesInDateWindow=@from message in df begin
            @where startDate<=message.date<endDate && messageBetweenPeopleOfInterest((user1,user2),message.senderName,message.sendeeName)
            @select {date=message.date}
            @collect DataFrame
            end
        return MessagesInDateWindow
    end
    function hourlyMessagingData(df::DataFrame,user1,user2,startDate,endDate)
        hourData=zeros(Int64,24)
        MessagesInDateWindow=messagesOfInterest(df,user1,user2,startDate,endDate)
        foreach(eachrow(MessagesInDateWindow)) do message
            hourData[Hour(message[:date].value)]+=1
        end
        return hourData
    end
    function hour_labels()
        map(1:24) do hour 
            hour_label(hour)
        end
    end
    function hour_label(hour)
        return hour<=12 ? string(hour)*":00 AM" : string(hour-12)*":00 PM"
    end
    function day_labels()
        map(1:7) do day
            dayabbr(day)
        end
    end
    function hourly_messaging_plot(df::DataFrame,
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                     )
            titlePlot=hourlyPlotTitle(user1,user2,startDate,endDate)
            hourly_messaging=hourlyMessagingData(df,user1,user2,startDate,endDate)

            plot(x=hour_labels(),y=hourly_messaging,Geom.point,Guide.title(titlePlot),Guide.ylabel("Total message count"))
    end
    function hourlyVsWeekPlotTitle(user1::AbstractString,user2::AbstractString,startDate,endDate)
        "Week-hour messaging heat map between "*user1*" and "*user2*"\n from "*dateToString(startDate)*" to "*dateToString(endDate)
    end
    function hours_vs_week_plot(df::DataFrame,
        user1::AbstractString,
        user2::AbstractString,
        startDate::DateTime,
        endDate::DateTime)
        titlePlot=hourlyVsWeekPlotTitle(user1,user2,startDate,endDate)
        selectedMessages=messagesOfInterest(df,user1,user2,startDate,endDate)
        selectedMessages[:DayOfWeek]=map(date->dayofweek(date),selectedMessages[:date])
        selectedMessages[:HourOfDay]=map(date->hour(date), selectedMessages[:date])
        #setlevels!(selectedMessages[:DayOfWeek],map(dayNumber->dayabbr(dayNumber),1:7))
        plot(selectedMessages, x="HourOfDay", y="DayOfWeek",
                            Guide.xticks(ticks=collect(1:24)),
                            Scale.x_continuous(labels=x->hour_label(x)),
                            Guide.yticks(ticks=collect(1:7)),
                            Scale.y_continuous(labels=x->dayabbr(x)),
                            Guide.ylabel("Day of the week"),
                            Guide.xlabel("Hour"), 
                            Geom.histogram2d, 
                            Guide.title(titlePlot))
    end
    export hours_vs_week_plot, hourly_messaging_plot, daily_messaging_plot
end