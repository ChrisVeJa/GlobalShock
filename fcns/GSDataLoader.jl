################################################################################
# GLOBAL SHOCKS: Data maker
# I will cut every dataset at 2018Q4
# Written by: Christian Velasquez
# velasqcb@bc.edu
################################################################################
function GSDataLoader(dir1)

if ~isdir(".//Figures")   mkdir("Figures") end
# ------------------------------------------------------------------------------
# Quaterly labels
# ------------------------------------------------------------------------------
qlabel = Array{String,2}(undef, 84, 1)
for i = 1:84
    year = string(1998 + div(i - 1, 4))
    quaterly = "Q" * string(mod(i - 1, 4) + 1)
    qlabel[i] = year * quaterly
end

#= ------------------------------------------------------------------------
	[1.1] GDP G20
	link:		https://data.oecd.org/gdp/quarterly-gdp.htm#indicator-chart
	We select volume index
 The quaterly data starts at `1998Q1`
 ------------------------------------------------------------------------ =#
g20 = DataFrame(CSV.File("$dir1/DP_LIVE_14072020212217545.csv"));
g20 = g20[g20.LOCATION.=="G-20", :];
g20 = g20[1:end-4, [1, 6, 7]];
g20 = log.(g20[:,3])
#= ------------------------------------------------------------------------
 	[1.2] BAA spread
	link: https://fred.stlouisfed.org/series/BAAFFM
	serie: Moody's Seasoned Baa Corporate Bond Minus Federal Funds Rate
	rename to FRED and save in xlsx format
 The quaterly data starts at `1998Q1`
 ------------------------------------------------------------------------ =#
