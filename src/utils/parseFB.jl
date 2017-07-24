module ParseFB
  import MessengerAnalyze
  import MessengerAnalyzeTypes
  #  using Calendar
   using Gumbo, Cascadia, Query,DataFrames
  function getMembers(thread::Gumbo.HTMLNode)
    split(split(thread[1].text,"<")[1],", ")
  end
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
  function getTextAndMulti(message::Gumbo.HTMLNode)
    length(children(message))==0&& return ("",true)
    return (message[1].text,false)
  end
  function extractMessage(members::Vector{stringType},message::Tuple{Gumbo.HTMLNode,Gumbo.HTMLNode},df::DataFrame) where stringType<:AbstractString
    textMessage,multiMedia=getTextAndMulti(message[2])
    messageSender=matchall(sel".user",message[1])[1][1].text
    messageTime=getTime(matchall(sel".meta",message[1])[1][1].text)
    messageSendee = setdiff(members,[messageSender])[1]
    messageEntered=MessengerAnalyzeTypes.Message(messageSender,
                                            messageSendee,
                                            Dates.Year(messageTime),
                                            Dates.Month(messageTime),
                                            Dates.Day(messageTime),
                                            Dates.dayofweek(messageTime),
                                            Dates.Hour(messageTime),
                                            Dates.Minute(messageTime),
                                            messageTime,
                                            textMessage,
                                            Int64(multiMedia))
    push!(df,arrayFromType(messageEntered))
  end
  function arrayFromType(entry::MessengerAnalyzeTypes.AbstractEntry) 
    map(fieldname->getfield(entry,fieldname),fieldnames(entry))
  end
  function extractThread(thread::Gumbo.HTMLNode,df::DataFrame)
    members = getMembers(thread)
    length(members)==2 || (println("only processing 2 person conversations"); return)
    messageMetaData=matchall(sel".message",thread)
    messages=matchall(sel"li, p",thread)
    pairedMetaMessages=map(idx->(messageMetaData[idx],messages[idx]), 1:length(messages))
    foreach(pairedMetaMessages) do pairMetaMessage 
      extractMessage(members,pairMetaMessage,df)
    end
  end
  function fieldtypes(entryType::DataType)
    map(fieldname->fieldtype(entryType,fieldname),fieldnames(entryType))
  end
  function dataFrameFromType(::Type{entryType}) where entryType<:MessengerAnalyzeTypes.AbstractEntry
      DataFrame(fieldtypes(entryType),fieldnames(entryType),0)
  end
  function getUserName(messages::Gumbo.HTMLDocument)
    userNameNode=matchall(sel"h1",messages.root)
    children(userNameNode[1])[1].text
  end
  function getMessagingPartners(df::DataFrame,userName::String)
    messagePartner = @from message in df begin
                    @let partner = (message.sendeeName == userName? message.senderName : message.sendeeName)
                    @group message by partner into g
                    @select {Name=g.key,Count=length(g)}
                    @collect DataFrame
      end
      return messagePartner
  end
  function extractFile(pathToFolder::String)
    messages=parsehtml(readstring(pathToFolder*"/messages.htm"))
    selectThreads=sel".thread"
    threads=matchall(selectThreads,messages.root)
    userName=getUserName(messages)
    dataFrame=dataFrameFromType(MessengerAnalyzeTypes.Message)
    foreach(threads) do thread
      extractThread(thread,dataFrame)
    end
    messagingPartners=getMessagingPartners(dataFrame,userName)
    return MessengerAnalyzeTypes.UserQuery(userName,messagingPartners,dataFrame)
  end
end
