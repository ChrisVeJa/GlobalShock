####################################################################################
#           GLOBAL SHOCKS: Heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
####################################################################################

# ===========================================================================
# 							[0] Libraries
# ===========================================================================
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall, JLD;
include(".//fcns//GShock.jl");
#include(".//fcns//Comparison.jl");
include(".//fcns//fcns.jl");
include(".//fcns//part1.jl");
# ===========================================================================
# 							[1] Introduction
# ===========================================================================
colist  = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange  :red :purple :magenta :rosybrown4 :darkorchid4 :hotpink3 :palevioletred4 :cyan]
dir1 = "G:/My Drive/GlobalShocks/data";
labels = ["GDP G20" "ComPrice" "BAA spread" "GDP" "C" "I" "XN" "q" "i"];
p = 2
h = 40
nrep = 5000
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.1] Loading Data (if there is not GSdata.jl run line 28)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
# wvar, dataset, qlabel, list = GShock.GSDataLoader(dir1);
# save("GSdata.jld", "dataset", dataset, "wvar", wvar,"qlabel", qlabel, "list" , list);

dd = load("GSdata.jld")
wvar, dataset, qlabel, list = (dd["wvar"], dd["dataset"],dd["qlabel"], dd["list"])
part1(dataset,wvar);
dd = nothing
# ===========================================================================
# 							[2] GLOBAL SHOCKS
# ===========================================================================
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.1] Estimation and Results by country
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
nc = nfields(dataset)
nv = size(dataset[1])[2]
bnam = "Country"
CouList = bnam .* string.(1:nc) .* ".svg"
for i in 1:nc
	y = dataset[i]
	output = Symbol.(bnam.* string(i));
	model  = GShock.GSstimation(y, p, h, xblock = true, nx = 3)
	ex =:($output = $model);
	eval(ex);
	GSGraph(model[1],CouList[i], labels, colg = colist[i], varI=4);
end

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.2] Reporting by group of country both GS and NF shocks
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#

ecx, dcx  = GSgroups(bnam,1:10,9,40,5000,7);
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "Groups", varI=4);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "Groups", varI=4);
ToHtml("table1.html",round.(ecx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);
ToHtml("table2.html",round.(dcx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);


# ===========================================================================
# 					[3] COMPARISON OF SHOCKS
# ===========================================================================
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[3.1] Impact in macro variables
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "World", varI=1, varF=3);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "World", varI=1, varF=3);

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[3.2] Comparison
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.1] Effects in global variables	        =#
lab = ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"];
tit = ["Global Output" "Commodity Price" "BAA spread"];
p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,lab);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400), title = tit);
savefig(".//Figures//World//Comparison.svg");

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.2] Effects in domestic variables	    =#
raw = cat(ecx.IrfGS.Qntls[2][4:end,:], ecx.IrfNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompIRFecx.svg");
raw = cat(dcx.IrfGS.Qntls[2][4:end,:], dcx.IrfNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompIRFdcx.svg");
raw = cat(ecx.FevGS.Qntls[2][4:end,:], ecx.FevNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw, ".//Figures//World//CompFEVecx.svg");
raw = cat(dcx.FevGS.Qntls[2][4:end,:], dcx.FevNF.Qntls[2][4:end,:], dims=3);
GraphAux(raw,".//Figures//World//CompFEVdcx.svg");
cp(".//Figures",".//docs//images//Figures",force=true);
display("Workout finished")

#= ===========================================================================
# 				[5] COMPARISON OF METHODOLOGIES
# ===========================================================================

ΔIRF  = Array{Float64,3}(undef, 9, 40,ncou * 5000)
ΔFEV  = Array{Float64,3}(undef, 9 ,40,ncou * 5000)
for i in 1:ncou
	y = dataset[:,(i-1)*nvar+1:i*nvar];
	ran = 5000*(i-1)+1:5000*i;
	ΔIRF[:,:,ran], ΔFEV[:,:,ran] = GSComp.GScomparison(y,2,40)
end
ΔIRFQec  = GSComp.Qntls(ΔIRF[:,:,1:6*5000], 6 * 5000, [0.16 0.5 0.84], 9, 40)
ΔFEVQec  = GSComp.Qntls(ΔFEV[:,:,1:6*5000], 6* 5000, [0.16 0.5 0.84], 9, 40)
ΔIRFQdc  = GSComp.Qntls(ΔIRF[:,:,6*5000+1:end], 4 * 5000, [0.16 0.5 0.84], 9, 40)
ΔFEVQdc  = GSComp.Qntls(ΔFEV[:,:,6*5000+1:end], 4* 5000, [0.16 0.5 0.84], 9, 40)
=#
