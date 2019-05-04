
  
    mutable struct UserQuery
        userName::AbstractString
        peopleMessaged::DataFrame
        dataFrameOfMessages::DataFrame
    end

    mutable struct Message
        senderName::String
        sendeeName::String
        year::Year
        month::Month
        day::Day
        dayOfWeek::Int
        hour::Hour
        minute::Minute
        date::DateTime
        messageText::String
        multiMedia::Integer
    end
