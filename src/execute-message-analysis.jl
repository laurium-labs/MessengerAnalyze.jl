#!/usr/bin/env julia
push!(LOAD_PATH, (@__DIR__))

using ArgParse
import MessengerAnalyze

function main(args)

    # initialize the settings (the description is for the help screen)
    s = ArgParseSettings(description = "Example 1 for argparse.jl: minimal usage.")

    @add_arg_table s begin
        "--config-file"               # an option (will take an argument)
    end

    parsed_args = parse_args(s) # the result is a Dict{String,Any}
    for (key,val) in parsed_args
        println("  $key  =>  $(repr(val))")
    end
    MessengerAnalyze.analyzeFile(parsed_args["config-file"])
end

main(ARGS)
