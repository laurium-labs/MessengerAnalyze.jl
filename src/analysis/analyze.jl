module DateAnalysis
    import MessengerAnalyze 
    using Query
    using DataFrames
    struct DateRangeAnalysis
        names::Tuple{AbstractString,AbstractString}
        beginAnalysis::DateTime
        endAnalysis::DateTime
    end
    function DateRangeAnalysis(config)
        DateRangeAnalysis((config["user-name-1"],config["user-name-2"]),DateTime(config["begin-date"]),DateTime(config["end-date"]))
    end

    function getYearMonth(dateTime::DateTime)
        return DateTime(Year(dateTime),Month(dateTime)) 
    end
    function monthYearsBetween(monthYearBegin::DateTime,monthYearEnd::DateTime)
        monthRange=Vector{DateTime}()
        currentMonth=monthYearBegin
        while currentMonth<monthYearEnd
            push!(monthRange,currentMonth)
            currentMonth+=Month(1)
        end
    end
    function countMessagesInMonth(date::DateTime,names::Tuple{AbstractString,AbstractString})
        MessagesTable = MessengerAnalyze.Utils.DataHandling.getSQLiteSource(MessengerAnalyze.Utils.DataHandling.Message)
        beginTime=Dates.datetime2unix(date)
        endTime = Dates.datetime2unix(date+Month(1))
        MessagesInMonth=   @from message in MessagesTable do 
                    @where beginTime<message.timeMessage<endTime && (message.senderName ==(names[1]|names[2]) && message.sendeeName ==(names[1]|names[2])  )
                    @select {message.timeMessage}
                    @collect DataFrame
        end
        return nrow(MessagesInMonth)
    end
    function MessengerAnalyze.producePlotMonthly(dateRange::DateRangeAnalysis,database::MessengerAnalyze.Database)
        monthYearBegin = getYearMonth(dateRange.beginAnalysis)
        monthYearEnd = getYearMonth(dateRange.endAnalysis)
        monthYearRange = monthYearsBetween(monthYearBegin,monthYearEnd)
        counts=map(date->countMessagesInMonth(date,dateRange.names),monthYearRange)
        

    end

end