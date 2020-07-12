module GlobalShock
using Random,
    DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions

################################################################################
#  [1] STRUCTURES FOR CONTAINERS
################################################################################

# ------------------------------------------------------
# [1.1] Estimated Parameters
struct Parameters
    B::Array   # Estimated βs
    Σ::Array   # Variance Covariance matrix
    Γ::Array   # Median of identificacion matrix
    ξ::Array   # Median of Eigenvectors
end
# ------------------------------------------------------
# [1.2] Post Estimation
struct PostVAR
    Mean::Any
    Qntls::Any
end
# ------------------------------------------------------
# [1.3] Output structure
struct GSsolve
    Set::Any           # Tuple with some settings of the model
    Par::Parameters    # Estimated parameters
    IrfGS::PostVAR     # Impulse response function
    FevGS::PostVAR     # Forecast Error Variances decomposition
	IrfNF::PostVAR     # Impulse response function Non fundamental
    FevNF::PostVAR     # Forecast Error Variances decomposition Non fundamental
end

################################################################################
#  [2] MAIN FUNCTIONS
################################################################################

# ------------------------------------------------------
# [2.1] Estimation of Global Shocks
# ------------------------------------------------------
function GSstimation(
    y,
    p,
    h;
    xblock = false,
    GOS = true,
    nx = 0,
    VarGS = 1:3,
    nmodls = 5000,
    Lτ = 1,
    Uτ = 5,
    quint = [0.16 0.50 0.84],
	nonfun = true,
)
    # --------------------------------------------------------
    # [2.1.1] VAR in reduce form
    m = size(y)[2]
    Y, X = VARData(y, p)
    B, Φ = OLSbetas(Y, X, m, p, Xblock = xblock, Nx = nx)

    # --------------------------------------------------------
    #  Stability Checking
    if maximum(abs.(eigvals(Φ))) >= 1
        println("The original model is not stationary, but we report only stationary draws")
    end

    # --------------------------------------------------------
    # [2.1.2] Residual of the reduce form
    T, mn = size(X)
    E = Y - X * B
    Σ = (E' * E) / (T - mn)
    SS = (E' * E)

    # --------------------------------------------------------
    # [2.1.3] Global Shock identification
    display("Global Shock is being estimated...")
    Γ = Array{Float64,2}(undef, m, nmodls) # All the identification vectors
    aux1 = (xblock * nx) + (1 - xblock) * m
    ξ = Array{Float64,3}(undef, aux1, aux1, nmodls)
    IRFGS = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
    FEVGS = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
	IRFNF = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
    FEVNF = Array{Float64,3}(undef, m, h, nmodls) # Container for IRF of GS
	U = Array{Float64,2}(undef, T, nmodls) # Identified shocks
    for i = 1:nmodls
        out0, out1, out2, ξ[:, :, i] = GSsimulation(
            Y, X, B, SS, p, Lτ, Uτ; Xblock = xblock,
			nx = nx, varGS = VarGS, nonfun = nonfun,
        )
        # β, Φ, Γ, ξ
		Uaux   = out2\(E')
		U[:,i] = vec(Uaux[1,:])
        IRF, FEV = irf_fevd(out1, out2, h, m)
        IRFGS[:, :, i] = IRF[:, 1, :]
        FEVGS[:, :, i] = FEV[:, 1, :]
		IRFNF[:, :, i] = IRF[:, 2, :]
		FEVNF[:, :, i] = FEV[:, 2, :]
        Γ[:, i] = out2[:, 1]
    end

    # --------------------------------------------------------
    # [2.1.4] Percentiles : Julia does not have a quintile
    # command that work in RN arrays

	# -------- Means --------
    IRFGSM  = dropdims(mean(IRFGS, dims = 3), dims = 3)
    FEVDGSM = dropdims(mean(FEVGS, dims = 3), dims = 3)
	IRFNFM  = dropdims(mean(IRFNF, dims = 3), dims = 3)
    FEVDNFM = dropdims(mean(FEVNF, dims = 3), dims = 3)

	# -------- Percentiles --------
    IRFGSQ  = Qntls(IRFGS, nmodls, quint, m, h)
    FEVDGSQ = Qntls(FEVGS, nmodls, quint, m, h)
	IRFNFQ  = Qntls(IRFNF, nmodls, quint, m, h)
	FEVDNFQ = Qntls(FEVNF, nmodls, quint, m, h)

	# -------------------------
    Γ = median(Γ, dims = 2)
    ξ = median(ξ, dims = 3)
    display("It is already done!")
    Set = (
        lags = p,
        horizon = h,
        ExoBlock = xblock,
        Nexo = nx,
        GlobalShock = GOS,
        VarGlobalShock = VarGS,
        replicatios = nmodls,
        τ = [Lτ, Uτ],
        quintiles = quint,
    )
	mytup =(irfgs = IRFGS, fevgs= FEVGS,irfnf = IRFNF,fevnf=FEVNF);
    return GSsolve(
        Set,
        Parameters(B, Σ, Γ, ξ),
        PostVAR(IRFGSM, IRFGSQ),
        PostVAR(FEVDGSM, FEVDGSQ),
		PostVAR(IRFNFM, IRFNFQ),
		PostVAR(FEVDNFM, FEVDNFQ),
    ), mean(U,dims=2) , mytup ;
end

# ------------------------------------------------------
# [2.2] Bayesian Simulation
# ------------------------------------------------------

function GSsimulation(
    Y,
    X,
    B,
    SS,
    p,
    Lτ,
    Uτ;
    Xblock = false,
    nx = 3,
    varGS = 1:3,
	nonfun = true,
)
    # --------------------------------------------------------
    # [2.2.1] Drawing βₙ
    T, m = size(Y)
    σdist = InverseWishart(T, SS)
    b = vec(B)
    rc, cc = size(B)
    Σ = rand(σdist)                   # Sampling from an Inverse  Wishart
    XX = Symmetric(inv(X'X), :L)
    kr = kron(Σ, XX)
    disti = MvNormal(b, kr)
    β, Φ = BetaDraw(disti, rc, cc, m, p)

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
    IRF = Array{Float64,3}(undef, m, m, Uτ)
    aux_IRF[:, :, 1] = Φ
    IRF[:, :, 1] = aux_IRF[1:m, 1:m, 1] * C1

    for i = 2:Uτ
        aux_IRF[:, :, i] = Φ * aux_IRF[:, :, i-1]
        IRF[:, :, i] = aux_IRF[1:m, 1:m, i] * C1
    end

    # --------------------------------------------------------
    # [2.2.4] Global Shocks Identification

    # [Step 1] Matrix Λ and their weights
    tvars = length(varGS)
    Λ = zeros(
        (Xblock * nx) + (1 - Xblock) * m,
        (Xblock * nx) + (1 - Xblock) * m,
        tvars,
    )
    λ = zeros(tvars)
    for i = 1:tvars
        Λ[:, :, i] =
            Λmatrix(IRF, varGS[i], m; Lτ = 1, Uτ = 5, Xblock = Xblock, nx = nx)
        λ[i] = tr(Λ[:, :, i])
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

################################################################################
# [3] SUPPORTING FUNCTIONS
################################################################################

# ------------------------------------------------------
# [3.1] Data for VAR
# ------------------------------------------------------
function VARData(y::Array, p; Cons = true, trend = false, τ = 1)
    T, n = size(y)
    T = T - p
    r = p + 1
    Y = y[r:end, :]
    X = Array{Float64}(undef, T, n * p + Cons + trend * τ)
    for i = 1:p
        X[:, n*(i-1)+1:i*n] = y[r-i:end-i, :]
    end
    if Cons
        X[:, end-trend*τ] = ones(T)
    end
    if trend
        for i = 1:τ
            X[:, end-i+1] = (1:T) .^ (τ - i + 1)
        end
    end
    return Y, X
end

# ------------------------------------------------------
# [3.2] OLS estimation
# ------------------------------------------------------
function OLSbetas(Y::Array, X::Array, m, p; Xblock = false, Nx = 0)
    B = (X' * X) \ (X' * Y)
    if Xblock
        Bres = ROLS(X, B, m, p, Nx)
        B = Bres
    end
    f = B'
    f = f[:, 1:m*p]
    Φ = [f; I(m * (p - 1)) zeros(m * (p - 1), m)]

    if ~isa(Φ, Array)
        Φ = Array(Φ) # Just to apply eigvals later
    end
    return B, Φ
end

# ------------------------------------------------------
# [3.3] Restricted OLS
# ------------------------------------------------------
function ROLS(x, β, m, p, nx)
    row, cols = size(β)
    nres = (m - nx) * nx * p
    RR = zeros(row, cols)

    for i = 1:p
        RR[m * (i - 1)+nx+1:m*i, 1:nx] = ones(m - nx, nx)
    end

    R = zeros(nres, length(β))
    index = findall(x -> x == 1, RR)

    for i = 1:nres
        R[i, (index[i][2]-1)*row+index[i][1]] = 1
    end
    # Objectives
    r = zeros(nres, 1)
    α = vec(β)

    # Restricted Estimation
    X = kron(I(m), x)
    XX = inv(X' * X)
    αR = α + (XX * R') * (inv((R * XX * R')) * (r - R * α))
    αR[vec(RR).==1] .= 0  # Jusdt to eliminate the round difference
    return reshape(αR, (row, cols))
end

# --------------------------------------------------------
# [3.4] Simulating β from a diffuse inverse wishart prior
# --------------------------------------------------------
function BetaDraw(disti, rc, cc, m, p)
    status = 1
    β_draw = Array{Float64,2}(undef, rc, cc)
    Φ_draw = Array{Float64,2}(undef, m * p, m * p)
    while status >= 1
        b_draw = rand(disti)
        β_draw = reshape(b_draw, (rc, cc))
        f = β_draw'
        f = f[:, 1:m*p]
        Φ_draw = [f; I(m * (p - 1)) zeros(m * (p - 1), m)]
        if ~isa(Φ_draw, Array)
            Φ_draw = Array(Φ_draw)
        end
        status = maximum(abs.(eigvals(Φ_draw)))
    end
    return β_draw, Φ_draw
end
# ------------------------------------------------------
# [3.4] Calculating matrix of cumulative FEVD
# ------------------------------------------------------
function Λmatrix(IRF, nvar, m; Lτ = 1, Uτ = 5, Xblock = false, nx = 0)
    Λ = zeros(m, m)
    for i = 1:Uτ
        R_tilde = IRF[nvar, :, i]
        Λ = Λ + ((Uτ - 1) + 1 - max(Lτ - 1, i - 1)) * (R_tilde * R_tilde')
    end
    if Xblock
        Λ = Λ[1:nx, 1:nx]
    end
    return Λ
end

# ------------------------------------------------------
# [3.5] IRF and FEVD functions
# ------------------------------------------------------
function irf_fevd(Θ, Γ, h, m)
    # --------------------------------------------------
    # [3.5.1] Impulse Response functions
    n = size(Θ)[1]
    IRFred = Array{Float64,3}(undef, n, n, h)
    IRFred[:, :, 1] = Θ
    IRF = Array{Float64,3}(undef, m, m, h)
    IRF[:, :, 1] = Θ[1:m, :1:m] * Γ

    for i = 2:h
        IRFred[:, :, i] = Θ * IRFred[:, :, i-1]
        IRF[:, :, i] = IRFred[1:m, 1:m, i] * Γ
    end

    # --------------------------------------------------
    # [3.5.2] Forecast Error variance Decomposition
    MSPEkj = cumsum(IRF .^ 2, dims = 3)
    MSPEk = sum(MSPEkj, dims = 2)
    FEVD = MSPEkj ./ MSPEk
    return IRF, FEVD
end

# ------------------------------------------------------
# [3.6] Get quantiles
# ------------------------------------------------------
function Qntls4D(x, nmodls, quintls, m, h)
    xvec = [vec(x[:, :, :, i]) for i = 1:nmodls]
    xvec = hcat(xvec...)
    sort!(xvec, dims = 2)
    indxs = convert(Array{Int64}, floor.(quintls .* nmodls))
    xqnt = [reshape(xvec[:, indxs[i]], (m, m, h)) for i = 1:length(indxs)]
    xtup = Tuple(x for x in xqnt)
    perci = "perct" .* string.(Int.(floor.(quintls * 100)))
    perci = Symbol.(perci)
    keys = (:perct1, :perct2, :perct3)
    xNtup = (; zip(perci, xtup)...)
    return xNtup
end

function Qntls(x, nmodls, quintls, m, h)
    xvec = [vec(x[:, :, i]) for i = 1:nmodls]
    xvec = hcat(xvec...)
    sort!(xvec, dims = 2)
    indxs = convert(Array{Int64}, floor.(quintls .* nmodls))
    xqnt = [reshape(xvec[:, indxs[i]], (m, h)) for i = 1:length(indxs)]
    xtup = Tuple(x for x in xqnt)
    perci = "perct" .* string.(Int.(floor.(quintls * 100)))
    perci = Symbol.(perci)
    keys = (:perct1, :perct2, :perct3)
    xNtup = (; zip(perci, xtup)...)
    return xNtup
end
end
