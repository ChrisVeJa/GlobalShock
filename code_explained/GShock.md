module GShock
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall;

################################################################################
#  [1] STRUCTURES FOR CONTAINERS
################################################################################
include("GSDataLoader.jl")
include("mainsup.jl")
# ------------------------------------------------------
# [1.1] Estimated Parameters
struct Param
    B::Array   # Estimated βs
    Σ::Array   # Variance Covariance matrix
    Γ::Array   # Median of identificacion matrix
    ξ::Array   # Median of Eigenvectors
end
# ------------------------------------------------------
# [1.2] Post Estimation
struct Post
    Mean
    Qntls
end
# ------------------------------------------------------
# [1.3] Output structure
struct GSsolve
    Par	      # Estimated parameters
    IrfGS     # Impulse response function
    FevGS     # Forecast Error Variances decomposition
	IrfNF     # Impulse response function Non fundamental
    FevNF     # Forecast Error Variances decomposition Non fundamental
end

################################################################################
#  [2] MAIN FUNCTIONS
################################################################################

# ------------------------------------------------------
# [2.1] Estimation of Global Shocks
# ------------------------------------------------------
function GSstimation(y, p, h; xblock = false, GOS = true, nx = 0, VarGS = 1:3, nmodls = 5000,
		Lτ = 1, Uτ = 5, quint = [0.16 0.50 0.84], NF = true)
    # --------------------------------------------------------
    # [2.1.1] VAR in reduce form
    m = size(y)[2]
    Y, X = VARData(y, p)
    B, Φ = OLSbetas(Y, X, m, p, Xblock = xblock, Nx = nx)

    # --------------------------------------------------------
    #  Stability Checking
    if maximum(abs.(eigvals(Φ))) >= 1
        println("Not stationary model, we report only stationary draws")
    end

    # --------------------------------------------------------
    # [2.1.2] Residual of the reduce form
    T, mn = size(X)
    E = Y - X * B
    Σ = (E' * E) / (T - mn)
    SS = (E' * E)

    # --------------------------------------------------------
    # [2.1.3] Global Shock identification
    display("Model is being estimated...")
    Γ     = Array{Float64,2}(undef, m, nmodls) # All the identification vectors
    aux1  = (xblock * nx) + (1 - xblock) * m
    ξ 	  = Array{Float64,3}(undef, aux1, aux1, nmodls)
    IRFGS = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
    FEVGS = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
	IRFNF = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
    FEVNF = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
	U     = Array{Float64,2}(undef, T, nmodls) # Identified shocks
    for i = 1:nmodls
		β, Φ, γ, ξ[:, :, i] =
    	GSsimulation(Y, X, B, SS, p, Lτ, Uτ, Xblock = xblock, nx = nx, varGS = VarGS, nonfun = NF);
        # β, Φ, Γ, ξ
		Uaux   = γ\(E')
		U[:,i] = vec(Uaux[1,:])
        IRF, FEV = irf_fevd(Φ, γ, h, m)
        IRFGS[:, :, i] = IRF[:, 1, :]
        FEVGS[:, :, i] = FEV[:, 1, :]
		IRFNF[:, :, i] = IRF[:, 2, :]
		FEVNF[:, :, i] = FEV[:, 2, :]
        Γ[:, i] = γ[:, 1]
    end

    # --------------------------------------------------------
    # [2.1.4] Percentiles : Julia does not have a quintile
    # command that work in RN arrays
	# -------- Means --------
    irf1m = dropdims(mean(IRFGS, dims = 3), dims = 3)
    fev1m = dropdims(mean(FEVGS, dims = 3), dims = 3)
	irf2m = dropdims(mean(IRFNF, dims = 3), dims = 3)
    fev2m = dropdims(mean(FEVNF, dims = 3), dims = 3)

	# -------- Percentiles --------
    irf1q = Qntls(IRFGS, nmodls, quint, m, h)
    fev1q = Qntls(FEVGS, nmodls, quint, m, h)
	irf2q = Qntls(IRFNF, nmodls, quint, m, h)
	fev2q = Qntls(FEVNF, nmodls, quint, m, h)

	# -------------------------
    Γ = median(Γ, dims = 2)
    ξ = median(ξ, dims = 3)
    display("It ends!")


	# ------------------------
	# Outputs
	mytup =(irfgs = IRFGS, fevgs= FEVGS,irfnf = IRFNF,fevnf=FEVNF);
	params = Param(B, Σ, Γ, ξ)
	post1  = Post(irf1m, irf1q)
	post2  = Post(fev1m, fev1q)
	post3  = Post(irf2m, irf2q)
	post4  = Post(fev2m, fev2q)
	gsolve = GSsolve(params, post1, post2, post3, post4)
    return gsolve, mean(U,dims=2) , mytup
end

# ------------------------------------------------------
# [2.2] Bayesian Simulation
# ------------------------------------------------------

function GSsimulation(Y, X, B, SS, p, Lτ, Uτ; Xblock = false, nx = 3, varGS = 1:3, nonfun = true)
    # --------------------------------------------------------
    # [2.2.1] Drawing βₙ
    T, m   = size(Y)
    σdist  = InverseWishart(T, SS)
    b      = vec(B)
    rc, cc = size(B)
    Σ      = rand(σdist)                   # Sampling from an Inverse  Wishart
    XX     = Symmetric(inv(X'X), :L)
    kr     = kron(Σ, XX)
    disti  = MvNormal(b, kr)
    β, Φ   = BetaDraw(disti, rc, cc, m, p)
    # --------------------------------------------------------
    # [2.2.2] Cholesky Identification
    E1 = Y - X * β
    Σ1 = (E1' * E1) / (T - size(X, 2))
    C1 = cholesky(Σ1).L

    # --------------------------------------------------------
    # [2.2.3] Impulse-Response Function :
    #   The IRF[i,j,k] is the response k-period ahead of
    #   the variable i when is hit by the shock j;
    aux_IRF = Array{Float64,3}(undef, m * p, m * p, Uτ)
    IRF 	= Array{Float64,3}(undef, m, m, Uτ)
    aux_IRF[:, :, 1] = Φ
    IRF[:, :, 1]   	 = aux_IRF[1:m, 1:m, 1] * C1

    for i = 2:Uτ
        aux_IRF[:, :, i] = Φ * aux_IRF[:, :, i-1]
        IRF[:, :, i]     = aux_IRF[1:m, 1:m, i] * C1
    end

    # --------------------------------------------------------
    # [2.2.4] Global Shocks Identification
    # [Step 1] Matrix Λ and their weights
    tvars = length(varGS)
	naux  = (Xblock * nx) + (1 - Xblock) * m;
    Λ = zeros(naux, naux,  tvars)
    λ = zeros(tvars)
    for i = 1:tvars
        Λ[:, :, i] = Λmatrix(IRF, varGS[i], m; Lτ = Lτ, Uτ = Uτ, Xblock = Xblock, nx = nx)
        λ[i] 	   = tr(Λ[:, :, i])
    end
    λ = prod(λ) ./ λ

    # [Step 2] Matrix ξ
    Ξ = dropdims(sum(reshape(λ, 1, 1, :) .* Λ, dims = 3), dims = 3)
    # [Step 3] Eigenvector sorted by the max eigenvalue
    ξ = eigen(Ξ).vectors[:, end:-1:1]
    # [Step 4] NON FUNDAMENTAL SHOCK
	if nonfun
		nξ  = size(ξ)[1];
	    L   = [-ξ[2:end,1] ./ ξ[1,1] I(nξ-1)];
	    BL  = L*L';
	    BL  = Array(BL);
	    pos_tot=2;
	    Λaux= L*Λ[:,:,pos_tot]*L';
	    ψ   = eigen(Λaux, BL).vectors[:,end];
	    Ψ   = convert(Array,(ψ'*L)');
	    Ξ   = [ξ[:,1] Ψ];
	    # New Identification matrix
	    nsp = nullspace(Array(Ξ'))
	    ξ   = [Ξ nsp[:,1:(nξ-2)]];
	end
    # [Step 5] New Identification matrix
    if Xblock
        Γ = [C1[:, 1:nx] * ξ C1[:, nx+1:end]]
    else
        Γ = C1 * ξ
    end
    Γ = sign.(diag(Γ))' .* Γ  # Normalization to improve identification
    return β, Φ, Γ, ξ # betas, Companion Form, Identification, Eigenvectors
end
end
