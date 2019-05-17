
  
    mutable struct UserQuery
        userName::AbstractString
        peopleMessaged::DataFrame
        dataFrameOfMessages::DataFrame
    end

    mutable struct Message
        senderName::String
        sendeeName::String
        date::DateTime
        messageText::String
        multiMedia::Integer
    end
