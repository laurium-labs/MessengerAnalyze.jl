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
    function countInDateBucket(date::DateTime,
                                names::Tuple{AbstractString,AbstractString},
                                df::DataFrame,
                                timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        dateEnd=date+timeGradation(1)
        MessagesInDate = @from message in df begin
                    @where date<=get(message.date)<dateEnd (message.senderName ==(names[1]|names[2]) && message.sendeeName ==(names[1]|names[2])  )
                    @select {message.date}
                    @collect DataFrame
        end
        return nrow(MessagesInDate)
    end


    function timeGroupingString(timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        timeGradation==Dates.Year && return "Yearly"
        timeGradation==Dates.Month && return "Monthly"
        timeGradation==Dates.Week && return "Weekly"
        timeGradation==Dates.Day && return "Daily"
    end
    function titleTotal(user1::AbstractString,user2::AbstractString,timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        "Total "*timeGroupingString(timeGradation)*" messages between "*user1* " and "*user2
    end 
    function producePlotTotal(df::DataFrame, 
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                        timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        beginningTime=getRoundedTime(startDate,timeGradation)
        endTime = getRoundedTime(endDate,timeGradation)
        timeRange = getRangeOfDates(beginningTime,endTime,timeGradation)
        messagesInDateStep= map(date->countInDateBucket(date,(user1,user2),df,timeGradation),timeRange)
        lineplot(timeRange,messagesInDateStep,titleTotal(user1,user2,timeGradation))
        
    end
    function lineplot(dates::Vector{DateTime},messagesInDateStep::Vector{Int},titlePlot)


        df = DataFrame()
        df[:Dates]=dates
        df[:messageCount]=messagesInDateStep
        
        plot(x=df[:Dates],y=df[:messageCount],Guide.title(titlePlot),Guide.xlabel(""),Guide.ylabel("messages"))
        
    end
end