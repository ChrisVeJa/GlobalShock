####################################################################################
#           GLOBAL SHOCKS: Heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
####################################################################################

# ===========================================================================
# 							[0] Libraries
# ===========================================================================
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall;
include(".//fcns//GlobalShockDataLoader.jl");
include(".//fcns//GlobalShocks.jl");
include(".//fcns//fcns.jl");

# ===========================================================================
# 							[1] Introduction
# ===========================================================================
colist  = [:sienna4 :slateblue4 :teal :darkgoldenrod :blue :green :orange  :red :purple :magenta :rosybrown4 :darkorchid4 :hotpink3 :palevioletred4 :cyan]
dir1 = "G:/My Drive/GlobalShocks/data";

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.1] Loading Data
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
wvar, dataset, qlabel, list = GlobalShockDataLoader(dir1);

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.2 Correlations]
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
CoRR = cor(wvar);
display(CoRR);

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.3 Figure 2]
	In this part we are just interested in some graphics, then
	I will just consider a light version of each model
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
ncou = length(list);
nvar = div(size(dataset)[2],ncou);
nq = size(dataset)[1]
p = 2;
h = 40;
U = fill(NaN,nq,ncou);
for i in 1:ncou
    start = 1 + nvar*(i-1);
    y = dataset[:, start:nvar*i];
	model1, Uaux, _tup1 =
    GlobalShock.GSstimation(y, p, h, VarGS = 2, nonfun = false, nmodls = 1000);
    tt = length(Uaux);
    U[end+1-tt:end,i] = Uaux;
