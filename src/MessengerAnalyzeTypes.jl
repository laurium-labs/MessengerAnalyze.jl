module MessengerAnalyzeTypes
    using DataFrames
    abstract type AbstractEntry end
  
    mutable struct UserQuery
        userName::AbstractString
        peopleMessaged::DataFrame
        dataFrameOfMessages::DataFrame
    end

    mutable struct Message<:AbstractEntry
        senderName::String
        sendeeName::String
        year::Dates.Year
        month::Dates.Month
        day::Dates.Day
        dayOfWeek::Int
        hour::Dates.Hour
        minute::Dates.Minute
        date::DateTime
        messageText::String
        multiMedia::Integer
    end

end