y = DataFrame(CSV.File("$dir1/BAAFFM.csv"));
y = y[217:end-18,:];
Tmonth = size(y)[1];
baaq = zeros(Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        baaq[j] = mean(y[(j-1)*3+1:3*j, 2]);
    end
end

#= ------------------------------------------------------------------------
 [1.3]Import Price Index:Industrialized Countries- Manufactured articles
 link: https://fred.stlouisfed.org/series/INDUSMANU
 The monthly data starts at `1990M12`
 The quaterly starts at 1994Q1
 ------------------------------------------------------------------------ =#
y = DataFrame(CSV.File("$dir1/INDUSMANU.csv"));
y = y[86:end-18,:];
y = parse.(Float64,convert(Vector,y[:,2]));
Tmonth = size(y)[1];
indusq = zeros(Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        indusq[j] = mean(y[(j-1)*3+1:3*j])/100
    end
end

#= ------------------------------------------------------------------------
	[1.4] Commodity Prices
		Link: https://www.imf.org/en/Research/commodity-prices
		Commodity Data Portal
 ------------------------------------------------------------------------ =#
y = XLSX.readdata("$dir1/ExternalData.xlsx","Values!A149:CJ490");
y = y[73:end-18, 1:2];
Tmonth = size(y)[1];
commq = zeros(Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        commq[j] = mean(y[(j-1)*3+1:3*j, 2])
    end
end
commq = commq ./ indusq; # Real price of COMMODITIES
commq = log.(commq);

# ------------------------------------------------------------------------
# Graphics for global variables
# ------------------------------------------------------------------------

Wvar = [g20 commq baaq];
wvar = Wvar[2:end, :] - Wvar[1:end-1, :];
wvar = [100 * wvar[:, 1:2] 0.5 * Wvar[2:end, 3]];
Wlabel = qlabel[2:end];

T = size(wvar)[1];
p = plot(
    wvar[:, [1, 3]],
    ylims = (-2, 5),
    fg_legend = :transparent,
    legendfontsize = 6,
    label = ["G20 output" "BAA spread"],
    legend = :bottomleft,
    xticks = (1:12:T, Wlabel[1:12:T]),
    w = [1 2.5],
    style = [:dash :dot],
    c = [:black :gray],
    title = "Figure 1: Evolution of macro variables",
    titlefontsize = 10,
    ygrid = :none,
)
p = twinx();
plot!(
    p,
    wvar[:, 2],
    ylims = (-45, 40),
    legend = false,
    xticks = :none,
    c = :red,
    w = 1.15,
    alpha = 0.75,
    ygridstyle = :dash,
);
plot!(NaN .* (1:T), c = :red, label = "Real commodity prices");
savefig(".//Figures//intro1.svg");

#= ------------------------------------------------------------------------
 	 [-] COMMODITIES PRICES BY COUNTRY
			Link: https://www.imf.org/en/Research/commodity-prices
			To obtain the price of differents commodities we can choose
				COMMODITY DATA PORTAL
				For Commoditi price index by country we choose
				Commodity terms of trade
				selected: Commodity Export Price Index, Individual Commodites
				Weighted by Ratio of Exports to Total Commodity Exports
				Recent, Monthly (1980 - present), Fixed Weights,
				Index (June 2012 = 100)"
 ------------------------------------------------------------------------ =#

y = XLSX.readdata(
    "$dir1/Commodity_Terms_of_Trade_Commodity_.xlsx",
    "data!A2:AKF184",
)
y= [y[:, 1] y[:, 2:2:end]];
y[1, 1] = "Country";
y= [y[:,1] y[:,218:469]];

list =
    ["Argentina" "Brazil" "Chile" "Colombia" "South Africa" "Peru" "Australia" "Canada" "New Zealand" "Norway"];
index = [findfirst(x -> x == i, y[:, 1]) for i in list];
y = dropdims(y[index, :], dims = 1);
y = y[:, 2:end];

# ------------------------------------------------------------------------
# Quarterly commodities
Tmonth = size(y)[2];
tot   = zeros(10, Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        tot[:, j] = mean(y[:, (j-1)*3+1:3*j], dims = 2)
    end
end
tot   = tot' ./ indusq;
tot   = log.(tot);
dtot  = tot[5:end,:] - tot[1:end-4,:];
dtot2 = (dtot .- mean(dtot, dims = 1)) ./ std(dtot, dims = 1);
T  = size(dtot)[1];
p1 = plot(layout = grid(3, 1), size = (1000, 1000))
plot!(
    dtot[:, 1:3],
    c = [:black :red :teal],
    markershape = [:none :circle :none],
    w = [1 1.5 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid],
    xaxis = false,
    grid = false,
    label = [list[1] list[2] list[3]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 1,
    tickfontsize = 10,
);
plot!(
    dtot[:, 4:6],
    c = [:black :red :teal],
    markershape = [:none :circle :none],
    w = [1 1.5 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid],
    xaxis = false,
    grid = false,
    label = [list[4] list[5] list[6]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 2,
    tickfontsize = 10,
);
plot!(
    dtot[:, 7:10],
    c = [:black :red :teal :purple],
    markershape = [:none :circle :none :none],
    w = [1 1.5 1 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid :solid],
    xticks = (1:24:T, qlabel[5:24:T+4]),
    grid = false,
    label = [list[7] list[8] list[9] list[10]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 3,
    tickfontsize = 10,
);
plot(p1);
savefig(".//Figures//comm1.svg");

p2 = plot(layout = grid(3, 1), size = (1000, 1000))
plot!(
    dtot2[:, 1:3],
    c = [:black :red :teal],
    markershape = [:none :circle :none],
    w = [1 1.5 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid],
    xaxis = false,
    grid = false,
    label = [list[1] list[2] list[3]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 1,
    tickfontsize = 10,
);
plot!(
    dtot2[:, 4:6],
    c = [:black :red :teal],
    markershape = [:none :circle :none],
    w = [1 1.5 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid],
    xaxis = false,
    grid = false,
    label = [list[4] list[5] list[6]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 2,
    tickfontsize = 10,
);
plot!(
    dtot2[:, 7:10],
    c = [:black :red :teal :purple],
    markershape = [:none :circle :none :none],
    w = [1 1.5 1 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid :solid],
    xticks = (1:24:T, qlabel[5:24:T+4]),
    grid = false,
    label = [list[7] list[8] list[9] list[10]],
    legendfontsize = 9,
    legend = :topleft,
    fg_legend = :transparent,
    bg_legend = :transparent,
    subplot = 3,
    tickfontsize = 10,
);
plot(p2);
savefig(".//Figures//comm2.svg");

#= ------------------------------------------------------------------------
 	 [-] REAL EFFECTIVE EXCHANGE RATE
	 	link:https://www.bis.org/statistics/eer.htm?m=6%7C381%7C676
		narrow indices
		The indices starts at 1994-1
 ------------------------------------------------------------------------ =#
y  = XLSX.readdata(
     "$dir1/broad.xlsx",
     "Real!A4:BI322",
);
y = y[1:302,:];
index = [findfirst(x -> x == i, y[1, :]) for i in list];
y  = dropdims(y[:,index], dims=2);
y  = y[51:end,:];
Tmonth = size(y)[1];
reer  = zeros(Int(floor(Tmonth / 3)),10);
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        reer[j,:] = mean(y[(j-1)*3+1:3*j,:], dims = 1)
    end
end
reer = log.(reer);
#= ------------------------------------------------------------------------
 	[-] NATIONAL ACCOUNTS
	[]  https://data.imf.org/regular.aspx?key=61545852
	[*] https://www.banrep.gov.co/es/catalogo-estadisticas-disponibles#pib1994
	Oferta y Demanda Finales en el Territorio Nacional /
		Precios constantes / Miles de millones de pesos /
		Trimestral / Información disponible desde 2005
	Oferta y demanda finales en el territorio nacional /
		Precios constantes / Miles de millones de pesos /
		Desestacionalizada trimestral / Información disponible desde 2000
	Oferta y demanda finales en el territorio nacional /
		A precios constantes / A millones de pesos /
		Trimestral / Información disponibles desde 1994 a 2007
	[**] Adjusted by seasonality using XArima13 in R

Mostly the structure of the matrices is
 [1] GDP      [2] Consumption  [3] Investment  [4] Exports
 [5] Imports  [6] Real GDP

And we want
GDP         --> [6]
CONSUMPTION --> [2]/[1] * [6]
INVESTMENT  --> [3]/[1] * [6]
TRADE       --> ([4] - [5])/[1]
 -------------------------------------------------------------------------- =#
Dataextract(y) =  begin
	# It puts in real terms everything
	d1 = y[6,:];                   # this is the real GDP
	d2 = (y[2,:] ./ y[1,:]) .* d1; # real consumption
	d3 = (y[3,:] ./ y[1,:]) .* d1; # real investment
	d4 = (y[4,:] .- y[5,:]) ./ y[1,:]; # % net exports
	return  convert(Matrix{Float64},[d1 d2 d3 100*d4]);
end

YBase(y,start) = begin
	# It put the serie y in a year base
	return log.(100* (y ./ mean(y[start:start+3])))
end


#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	Argentina
	Not seasonal adjusted
	Start: 1993Q1
	Base : 2000
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
basey = 2000;
y    = DataFrame(XLSX.readdata("$dir1/GDP1.xlsx", "Quarterly!B8:DU31"));
aux1 = convert(Vector{Float64},y[12,17:end]);
	# -----------------------
	# Removing the seasonality
	# -----------------------
	@rput aux1
	R" library(seasonal)";
	R" aux2 = ts(aux1, frequency = 4, start = c(1993, 1))";
	#R" plot(aux2)"
	R" m <- seas(aux2)";
	#R" plot(m)";
	R" out1 = m$data";
	@rget out1;
	out1 = out1[:,3]; # This is the series without seasonal effects

y  = convert(Matrix,y[[3,4, 6, 8, 9,12],17:end]);
ec1= Dataextract(y);
seas = y[6,:] ./ out1
ec1  = ec1 ./ seas;

stq = (basey-1993)*4+1;
ec1 = [YBase(ec1[:,1],stq) YBase(ec1[:,2],stq) YBase(ec1[:,3],stq) ec1[:,4]];
ec1 = ec1[21:104,:];
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Brazil
# Start at 1996Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

y  = DataFrame(XLSX.readdata("$dir1/GDP3.xlsx", "Quarterly!B8:DP30"));
y  = convert(Matrix,y[[14,15,17,19,20,22],25:end]);
ec2= Dataextract(y);
stq = (basey-1996)*4+1;
ec2 = [YBase(ec2[:,1],stq) YBase(ec2[:,2],stq) YBase(ec2[:,3],stq) ec2[:,4]];
ec2 = ec2[9:92,:];

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Chile
# Start at 1996Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP5.xlsx", "Quarterly!B8:DU30"));
y  = convert(Matrix,y[[14,15,17,19,20,22],29:end]);
ec3= Dataextract(y);
stq= (basey-1996)*4+1;
ec3= [YBase(ec3[:,1],stq) YBase(ec3[:,2],stq) YBase(ec3[:,3],stq) ec3[:,4]];
ec3 = ec3[9:92,:];
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 Colombia
 * It is already adjusted by
 seasonallity, but I need to chain
 the data to have a sample from 1994
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
y  = DataFrame(XLSX.readdata("$dir1/ColGDP.xlsx", "data!A3:CW8"));
y  = convert(Matrix,y[2:end, 2:end]);
y  = y';
stq= (basey-1994)*4+1;
ec4= [YBase(y[:,1],stq) YBase(y[:,2],stq) YBase(y[:,3],stq) y[:,4]];
ec4= ec4[17:100,:];
#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Peru
 ** It was adjusted with XArima13
 Starts at 1998Q1 all variable are real but not seassonaly adjusted
 https://estadisticas.bcrp.gob.pe/estadisticas/series/trimestrales/pbi-gasto
 Series:
	PN02529AQ 	Demanda Interna - Consumo Privado
	PN02533AQ  	Demanda Interna - Inversión Bruta Interna -
				Inversión Bruta Fija - Privada
	PN02536AQ	Exportaciones
	PN02537AQ	Importaciones
	PN02538AQ	PBI
+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
y  = DataFrame(XLSX.readdata("$dir1/Trimestral.xlsx", "Trimestrales!A2:F86"));

 # -----------------------
 # Removing the seasonality
 # -----------------------
	aux1 = convert(Vector{Float64},y[2:end,6]);
	@rput aux1
	R" library(seasonal)";
	R" aux2 = ts(aux1, frequency = 4, start = c(1998, 1))";
	#R" plot(aux2)"
	R" m <- seas(aux2)";
	#R" plot(m)";
	R" out1 = m$data";
	@rget out1;
	out1 = out1[:,3]; # This is the series without seasonal effects
	seas = aux1./out1
y  = convert(Matrix{Float64},y[2:end,2:end] ./ (seas));
trade = 100*((y[:,3] - y[:,4])./ y[:,5])
stq= (basey-1998)*4+1;
ec5= [YBase(y[:,5],stq) YBase(y[:,1],stq) YBase(y[:,2],stq) trade];

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# South Africa
# Starts at 1990Q1
# Additionally: http://www.statssa.gov.za/?page_id=1854&PPN=P0441&SCH=7746
#		GDP P0441- 2020Q1 (7,83 MB)
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP10.xlsx", "Quarterly!B8:DQ31"));
y  = convert(Matrix,y[[15,16,18,20,21,24],5:end]);
ec6= Dataextract(y);
stq= (basey-1990)*4+1;
ec6= [YBase(ec6[:,1],stq) YBase(ec6[:,2],stq) YBase(ec6[:,3],stq) ec6[:,4]];
ec6 = ec6[33:116,:]

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Australia
# Starts at 1990Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP2.xlsx", "Quarterly!B8:DU32"));
y  = convert(Matrix,y[[15,16,18,20,21,24],5:end]);
dc1= Dataextract(y);
stq= (basey-1990)*4+1;
dc1= [YBase(dc1[:,1],stq) YBase(dc1[:,2],stq) YBase(dc1[:,3],stq) dc1[:,4]];
dc1 = dc1[33:116,:];
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Canada
# Starts at 1990Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP4.xlsx", "Quarterly!B8:DS29"));
y  = convert(Matrix,y[[12,13,15, 17, 18, 21],5:end]);
dc2= Dataextract(y);
stq= (basey-1990)*4+1;
dc2= [YBase(dc2[:,1],stq) YBase(dc2[:,2],stq) YBase(dc2[:,3],stq) dc2[:,4]];
dc2 = dc2[33:116,:];
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# New Zealand
# Starts at 1990Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP7.xlsx", "Quarterly!B8:DU32"));
y  = convert(Matrix,y[[15,16, 18,20,21,24],5:end]);
dc3= Dataextract(y);
stq= (basey-1990)*4+1;
dc3= [YBase(dc3[:,1],stq) YBase(dc3[:,2],stq) YBase(dc3[:,3],stq) dc3[:,4]];
dc3 = dc3[33:116,:];
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# Norway
# Starts at 1990Q1
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("$dir1/GDP8.xlsx", "Quarterly!B8:DV30"));
y  = convert(Matrix,y[[14,15,17,19,20,22],5:end]);
dc4= Dataextract(y);
stq= (basey-1990)*4+1;
dc4= [YBase(dc4[:,1],stq) YBase(dc4[:,2],stq) YBase(dc4[:,3],stq) dc4[:,4]];
dc4 = dc4[33:116,:];

#= ------------------------------------------------------------------------
 	[-] INTEREST RATES
https://www.bis.org/statistics/cbpol.htm?m=6%7C382%7C679
https://estadisticas.bcrp.gob.pe/estadisticas/series/mensuales/tasas-de-interes
 -------------------------------------------------------------------------- =#
irate = XLSX.readdata("$dir1/cbpol_2007.xlsx", "Monthly!A3:K321");
y2    = XLSX.readdata("$dir1/intratePer.xlsx", "Mensuales!A2:B296");
yy = [irate[26:end,10] y2[2:end,2]];
dplot = convert(Matrix{Float64},yy[94:end,:]);
plot(dplot)
# Then the overnight interbak lending rate is a good proxy of mp
irate[26:end,10] = y2[2:end,2];
# Now, putting in the correct order
index = [findfirst(x -> x == i, irate[1,:]) for i in list];
irate = dropdims(irate[50:end-18,index], dims=2);
Tmonth = size(irate)[1];
irateq = zeros(Int(floor(Tmonth / 3)),10);
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        irateq[j,:] = mean(irate[(j-1)*3+1:3*j,:], dims = 1)
    end
end

Δipc = XLSX.readdata("$dir1/inflation.xlsx", "data!A1:K301");
index = [findfirst(x -> x == i, Δipc[1,:]) for i in list];
Δipc = dropdims(Δipc[2:end,index], dims=2);
Tmonth = size(Δipc)[1];
Δipcq = zeros(Int(floor(Tmonth / 3)),10);
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        Δipcq[j,:] = Δipc[i,:]
    end
end
Δipcq = Δipcq[17:end,:]
display(Δipcq)
rrateq = irateq - Δipcq
#= ------------------------------------------------------------------------
	CREATING THE DATASET
The order of the variables are:
g20 >> comm >> baa >> gdp >> cons >> inv >> trade >> reer >> irate
-------------------------------------------------------------------------- =#
mec1 = convert(Array{Float64},[g20 tot[:,1] baaq ec1 reer[:,1] rrateq[:,1]]);
mec2 = convert(Array{Float64},[g20 tot[:,2] baaq ec2 reer[:,2] rrateq[:,2]]);
mec3 = convert(Array{Float64},[g20 tot[:,3] baaq ec3 reer[:,3] rrateq[:,3]]);
mec4 = convert(Array{Float64},[g20 tot[:,4] baaq ec4 reer[:,4] rrateq[:,4]]);
mec5 = convert(Array{Float64},[g20 tot[:,5] baaq ec5 reer[:,5] rrateq[:,5]]);
mec6 = convert(Array{Float64},[g20 tot[:,6] baaq ec6 reer[:,6] rrateq[:,6]]);
mec7 = convert(Array{Float64},[g20 tot[:,7] baaq dc1 reer[:,7] rrateq[:,7]]);
mec8 = convert(Array{Float64},[g20 tot[:,8] baaq dc2 reer[:,8] rrateq[:,8]]);
mec9 = convert(Array{Float64},[g20 tot[:,9] baaq dc3 reer[:,9] rrateq[:,9]]);
mec10 = convert(Array{Float64},[g20 tot[:,10] baaq dc4 reer[:,10] rrateq[:,10]]);
dataset = (mec1, mec2, mec3, mec4, mec5, mec6, mec7, mec8, mec9, mec10)
return wvar,dataset, qlabel,list;
end
