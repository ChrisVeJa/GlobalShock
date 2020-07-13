####################################################################################
#           GLOBAL SHOCKS: Heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
####################################################################################

# ===========================================================================
# [0] Libraries and required module
# ===========================================================================
using Random, DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions, Plots;
include(".//fcns//GlobalShocks.jl");
include(".//fcns//fcns.jl");
include(".//fcns//ToHtml.jl");
if ~isdir(".//Figures")   mkdir("Figures") end
# ===========================================================================
# [1] Introduction
# ===========================================================================
gframe = DataFrame(XLSX.readtable("file1.xlsx", "data")...);
gdata = convert(Array{Float64},gframe[:,2:end]);
gdata = [100*gdata[2:end,1:2] - 100*gdata[1:end-1,1:2] 0.5*gdata[2:end,3]]
gdate = convert(Array{String},gframe[2:end,1]);

# --------------------------------------------------------------------------
# [1.1 Figure 1]
T = length(gdate);
p = plot(gdata[:,[1,3]],ylims=(-2,5),fg_legend = :transparent,
        legendfontsize=6,label = ["G20 output" "BAA spread"],
        legend=:bottomleft, xticks = (1:12:T, gdate[1:12:T]),
        w = [1 2.5],style = [:dash :dot], c= [:black :gray],
        title = "Figure 1: Evolution of macro variables" ,
        titlefontsize = 10, ygrid=:none,
        )
p = twinx()
plot!(p,gdata[:,2],ylims=(-50,20), legend= false,
    xticks= :none, c= :red, w= 1.15 , alpha=0.75,
    ygridstyle=:dash,
    )
plot!(NaN.*(1:T),c = :red, label= "Commodity prices");
savefig(".//Figures//intro1.svg")
# --------------------------------------------------------------------------
# [1.2 Correlations]
CoRR = cor(gdata);
display(CoRR)

# --------------------------------------------------------------------------
# [1.3 Figure 2]
# In this part we are just interested in some graphics, then
# I will just consider a light version of each model
df= DataFrame(XLSX.readtable("basedato.xlsx", "data")...)
p = 2;
h = 40;
U = fill(NaN,size(df)[1],10);
for i in 1:10
    start = 2 + 9*(i-1);
    y = convert(Array{Float64},df[:, start:start+8][completecases(df[:, start:start+8]), :]);
    model1, Uaux, _tup1 = GlobalShock.GSstimation(y, p, h, VarGS = 2,
                        nonfun = false, nmodls = 1000,
    );
    tt = length(Uaux);
    U[end+1-tt:end,i] = Uaux;
end
umean = [mean(U[i,:][.!isnan.(U[i,:])]) for i in 4:size(df)[1]];
umax = [maximum(U[i,:][.!isnan.(U[i,:])]) for i in 4:size(df)[1]];
UB   = umax - umean ;
umin = [minimum(U[i,:][.!isnan.(U[i,:])]) for i in 4:size(df)[1]];
LB   = umean - umin ;
umean = umean .- mean(umean);
taux= length(umean);
gd1 = gdata[end-taux+1:end,1]
gd1 = gd1 .- mean(gd1);
p   = plot(1:taux, umean, ribbon = (LB, UB),c = :teal, fillalpha=0.1, w = 1.5,
        fg_legend = :transparent, label = "News-augmented comm. shocks",
        title = "Figure 2: News-augmented commodity shocks vs G20 growth" ,
        titlefontsize = 10,xticks = (1:12:taux, gdate[end+1-taux:12:end]),
        legendfontsize=7, legend=:bottomleft)
plot!(1:taux,gd1, c=:red, w = 1.25, alpha = 0.85, label= "G20 output")
savefig(".//Figures//intro2.svg")
CoRR2 = cor([umean gd1]);
display(CoRR2)


# ===========================================================================
# [2] GLOBAL SHOCKS
# ===========================================================================
df   = DataFrame(XLSX.readtable("basedato.xlsx", "data")...)
name = [:GSArg :GSBra :GSChl :GSCol :GSPer :GSSoA :GSAus :GSCan :GSNrw :GSNzl];
countries = [:Argentina :Brazil :Chile :Colombia :Peru :SouthAfrica :Australia :Canada :Norway :NewZeland];
colist  = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange  :red :purple :magenta :rosybrown4 :darkorchid4 :hotpink3 :palevioletred4 :cyan]
CouList = string.(name) .* ".svg";
labels  = ["GDP G20" "ComPrice" "BAA spread" "GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"];
p = 2;
h = 40;

