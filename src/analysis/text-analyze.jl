module MessengerTextAnalysis    
    using TextAnalysis
    using Query
    using DataFrames
    using MessengerAnalyze.Utils.DateOperations

    function messageReciveSendMatch(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]&&sendeeName == names[2]) 
    end
    function termDocumentFromTimeWindow(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        start_date::DateTime,
        end_date::DateTime)
        @from message in df begin
            @where start_date<=get(message.date)<end_date && messageReciveSendMatch((from_user,to_user),get(message.senderName),get(message.sendeeName))
            @select {get(message.messageText)}
            @collect DataFrame
        end
    end
    function extractMessages(df::DataFrame, 
                        from_user::AbstractString, 
                        to_user::AbstractString, 
                        start_date::DateTime,
                        end_date::DateTime,
                        timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        beginningTime=MessengerAnalyze.Utils.DateOperations.getRoundedTime(start_date,timeGradation)
        endTime = MessengerAnalyze.Utils.DateOperations.getRoundedTime(end_date,timeGradation)
        timeRange = MessengerAnalyze.Utils.DateOperations.getRangeOfDates(beginningTime,endTime,timeGradation)
        println(timeRange)
        return map(val->val[1],messages)
    end

    function wordCloud(df::DataFrame,user_name1::AbstractString,user_name2,start_date::DateTime,end_date::DateTime)
        user1_to_user2_messages=extractMessages(df, user_name1,user_name2,start_date,end_date)
        user2_to_user1_messages=extractMessages(df, user_name2,user_name1,start_date,end_date)
        
    end
    function lsaMessenger(df::DataFrame,user_name1::AbstractString,user_name2::AbstractString,start_date::DateTime,end_date::DateTime,timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        
        user1_to_user2_messages=extractMessages(df, user_name1,user_name2,start_date,end_date,timeGradation)
        user2_to_user1_messages=extractMessages(df, user_name2,user_name1,start_date,end_date,timeGradation)

        crps = Corpus(Any[user1_to_user2_messages,user2_to_user1_messages])
        prepare!(crps)
        stem!(crps)
 
        @show lsa(crps)
    end

end