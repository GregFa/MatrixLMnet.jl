#= generate_testing dataset.jl script is used to generate data that will be use for testing.
1. Simulates dataset 
2. Apply MatrixLMnet v0.1.0 L1-penalized
3. Save datasets and estimates to be comapred with newer version =#


###########
# Library #
###########
using Distributions, Random, Statistics, LinearAlgebra, StatsBase
# using StableRNGs
# using DataFrames, MLBase, Distributed
using MatrixLMnet #v1.1.1
# using Test
using Helium


####################
# External sources #
####################
include("sim_helpers.jl")
# include("l1_helpers.jl")


###################
#  Simulated Data #
###################

#=
Description:
-----------

Model: 𝐘 = 𝐗 𝛃 𝐙' + 𝜎𝜖, with 𝜖∼𝑁(0,1) 

Simulate data set consisting  of 20/20/200 observations and 8 predictors.
We let 𝛽₁ = (3, 1.5, 0, 0, 2, 0, 0, 0), 𝛽₂ = (0, 1.5, 0, 3.5, 2, 0, 0 , 2) where
𝛃 = [𝛽₁, 𝛽₂] and 𝜎 = 3.
The pairwise correlation between 𝑋ᵢ and 𝑋ⱼ was set to be 𝑐𝑜𝑟(𝑖,𝑗)=(0.5)^|𝑖−𝑗|.
Here, the Z matrix is an identity matrix.
=#

rng = MatrixLMnet.Random.Xoshiro(2021);

# Simulation parameters
p = 8; # Number of predictors
β1 = [3.5, 1.5, 0,   0, 2, 0, 0 , 0];
β2 = [  0, 1.5, 0, 3.5, 2, 0, 0 , 2];
σ = 3;
n = 240;

# Generate correlation matrix 
matCor = zeros(p,p)
for j = 1:p, i = 1:p
    matCor[i,j] = 0.5^abs(i-j)
end

# Generate predictors
X = simulateCorrelatedData(matCor, n);

# Generate response
Y1 = X*β1 + σ*rand(Normal(0, 1), n);
Y2 = X*β2 + σ*rand(Normal(0, 1), n);
Y = hcat(Y1, Y2);

# Generate Z matrix
Z = 1.0*Matrix(I, 2, 2);

# Build raw data object from MatrixLM.jl
dat = MatrixLMnet.MatrixLM.RawData(Response(Y), Predictors(X, Z));

# Hyper parameters
λ = [10.0, 5.0, 3.0]
α =[1.0]


###############
# TEST Lasso  #
###############

# Lasso penalized regression - ista
est = mlmnet(dat, λ, method = "ista", addZIntercept = false, addXIntercept = false, isVerbose = false);
est_B_Lasso_ista = est.B[:, :, 3];

# Lasso penalized regression - fista
est = mlmnet(dat, λ, method = "fista", addZIntercept = false, addXIntercept = false, isVerbose = false);
est_B_Lasso_fista = est.B[:, :, 3];

# Lasso penalized regression - fista backtracking
MatrixLMnet.Random.seed!(rng, 2024)
est = mlmnet(dat, λ, method = "fista_bt", addZIntercept = false, addXIntercept = false, isVerbose = false); 
est_B_Lasso_fista_bt = est.B[:, :, 3];

# Lasso penalized regression - admm
est = mlmnet(dat, λ, method = "admm", addZIntercept = false, addXIntercept = false, isVerbose = false);
est_B_Lasso_admm = est.B[:, :, 3];

# Lasso penalized regression - cd
MatrixLMnet.Random.seed!(rng, 2024)
est = mlmnet(dat, λ, method = "cd", addZIntercept = false, addXIntercept = false, isVerbose = false);
est_B_Lasso_cd = est.B[:, :, 3];

#################################
# TEST Lasso - Crossvalidation  #
#################################

# Generate random row and column folds
nRowFolds = 10
nColFolds = 1

MatrixLMnet.Random.seed!(rng, 2024)
rowFolds = make_folds(dat.n, nRowFolds, max(nRowFolds, nColFolds))