# [2.1 Estimation by country]
for i in 1:length(countries)
    model = countries[i]
    display("Global shocks: $model")
    codmodel = gos_creator(df,i,name, p, h);
    eval(codmodel);
end

# [2.2 ] Creating groups of countries
quint = [0.16 0.50 0.84];
inp1 = (ExtraGSArg.irfgs, ExtraGSBra.irfgs, ExtraGSChl.irfgs, ExtraGSCol.irfgs, ExtraGSPer.irfgs, ExtraGSSoA.irfgs);
inp2 = (ExtraGSArg.fevgs, ExtraGSBra.fevgs, ExtraGSChl.fevgs, ExtraGSCol.fevgs, ExtraGSPer.fevgs, ExtraGSSoA.fevgs);
inp3 = (ExtraGSAus.irfgs, ExtraGSCan.irfgs, ExtraGSNrw.irfgs, ExtraGSNzl.irfgs);
inp4 = (ExtraGSAus.fevgs, ExtraGSCan.fevgs, ExtraGSNrw.fevgs, ExtraGSNzl.fevgs);
inp5 = (ExtraGSArg.irfnf, ExtraGSBra.irfnf, ExtraGSChl.irfnf, ExtraGSCol.irfnf, ExtraGSPer.irfnf, ExtraGSSoA.irfnf);
inp6 = (ExtraGSArg.fevnf, ExtraGSBra.fevnf, ExtraGSChl.fevnf, ExtraGSCol.fevnf, ExtraGSPer.fevnf, ExtraGSSoA.fevnf);
inp7 = (ExtraGSAus.irfnf, ExtraGSCan.irfnf, ExtraGSNrw.irfnf, ExtraGSNzl.irfnf);
inp8 = (ExtraGSAus.fevnf, ExtraGSCan.fevnf, ExtraGSNrw.fevnf, ExtraGSNzl.fevnf);
ecx  = (IrfGS = GScat(inp1,quint), FevGS = GScat(inp2,quint), IrfNF = GScat(inp5,quint), FevNF = GScat(inp6,quint));
dcx  = (IrfGS = GScat(inp3,quint), FevGS = GScat(inp4,quint), IrfNF = GScat(inp7,quint), FevNF = GScat(inp8,quint));
inp1 = nothing; inp2 = nothing; inp3 = nothing; inp4 = nothing;
inp5 = nothing; inp6 = nothing; inp7 = nothing; inp8 = nothing;
ExtraGSArg = nothing; ExtraGSBra = nothing; ExtraGSChl = nothing; ExtraGSCol = nothing; ExtraGSPer = nothing;
ExtraGSSoA = nothing; ExtraGSAus = nothing; ExtraGSCan = nothing; ExtraGSNrw = nothing; ExtraGSNzl = nothing;

# [2.2 ] Reporting by group of country both GS and NF shocks

GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "Groups", varI=4);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "Groups", varI=4);
ToHtml("table1.html",round.(ecx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);
ToHtml("table2.html",round.(dcx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);

# ===========================================================================
# [3] Reporting results by country
# ===========================================================================

for x in 1:length(countries)
    country = name[x];
    ex= :(GSGraph($country,CouList[$x], labels, colg = colist[$x], varI=4));
    eval(ex);
end
GSArg.FevGS.Qntls[2][4:end,:]'


# ===========================================================================
# [3] Comparison of shocks
# ===========================================================================

# [3.1] Impact in macro variables
GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod, subdir = "World", varI=1, varF=3);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 , subdir = "World", varI=1, varF=3);


# [3.2] Comparison
GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);
p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"]);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400),title =["Global Output" "Commodity Price" "BAA spread"]);
savefig(".//Figures//World//Comparison.svg");
raw = cat(ecx.IrfGS.Qntls[2][4:end,:], ecx.IrfNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonIRFecx.svg";
GraphAux(raw, myname);
raw = cat(dcx.IrfGS.Qntls[2][4:end,:], dcx.IrfNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonIRFdcx.svg";
GraphAux(raw, myname);
raw = cat(ecx.FevGS.Qntls[2][4:end,:], ecx.FevNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonFEVecx.svg";
GraphAux(raw, myname);
raw = cat(dcx.FevGS.Qntls[2][4:end,:], dcx.FevNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonFEVdcx.svg";
GraphAux(raw, myname);

cp(".//Figures",".//docs//images//Figures",force=true);
display("Workout finished")
