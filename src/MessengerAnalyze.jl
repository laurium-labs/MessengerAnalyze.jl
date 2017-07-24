module MessengerAnalyze
  import JSON
  using DataFrames
  using MessengerAnalyzeTypes
  function extractFile end
  function producePlot end



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

  function comparePeople(df::DataFrame,user1::AbstractString,user2::AbstractString,startDate::DateTime,endDate::DateTime)
    MessengerAnalyze.Analysis.DateAnalysis.producePlotMonthly(database,user1,user2,startDate,endDate)
  end

end
