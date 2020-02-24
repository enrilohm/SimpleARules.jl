using SimpleARules
using Test
# include("../src/arules.jl")

transactions = [["bla","blubb"], ["bla"]]

@testset "some tests" begin
    unique_items_expected = Dict("bla"=>1, "blubb"=>2)
    unique_items = SimpleARules.get_unique_items(transactions)
    @test unique_items == unique_items_expected

    sorted_integer_transactions_expected = [[1,2], [1]]
    sorted_integer_transactions = SimpleARules.get_sorted_integer_transactions(transactions, unique_items_expected)
    @test sorted_integer_transactions == sorted_integer_transactions_expected

    support_dict_expected_1 = Dict([1]=>2, [2]=>1)
    support_dict = SimpleARules.get_support_dict(sorted_integer_transactions_expected, 1, 1)
    @test support_dict == support_dict_expected_1

    support_dict_expected_2 = Dict([1,2]=>1)
    support_dict = SimpleARules.get_support_dict(sorted_integer_transactions_expected, 2, 1)
    @test support_dict == support_dict_expected_2

    support_dictionaries_expected = [support_dict_expected_1, support_dict_expected_2]
    support_dictionaries = SimpleARules.get_support_dictionaries(sorted_integer_transactions_expected, 2, 1)
    @test support_dictionaries == support_dictionaries_expected

    frequent_dict_expected = Dict(["bla"]=>2 ,["blubb"] => 1, ["bla","blubb"]=>1)
    frequent_df = SimpleARules.frequent(transactions, max_length=2, min_support=1)
    @test Dict(zip(frequent_df.set,frequent_df.support)) == frequent_dict_expected

    rules_expected = [(["bla"], ["blubb"], 2, 1, 0.5), (["blubb"], ["bla"], 1, 1, 1.)]
    rules = SimpleARules.get_rules(support_dictionaries_expected, unique_items_expected)
    @test rules == rules_expected

    min_confidence=0.7
    rules_df = SimpleARules.get_rules_df(support_dictionaries_expected, min_confidence, unique_items_expected)
    @test minimum(rules_df.confidence) >= min_confidence

    apriori_df = SimpleARules.apriori(transactions, max_length=2, min_support=0, min_confidence=0)
    @test length(apriori_df[:, :subset]) == 2
    @test Vector(apriori_df[1, :]) == [["bla"], ["blubb"], 2, 1, 0.5]
    @test Vector(apriori_df[2, :]) == [["blubb"], ["bla"], 1, 1, 1]
end