MatrixLMnet.Random.seed!(rng, 2024)
colFolds = make_folds(dat.m, nColFolds, max(nRowFolds, nColFolds))

# Lasso penalized regression - ista cv
est = mlmnet_cv(dat, λ, rowFolds, colFolds; method = "ista", addZIntercept = false, addXIntercept = false, isVerbose = false); 
smmr_Lasso = lambda_min(est);
smmr_ista = hcat(smmr_Lasso.AvgMSE, smmr_Lasso.AvgPropZero)

# Lasso penalized regression - fista cv
est = mlmnet_cv(dat, λ, rowFolds, colFolds; method = "fista", addZIntercept = false, addXIntercept = false, isVerbose = false); 
smmr_Lasso = lambda_min(est);
smmr_fista = hcat(smmr_Lasso.AvgMSE, smmr_Lasso.AvgPropZero)

# Lasso penalized regression - fista-bt cv
est = mlmnet_cv(dat, λ, rowFolds, colFolds; method = "fista_bt", addZIntercept = false, addXIntercept = false, isVerbose = false); 
smmr_Lasso = lambda_min(est);
smmr_fistabt = hcat(smmr_Lasso.AvgMSE, smmr_Lasso.AvgPropZero)

# Lasso penalized regression - admm cv
est = mlmnet_cv(dat, λ, rowFolds, colFolds; method = "admm", addZIntercept = false, addXIntercept = false, isVerbose = false); 
smmr_Lasso = lambda_min(est);
smmr_admm = hcat(smmr_Lasso.AvgMSE, smmr_Lasso.AvgPropZero)

# Lasso penalized regression - cd cv
est = mlmnet_cv(dat, λ, rowFolds, colFolds; method = "cd", addZIntercept = false, addXIntercept = false, isVerbose = false); 
smmr_Lasso = lambda_min(est);
smmr_cd = hcat(smmr_Lasso.AvgMSE, smmr_Lasso.AvgPropZero)


###############################
#  Save Dataset and Estimates #
###############################

# Output directory name
dataDir = realpath(joinpath(@__DIR__,"data"))

# Save X, Y, and Z
Helium.writehe(X, joinpath(dataDir, "Xmat.he"))
Helium.writehe(Y, joinpath(dataDir, "Ymat.he"))
Helium.writehe(Z, joinpath(dataDir, "Zmat.he"))


# Save folding indexes
mrowFolds = Matrix{Int64}(undef, length(rowFolds[1]), length(rowFolds))
for i in 1:length(rowFolds)
    mrowFolds[:,i] = rowFolds[i]
end 
 
mcolFolds = Matrix{Int64}(undef, length(colFolds[1]), length(colFolds))
for i in 1:length(colFolds)
    mcolFolds[:,i] = colFolds[i]
end 

Helium.writehe(mrowFolds, joinpath(dataDir, "row_folds.he"))
Helium.writehe(mcolFolds, joinpath(dataDir, "col_folds.he"))


# Save estimates results
Helium.writehe(est_B_Lasso_ista, joinpath(dataDir, "B_ista.he"))
Helium.writehe(est_B_Lasso_fista, joinpath(dataDir, "B_fista.he"))
Helium.writehe(est_B_Lasso_fista_bt, joinpath(dataDir, "B_fistabt.he"))
Helium.writehe(est_B_Lasso_admm, joinpath(dataDir, "B_admm.he"))
Helium.writehe(est_B_Lasso_cd, joinpath(dataDir, "B_cd.he"))

Helium.writehe(smmr_ista, joinpath(dataDir, "smmr_ista.he"))
Helium.writehe(smmr_fista, joinpath(dataDir, "smmr_fista.he"))
Helium.writehe(smmr_fistabt, joinpath(dataDir, "smmr_fistabt.he"))
Helium.writehe(smmr_admm, joinpath(dataDir, "smmr_admm.he"))
Helium.writehe(smmr_cd, joinpath(dataDir, "smmr_cd.he"))

