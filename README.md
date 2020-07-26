# **GLOBAL SHOCKS: Heterogeneous effect in small open economies**

## [1] List of codes

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
### [1.4] Module GShock
####  [1.4.1] STRUCTURES FOR CONTAINERS

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

```julia
gsolve::GSsolve, U, m::Tuple= GSstimation(y, p, h;
	xblock= false,
	GOS   = true,
	nx    = 0,
	VarGS = 1:3,
	nmodls= 5000,
	quint = [0.16 0.50 0.84],
	NF    = true,
	Lτ = 1, Uτ = 5,
)
```
```julia
β, Φ, Γ, ξ = GSsimulation(Y, X, B, SS, p, Lτ, Uτ;
	Xblock = false,
	nx     = 3,
	varGS  = 1:3,
	nonfun = true)
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

#####################################################################

Libraries
```julia
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall, JLD;
include(".//fcns//GShock.jl");
include(".//fcns//GSComp.jl");
include(".//fcns//fcns.jl");
include(".//fcns//part1.jl");
```
```julia
colist  = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange  :red :purple :magenta :rosybrown4 :darkorchid4 :hotpink3 :palevioletred4 :cyan]
dir1 = "G:/My Drive/GlobalShocks/data";
labels = ["GDP G20" "ComPrice" "BAA spread" "GDP" "C" "I" "XN" "q" "i"];
p = 2
h = 40
nrep = 5000
```
```julia
# time wvar, dataset, qlabel, list = GShock.GSDataLoader(dir1);
# save("GSdata.jld", "dataset", dataset, "wvar", wvar,"qlabel", qlabel, "list" , list);
dd = load("GSdata.jld");
wvar, dataset, qlabel, list = (dd["wvar"], dd["dataset"],dd["qlabel"], dd["list"]);
part1(dataset,wvar);
dd = nothing
```
```julia
nc = nfields(dataset)
nv = size(dataset[1])[2]
Lτ = 1
Uτ = 5
bnam = "Country"
cut = 6
CouList = bnam .* string.(1:nc) .* ".svg"
for i in 1:nc
	y = dataset[i]
	output = Symbol.(bnam.* string(i));
	model  = GShock.GSstimation(y, p, h, xblock = true, nx = 3)
	ex =:($output = $model);
	eval(ex);
	GSGraph(model[1],CouList[i], labels, colg = colist[i], varI=4);
end
```
```julia
ecx, dcx  = GSgroups(bnam,1:nc,nv,h,nrep,cut);
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "Groups", varI=4);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "Groups", varI=4);
ToHtml("table1.html",round.(ecx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);
ToHtml("table2.html",round.(dcx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);
```
```julia
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "World", varI=1, varF=3);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "World", varI=1, varF=3);
```
```julia
GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);
```
```julia
lab = ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"];
tit = ["Global Output" "Commodity Price" "BAA spread"];
p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,lab);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400), title = tit);
savefig(".//Figures//World//Comparison.svg");
```
```julia
raw = cat(ecx.IrfGS.Qntls[2][4:end,:], ecx.IrfNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompIRFecx.svg");
raw = cat(dcx.IrfGS.Qntls[2][4:end,:], dcx.IrfNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompIRFdcx.svg");
raw = cat(ecx.FevGS.Qntls[2][4:end,:], ecx.FevNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompFEVecx.svg");
raw = cat(dcx.FevGS.Qntls[2][4:end,:], dcx.FevNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw,".//Figures//World//CompFEVdcx.svg");
```
```julia
Δecx, Δdcx, ΔIRFcoun = GSComp.ComParison(dataset,p,h,Lτ,Uτ,nrep, cut);
ppl = plot(layout=(3,3), size=(1200,800), title = labels)
for i in 1:nv
	bands = (Δecx.bands[1][i,1:20] - Δecx.bands[2][i,1:20],	Δecx.bands[2][i,1:20] - Δecx.bands[3][i,1:20])
	plot!(1:20, Δecx.bands[2][i,1:20],c=:darkgoldenrod, ribbon = bands, fillalpha=0.2,
		label = :false, w = 1.5, grid= :false, subplot=i, framestyle = :zerolines)
end
savefig("./Figures/CompIRFECX.svg")
ppl = plot(layout=(3,3), size=(1200,800), title = labels)
for i in 1:nv
	bands = (Δdcx.bands[1][i,1:20] - Δdcx.bands[2][i,1:20],	Δdcx.bands[2][i,1:20] - Δdcx.bands[3][i,1:20])
	plot!(1:20, Δdcx.bands[2][i,1:20],c=:purple, ribbon = bands, fillalpha=0.2,
		label = :false, w = 1.5, grid= :false, subplot=i, framestyle = :zerolines)
end
plot(ppl)
savefig("./Figures/CompIRFDCX.svg")
ΔIRFcoun = ΔIRFcoun[10:end,:,:];
anim = @animate  for co in 1:nc
	ppl = plot(layout=(3,3), size=(1200,800), title = labels)
	for i in 1:nv
		if i == 9
			plot!(1:20, ΔIRFcoun[i,1:20,co], c=colist[co],
				label = list[co], w = 2.5, grid= :false, alpha=0.8,
				subplot=i, framestyle = :zerolines, legendfontsize = 10,
				fg_legend= :transparent, bg_legend= :transparent,
				legend=:best)
		else
			plot!(1:20, ΔIRFcoun[i,1:20,co], c=colist[co], alpha=0.8,
				label = :false, w = 2.5, grid= :false,
				subplot=i, framestyle = :zerolines)
		end
	end
end
gif(anim, "./Figures/IRFdif.gif", fps = 1);
cp(".//Figures",".//docs//images//Figures",force=true);
display("Workout finished")
```
