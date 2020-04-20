"""
Parsing the JSON in `data`
"""
function extract_country_data(country, data)
    deaths = map(e -> e["deaths"], data[country])
    confirmed=  map(e -> e["confirmed"], data[country])
    dates=  map(e -> Date(e["date"],dateformat"y-m-d"), data[country])
    recovered=map(e -> e["recovered"], data[country])
    (deaths=deaths, confirmed=confirmed, dates=dates, recovered=recovered)
end


function days_till_target_number(target_number,d=deaths, v=v)
    c=d[end] # Number of infected today 
    x=log(target_number/c)/log(2)
    doubling_time=log(2)/v[2]
    time=ceil(Int,x*doubling_time)
    doubling_time, time
end

function segmented_models(d,model_interval=5)
    segments=[i:i+model_interval-1 for i=1:model_interval:length(d)-model_interval+1]
    confirmed_segments=map(s->d[s], segments) 
    v_interval=[[ones(model_interval) [segments[i]...]]\ log.(confirmed_segments[i]) for i=1:length(confirmed_segments)]
    (segments=segments, v_interval=v_interval)
end

function plot_doubling_times(d,v_interval,segments,dates, p_head="Confirmed cases"; st=:bar)
    d_times=[days_till_target_number(20_000,d,v)[1] for v in v_interval] # Doubling times 
    plot(d_times, xticks=(1:length(segments), 
            string.(dates[[last(s) for s in segments]])),
         xrotation=45, label="", title="$p_head doubling time",
         ylabel="days", xlabel="date", seriestype=st)
end

function plot_whisker_fit(d,v_interval,segments, dates, p_head="Confirmed cases"; model_interval=5, date_density=date_density)
    p=scatter(1:length(dates),d, 
        label="data", title="$p_head of Covid-19", 
        legend=:topleft, xrotation=45, 
        xticks=(1:date_density:length(dates),string.(dates[1:date_density:length(dates)])))
    for i in eachindex(segments)
        plot!(p,first(segments[i]):last(segments[i])+model_interval,
            x->exp(v_interval[i][1]+v_interval[i][2]*x), 
            label="")
    end
    p
end