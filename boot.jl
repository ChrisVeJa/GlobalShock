using Random,
    DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions, Plots, CSV, RCall, JLD;
include("fcns/mainsup.jl")

function phidraw(y,x,m,p,nsmpl,t)
    maxλ = 1
    ϕd = nothing
    while maxλ >= 1
        pos = rand(1:nsmpl-t)
        yn = y[pos:pos+t-1,:]
        xn = x[pos:pos+t-1,:]
        βd, ϕd = OLSbetas(yn, xn, m, p, Xblock = true, Nx = 3)
        maxλ = maximum(abs.(eigvals(ϕd)))
    end
    return ϕd
end

function boots(B,Y,E,p,nsmpl)
    t, m = size(Y)
    nx  = m*p+1
    ebo = E[rand(1:t,nsmpl),:]
    rst = rand(p+1:t)
    y = Array{Float32,2}(undef,m,nsmpl)
    x = Array{Float32,2}(undef,nx,nsmpl)
    x[:,1] = [vec(Y[rst:-1:rst-1,:]') ; 1]
    βm = B'
    for i in 1:nsmpl-1
        y[:,i] = βm * x[:,i] + ebo[i,:]
        x[:,i+1] = [y[:,i] ; x[1:m,i] ; 1]
    end
    y[:,nsmpl] = βm * x[:,nsmpl] + ebo[nsmpl,:]
    y = y'
    x = x'
    collΦ = Array{Any,1}(undef,nrep)
    for i in 1:nrep
        collΦ[i] = phidraw(y,x,m,p,nsmpl,t)
    end
    return collΦ
end

p = 2
h = 40
nrep = 5000
dd = load("GSdata.jld")
dataset = dd["dataset"]

for k in dataset
    Y, X = VARData(k,p)
    B = (X'*X) \ (X'*Y)
    E = Y - X*B
    boots(B,Y,E,p,nsmpl)
end
