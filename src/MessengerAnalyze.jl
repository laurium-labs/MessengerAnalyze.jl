module MessengerAnalyze
  import JSON
  using DataFrames
  using MessengerAnalyzeTypes
  function extractFile end
  function producePlot end
  abstract type PlotType end
  type Total<:PlotType end
  type DailyAverage<:PlotType end


  module Utils
    map(filter(fileName->endswith(fileName,".jl"),readdir(string(@__DIR__)*"/utils"))) do fileName
        include((@__DIR__)*"/utils/"*fileName)
    end
  end
  module Analysis
    map(filter(fileName->endswith(fileName,".jl"),readdir(string(@__DIR__)*"/analysis"))) do fileName
        include((@__DIR__)*"/analysis/"*fileName)
    end
  end

  function extractFile(pathToFile::AbstractString)
    MessengerAnalyze.Utils.ParseFB.extractFile(pathToFile)
  end

  function comparePeople(df::DataFrame,
                        user1::AbstractString,
                        user2::AbstractString,
                        startDate::DateTime,
                        endDate::DateTime,
                        timeBucket::Type{dateType}, 
                        quantityDisplayed::Type{plotType}) where {dateType<:Dates.DatePeriod, plotType<:PlotType}
    MessengerAnalyze.Analysis.DateAnalysis.producePlot(df,user1,user2,startDate,endDate,timeBucket,quantityDisplayed)
  end

end
