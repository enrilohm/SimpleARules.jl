import StatsBase.countmap
using DataFrames
import Combinatorics.combinations

macro no_gc(ex)
    quote
        GC.enable(false)
        local val = $(esc(ex))
        while !GC.enable(true)
            nothing
        end
        GC.gc()
        val
    end
end

function get_unique_items(transactions::Array{Array{T,1},1}) where {T}
    unique_item_list = unique(vcat(transactions...))
    unique_items = Dict(zip(unique_item_list, range(1, stop=length(unique_item_list))))
end

function get_sorted_integer_transactions(transactions::Array{Array{T,1},1}, unique_items::Dict{T,Int}) where {T}
    sort.(map(x->map(y->unique_items[y],x), transactions))
end

function get_support_dict(transactions::Array{Array{Int,1},1}, item_set_size::Int, min_support::Int) where {T}
    if item_set_size == 1
        @no_gc item_sets = map(x->[x], vcat(transactions...))
    else
        @no_gc item_sets = vcat(collect.(combinations.(transactions,item_set_size))...)
    end
    support_dict = countmap(item_sets)
    return filter(x -> x[2] >= min_support, support_dict)
end

function get_support_dictionaries(transactions::Array{Array{Int,1},1}, max_length::Int, min_support::Int) where {T}
    support_dictionaries = Array{Dict{Array{Int,1},Int},1}()
    for item_set_size in range(1, stop=max_length)
        push!(support_dictionaries, get_support_dict(transactions,item_set_size, min_support))
    end
    return support_dictionaries
end

function frequent(transactions::Array{Array{T,1},1};max_length::Int,min_support::Int) where {T}
    unique_items = get_unique_items(transactions)
    integer_transactions = get_sorted_integer_transactions(transactions,unique_items)
    support_dictionaries = get_support_dictionaries(integer_transactions,max_length,min_support)

    unique_item_list = map(x->x[1],sort(collect(unique_items), by=x->x[2]))
    df=DataFrame(map(x->(unique_item_list[x[1]],x[2]), vcat(collect.(support_dictionaries)...)))
    rename!(df,[:set,:support])
end

function get_rules(support_dictionaries::Array{Dict{Array{Int,1},Int},1}, unique_items::Dict{T,Int}) where {T}
    rules = Array{Tuple{Array{T,1}, Array{T,1}, Int, Int, Float64},1}()
    unique_item_list_sorted = map(x->x[1], sort(collect(unique_items), by=x->x[2]))
    for item_set_size in range(2, stop=length(support_dictionaries))
        println("generating rules for item-set-size: $item_set_size  ")
        for (itemset, support_suggestion) in support_dictionaries[item_set_size]
            for subset in collect(combinations(itemset))[1:end-1]
                suggestion = setdiff(itemset, subset)
                support_subset = support_dictionaries[length(subset)][subset]
                confidence = support_suggestion / support_subset
                push!(rules, (unique_item_list_sorted[subset], unique_item_list_sorted[suggestion], support_subset, support_suggestion, confidence))
            end
        end
    end
    rules
end

function get_rules_df(support_dictionaries::Array{Dict{Array{Int,1},Int64},1}, min_confidence, unique_items)
    rules = get_rules(support_dictionaries, unique_items)
    rules_df = DataFrame(filter(x-> x[5] >= min_confidence, rules))
    col_names = [:subset, :suggestion, :support_subset, :support_suggestion, :confidence]
    rename!(rules_df, col_names)
end

function apriori(transactions::Array{Array{T,1},1}; max_length::Int, min_support::Int, min_confidence::Union{Int,Float64}) where {T}
    unique_items = get_unique_items(transactions)
    integer_transactions = get_sorted_integer_transactions(transactions, unique_items)
    support_dictionaries = get_support_dictionaries(integer_transactions, max_length, min_support)
    rules_df = get_rules_df(support_dictionaries, min_confidence, unique_items)
end
