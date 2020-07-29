# **GLOBAL SHOCKS: Heterogeneous effect in small open economies**
## LIST OF CODES
### [1] Master program
Requisites: Random, DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions, Plots, CSV, RCall, JLD;
.jl files to include: `GSshock`,`GSComp`, `fcns`, and  `part1`

A briefly explanation of the master program (this is a pseudo-code please dont try to run it)
```julia
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall, JLD;
include(".//fcns//GShock.jl");
include(".//fcns//GSComp.jl");
include(".//fcns//fcns.jl");
include(".//fcns//part1.jl");
colist  := List of colors that you will use in the graphics (type Symbol)
dir1 := Directory that host the data
labels := Variable names
p := lags ; h := horizon for IRF, FEV ; nrep := Number of simulations

if you want to load the data run 
	wvar, dataset, qlabel, list = GShock.GSDataLoader(dir1);
	save("GSdata.jld", "dataset", dataset, "wvar", wvar,"qlabel", qlabel, "list" , list);
else
	dd = load("GSdata.jld");
	wvar, dataset, qlabel, list = (dd["wvar"], dd["dataset"],dd["qlabel"], dd["list"]);
end

part1(dataset,wvar) # This line run all the work for the introduction
```
Now we have the data, then we need to set some prelimaries
```julia
nc := Number of countries; nv := Number of variables; Lτ := Lower bound ; Uτ := Upper bound for maximization
bnam := prefix for the models (type String) 
cut := Number of countries that belongs to ecx
CouList = bnam .* string.(1:nc) .* ".svg" # it creates the name for the graphs
```
After that, we estimate and graphic each model using a loop and metaprogramming
```julia
for i in 1:nc
	y = dataset[i]
	output = Symbol.(bnam.* string(i));
	model  = GShock.GSstimation(y, p, h, xblock = true, nx = 3)
	ex =:($output = $model);
	eval(ex);
	GSGraph(model[1],CouList[i], labels, colg = colist[i], varI=4);
end
```
With that, we can create the country groups and made tha graph for the contribution to domestic variable FEV (from the variable number 4)
```julia
ecx, dcx  = GSgroups(bnam,1:nc,nv,h,nrep,cut);
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "Groups", varI=4);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "Groups", varI=4);
# Next lines creates the html tables (not important)
```
and the explanation over global variables (from variable 1 to variable 3)
```julia
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "World", varI=1, varF=3);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "World", varI=1, varF=3);
```
Creating the matrix containers for global shock and non fundamental. Then, we graph
```julia
GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);
lab = ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"];
tit = ["Global Output" "Commodity Price" "BAA spread"];
p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,lab);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400), title = tit);
savefig(".//Figures//World//Comparison.svg");
```
We can nake something similar for the domestic bloc
```julia
lab = ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"]
raw1 = cat(ecx.IrfGS.Qntls[2][4:end, :], dcx.IrfGS.Qntls[2][4:end, :], dims = 3)
raw2 = cat(ecx.IrfNF.Qntls[2][4:end, :], dcx.IrfNF.Qntls[2][4:end, :], dims = 3)
p1 = myplot([raw1[1, :, :] raw2[1, :, :]], h, "")
p2 = myplot([raw1[2, :, :] raw2[2, :, :]], h, "")
p3 = myplot([raw1[3, :, :] raw2[3, :, :]], h, lab)
p4 = myplot([raw1[4, :, :] raw2[4, :, :]], h, "")
p5 = myplot([raw1[5, :, :] raw2[5, :, :]], h, "")
p6 = myplot([raw1[6, :, :] raw2[6, :, :]], h, "")
tit = ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]
plot(p1, p2, p3, p4, p5, p6, layout = (2, 3), size = (1200, 800), grid = false, title = tit)
savefig(".//Figures//World//CompIRF.svg")

raw1 = cat(ecx.FevGS.Qntls[2][4:end, :], dcx.FevGS.Qntls[2][4:end, :], dims = 3)
raw2 = cat(ecx.FevNF.Qntls[2][4:end, :], dcx.FevNF.Qntls[2][4:end, :], dims = 3)
p1 = myplot([raw1[1, :, :] raw2[1, :, :]], h, "")
p2 = myplot([raw1[2, :, :] raw2[2, :, :]], h, "")
p3 = myplot([raw1[3, :, :] raw2[3, :, :]], h, "")
p4 = myplot([raw1[4, :, :] raw2[4, :, :]], h, "")
p5 = myplot([raw1[5, :, :] raw2[5, :, :]], h, lab)
p5 = plot(p5, legend = :bottomright)
p6 = myplot([raw1[6, :, :] raw2[6, :, :]], h, "");
plot(p1, p2, p3, p4, p5, p6, layout = (2, 3), size = (1200, 800), title = tit)
savefig(".//Figures//World//CompFEV.svg")
```
Finally we make the comparison between global shocks and news-augmented terms of trade
```julia
Δecx, Δdcx, ΔIRFcoun = GSComp.ComParison(dataset, p, h, Lτ, Uτ, nrep, cut);
ppl = plot(layout = (3, 3), size = (1200, 800), title = labels)
for i = 1:nv
    bands = (
        Δecx.bands[1][i, 1:20] - Δecx.bands[2][i, 1:20],
        Δecx.bands[2][i, 1:20] - Δecx.bands[3][i, 1:20],
    )
    plot!(
        1:20,
        Δecx.bands[2][i, 1:20],
        c = :darkgoldenrod,
        ribbon = bands,
        fillalpha = 0.2,
        label = :false,
        w = 1.5,
        grid = :false,
        subplot = i,
        framestyle = :zerolines,
    )
end
savefig("./Figures/CompIRFECX.svg")
ppl = plot(layout = (3, 3), size = (1200, 800), title = labels)
for i = 1:nv
    bands = (
        Δdcx.bands[1][i, 1:20] - Δdcx.bands[2][i, 1:20],
        Δdcx.bands[2][i, 1:20] - Δdcx.bands[3][i, 1:20],
    )
    plot!(
        1:20,
        Δdcx.bands[2][i, 1:20],
        c = :purple,
        ribbon = bands,
        fillalpha = 0.2,
        label = :false,
        w = 1.5,
        grid = :false,
        subplot = i,
        framestyle = :zerolines,
    )
end
plot(ppl)
savefig("./Figures/CompIRFDCX.svg")
 # The rest of the code is not necessary
```
After explaining the master code we will go through the modules and functions
### [2] Module GShock
####  [2.1] Containers

