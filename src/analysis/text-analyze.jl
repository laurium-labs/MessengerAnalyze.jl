module MessengerTextAnalysis    
    using TextAnalysis
    using Query
    using DataFrames
    using MessengerAnalyze
    using MessengerAnalyze.Utils.DateOperations

    function messageReciveSendMatch(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]&&sendeeName == names[2]) 
    end  
    function participationMatch(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]&&sendeeName == names[2])||(senderName ==names[2]&&sendeeName == names[1])
    end  
    function document_one_way(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        start_date::DateTime,
        end_date::DateTime)
        nt_messages=@from message in df begin
            @where start_date<=get(message.date)<end_date && messageReciveSendMatch((from_user,to_user),get(message.senderName),get(message.sendeeName))
            @select {get(message.messageText)}
            @collect 
        end
        length(nt_messages)==0 && return ""
        mapreduce(entry->entry._1_,(l,r)->l*" "*r,nt_messages)
    end
    function document_two_way(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        start_date::DateTime,
        end_date::DateTime)
        nt_messages=@from message in df begin
            @where start_date<=get(message.date)<end_date && participationMatch((from_user,to_user),get(message.senderName),get(message.sendeeName))
            @select {get(message.messageText)}
            @collect 
        end
        length(nt_messages)==0 && return ""
        mapreduce(entry->entry._1_,(l,r)->l*" "*r,nt_messages)
    end
    function get_corpus(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        start_date::DateTime,
        end_date::DateTime,
        timeGradation::Type{dateType},
        extraction_function::Function) where dateType<:Dates.DatePeriod

        beginningTime=MessengerAnalyze.Utils.DateOperations.getRoundedTime(start_date,timeGradation)
        endTime = MessengerAnalyze.Utils.DateOperations.getRoundedTime(end_date,timeGradation)
        timeRange = MessengerAnalyze.Utils.DateOperations.getRangeOfDates(beginningTime,endTime,timeGradation)
        documents=Vector{Union{TextAnalysis.FileDocument, TextAnalysis.NGramDocument, TextAnalysis.StringDocument, TextAnalysis.TokenDocument}}()
        for idx in 1:(length(timeRange)-1)
            messages_in_window=extraction_function(df,from_user,to_user,timeRange[idx],timeRange[idx+1])
            length(messages_in_window)!=0&&push!(documents,StringDocument(messages_in_window))
        end
        return Corpus(documents)
    end

    function one_way_corpus(df::DataFrame,
                        user_name1::AbstractString,
                        user_name2::AbstractString,
                        start_date::DateTime,
                        end_date::DateTime,
                        timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        user1_to_user2_messages=get_corpus(df, user_name1,user_name2,start_date,end_date,timeGradation,document_one_way)
    end
    function two_way_corpus(df::DataFrame,
        user_name1::AbstractString,
        user_name2::AbstractString,
        start_date::DateTime,
        end_date::DateTime,
        timeGradation::Type{dateType}) where dateType<:Dates.DatePeriod
        user1_to_user2_messages=get_corpus(df, user_name1,user_name2,start_date,end_date,timeGradation,document_two_way)
    end
end