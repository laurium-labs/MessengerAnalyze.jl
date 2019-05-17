using MessengerAnalyze:extract_conversations, daily_messaging_plot, 
        DailyAverage, hours_vs_week_plot, MessengerAnalyze, build_lda, topic_top_words, two_way_corpus, 
        aggregate_topic_weights_by_month, converastion_topic_over_time, plot_topics, save_svg_plot
using Dates
using TimeZones
using TextAnalysis
using Colors
using ColorTypes

df = extract_conversations("/home/bhalonen/Downloads/facebook-data/", tz"EST")
total_messaging_plot = daily_messaging_plot(df, "Brent Halonen", "Chloe Halonen", DateTime(2015, 11, 1), DateTime(2019,4,15), Month, DailyAverage)
pre_dating_schedule = hours_vs_week_plot(df, "Brent Halonen", "Chloe Halonen", DateTime(2015, 11, 1), DateTime(2016,6,15))
dating_schedule = hours_vs_week_plot(df, "Brent Halonen", "Chloe Halonen", DateTime(2016,6,15), DateTime(2018,6,15))
married_schedule = hours_vs_week_plot(df, "Brent Halonen", "Chloe Halonen", DateTime(2018,6,15), DateTime(2019,3,30))
save_svg_plot(total_messaging_plot, "images/total_messageing_CH_BH.svg")
save_svg_plot(pre_dating_schedule, "images/pre_dating_schedule_CH_BH.svg")
save_svg_plot(dating_schedule, "images/dating_schedule_CH_BH.svg")
save_svg_plot(married_schedule, "images/married_schedule_CH_BH.svg")


corpus = two_way_corpus(df, "Brent Halonen", "Chloe Halonen", DateTime(2015, 11, 1), DateTime(2019,4,15), Hour )
topic_count = 8
ϕ, θ, corpus_dtm = build_lda(corpus, topic_count, number_iterations=10000)

topic_top_words(ϕ, corpus_dtm, 10)
conversation_weight = converastion_topic_over_time(θ, corpus)
aggregated_data = aggregate_topic_weights_by_month(conversation_weight) 
colors_plot = [colorant"#e6194B", colorant"#3cb44b",colorant"#ffe119",colorant"#4363d8",colorant"#f58231", colorant"#911eb4", colorant"#42d4f4", colorant"#f032e6" ]
plots =plot_topics(aggregated_data, colors_plot)
mktempdir() do dir 
    save_svg_plot(plots[1], joinpath(dir,"example.svg"))
end
foreach(1:length(plots)) do idx
    save_svg_plot(plots[idx], "images/Topic_$(idx).svg")
end

