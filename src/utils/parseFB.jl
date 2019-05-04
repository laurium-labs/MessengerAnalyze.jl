module ParseFB
  import MessengerAnalyze
  #  using Calendar
   using EzXML, Query,DataFrames
   using Dates
   """
   Big hack, should be fixed in Base. Considering this project.
   """
   function processAmPm(timeZoneRemoved::AbstractString,dateNo12Hour::DateTime)
       if contains(timeZoneRemoved,"am")
         if Dates.Hour(dateNo12Hour)==12
           return dateNo12Hour-Dates.Hour(12)
         else
           return dateNo12Hour
         end
       else
         if Dates.Hour(dateNo12Hour)==12
           return dateNo12Hour
         else
           return dateNo12Hour+Dates.Hour(12)
         end
       end
   end
   function removeTimezone12Hour(originalString::AbstractString)
       return originalString[1:end-6]
   end
   function getTime(timeStringFB::AbstractString)
       dateNo12Hour= DateTime(removeTimezone12Hour(timeStringFB),"E, U d, y at HH:MM")
       processAmPm(timeStringFB,dateNo12Hour)
   end
   function getUserName(messages)
       node=find(messages,"//title")
       split(nodecontent(node[1]),"-")[1]|>strip
   end
   function membersOfConversation(conversation)
       titleInfo=find(conversation|>root,"//title")
       length(titleInfo)==0 && return 0
       map(strip,split(split(titleInfo[1]|>nodecontent,"Conversation with")[2],","))
   end
   function getTextAndMulti(message)
       message==""&& return ("",true)
       return (message,false)
   end
   function arrayFromType(entry::MessengerAnalyze.Message) 
       map(fieldname->getfield(entry,fieldname),fieldnames(entry))
   end
   function logMessage(date::AbstractString,sender::AbstractString,sendee::AbstractString,message::AbstractString,messageLog::DataFrame)
       date_parsed=getTime(date)
       textMessage,multiMedia=getTextAndMulti(message)
       messageEntered=MessengerAnalyze.Message(sender,
                                           sendee,
                                           Dates.Year(date_parsed),
                                           Dates.Month(date_parsed),
                                           Dates.Day(date_parsed),
                                           Dates.dayofweek(date_parsed),
                                           Dates.Hour(date_parsed),
                                           Dates.Minute(date_parsed),
                                           date_parsed,
                                           textMessage,
                                           Int64(multiMedia))
       push!(messageLog,arrayFromType(messageEntered))
   end    
   function extractConversation(pathToFile::AbstractString,messageLog::DataFrame,analyzedUser::AbstractString)
       conversation=readhtml(pathToFile)
       members=membersOfConversation(conversation)
       members==0&&return
       senders=map(nodecontent,filter(elem->(haskey(elem,"class")&&elem["class"]=="user"),find(conversation|>root,"//span")))
       messages=map(nodecontent,find(conversation|>root,"//p"))
       dates=map(nodecontent,filter(elem->(haskey(elem,"class")&&elem["class"]=="meta"),find(conversation|>root,"//span")))
   
       messageDescriptions=map(zip(senders,messages,dates)) do messageDescription
           (sender=messageDescription[1], message=messageDescription[2], date=messageDescription[3])
       end
       foreach(messageDescriptions) do messageDescription
           if messageDescription.sender == analyzedUser
               foreach(members) do member
                   logMessage(messageDescription.date,messageDescription.sender,member,messageDescription.message,messageLog)
               end
           else
               logMessage(messageDescription.date,messageDescription.sender,analyzedUser,messageDescription.message,messageLog)
           end
       end
   end
     function fieldtypes(entryType::DataType)
       map(fieldname->fieldtype(entryType,fieldname),fieldnames(entryType))
     end
     function dataFrameFromType(::Type{entryType}) where entryType<:MessengerAnalyze.Message
         DataFrame([fieldtypes(entryType)...],[fieldnames(entryType)...],0)
     end
   function extractFolder(pathToFolder::String)
       messageLog=dataFrameFromType(MessengerAnalyze.Message)
       messages=readhtml(joinpath(pathToFolder,"html/messages.htm"))
       analyzedUser=getUserName(messages)
       referencesToConversations=map(node->node["href"],find(messages,"//a"))[11:end]
       foreach(referencesToConversations) do file
         extractConversation(joinpath(pathToFolder,file),messageLog,analyzedUser)
       end
       return messageLog
   end
end
