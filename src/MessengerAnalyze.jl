module MessengerAnalyze
  using DataFrames
  function extractFile end
  function producePlot end
  abstract type PlotType end
  type Total<:PlotType end
  type DailyAverage<:PlotType end
  include((@__DIR__)*"/MessengerAnalyzeTypes.jl")
  export Total, DailyAverage, extractFolder,dailyMessagingPlot, hourlyMessagingPlot, hoursVsWeekPlot, one_way_corpus, two_way_corpus
  module Utils
    foreach(filter(fileName->endswith(fileName,".jl"),readdir(string(@__DIR__)*"/utils"))) do fileName
        include((@__DIR__)*"/utils/"*fileName)
    end
  end
  module Analysis
    foreach(filter(fileName->endswith(fileName,".jl"),readdir(string(@__DIR__)*"/analysis"))) do fileName
        include((@__DIR__)*"/analysis/"*fileName)
    end
  end

  function extractFolder(pathToFile::AbstractString)
    MessengerAnalyze.Utils.ParseFB.extractFolder(pathToFile)
  end

  function dailyMessagingPlot(df::DataFrame,
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                        timeBucket::Type{dateType}, 
                        quantityDisplayed::Type{plotType},
                        pathToSavePlot::AbstractString) where {dateType<:Dates.DatePeriod, plotType<:PlotType}
    MessengerAnalyze.Analysis.DateAnalysis.producePlot(df,user1,user2,startDate,endDate,timeBucket,quantityDisplayed,pathToSavePlot)
  end
  function hourlyMessagingPlot(df::DataFrame,
                              user1::AbstractString,
                              user2::AbstractString,
                              startDate::DateTime,
                              endDate::DateTime,
                              pathToSavePlot::AbstractString)
    MessengerAnalyze.Analysis.DateAnalysis.hourlyPlot(df,user1,user2,startDate,endDate,pathToSavePlot)
  end
  function hoursVsWeekPlot(df::DataFrame,
                            user1::AbstractString,
                            user2::AbstractString,
                            startDate::DateTime,
                            endDate::DateTime,
                            pathToSavePlot::AbstractString)
    MessengerAnalyze.Analysis.DateAnalysis.hoursVsWeekPlot(df,user1,user2,startDate,endDate,pathToSavePlot)
  end

end
