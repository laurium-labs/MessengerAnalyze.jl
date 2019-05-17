module DateOperations
    using Dates
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
        return DateTime(Year(date),Month(date), Day(date), Hour(date)) 
    end
    function getRangeOfDates(beginningTime::DateTime,endTime::DateTime,timeGradation::Type{dateType}) where dateType<:Period
        dateRange=Vector{DateTime}()
        currentDate=beginningTime
        while currentDate<=endTime
            push!(dateRange,currentDate)
            currentDate+=timeGradation(1)
        end
        dateRange
    end
end