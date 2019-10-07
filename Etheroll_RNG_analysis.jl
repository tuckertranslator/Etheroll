API_token = "" #input your Etherscan API token
using HTTP, JSON, StatsBase, Statistics, Pkg, Plots, CSV
pyplot()

fb = 6290000 #first block to start from

log_array = [] #for stroing event logs from API call
for i in 1:400 #the logs come in batches of 1000 — get as many as possible
    print(i,", ")
    link = "https://api.etherscan.io/api?module=logs&action=getLogs&fromBlock=$fb&toBlock=latest&address=0xa52e014b3f5cc48287c2d483a3e026c32cc76e6d&topic0=0x8dd0b145385d04711e29558ceab40b456976a2b9a7d648cc1bcd416161bf97b9&apikey=$API_token"

    r = HTTP.request("GET", link)
    r = String(r.body)

    x = JSON.parse(r)["result"]
    push!(log_array, x)
    fb = parse(Int64, x[end]["blockNumber"]) + 1 #for tracking progress
    println(fb) 
    
end


result_array = Int64[] #for storing Oracle results
for i in 1:length(log_array)
    for j in 1:length(log_array[i])
        result = parse(Int64, log_array[i][j]["data"][129:130], base = 16) #results stored in hex at index 129:130
        push!(result_array, result)
    end
end
filter!(x->x !== 0, result_array) #results of 0 == failed tx

#CSV.write() — once you've pulled from API once, save results as CSV to save time in future
result_array = CSV.read("/Users/tuckercahillchambers/Desktop/Crypto projects/Etheroll_results.csv")
result_array = Matrix{Int64}(result_array)
result_array = result_array[:,1]

random = rand(1:100, 269754)
x = countmap([r for r in random])
plot(x, seriestype = :bar, color = :purple,
    xticks = (0:5:100),  
    xlab = "Result", ylab = "Occurrences",
    title = "Histogram of results from rand()",
    legend = false)

std(random)

Provable = countmap([r for r in result_array])
plot(Provable, seriestype = :bar, 
    xticks = (0:5:100),
    xlab = "Result", ylab = "Occurrences",
    title = "Histogram of results from Etheroll",
    legend = false)

median(collect(values(Provable)))

#if result below is true, results > 90 are less likely to repeat 
#

cnt_array = []
for i in 1:length(result_array)-1
    cnt = 0
    while result_array[i] > 90
        cnt += 1
        i += 1
    end
    push!(cnt_array, cnt)
end
cnt_array

c = countmap([run for run in cnt_array])
sort(collect(c), by=x->x[1])[3:end]

#if result below is true, then there would be advantage 
#in betting a low number (i.e. risking a lower-prob bet, at e.g 30)
#if 3 oracle results come back < 11, BUT WHY? 
#because there seems to be ~1/5 probability of seeing another result < 11

cnt_array = []
for i in 1:length(result_array)-1
    cnt = 0
    while result_array[i] < 11
        cnt += 1
        i += 1
    end
    push!(cnt_array, cnt)
end
cnt_array

c = countmap([run for run in cnt_array])
sort(collect(c), by=x->x[1])[3:end]

t = zeros(Float64, 100,3)

for i in 1:length(result_array) - 1   
    for j in 1:length(t)
        if j == result_array[i]
            if result_array[i+1] > j 
                t[j, 1] += 1
            elseif result_array[i+1] < j 
                t[j, 2] += 1
            end
        end
    end
end


r = zeros(Float64, 100,3)

for i in 1:length(random) - 1
    for j in 1:length(r)
        if j == random[i]
            if random[i+1] > j 
                r[j, 1] += 1
            elseif random[i+1] < j 
                r[j, 2] += 1
            end
        end
    end
end

for i in 1:size(t)[1]
    t[i,3] = round(minimum(t[i,1:2])/maximum(t[i,1:2]), digits = 2)
end


for i in 1:size(r)[1]
    r[i,3] = round(minimum(r[i,1:2])/maximum(r[i,1:2]), digits = 2)
end


x = collect(t[:,3])
y =  collect(r[:,3])
plot(x, xticks = collect(0:5:100), yticks = collect(0:0.1:1), ylim = (0,1.0), label = "Etheroll", lw = 3,
    ylab = "Ratio", xlab = "Result", title = "[n+1]>n / [n+1]<n")
plot!(y, lc = :purple, label = "rand()", lw = 3)

for i in 1:size(t)[1]
    t[i,3] = round(t[i,1]/t[i,2], digits = 2)
end

for i in 1:size(r)[1]
    r[i,3] = round(r[i,1]/r[i,2], digits = 2)
end


plot(t[:,3], seriestype = :scatter, xticks = collect(1:9:100), 
    legend = false,
    title = "[n+1] > n  /  [n+1] < n", 
    xlab = "n (Oraclize result)", ms = 6)
plot!(r[:,3], seriestype = :scatter, 
    legend = false, color = :purple, ms = 4)

#What is the MEAN distance between appearances of same oracle result?
cnt = countmap([c for c in result_array])
cnt = sort(collect(cnt), by=x->x[1])

test = []
y = 0
for i in 1:100
    x = findall(x->x == i, result_array)[2:end] - findall(x->x == i, result_array)[1:end-1]
    push!(test, mean(x))
end
test_mean = round.(test, digits = 1)

#What is the MEDIAN distance between appearances of same oracle result?
cnt = countmap([c for c in result_array])
cnt = sort(collect(cnt), by=x->x[1])

