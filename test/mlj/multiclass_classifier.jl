module TestMulticlassLGBM


using MLJBase
using Test
using Random: seed!

import CategoricalArrays
import LightGBM

## CLASSIFIER -- shamelessly adapted from binary_classification.jl

# test multiclass case:
N = 5
Nsamples = 3000
seed!(0)

model = LightGBM.MLJInterface.LGBMClassifier(num_iterations=100)

X       = (x1=rand(Nsamples), x2=rand(Nsamples), x3=rand(Nsamples))
ycat    = string.(mod.(round.(Int, X.x1 * 10), N)) |> MLJBase.categorical
weights = Float64.(MLJBase.int(ycat)) # just use the 1's/2's directly as multipliers

y = MLJBase.identity.(ycat) # make plain Vector with categ. elements (actually not sure what this is doing)

# fit once, without weights
train, test              = MLJBase.partition(MLJBase.eachindex(y), 0.6)
fitresult, cache, report = MLJBase.fit(model, 0, MLJBase.selectrows(X, train), y[train];)
yhat                     = MLJBase.mode.(MLJBase.predict(model, fitresult, MLJBase.selectrows(X, test)))

# fit again with weights
fitresult, cache, report = MLJBase.fit(model, 0, MLJBase.selectrows(X, train), y[train], weights[train])
yhat_with_weights        = MLJBase.mode.(MLJBase.predict(model, fitresult, MLJBase.selectrows(X, test)))

misclassification_rate   = sum(yhat .!= y[test])/length(test)

@test misclassification_rate < 0.015

# All we can really say about fitting with/without weights for this example is that the solutions shouldn't be identical
@test yhat_with_weights != yhat

# Cache contains iterations counts history
@test cache isa NamedTuple
@test cache.num_boostings_done == [100]

@test isa(report, NamedTuple)

expected_return_type = Tuple{
    LightGBM.LGBMClassification,
    CategoricalArrays.CategoricalArray,
    LightGBM.MLJInterface.LGBMClassifier,
}

@test isa(fitresult, expected_return_type)

# Provided by Anthony Blaom as a simple integration test
X, y = @load_iris;
model = LightGBM.MLJInterface.LGBMClassifier()
yhat = fit!(machine(model, X, y); verbosity=0) |> predict;
@test scitype(mode.(yhat)) <: AbstractVector{Multiclass{3}}
@test mean(cross_entropy(yhat, y)) < 0.6  # or do proper out-of-sample test


end # module
true
