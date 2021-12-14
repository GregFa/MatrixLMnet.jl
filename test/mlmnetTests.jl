###########
# Library #
###########
using MatrixLM
using Distributions, Random, Statistics, LinearAlgebra, StatsBase
using MatrixLMnet2
using DataFrames
using Test
using BenchmarkTools
using Helium

####################
# External sources #
####################
include("sim_helpers.jl")
# include("l1_helpers.jl")


####################################################
# TEST Lasso vs Elastic Net (𝛼=1) - Simulated Data #
####################################################

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
# Helium.writehe(X, "test/data/Xmat.he")

# Generate response
Y1 = X*β1 + σ*rand(Normal(0, 1), n);
Y2 = X*β2 + σ*rand(Normal(0, 1), n);
Y = hcat(Y1, Y2);
# Helium.writehe(Y, "test/data/Ymat.he")

# Generate Z matrix
Z = 1.0*Matrix(I, 2, 2);

# Helium.readhe("test/data/Xmat.he")
# # Build raw data object from MatrixLM.jl
# X = Helium.readhe("test/data/Xmat.he")
# Y = Helium.readhe("test/data/Ymat.he")
dat = RawData(Response(Y), Predictors(X, Z));

# Hyper parameters
λ = [10.0, 5.0, 3.0]
α = [1.0]

############################################
# TEST 1 Lasso vs Elastic Net (𝛼=1) - ista #
############################################


# Elastic net penalized regression
est1 = MatrixLMnet2.mlmnet(dat, λ, α, method = "ista", hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net = est1.B[:, :, 3, 1];

# Elastic net penalized regression
est3 = MatrixLMnet2.mlmnet(dat, λ, method = "ista",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net3 = est3.B[:, :, 3, 1];

# Lasso penalized regression
est2 = mlmnet(ista!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Lasso = est2.B[:, :, 3];



println("Lasso vs Elastic Net when α=1 test 1 - ista: ", @test est_B_Net3 == est_B_Lasso)

@btime  MatrixLMnet2.mlmnet(dat, λ, α, method = "ista", hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  MatrixLMnet2.mlmnet(dat, λ, method = "ista",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  mlmnet(ista!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);

#############################################
# TEST 2 Lasso vs Elastic Net (𝛼=1) - fista #
#############################################


# Elastic net penalized regression
est1 = MatrixLMnet2.mlmnet(dat, λ, α, method = "fista", hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net = est1.B[:, :, 3, 1];

# Elastic net penalized regression
est3 = MatrixLMnet2.mlmnet(dat, λ, method = "fista",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net3 = est3.B[:, :, 3, 1];

# Lasso penalized regression
est2 = mlmnet(fista!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Lasso = est2.B[:, :, 3];



println("Lasso vs Elastic Net when α=1 test 2 - fista: ", @test est_B_Net3 == est_B_Lasso)

@btime  MatrixLMnet2.mlmnet(dat, λ, α, method = "fista", hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  MatrixLMnet2.mlmnet(dat, λ, method = "fista",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  mlmnet(fista!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);

##########################################################
# TEST 3 Lasso vs Elastic Net (𝛼=1) - fista backtracking #
##########################################################


# Elastic net penalized regression
est1 = MatrixLMnet2.mlmnet(dat, λ, α, method = "fista_bt", hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net = est1.B[:, :, 3, 1];

# Elastic net penalized regression
est3 = MatrixLMnet2.mlmnet(dat, λ, method = "fista_bt",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net3 = est1.B[:, :, 3, 1];

# Lasso penalized regression
est2 = mlmnet(fista_bt!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Lasso = est2.B[:, :, 3];



println("Lasso vs Elastic Net when α=1 test 3 - fista_bt: ", @test est_B_Net3 == est_B_Lasso)

@btime  MatrixLMnet2.mlmnet(dat, λ, α, method = "fista_bt", hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  MatrixLMnet2.mlmnet(dat, λ, method = "fista_bt",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  mlmnet(fista_bt!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);

############################################
# TEST 4 Lasso vs Elastic Net (𝛼=1) - admm #
############################################


# Elastic net penalized regression
est1 = MatrixLMnet2.mlmnet(dat, λ, α, method = "admm", hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net = est1.B[:, :, 3, 1];

# Elastic net penalized regression
est3 = MatrixLMnet2.mlmnet(dat, λ, method = "admm",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net3 = est1.B[:, :, 3, 1];

# Lasso penalized regression
est2 = mlmnet(admm!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Lasso = est2.B[:, :, 3];



println("Lasso vs Elastic Net when α=1 test 3 - admm: ", @test est_B_Net3 == est_B_Lasso)

@btime  MatrixLMnet2.mlmnet(dat, λ, α, method = "admm", hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  MatrixLMnet2.mlmnet(dat, λ, method = "admm",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  mlmnet(admm!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);

##########################################
# TEST 5 Lasso vs Elastic Net (𝛼=1) - cd #
##########################################

# Elastic net penalized regression
Random.seed!(2021)
est1 = MatrixLMnet2.mlmnet(dat, λ, α, method = "cd", hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net = est1.B[:, :, 3, 1];

# Elastic net penalized regression
Random.seed!(2021)
est3 = MatrixLMnet2.mlmnet(dat, λ, method = "cd",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Net3 = est3.B[:, :, 3, 1];

# Lasso penalized regression
Random.seed!(2021)
est2 = mlmnet(cd!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);
est_B_Lasso = est2.B[:, :, 3];

println("Lasso vs Elastic Net when α=1 test 5 - cd: ", @test est_B_Net3 == est_B_Lasso)

@btime  MatrixLMnet2.mlmnet(dat, λ, α, method = "cd", hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  MatrixLMnet2.mlmnet(dat, λ, method = "cd",  hasZIntercept = false, hasXIntercept = false, isVerbose = false);

@btime  mlmnet(cd!, dat, λ, hasZIntercept = false, hasXIntercept = false, isVerbose = false);

println("Tests finished!")
