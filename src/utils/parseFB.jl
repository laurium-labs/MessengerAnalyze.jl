module ParseFB
  import MessengerAnalyze
   using JSON, Query,DataFrames
   using Dates
   using TimeZones

   function get_user_name(fb_data_folder::AbstractString)
       JSON.parsefile(joinpath(fb_data_folder,"profile_information/profile_information.json"))["profile"]["name"]["full_name"]
   end
   function members_of_conversation(conversation::Dict)
       map(participant->participant["name"],conversation["participants"])
   end
   function arrayFromType(entry::MessengerAnalyze.Message) 
       map(fieldname->getfield(entry,fieldname),fieldnames(typeof(entry)))
   end
   function log_message(message::Dict, members::Vector,message_log::DataFrame, time_zone::FixedTimeZone)
        content = haskey(message, "content") ? message["content"] : ""
        multimedia = haskey(message, "photos") || haskey(message, "audio_files")
       date = DateTime(astimezone(TimeZones.unix2zdt(message["timestamp_ms"]/1000), time_zone))
       sender = message["sender_name"]
       sendee = filter(member-> member != sender, members)[1]
       messageEntered=MessengerAnalyze.Message(sender,
                                           sendee,
                                           date,
                                           content,
                                           Int64(multimedia))
       push!(message_log, arrayFromType(messageEntered))
   end    
   function extract_conversation(conversation::Dict,message_log::DataFrame, analyzed_user::AbstractString, time_zone::FixedTimeZone)
      members=members_of_conversation(conversation)
      length(members)!=2 && return
      foreach(conversation["messages"]) do message
        log_message(message,members,message_log, time_zone)
      end
   end
     function dataFrameFromType(::Type{entryType}) where entryType<:MessengerAnalyze.Message
         DataFrame([fieldtypes(entryType)...],[fieldnames(entryType)...],0)
     end
   function extract_conversations(fb_data_folder::AbstractString, time_zone::FixedTimeZone)
       messageLog=dataFrameFromType(MessengerAnalyze.Message)
       conversations = readdir(joinpath(fb_data_folder, "messages", "inbox"))
       analyzed_user=get_user_name(fb_data_folder)
       foreach(conversations) do conversation_folder
          full_conversation_folder = joinpath(fb_data_folder,"messages", "inbox",conversation_folder)
          foreach(readdir(full_conversation_folder)) do conversation_file
            splitext(conversation_file)[2] != ".json" && return
            conversation = JSON.parsefile(joinpath(full_conversation_folder,conversation_file))
            extract_conversation(conversation,messageLog,analyzed_user, time_zone)
          end 
       end
       return messageLog
   end
   export extract_conversations
end
