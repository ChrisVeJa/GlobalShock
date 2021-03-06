################################################################################
#  [2] MAIN FUNCTIONS
################################################################################
module GSComp
using Random, DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions
include("mainsup.jl")
function ComParison(dataset,p,h,Lτ,Uτ,nmodls, cut)
    quint = [0.16 0.50 0.84]
    nc = nfields(dataset)
    m  = size(dataset[1])[2]
    ΔIRF = Array{Float32,3}(undef,m,h,nc*nmodls)
    ΔIRFcoun = Array{Float32,3}(undef,2*m,h,nc)
    j = 1
    for y in dataset
        range = nmodls*(j-1)+1:nmodls*j
        cout = GScomparison(y,p,h,Lτ, Uτ, nmodls)
        ΔIRF[:, :, range] = cout
        Δmn = dropdims(mean(cout, dims=3),dims=3)
        Δmd = dropdims(median(cout, dims=3),dims=3)
        ΔIRFcoun[:,:,j] = [Δmn; Δmd]
        j+=1
    end
    g1 = ΔIRF[:, :, 1:cut*nmodls]
    g2 = ΔIRF[:, :, cut*nmodls+1:end]
    Δmn1 = dropdims(mean(g1, dims=3),dims=3)
    Δmd1 = dropdims(median(g1, dims=3),dims=3)
    Δqt1 = Qntls(g1, nmodls, quint, m, h)
    Δmn2 = dropdims(mean(g2, dims=3),dims=3)
    Δmd2 = dropdims(median(g2, dims=3),dims=3)
    Δqt2 = Qntls(g2, (nc-cut)*nmodls, quint, m, h)
    ecx = (mean = Δmn1, median = Δmd1, bands = Δqt1)
    dcx = (mean = Δmn2, median = Δmd2, bands = Δqt2)
    return ecx, dcx, ΔIRFcoun
end

function GScomparison(y, p, h, Lτ, Uτ, nmodls)
    nx = 3
    varGS = 1:3
    pos_tot = 2
    # --------------------------------------------------------
    # [2.1.1] VAR in reduce form
    m = size(y)[2]
    Y, X = VARData(y, p)
    B, Φ = OLSbetas(Y, X, m, p, Xblock = true, Nx = nx)
    # --------------------------------------------------------
    # [2.1.2] Residual of the reduce form
    E = Y - X * B
    SS = (E' * E)
    # --------------------------------------------------------
    # [2.1.3] Global Shock identification
    ΔIRF = Array{Float64,3}(undef, m, h, nmodls)
    for i = 1:nmodls
        Φ, Γ, Γcom = GSComSim(Y, X, B, SS, p, Lτ, Uτ, pos_tot, nx, varGS)
        #Φ, Γ, ξ_tot
        IRF1, f1 = irf_fevd(Φ, Γ, h, m)
        IRF2, f2 = irf_fevd(Φ, Γcom, h, m)
        ΔIRF[:, :, i] = IRF1[:, 1, :] - IRF2[:, 1, :]
    end
    return ΔIRF
end
function GSComSim(Y, X, B, SS, p, Lτ, Uτ, pos_tot, nx, varGS)
    # --------------------------------------------------------
    # [2.2.1] Drawing βₙ
    Xblock = true
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
    # [2.2.4] New Augmented ToT as in Zeev
    Λtot = Λmatrix(IRF, pos_tot, m; Lτ = Lτ, Uτ = Uτ, Xblock = true, nx = nx)
    ξcom = eigen(Λtot).vectors[:, end:-1:1]
    ξcom = sign.(diag(ξcom))' .* ξcom
    Γcom = [C1[:, 1:nx] * ξcom C1[:, nx+1:end]]
    Γcom = sign.(diag(Γcom))' .* Γcom
    # --------------------------------------------------------
    # [2.2.4] Global Shocks Identification
    # [Step 1] Matrix Λ and their weights
    k = length(varGS)
    n = (Xblock * nx) + (1 - Xblock) * m
    Λ = zeros(n, n, k)
    λ = zeros(k)
    for i = 1:k
        Λ[:, :, i] = Λmatrix(IRF, varGS[i], m; Lτ = Lτ, Uτ = Uτ, Xblock = true, nx = nx)
        λ[i] = tr(Λ[:, :, i])
    end
    λ = prod(λ) ./ λ
    Ξ = dropdims(sum(reshape(λ, 1, 1, :) .* Λ, dims = 3), dims = 3)
    ξ = eigen(Ξ).vectors[:, end:-1:1]
    Γ = [C1[:, 1:nx] * ξ C1[:, nx+1:end]]
    Γ = sign.(diag(Γ))' .* Γ  # Normalization to improve identification
    return Φ, Γ, Γcom # Identification, New-augmented
end
end
