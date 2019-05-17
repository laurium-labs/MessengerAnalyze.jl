module MessengerTextAnalysis
using TextAnalysis
using SparseArrays
using SparseArrays:nonzeroinds
using MessengerAnalyze.Utils.DateOperations:getRoundedTime
using DataFrames
using Query
using Dates
using Statistics
using Gadfly
using Compose
using Colors
using ColorTypes
function topic_top_words(ϕ::SparseMatrixCSC, corpus_dtm::DocumentTermMatrix, words_per_topic::Integer )
    map(1:size(ϕ,1)) do idx_topic
        vector_of_interest = ϕ[idx_topic,:]
        sorted_idxs=sort(SparseArrays.nonzeroinds(vector_of_interest), lt=(l,r) -> vector_of_interest[l] < vector_of_interest[r])
        map(sorted_idxs[end-words_per_topic+1:end]) do idx
            corpus_dtm.terms[idx]
        end 
    end
end
function converastion_topic_over_time(θ::Matrix, corpus::Corpus)
    date_times = map(document->DateTime(document.metadata.timestamp),corpus.documents)
    df = DataFrame(date_time = date_times)
    foreach(1:size(θ, 1)) do idx
        df[Symbol("topic $(idx)")] = map(val -> isnan(val) ? 0.0 : val, θ[idx, :])
    end
    return df
end
get_topics(df::DataFrame) = filter(name-> name!=:date_time && name != :rounded_month && name != :month, names(df))
function aggregate_topic_weights_by_month(df::DataFrame)
    topics = get_topics(df)
    df[:rounded_month] = map(time -> getRoundedTime(time, Month), df[:date_time])
    grouped_data = @from i in df begin
        @group i by i.rounded_month
        @collect 
    end
    summarize_data = let
        closest_month = map(month_data -> month_data.rounded_month[1],grouped_data)
        result_df = DataFrame(month=closest_month)
        foreach(topics) do topic
            weights = map(grouped_data) do month_topic_weight
                mean(el ->getfield(el, topic), month_topic_weight)
            end
            result_df[topic] = weights
        end
        result_df
    end
end

function plot_topics(θ::Matrix, corpus::Corpus;  colors_plot::Union{Vector{<:Color}, Nothing} = nothing)
    df_monthly_aggregated_topics = aggregate_topic_weights_by_month(converastion_topic_over_time(θ, corpus))
    plot_topics(df_monthly_aggregated_topics, colors_plot)
end
function plot_topics(df_monthly_aggregated_topics::DataFrame;  colors_plot::Union{Vector{<:Color}, Nothing} = nothing)

    topics = get_topics(df_monthly_aggregated_topics)    
    colors_plot = colors_plot == nothing ? distinguishable_colors(length(topics)) : colors_plot
    map(1:length(topics)) do idx
        plot(x=df_monthly_aggregated_topics[:month],y=df_monthly_aggregated_topics[topics[idx]],Guide.xlabel(""),Guide.ylabel("average content weight of $(string(topics[idx]))"),color=repeat(["$(string(topics[idx]))"]), Scale.color_discrete_manual(colors_plot[idx]))
    end
end
function build_lda(corpus::Corpus, number_of_topics::Integer; number_iterations::Integer=10000)
    update_lexicon!(corpus)
    corpus_dtm = DocumentTermMatrix(corpus)
    ϕ, θ  = lda(corpus_dtm, number_of_topics, number_iterations, .1, .1)
    return ϕ, θ, corpus_dtm 
end
export topic_top_words, build_lda, aggregate_topic_weights_by_month, converastion_topic_over_time, plot_topics
end