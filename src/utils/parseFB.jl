module ParseFB
  import MessengerAnalyze
  #  using Calendar
   using Gumbo
   using Cascadia
  function getMembers(thread::Gumbo.HTMLNode)
    split(split(thread[1].text,"<")[1],", ")
  end
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
  function extractMessage(members::Vector{stringType},message::Tuple{Gumbo.HTMLNode,Gumbo.HTMLNode},database::MessengerAnalyze.Database) where stringType<:AbstractString
    textMessage,multiMedia=getTextAndMulti(message[2])
    messageSender=matchall(sel".user",message[1])[1][1].text
    messageTime=getTime(matchall(sel".meta",message[1])[1][1].text)
    messageSendee = setdiff(members,messageSender)[1]
    messageEntered=MessengerAnalyze.Utils.DatabaseHandling.Message(0,messageSender,messageSendee,Dates.datetime2unix(messageTime),textMessage,Int64(multiMedia))
    MessengerAnalyze.Utils.DatabaseHandling.writeDB(database,messageEntered)
  end
  function extractThread(thread::Gumbo.HTMLNode,database::MessengerAnalyze.Database)
    members = getMembers(thread)
    length(members)==2 || (println("only processing 2 person conversations"); return)
    messageMetaData=matchall(sel".message",thread)
    messages=matchall(sel"li, p",thread)
    pairedMetaMessages=map(idx->(messageMetaData[idx],messages[idx]), 1:length(messages))
    foreach(pairedMetaMessages) do pairMetaMessage 
      
      extractMessage(members,pairMetaMessage,database)
    end
  end

  function extractFile(database::MessengerAnalyze.Database,pathToFolder::String)
    messages=parsehtml(readstring(pathToFolder*"/messages.htm"))
    selectThreads=sel".thread"
    threads=matchall(selectThreads,messages.root)
    foreach(threads) do thread
      extractThread(thread,database)
    end
  end
end