end
umean = [mean(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
umax = [maximum(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
umin = [minimum(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
UB = umax - umean ;
LB = umean - umin ;
umean = umean .- mean(umean);
taux = length(umean);
gd1 = wvar[end-taux+1:end,1]
gd1 = gd1 .- mean(gd1);
pp = plot(1:taux, umean, ribbon = (LB, UB),c = :teal, fillalpha=0.1, w = 1.5,
    	fg_legend = :transparent, label = "News-augmented comm. shocks",
    	title = "Figure 2: News-augmented commodity shocks vs G20 growth" ,
    	titlefontsize = 10,xticks = (1:12:taux, qlabel[end+1-taux:12:end]),
    	legendfontsize=7, legend=:bottomleft);
plot!(1:taux,gd1, c=:red, w = 1.25, alpha = 0.85, label= "G20 output");
savefig(".//Figures//intro2.svg");

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[1.5 Correlations]
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
CoRR2 = cor([umean gd1]);
display(CoRR2);
comprice = dataset[:,[2,11,20,29,38,47,56,65,74,83]];
corcom   = cor(comprice)
corvec   = Vector{Float64}(undef,div(ncou*(ncou+1),2)-ncou);
corvec[1] = corcom[2,1]
for i in 3:ncou
	lb = div(((i-1)*(i-2)),2)+1;
	ub = div((i*(i-1)),2);
	corvec[lb:ub] = corcom[i,1:i-1];
end
# ===========================================================================
# 							[2] GLOBAL SHOCKS
# ===========================================================================
name = Symbol.("mec" .* string.(1:10));
errs = Symbol.("uec" .* string.(1:10));
tups = Symbol.("tec" .* string.(1:10));

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.1] Estimation by country
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
for i in 1:ncou
	y = dataset[:,(i-1)*nvar+1:i*nvar];
	n1= name[i] ; n2 = errs[i] ; n3 = tups[i];
	ex =:(($n1, $n2, $n3) = GlobalShock.GSstimation($y, p, h, xblock = true, nx = 3));
	eval(ex);
end

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.2] Creating groups of countries
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
quint = [0.16 0.50 0.84];
in1 = (tec1.irfgs, tec2.irfgs, tec3.irfgs, tec4.irfgs, tec5.irfgs, tec6.irfgs);
in2 = (tec1.fevgs, tec2.fevgs, tec3.fevgs, tec4.fevgs, tec5.fevgs, tec6.fevgs);
in3 = (tec7.irfgs, tec8.irfgs, tec9.irfgs, tec10.irfgs);
in4 = (tec7.fevgs, tec8.fevgs, tec9.fevgs, tec10.fevgs);
in5 = (tec1.irfnf, tec2.irfnf, tec3.irfnf, tec4.irfnf, tec5.irfnf, tec6.irfnf);
in6 = (tec1.fevnf, tec2.fevnf, tec3.fevnf, tec4.fevnf, tec5.fevnf, tec6.fevnf);
in7 = (tec7.irfnf, tec8.irfnf, tec9.irfnf, tec10.irfnf);
in8 = (tec7.fevnf, tec8.fevnf, tec9.fevnf, tec10.fevnf);

ecx  = (IrfGS = GScat(in1,quint), FevGS = GScat(in2,quint),
		IrfNF = GScat(in5,quint), FevNF = GScat(in6,quint));
dcx  = (IrfGS = GScat(in3,quint), FevGS = GScat(in4,quint),
 		IrfNF = GScat(in7,quint), FevNF = GScat(in8,quint));

in1, in2, in3, in4, in5, in6, in7, in8 = (0,0,0,0,0,0,0,0);
tec1, tec2, tec3, tec4, tec5, tec6, tec, tec8 = (0,0,0,0,0,0,0,0);

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[2.3] Reporting by group of country both GS and NF shocks
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
labels =
["GDP G20" "ComPrice" "BAA spread" "GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"];

GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod,
	subdir = "Groups", varI=4);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 ,
	subdir = "Groups", varI=4);
ToHtml("table1.html",round.(ecx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);
ToHtml("table2.html",round.(dcx.FevGS.Qntls[2][4:end,:]', digits=2),
        ["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"]);


# ===========================================================================
# 					[3] RESULTS BY COUNTRY
# ===========================================================================
countries =
    [:Argentina :Brazil :Chile :Colombia :Peru :SouthAfrica :Australia :Canada :NewZealand :Norway];
CouList = string.(name) .* ".svg";
for x in 1:length(countries)
    country = name[x];
    ex= :(GSGraph($country,CouList[$x], labels, colg = colist[$x], varI=4));
    eval(ex);
end

# ===========================================================================
# 					[4] COMPARISON OF SHOCKS
# ===========================================================================

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[4.1] Impact in macro variables
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#

GSGraph(ecx, "ECX.svg", labels, colg = :darkgoldenrod,
		subdir = "World", varI=1, varF=3,
);
GSGraph(dcx, "DCX.svg", labels, colg = :darkorchid4 ,
 		subdir = "World", varI=1, varF=3,
);

#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
[4.2] Comparison
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#

GStoWorld = cat(ecx.FevGS.Qntls[2][1:3,:],dcx.FevGS.Qntls[2][1:3,:], dims=3);
NFtoWorld = cat(ecx.FevNF.Qntls[2][1:3,:],dcx.FevNF.Qntls[2][1:3,:], dims=3);

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.1] Effects in global variables
+++++++++++++++++++++++++++++++++++++++++++++ =#

p1 = myplot([GStoWorld[1,:,:]  NFtoWorld[1,:,:]],h,"");
p2 = myplot([GStoWorld[2,:,:]  NFtoWorld[2,:,:]],h,
	 ["Global Shock ECX" "Global Shock DCX" "Non-fun ECX" "Non-fun DCX"]);
p3 = myplot([GStoWorld[3,:,:]  NFtoWorld[3,:,:]],h,"");
plot(p1,p2,p3, layout=(1,3),size=(1200,400),
	title = ["Global Output" "Commodity Price" "BAA spread"]);
savefig(".//Figures//World//Comparison.svg");

#= ++++++++++++++++++++++++++++++++++++++++++
[4.2.2] Effects in domestic variables
+++++++++++++++++++++++++++++++++++++++++++++ =#

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
