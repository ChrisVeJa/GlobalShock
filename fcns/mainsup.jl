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
