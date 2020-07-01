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
p = 2;
h = 40;
for i in 1:length(countries)
    display("****************************************");
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
    ex= :(GSGraph($country,CouList[$x], colg = colist[$x]));
    eval(ex);
end

# ===============================================
# [2] Creating groups of countries
# ===============================================
inp1 = (IRFGSArg, IRFGSBra,IRFGSChl ,IRFGSCol, IRFGSPer, IRFGSSoA);
inp2 = (FEVDGSArg, FEVDGSBra,FEVDGSChl ,FEVDGSCol, FEVDGSPer, FEVDGSSoA);
inp3 = (IRFGSAus, IRFGSCan, IRFGSNrw, IRFGSNzl);
inp4 = (FEVDGSAus, FEVDGSCan, FEVDGSNrw, FEVDGSNzl);
quint = [0.16 0.50 0.84];

ecx = (IRF = GScat(inp1,quint), FEVD= GScat(inp2,quint));
dcx = (IRF = GScat(inp3,quint), FEVD= GScat(inp4,quint));

(IRFGSArg, IRFGSBra,IRFGSChl ,IRFGSCol, IRFGSPer, IRFGSSoA) = (nothing ,nothing,nothing ,nothing,nothing ,nothing);
(FEVDGSArg, FEVDGSBra,FEVDGSChl ,FEVDGSCol, FEVDGSPer, FEVDGSSoA)= (nothing ,nothing,nothing ,nothing,nothing ,nothing);
(IRFGSAus, IRFGSCan, IRFGSNrw, IRFGSNzl) = (nothing ,nothing,nothing ,nothing);
(FEVDGSAus, FEVDGSCan, FEVDGSNrw, FEVDGSNzl) = (nothing ,nothing,nothing ,nothing);
(inp1, inp2 , inp3, inp4) = (nothing, nothing, nothing, nothing);

GSGraph(ecx, "ECX", colg= :darkgoldenrod, subdir = "Groups");
GSGraph(ecx, "DCX", colg = :darkorchid4 , subdir = "Groups");

# ===============================================
# [3] Non-fundamental commoditi price shock
# ===============================================
