module MessengerAnalyze
  import JSON
  using DataFrames
  function extractFile end
  function producePlot end

  abstract type Database end

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

  function parseConfig(config)
    JSON.parse(readstring(config))
  end

  function analyzeFile(configPath)
    config=parseConfig(configPath)
    database=MessengerAnalyze.Utils.DatabaseHandling.Database(config)
    MessengerAnalyze.Utils.DatabaseHandling.setUp(database)
    MessengerAnalyze.Utils.ParseFB.extractFile(database,config["path-FB-file"])
  end

end
