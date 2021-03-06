####################################################################################
#           GLOBAL SHOCKS: Heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
####################################################################################

# ===========================================================================
# 							[0] Libraries
# ===========================================================================
using Random,
    DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions, Plots, CSV, RCall, JLD;

include(".//fcns//GShock.jl");
include(".//fcns//GSComp.jl");
include(".//fcns//fcns.jl");
include(".//fcns//part1.jl");
# ===========================================================================
# 							[1] Introduction
# ===========================================================================
colist = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange :red :purple :magenta]
dir1 = "G:/My Drive/GlobalShocks/data";
labels = ["GDP G20" "ComPrice" "BAA spread" "GDP" "C" "I" "XN" "q" "r"];
p = 2
h = 40
nrep = 5000
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.1] Loading Data (if there is not GSdata.jl run line 28)
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
#wvar, dataset, qlabel, list = GShock.GSDataLoader(dir1)
#save("GSdata.jld", "dataset", dataset, "wvar", wvar,"qlabel", qlabel, "list" , list)
dd = load("GSdata.jld")
wvar, dataset, qlabel, list = (dd["wvar"], dd["dataset"], dd["qlabel"], dd["list"])
part1(dataset, wvar)
dd = nothing  # it is just to reduce the memory stress
# ===========================================================================
# 							[2] GLOBAL SHOCKS
# ===========================================================================
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.1] Estimation and Results by country
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
nc = nfields(dataset)
nv = size(dataset[1])[2]
Lτ = 1
Uτ = 5
bnam = "Country"
cut = 6
CouList = bnam .* string.(1:nc) .* ".svg"
for i = 1:nc
    y = dataset[i]
    output = Symbol.(bnam .* string(i))
    model = GShock.GSstimation(y, p, h, xblock = true, nx = 3)
    ex = :($output = $model)
    eval(ex)
    GSGraph(model[1], CouList[i], labels, colg = colist[i], varI = 4)
end

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.2] Reporting by group of country both GS and NF shocks
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
ecx, dcx = GSgroups(bnam, 1:nc, nv, h, nrep, cut);
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "Groups", varI = 4)
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4, subdir = "Groups", varI = 4)
varnames = ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]
ToHtml("table1.html",round.(ecx.FevGS.Qntls[2][4:end, :]', digits = 2), varnames)
ToHtml("table2.html", round.(dcx.FevGS.Qntls[2][4:end, :]', digits = 2), varnames)

# ===========================================================================
# 					[3] COMPARISON OF SHOCKS
# ===========================================================================
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[3.1] Impact in macro variables
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "World", varI = 1, varF = 3)
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4, subdir = "World", varI = 1, varF = 3)

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[3.2] Comparison
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
GStoWorld = cat(ecx.FevGS.Qntls[2][1:3, :], dcx.FevGS.Qntls[2][1:3, :], dims = 3)
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3, :], dcx.FevNF.Qntls[2][1:3, :], dims = 3)

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.1] Effects in global variables	        =#
lab = ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"]
tit = ["Global Output" "Commodity Price" "BAA spread"]
p1 = myplot([GStoWorld[1, :, :] NFtoWorld[1, :, :]], h, "")
p2 = myplot([GStoWorld[2, :, :] NFtoWorld[2, :, :]], h, lab)
p3 = myplot([GStoWorld[3, :, :] NFtoWorld[3, :, :]], h, "")
plot(p1, p2, p3, layout = (1, 3), size = (1200, 400), title = tit, grid = :false)
savefig(".//Figures//World//Comparison.svg")

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.2] Effects in domestic variables	    =#
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

# ===========================================================================
# 				[5] COMPARISON OF METHODOLOGIES
# ===========================================================================
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
cp(".//Figures", ".//docs//images//Figures", force = true)
display("Workout finished")
