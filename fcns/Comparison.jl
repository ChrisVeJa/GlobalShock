################################################################################
#  [2] MAIN FUNCTIONS
################################################################################
module GSComp
using Random,
    DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions
include("mainsup.jl")
# ------------------------------------------------------
# [2.1] Estimation of Global Shocks
# ------------------------------------------------------
function GScomparison(y, p, h)
	GOS = true
	nx = 3
	VarGS = 1:3
	nmodls = 5000
	Lτ = 1
	Uτ = 5
	quint = [0.16 0.50 0.84]
	nonfun = true
	pos_tot=2,
    # --------------------------------------------------------
    # [2.1.1] VAR in reduce form
    m    = size(y)[2]
    Y, X = VARData(y, p)
    B, Φ = OLSbetas(Y, X, m, p, Xblock = true, Nx = nx)
    # --------------------------------------------------------
    # [2.1.2] Residual of the reduce form
    T, mn = size(X)
    E = Y - X * B
    Σ = (E' * E) / (T - mn)
    SS = (E' * E)
	# --------------------------------------------------------
    # [2.1.3] Global Shock identification
    ΔIRF = Array{Float64,3}(undef, m, h, nmodls)
    ΔFEV = Array{Float64,3}(undef, m, h, nmodls)
    for i = 1:nmodls
        ou1, ou2, ou3 = GSsimulation(Y, X, B, SS, p, Lτ, Uτ, pos_tot, nx,varGS)
        #Φ, Γ, ξ_tot
        IRF1, FEV1 = irf_fevd(ou1, ou2, h, m)
		IRF2, FEV2 = irf_fevd(ou1, ou3, h, m)
        ΔIRF[:, :, i] = IRF1[:, 1, :]- IRF2[:, 1, :]
        ΔFEV[:, :, i] = FEV1[:, 1, :]- FEV2[:, 1, :]
    end
	# -------- Means --------
    ΔIRFmean = dropdims(mean(ΔIRF, dims = 3), dims = 3)
    ΔFEVmean = dropdims(mean(ΔFEV, dims = 3), dims = 3)
	# -------- Percentiles --------
    ΔIRFquint = Qntls(ΔIRF, nmodls, quint, m, h)
    ΔFEVquint = Qntls(ΔFEV, nmodls, quint, m, h)
	# -------------------------
end

# ------------------------------------------------------
# [2.2] Bayesian Simulation
# ------------------------------------------------------

function GSComSim(Y, X, B, SS, p, Lτ, Uτ, pos_tot, nx,varGS)
    # --------------------------------------------------------
    # [2.2.1] Drawing βₙ
    T, m = size(Y)
    σdist = InverseWishart(T, SS)
    b = vec(B)
    rc, cc = size(B)
    Σ = rand(σdist)
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
    aux_IRF = Array{Float64,3}(undef, m * p, m * p, Uτ)
    IRF = Array{Float64,3}(undef, m, m, Uτ)
    aux_IRF[:, :, 1] = Φ
    IRF[:, :, 1] = aux_IRF[1:m, 1:m, 1] * C1
    for i = 2:Uτ
        aux_IRF[:, :, i] = Φ * aux_IRF[:, :, i-1]
        IRF[:, :, i] = aux_IRF[1:m, 1:m, i] * C1
    end
	# --------------------------------------------------------
    # [2.2.4] New Augmented ToT
	 Λ_tot = Λmatrix(IRF, pos_tot, m; Lτ = Lτ, Uτ = Uτ, Xblock = Xblock, nx = nx)
	 ξ_tot = eigen(Λ_tot).vectors[:, end:-1:1]
	 ξ_tot = sign.(diag(ξ_tot))' .* ξ_tot
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
    # [Step 5] New Identification matrix
    Γ = [C1[:, 1:nx] * ξ C1[:, nx+1:end]]
    Γ = sign.(diag(Γ))' .* Γ  # Normalization to improve identification
    return Φ, Γ, ξ_tot # Identification, New-augmented
end
end