test = []
test_geo = []
y = 0
for i in 1:100
    x = findall(x->x == i, result_array)[2:end] - findall(x->x == i, result_array)[1:end-1]
    push!(test, median(x))
    push!(test_geo, geomean(x))
end
test = round.(test, digits = 1)
test_geo = round.(test_geo, digits = 1)

#Median gap between consecutive appearances of 
plot(test, seriestype = :scatter, reg = true, mc = :blue, ms = 6, label = "Median", 
    ylab = "Value", xlab = "Result", title = "Median and Geometric mean gaps")

#MEAN gap between consecutive appearances of 
plot(test_mean, seriestype = :scatter, reg = true, 
    xticks = (0:10:100), label = "Mean",
    title = "Mean and Median gaps btwn consecutive occurrences", ms = 6,
    xlab = "Result", ylab = "Mean gap", lc = :red, lw = 2)
plot!(test, seriestype = :scatter, reg = true, mc = :green, ms = 6, lw = 2, lc = :red, label = "Median", 
    ylab = "Value", xlab = "Result")

#What is the MEAN distance between appearances of same oracle result?
cnt = countmap([c for c in random])
cnt = sort(collect(cnt), by=x->x[1])

test = []
y = 0
for i in 1:100
    x = findall(x->x == i, random)[2:end] - findall(x->x == i, random)[1:end-1]
    push!(test, mean(x))
end
test_mean = round.(test, digits = 1)

#What is the MEDIAN distance between appearances of same oracle result?
cnt = countmap([c for c in random])
cnt = sort(collect(cnt), by=x->x[1])

test = []
test_geo = []
y = 0
for i in 1:100
    x = findall(x->x == i, random)[2:end] - findall(x->x == i, random)[1:end-1]
    push!(test, median(x))
    push!(test_geo, geomean(x))
end
test = round.(test, digits = 1)
test_geo = round.(test_geo, digits = 1)

#Median gap between consecutive appearances of 
plot(test, seriestype = :scatter, reg = true, mc = :blue, ms = 6, label = "Median", 
    ylab = "Value", xlab = "Result", title = "Median and Geometric mean gaps")

#MEAN gap between consecutive appearances of 
plot(test_mean, seriestype = :scatter, reg = true, 
    xticks = (0:10:100), label = "Mean",
    title = "Mean and Median gaps btwn consecutive occurrences", ms = 6, mc = :pink,
    xlab = "Result", ylab = "Mean gap", lc = :red, lw = 2)
plot!(test, seriestype = :scatter, reg = true, mc = :purple, ms = 6, lw = 2, lc = :red, label = "Median", 
    ylab = "Value", xlab = "Result")

#What is the MEDIAN distance between appearances of same oracle result?
cnt = countmap([c for c in result_array])
cnt = sort(collect(cnt), by=x->x[1])

test = []
test_geo = []
y = 0
for i in 1:100
    x = findall(x->x == i, result_array)[2:end] - findall(x->x == i, result_array)[1:end-1]
    push!(test, median(x))
    push!(test_geo, geomean(x))
end
test = round.(test, digits = 1)
test_geo = round.(test_geo, digits = 1)

#Median gap between consecutive appearances of 
plot(test, seriestype = :scatter, reg = true, mc = :blue, ms = 6, label = "Median", 
    ylab = "Value", xlab = "Result", title = "Median and Geometric mean gaps")
plot!(test_geo, seriestype = :scatter, reg = true, mc = :green, ms = 6, label = "Geometric mean")


x = findall(x->x == 1, result_array)[2:end] - findall(x->x == 1, result_array)[1:end-1]
c = countmap([c for c in x])
sort(collect(c), by=x->x[1])

x = collect(keys(sort(collect(c), by=x->x[1])))
y = collect(values(sort(collect(c), by=x->x[1])))

x = getindex.(x, 1)
y = getindex.(y, 2)

bar(x,y)

#Simulate using Provable results (result_array)

super_array = []
for r in 1:9 
    stack_array = []
    print(r, ": ")
        bet_amt = 0.2
        tx_cost = 0.000025
        stack = 0 #initial value of ETH stack
        X = 1 #set 'bet under' amount (setting X as 1 == 'bet under' 2)
        for i in collect(1:3:Int64(length(result_array)))
            cnt = 0
            bet = 0
            if result_array[i] == X #prompt the iterative betting
                bet += bet_amt + tx_cost #make bet
                stack -= bet #subtract bet from stack
                i += 1 #move ahead one result in result_array

                #iterate over next results, for run of r, betting each time
                while result_array[i] !== X && cnt <= r && i !== length(result_array)
                    #print(bet)
                    if bet > 0.2
                        bet = bet*1.5 - tx_cost #update bet — TESTING FOR INCREMENTAL STRATEGY
                        if bet < 0.2 #this loop is used if you want t have bet amount decrease iteratively
                            bet = 0.2
                        end
                    end
                    stack -= bet
                    cnt += 1
                    i += 1
                    push!(stack_array, stack)
                end
                cnt = 0
                if result_array[i] == X
                    stack += bet * (99 - X)/X + bet_amt 
                end
                push!(stack_array, stack)
            end
        end
    push!(super_array, stack_array)
    println(round(stack, digits=0))
end

nums = ["1" "2" "3" "4" "5" "6" "7" "8" "9"]
plot(super_array, lw = 2, label = nums,
    ylab = "ETH won", xlab = "Number of bets", title = "Strategy performance")

nums = ["1" "2" "3" "4" "5" "6" "7" "8" "9"]
plot(super_array, lw = 2, label = nums,
    ylab = "ETH won", xlab = "Number of bets", title = "Strategy performance")
