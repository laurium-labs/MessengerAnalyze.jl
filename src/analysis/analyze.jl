module DateAnalysis
    import MessengerAnalyze 
    using Query
    using DataFrames
    using Gadfly
    using MessengerAnalyzeTypes
    struct DateRangeAnalysis
        names::Tuple{AbstractString,AbstractString}
        beginAnalysis::DateTime
        endAnalysis::DateTime
    end
    function DateRangeAnalysis(config)
        DateRangeAnalysis((config["user-name-1"],config["user-name-2"]),DateTime(config["begin-date"]),DateTime(config["end-date"]))
    end

    function getYearMonth(dateTime::DateTime)
        return DateTime(Dates.Year(dateTime),Dates.Month(dateTime)) 
    end
    function monthYearsBetween(monthYearBegin::DateTime,monthYearEnd::DateTime)
        monthRange=Vector{DateTime}()
        currentMonth=monthYearBegin
        while currentMonth<=monthYearEnd
            push!(monthRange,currentMonth)
            currentMonth+=Dates.Month(1)
        end
        monthRange
    end
    function countMessagesInMonth(date::DateTime,names::Tuple{AbstractString,AbstractString},df::DataFrame)
        endTime =date+Dates.Month(1)
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
           Dates.monthabbr(date)*" "*string(Int64(Dates.year(date)))
        end
        
        plot(counts,xticks= (1:length(counts),labels),title="Monthly data",legend=false,yaxis="messages")
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Dates.Year})
        return DateTime(Dates.Year(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Dates.Month})
        return DateTime(Dates.Year(date),Dates.Month(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Dates.Week})
        return DateTime(Dates.Year(date),Dates.Month(date),Dates.Week(date)) 
    end
    function getRoundedTime(date::DateTime,timeGradation::Type{Dates.Day})
        return DateTime(Dates.Year(date),Dates.Month(date),Dates.Week(date), Dates.Day(date)) 
    end 
    function getRoundedTime(date::DateTime,timeGradation::Type{Dates.Hour})
        return DateTime(Dates.Year(date),Dates.Month(date),Dates.Week(date), Dates.Day(date), Dates.Hour(date)) 
    end
    function getRangeOfDates(beginningTime::DateTime,endTime::DateTime,timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        dateRange=Vector{DateTime}()
        currentDate=beginningTime
        while currentDate<=endTime
            push!(dateRange,currentDate)
            currentDate+=timeGradation(1)
        end
        dateRange
    end
    function messageBetweenPeopleOfInterest(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]|| senderName == names[2]) && (sendeeName==names[1] ||sendeeName ==names[2])
    end
    function countInDateBucket(date::DateTime,
                                names::Tuple{AbstractString,AbstractString},
                                df::DataFrame,
                                timeGradation::Type{dateType},
                                quantityDisplayed::Type{plotType}) where {dateType<:Dates.DatePeriod,plotType<:MessengerAnalyze.PlotType}
        dateEnd=date+timeGradation(1)
        MessagesInDate = @from message in df begin
                    @where date<=get(message.date)<dateEnd && messageBetweenPeopleOfInterest(names,get(message.senderName),get(message.sendeeName))
                    @select {message.date}
                    @collect DataFrame
        end
        return nrow(MessagesInDate)/(quantityDisplayed==MessengerAnalyze.Total? 1: Dates.days(dateEnd-date))
    end


    function timeGroupingString(timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        timeGradation==Dates.Year && return "Yearly"
        timeGradation==Dates.Month && return "Monthly"
        timeGradation==Dates.Week && return "Weekly"
        timeGradation==Dates.Day && return "Daily"
    end
    function titlePlot(user1::AbstractString,
                        user2::AbstractString,
                        timeGradation::Type{dateType},
                        quantityDisplayed::Type{plotType}) where {dateType<:Dates.DatePeriod, plotType<:MessengerAnalyze.PlotType}
        (quantityDisplayed==MessengerAnalyze.Total?"Total ":"Average daily aggregated ")*
        timeGroupingString(timeGradation)*" messages between \n $user1 and $user2"
    end 
    function producePlot(df::DataFrame, 
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                        timeGradation::Type{dateType},
                        quantityDisplayed::Type{plotType}) where {dateType<:Dates.DatePeriod, plotType<:MessengerAnalyze.PlotType}
        beginningTime=getRoundedTime(startDate,timeGradation)
        endTime = getRoundedTime(endDate,timeGradation)
        timeRange = getRangeOfDates(beginningTime,endTime,timeGradation)
        messagesInDateStep= map(date->countInDateBucket(date,(user1,user2),df,timeGradation,quantityDisplayed),timeRange)
        lineplot(timeRange,messagesInDateStep,titlePlot(user1,user2,timeGradation,quantityDisplayed))
        
    end
    function lineplot(dates::Vector{DateTime},messagesInDateStep::Vector{real},titlePlot) where real<:Real
        df = DataFrame()
        df[:Dates]=dates
        df[:messageCount]=messagesInDateStep  
        data_plot=plot(x=df[:Dates],y=df[:messageCount],Guide.title(titlePlot),Guide.xlabel(""),Guide.ylabel("messages"))
        draw(SVG(titlePlot*".svg",8inch,8inch),data_plot)
    end
    function dateToString(date::DateTime)
        string(Dates.monthabbr(Dates.Month(date).value))*"-"*string(Dates.Day(date).value)*"-"string(Dates.Year(date).value)
    end
    function hourlyPlotTitle(user1::AbstractString,user2::AbstractString,startDate,endDate)
        "Hourly messaging between "*user1*" and "*user2*"\n from "*dateToString(startDate)*" to "*dateToString(endDate)
    end
    function hourlyMessagingData(df::DataFrame,user1,user2,startDate,endDate)
        hourData=zeros(Int64,24)
        MessagesInDateWindow=@from message in df begin
                            @where startDate<=get(message.date)<endDate && messageBetweenPeopleOfInterest((user1,user2),get(message.senderName),get(message.sendeeName))
                            @select {hour=message.hour}
                            @collect DataFrame
                            end
        foreach(eachrow(MessagesInDateWindow)) do message
            hourData[message[:hour].value+1]+=1
        end
        return hourData
    end
    function hourlyPlot(df::DataFrame,
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime
                     )
            titlePlot=hourlyPlotTitle(user1,user2,startDate,endDate)
            hourly_messaging=hourlyMessagingData(df,user1,user2,startDate,endDate)
            hour_labels=map(1:24) do hour 
                hour<=12? string(hour)*":00 AM":string(hour-12)*":00 PM"
            end
            println(hour_labels)
            hourly_plot=plot(x=hour_labels,y=hourly_messaging,Geom.point,Guide.title(titlePlot),Guide.ylabel("Total message count"))
            draw(SVG(mapreduce(string,(l,r)->l*r,"",split(titlePlot,"\n"))*".svg",6inch,6inch),hourly_plot)
    end
end