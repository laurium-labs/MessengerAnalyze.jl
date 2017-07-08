module MessengerAnalyze
  import JSON
  using DataFrames
  function extractFile end

  abstract type Database end


 module Utils
    map(filter(fileName->endswith(fileName,".jl"),readdir(string(@__DIR__)*"/utils"))) do fileName
        include((@__DIR__)*"/utils/"*fileName)
    end
  end

  function parseConfig(config)
    JSON.parse(readstring(config))
  end

  function analyzeFile(config)
    config=parseConfig(config)

    # MessengerAnalyze.Utils.ParseFB.extractFile(config["path-FB-file"])
  end

end
