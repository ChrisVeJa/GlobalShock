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

GSGraph(ecx, "ECX", labels, colg = :darkgoldenrod, subdir = "Groups");
GSGraph(dcx, "DCX", labels, colg = :darkorchid4 , subdir = "Groups");
