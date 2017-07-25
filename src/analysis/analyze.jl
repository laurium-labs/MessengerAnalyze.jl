module DateAnalysis
    import MessengerAnalyze 
    using Query
    using DataFrames
    using Plots
    using MessengerAnalyzeTypes
    plotlyjs()
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
                    @where date<=get(message.date)<endTime #&& (message.senderName ==(names[1]|names[2]) && message.sendeeName ==(names[1]|names[2])  )
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

end