####################################################################################
#           GLOBAL SHOCKS: Heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
####################################################################################

# ===============================================
# [0] Libraries and required module
# ===============================================
using Random, DataFrames, XLSX, LinearAlgebra, Statistics, StatsBase, Distributions, Plots;
include(".//fcns//GlobalShocks.jl");
include(".//fcns//fcns.jl");

# ===============================================
# [1] Estimation by country
# ===============================================
df   = DataFrame(XLSX.readtable("basedato.xlsx", "data")...)
name = [:GSArg :GSBra :GSChl :GSCol :GSPer :GSSoA :GSAus :GSCan :GSNrw :GSNzl];
countries = [:Argentina :Brazil :Chile :Colombia :Peru :SouthAfrica :Australia :Canada :Norway :NewZeland];
labels = ["GDP G20" "ComPrice" "BAA spread" "GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"];
p = 2;
h = 40;
for i in 1:length(countries)
    model = countries[i]
    display("Global shocks: $model")
    codmodel = gos_creator(df,i,name, p, h);
    eval(codmodel);
end

# ===============================================
# [2] Reporting by country
# ===============================================
colist = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange  :red :purple :magenta :rosybrown4 :darkorchid4 :hotpink3 :palevioletred4 :cyan]
CouList = string.(name) .* ".png";

for x in 1:length(countries)
    country = name[x];
    ex= :(GSGraph($country,CouList[$x], labels, colg = colist[$x], varI=4));
    eval(ex);
end

# ===============================================
# [2] Creating groups of countries
# ===============================================
inp1 = (ExtraGSArg.irfgs, ExtraGSBra.irfgs, ExtraGSChl.irfgs, ExtraGSCol.irfgs, ExtraGSPer.irfgs, ExtraGSSoA.irfgs);
inp2 = (ExtraGSArg.fevgs, ExtraGSBra.fevgs, ExtraGSChl.fevgs, ExtraGSCol.fevgs, ExtraGSPer.fevgs, ExtraGSSoA.fevgs);
inp3 = (ExtraGSAus.irfgs, ExtraGSCan.irfgs, ExtraGSNrw.irfgs, ExtraGSNzl.irfgs);
inp4 = (ExtraGSAus.fevgs, ExtraGSCan.fevgs, ExtraGSNrw.fevgs, ExtraGSNzl.fevgs);
inp5 = (ExtraGSArg.irfnf, ExtraGSBra.irfnf, ExtraGSChl.irfnf, ExtraGSCol.irfnf, ExtraGSPer.irfnf, ExtraGSSoA.irfnf);
inp6 = (ExtraGSArg.fevnf, ExtraGSBra.fevnf, ExtraGSChl.fevnf, ExtraGSCol.fevnf, ExtraGSPer.fevnf, ExtraGSSoA.fevnf);
inp7 = (ExtraGSAus.irfnf, ExtraGSCan.irfnf, ExtraGSNrw.irfnf, ExtraGSNzl.irfnf);
inp8 = (ExtraGSAus.fevnf, ExtraGSCan.fevnf, ExtraGSNrw.fevnf, ExtraGSNzl.fevnf);
quint = [0.16 0.50 0.84];

ExtraGSArg = nothing; ExtraGSBra = nothing; ExtraGSChl = nothing; ExtraGSCol = nothing; ExtraGSPer = nothing;
ExtraGSSoA = nothing; ExtraGSAus = nothing; ExtraGSCan = nothing; ExtraGSNrw = nothing; ExtraGSNzl = nothing;

ecx = (IrfGS = GScat(inp1,quint), FevGS = GScat(inp2,quint), IrfNF = GScat(inp5,quint), FevNF = GScat(inp6,quint));
dcx = (IrfGS = GScat(inp3,quint), FevGS = GScat(inp4,quint), IrfNF = GScat(inp7,quint), FevNF = GScat(inp8,quint));

inp1 = nothing; inp2 = nothing; inp3 = nothing; inp4 = nothing;
inp5 = nothing; inp6 = nothing; inp7 = nothing; inp8 = nothing;

GSGraph(ecx, "ECX", labels, colg = :darkgoldenrod, subdir = "Groups", varI=4);
GSGraph(dcx, "DCX", labels, colg = :darkorchid4 , subdir = "Groups", varI=4);
GSGraph(ecx, "ECX", labels, colg = :darkgoldenrod, subdir = "World", varI=1, varF=3);
GSGraph(dcx, "DCX", labels, colg = :darkorchid4 , subdir = "World", varI=1, varF=3);

GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);
p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"]);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400),title =["Global Output" "Commodity Price" "BAA spread"]);
savefig(".//Figures//World//Comparison.png");


raw = cat(ecx.IrfGS.Qntls[2][4:end,:], ecx.IrfNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonIRFecx.png";
GraphAux(raw, myname);
raw = cat(dcx.IrfGS.Qntls[2][4:end,:], dcx.IrfNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonIRFdcx.png";
GraphAux(raw, myname);
raw = cat(ecx.FevGS.Qntls[2][4:end,:], ecx.FevNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonFEVecx.png";
GraphAux(raw, myname);
raw = cat(dcx.FevGS.Qntls[2][4:end,:], dcx.FevNF.Qntls[2][4:end,:], dims=3);
myname = ".//Figures//World//ComparisonFEVdcx.png";
GraphAux(raw, myname);

cp(".//Figures",".//docs//images//Figures",force=true);
display("Workout finished")
