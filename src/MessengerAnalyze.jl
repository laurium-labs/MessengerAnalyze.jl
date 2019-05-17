module MessengerAnalyze
  using DataFrames
  using TimeZones
  using Reexport
  using Gadfly

  function extractFile end
  function producePlot end
  abstract type PlotType end
  abstract type Total<:PlotType end
  abstract type DailyAverage<:PlotType end
  using Dates
  include((@__DIR__)*"/MessengerAnalyzeTypes.jl")
  export Total, DailyAverage, extract_conversations, daily_messaging_plot, hourly_messaging_plot, hours_vs_week_plot, one_way_corpus, two_way_corpus, build_lda, topic_top_words
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
  @reexport using .Utils.MessengerTextParsing
  @reexport using .Analysis.MessengerTextAnalysis
  @reexport using .Analysis.DateAnalysis
  @reexport using .Utils.ParseFB

  function save_svg_plot(plot::Plot , path_to_save_plot::AbstractString)
    draw(SVG(path_to_save_plot,6inch,6inch),plot)
  end

end
