using HTTP, JSON


API_token = "" # to override with your Etherscan API key
fb = 6290000 #first block to start from

log_array = [] #for stroing event logs from API call
for i in 1:400 #the logs come in batches of 1000 — get as many as possible
    global fb
    global API_token
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
print(result_array)
