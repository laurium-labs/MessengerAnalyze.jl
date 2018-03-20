module MessengerTextAnalysis    
    using TextAnalysis
    using Query
    using DataFrames
    using MessengerAnalyze
    using MessengerAnalyze.Utils.DateOperations: getRoundedTime, getRangeOfDates

    export one_way_corpus, two_way_corpus

    function direction_match(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]&&sendeeName == names[2]) 
    end  
    function participation_match(names::Tuple{AbstractString,AbstractString},senderName,sendeeName)
        (senderName ==names[1]&&sendeeName == names[2])||(senderName ==names[2]&&sendeeName == names[1])
    end  
    function bucket_date(date::DateTime,timeRange::Vector{DateTime})

        indicies=findin(timeRange,[date])
        length(indicies)!=0?indicies[1]:-1
    end
    function document_vector(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        timeRange::Vector{DateTime},
        timeGradation::Type{dateType},
        user_match::Function) where dateType<:Dates.Period
        documents=Vector{Union{TextAnalysis.FileDocument, TextAnalysis.NGramDocument, TextAnalysis.StringDocument, TextAnalysis.TokenDocument}}()
        user_messages=@from message in df begin
            @where user_match((from_user,to_user),get(message.senderName),get(message.sendeeName))
            @select {Text=get(message.messageText),Date=get(message.date)}
            @collect DataFrame
        end
        length(user_messages)==0 && return ""
        user_messages[:bucket]=map(date->bucket_date(getRoundedTime(date,timeGradation),timeRange),user_messages[:Date])
        
        date_bucketed_messages = @from i in user_messages begin
            @where get(i.bucket)>0
            @group i.Text by i.bucket
            @collect 
        end
        foreach(date_bucketed_messages) do bucket_message
            string_messages=mapreduce(String,(l,r)->l*" "*r,bucket_message)
            length(string_messages)==0 && return
            push!(documents,StringDocument(string_messages))
        end
        return documents
    end
    function get_corpus(df::DataFrame, 
        from_user::AbstractString, 
        to_user::AbstractString, 
        start_date::DateTime,
        end_date::DateTime,
        timeGradation::Type{dateType},
        direction_function::Function) where dateType<:Dates.Period

        beginningTime=MessengerAnalyze.Utils.DateOperations.getRoundedTime(start_date,timeGradation)
        endTime = MessengerAnalyze.Utils.DateOperations.getRoundedTime(end_date,timeGradation)
        timeRange = MessengerAnalyze.Utils.DateOperations.getRangeOfDates(beginningTime,endTime,timeGradation)
        documents=document_vector(df,from_user,to_user,timeRange,timeGradation,direction_function)
        return Corpus(documents)
    end

    function one_way_corpus(df::DataFrame,
                        user_name1::AbstractString,
                        user_name2::AbstractString,
                        start_date::DateTime,
                        end_date::DateTime,
                        timeGradation::Type{dateType}) where dateType<:Dates.Period
        user1_to_user2_messages=get_corpus(df, user_name1,user_name2,start_date,end_date,timeGradation,direction_match)
    end
    function two_way_corpus(df::DataFrame,
        user_name1::AbstractString,
        user_name2::AbstractString,
        start_date::DateTime,
        end_date::DateTime,
        timeGradation::Type{dateType}) where dateType<:Dates.Period
        user1_to_user2_messages=get_corpus(df, user_name1,user_name2,start_date,end_date,timeGradation,participation_match)
    end
end