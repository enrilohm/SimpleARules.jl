# SimpleApriori
Blunt implementation that yields the result of the apriori algorithm.

## Installation
within julia package manager (Pkg)
```
pkg> add https://github.com/enrilohm/SimpleARules.jl.git
```

## Example
```julia
using SimpleARules
transactions = [["eggs", "bacon", "soup"],
                ["eggs", "bacon", "apple"],
                ["soup", "bacon", "banana"]]
frequent(transactions, max_length=3, min_support=1)
apriori(transactions, max_length=3, min_support=1, min_confidence=0.1)
```
