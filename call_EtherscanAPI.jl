using HTTP, JSON

# to override with your Etherscan API key
API_token = ""
# first block to start from
first_block = 6290000
log_result_topic = "0x8dd0b145385d04711e29558ceab40b456976a2b9a7d648cc1bcd416161bf97b9"
contract_address = "0xA52e014B3f5Cc48287c2D483A3E026C32cc76E6d"


# gets logs from a given block
function get_logs(from_block; to_block="latest")
    get_logs_url = "https://api.etherscan.io/api?module=logs&action=getLogs"
    url = "$get_logs_url&fromBlock=$from_block&toBlock=$to_block&address=$contract_address&topic0=$log_result_topic&apikey=$API_token"
    response = HTTP.request("GET", url)
    body = String(response.body)
    JSON.parse(body)["result"]
end

# pulls batches of logs and concatenates to a resulting array
function get_logs_batch(from_block, batch_count)
    # for stroing event logs from API call
    log_array = []
    for i in 1:batch_count
        print(i,", ")
        logs = get_logs(from_block)
        # going to the next batch
        from_block = parse(Int64, logs[end]["blockNumber"]) + 1
        println(from_block)
        log_array = vcat(log_array, logs)
    end
    return log_array
end

# extracts Oracle result number given an array of logs
function extract_oracle_results(log_array)
    # for storing Oracle results
    result_array = Int64[]
    for i in 1:length(log_array)
        # results stored in hex at index 129:130
        result = parse(Int64, log_array[i]["data"][129:130], base = 16)
        push!(result_array, result)
    end
    # dropping failed transactions (result == 0)
    filter!(x->x !== 0, result_array)
end


function main()
    log_array = get_logs_batch(first_block, 400)
    result_array = extract_oracle_results(log_array)
    print(result_array)
end

main()
