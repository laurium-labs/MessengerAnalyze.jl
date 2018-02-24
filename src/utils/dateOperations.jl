module DateOperations
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
end