- `Param`
  - `B` : Estimated βs
  - `Σ` : Variance Covariance matrix
  - `Γ` : Median of identificacion matrix
  - `ξ` : Median of Eigenvectors
- `Post`
  - `Mean` : Average
  - `Qntld`: Percentiles
- `GSsolve`
  - `Par`: Estimated parameters
  - `IrfGS`: Impulse response function
  - `FevGS`: Forecast Error Variances decomposition
  - `IrfNF`: Impulse response function Non fundamental
  - `FevNF`: Forecast Error Variances decomposition Non fundamental
####  [2.2] Main functions
The function `GSstimation` estimates the structural form for both shocks: global and non-fundamental, having
the following syntax 
```julia
gsolve::GSsolve, U, m::Tuple = GSstimation(y, p, h; 
			xblock= false, GOS = true, nx = 0, VarGS = 1:3, 
			nmodls= 5000, quint = [0.16 0.50 0.84], NF= true, 
			Lτ = 1, Uτ = 5,
			)
```
Now I will explain the code itself (again, it is a pseudo code but follow pretty close the original)
```julia
function GSstimation(...)
    # 1. Estimation of the reduce form of the VAR
    m = size(y)[2]
    Y, X = VARData(...)  # Creation of regressors from y
    B, Φ = OLSbetas(...) # Restricted OLS estimation

    # [2] Calculate variance-covariance matrix
    # [3] Creates data containers
    # [4] Identification
	  for i = 1:nmodls
		β, Φ, γ, ξ[:, :, i] =  	GSsimulation(...) # makes the simulation
		Uaux   = γ\(E') # calculates partial identified structural shocks
	        IRF, FEV = irf_fevd(Φ, γ, h, m) # computing irf and fevd
	  end
    # [5] Calculating percentiles and creating outputs
end
```
The central part of the working is made by the function `GSsimulation`, which have the following syntax
```julia
β, Φ, Γ, ξ = GSsimulation(Y, X, B, SS, p, Lτ, Uτ; Xblock = false, nx =3, varGS = 1:3, nonfun = true)
```
and makes:
```julia
function GSsimulation(...)
    # --------------------------------------------------------
    # [1] Bayesian step: 
    T, m   = size(Y)
    σdist  = InverseWishart(T, SS)   # distribution for Σ
    b      = vec(B)
    rc, cc = size(B)
    Σ      = rand(σdist)             # Sampling Σ
    XX     = Symmetric(inv(X'X), :L)
    kr     = kron(Σ, XX)
    disti  = MvNormal(b, kr)	     # distribution for  β
    β, Φ   = BetaDraw(disti, rc, cc, m, p)  #  draw β until get one stable

    C1 := Cholesky Identification | Σ, β
    IRF:= Calculating IRFs for the desired interval

    # [2] Global Shocks Identification
	    # [Step 1] Matrix Λ and their weights
	    for i = 1:tvars
		Λ[:, :, i] = Λmatrix(IRF, varGS[i], m; Lτ = Lτ, Uτ = Uτ, Xblock = Xblock, nx = nx)
		λ[i] 	   = tr(Λ[:, :, i])
	    end
	    λ = prod(λ) ./ λ  # these are the weights 

	    # [Step 2] Matrix ξ
    	    Ξ := weigthed sum of  Λ
	    ξ := ordered eigenvector from the larger to smaller
    # [3] NON FUNDAMENTAL SHOCK
	    nξ  = size(ξ)[1];
	    L   = [-ξ[2:end,1] ./ ξ[1,1] I(nξ-1)] # This is the matrix ϕ'Γ'
	    BL  = L*L';
	    Λaux= L*Λ[:,:,pos_tot]*L';   	 # pos_tot is the position of terms of trade 
	    ψ   = eigen(Λaux, BL).vectors[:,end] # generalized eigenvalue-eigenvector
	    Ξ   = [ξ[:,1] Ψ]			 # new matrix with identied response vectors
	    nsp = nullspace(Array(Ξ'))           # Calculating the null-space for the matrix Ξ
	    ξ   = [Ξ nsp[:,1:(nξ-2)]];		 # Identification matrix (just the first two columns)

    # [4] New Identification matrix
	    if there is an exogenous bloc
		Γ = [C1[:, 1:nx] * ξ C1[:, nx+1:end]]
	    else
		Γ = C1 * ξ
	    end
            Γ = sign.(diag(Γ))' .* Γ  # Normalization to improve identification
end
```
### [1.1] Creating the groups of countries
In this code we create a matrix with the mean and quintiles for a group de countries.
```julia
ecx, dcx =  GSgroups(name,range,nv,h,nrep,cut)
```
where `ecx`, `dcx` are NamedTuple with fields:
- `IrfGS` : response of each variable for a global shock
- `FevGS` : contribuion of global shocks to the FEV
- `IrfNF` : response of each variable for a non fundamental shock
- `FevNF` : contribuion of non-fundamental shocks to the FEV

with the arguments
- `name`: prefix that works as base for the models,
- `range`: range for the name models
- `nv`: number of variables
- `h`: Horizon for IRF and FEVD
- `nrep`: number of replications in each model
- `cut`: number of countries in the first group

### [1.2] Graphics
```julia
GSGraph(model, name, labels; colg =:sienna, subdir="Countries", varI=1, varF = 0)
```
```julia
ModelGraph(data,nf,varI,varF,name,labels,colg)
```
```julia
p1 = myplot(data,h,mylabel)
```
### [1.3] HTML tables
The following code creates a file `name.html` which print a matrix `matt` with the name `colnames` in html format
```julia
ToHtml(file, matt, colnames)
```


### [1.4] Module GSComp
```julia
ecx, dcx, ΔIRFcoun = ComParison(dataset,p,h,Lτ,Uτ,nmodls, cut)
```
```julia
ΔIRF =  GScomparison(y, p, h, Lτ, Uτ, nmodls)
```
```julia
Φ, Γ, Γcom = GSComSim(Y, X, B, SS, p, Lτ, Uτ, pos_tot, nx, varGS)
```
```

