################################################################################
#    GLOBAL SHOCKS: Data maker heterogeneous response in Small Open Economies
# Written by: Christian Velasquez
# Any comment, doubt or suggestion just send me an email to velasqcb@bc.edu
################################################################################
using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV, RCall;


# ------------------------------------------------------------------------------
# Quaterly labels
# ------------------------------------------------------------------------------
qlabel = Array{String,2}(undef, 164, 1)
for i = 1:164
    year = string(1980 + div(i - 1, 4))
    quaterly = "Q" * string(mod(i - 1, 4) + 1)
    qlabel[i] = year * quaterly
end

# ------------------------------------------------------------------------------
# 	DATA
# ------------------------------------------------------------------------------

#= ------------------------------------------------------------------------
	[1.1] GDP G20
	link:		https://data.oecd.org/gdp/quarterly-gdp.htm#indicator-chart
	We select volume index
 The quaterly data starts at `1998Q1`
 ------------------------------------------------------------------------ =#

g20 =
    DataFrame(CSV.File("./Data/DP_LIVE_14072020212217545.csv"));
g20 = g20[g20.LOCATION.=="G-20", :];
g20 = g20[:, [1, 6, 7]];

#= ------------------------------------------------------------------------
 	[1.2] BAA spread
	link: https://fred.stlouisfed.org/series/BAAFFM
	serie: Moody's Seasoned Baa Corporate Bond Minus Federal Funds Rate
	rename to FRED and save in xlsx format

 The quaterly data starts at `1980Q1`
 ------------------------------------------------------------------------ =#

y = DataFrame(CSV.File("./Data/BAAFFM.csv"));
Tmonth = size(y)[1];
baaq = zeros(Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        baaq[j] = mean(y[(j-1)*3+1:3*j, 2])
    end
end

#= ------------------------------------------------------------------------
	[1.3] Commodity Prices
		Link: https://www.imf.org/en/Research/commodity-prices
		Commodity Data Portal

 The quaterly data starts at `1992Q1`
 ------------------------------------------------------------------------ =#
y = XLSX.readdata(
    "./Data/ExternalData.xlsx",
    "Values!A149:CJ490",
);
y = y[:, 1:2]
Tmonth = size(y)[1];
commq = zeros(Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        commq[j] = mean(y[(j-1)*3+1:3*j, 2])
    end
end

# ------------------------------------------------------------------------
# Graphics for global variables
# ------------------------------------------------------------------------

Wvar = [log.([g20[1:84, 3] commq[25:108]]) baaq[73:156]];
wvar = Wvar[2:end, :] - Wvar[1:end-1, :];
wvar = [100 * wvar[:, 1:2] 0.5 * Wvar[2:end, 3]];
Wlabel = qlabel[73:156];

T = size(wvar)[1];
p = plot(
    wvar[:, [1, 3]],
    ylims = (-2, 5),
    fg_legend = :transparent,
    legendfontsize = 6,
    label = ["G20 output" "BAA spread"],
    legend = :bottomleft,
    xticks = (1:12:T, Wlabel[2:12:T+1]),
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
    ylims = (-50, 40),
    legend = false,
    xticks = :none,
    c = :red,
    w = 1.15,
    alpha = 0.75,
    ygridstyle = :dash,
);
plot!(NaN .* (1:T), c = :red, label = "Commodity prices");
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
    "./Data/Commodity_Terms_of_Trade_Commodity_.xlsx",
    "data!A2:AKF184",
)
y= [y[:, 1] y[:, 2:2:end]];
y[1, 1] = "Country";
list =
    ["Argentina" "Brazil" "Chile" "Colombia" "South Africa" "Peru" "Australia" "Canada" "New Zealand" "Norway"];
index = [findfirst(x -> x == i, y[:, 1]) for i in list];
y = dropdims(y[index, :], dims = 1);
y = y[:, 2:end];

# ------------------------------------------------------------------------
# Quarterly commodities
Tmonth = size(y)[2];
dataCq = zeros(10, Int(floor(Tmonth / 3)));
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        dataCq[:, j] = mean(y[:, (j-1)*3+1:3*j], dims = 2)
    end
end
dataCq     = log.(dataCq);
dataCqyty  = dataCq[:, 5:end] - dataCq[:, 1:end-4];
dataCqyty2 =
    (dataCqyty .- mean(dataCqyty, dims = 2)) ./ std(dataCqyty, dims = 2);

dataCqyty  = convert(Array, dataCqyty'); # Matrix form
dataCqyty2 = dataCqyty2';# Standarized variables

T  = size(dataCqyty)[1];
p1 = plot(layout = grid(3, 1), size = (1000, 1000))
plot!(
    dataCqyty[:, 1:3],
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
    dataCqyty[:, 4:6],
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
    dataCqyty[:, 7:10],
    c = [:black :red :teal :purple],
    markershape = [:none :circle :none :none],
    w = [1 1.5 1 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid :solid],
    xticks = (1:24:T, qlabel[5:24:T]),
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
    dataCqyty2[:, 1:3],
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
    dataCqyty2[:, 4:6],
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
    dataCqyty2[:, 7:10],
    c = [:black :red :teal :purple],
    markershape = [:none :circle :none :none],
    w = [1 1.5 1 1],
    markersize = 2.5,
    markercolor = :red,
    markerstrokewidth = 0.1,
    style = [:solid :dot :solid :solid],
    xticks = (1:24:T, qlabel[5:24:T]),
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
     "./Data/broad.xlsx",
     "Real!A4:BI322",
);
index = [findfirst(x -> x == i, y[1, :]) for i in list];
y  = dropdims(y[:,index], dims=2);
y  = y[3:end,:];
Tmonth = size(y)[1];
reerq  = zeros(Int(floor(Tmonth / 3)),10);
for i = 1:Tmonth
    if mod(i, 3) == 0
        j = div(i, 3)
        reerq[j,:] = mean(y[(j-1)*3+1:3*j,:], dims = 1)
    end
end

#= ------------------------------------------------------------------------
 	[-] NATIONAL ACCOUNTS
	[]  https://data.imf.org/regular.aspx?key=61545852
	[*] https://www.banrep.gov.co/es/catalogo-estadisticas-disponibles#pib1994
	Oferta y Demanda Finales en el Territorio Nacional / Precios constantes / Miles de millones de pesos / Trimestral / Información disponible desde 2005
	Oferta y demanda finales en el territorio nacional / Precios constantes / Miles de millones de pesos / Desestacionalizada trimestral / Información disponible desde 2000
	Oferta y demanda finales en el territorio nacional / A precios constantes / A millones de pesos / Trimestral / Información disponibles desde 1994 a 2007
	[**] https://estadisticas.bcrp.gob.pe/estadisticas/series/trimestrales/pbi-gasto

Mostly the structure of the matrices is
 [1] GDP      [2] Consumption  [3] Investment  [4] Exports
 [5] Imports  [6] Real GDP     [7] Deflactor

And we want
GDP         --> [6]
CONSUMPTION --> [2]/[1] * [6]
INVESTMENT  --> [3]/[1] * [6]
TRADE       --> ([4] - [5])/[1]
 ---------------------------------------------------------- =#
Dataextract(y) =  begin
	d1 = y[6,:];  # this is the real GDP
	d2 = (y[2,:] ./ y[1,:]) .* d1; # real consumption
	d3 = (y[3,:] ./ y[1,:]) .* d1; # real investment
	d4 = (y[4,:] .- y[5,:]) ./ y[1,:]; # % net exports
	return  convert(Matrix{Float64},[d1 d2 d3 100*d4]);
end

# ++++++++++++++++++++++++++++++++++++
# Argentina **
# ++++++++++++++++++++++++++++++++++++
y    = DataFrame(XLSX.readdata("./Data/GDP1.xlsx", "Quarterly!B8:DU31"));
aux1 = convert(Vector{Float64},y[12,5:end]);

	# -----------------------
	# Removing the seasonality
	# -----------------------
	@rput aux1
	R" library(seasonal)";
	R" aux2 = ts(aux1, frequency = 4, start = c(1990, 1))";
	R" plot(aux2)"
	R" m <- seas(aux2)";
	R" plot(m)";
	R" out1 = m$data";
	@rget out1;
	out1 = out1[:,3]; # This is the series without seasonal effects
seas = aux1./out1
y  = y[[3,4, 6, 8, 9, 12, 13],:]

# ++++++++++++++++++++++++++++++++++++
# Brazil
# ++++++++++++++++++++++++++++++++++++

y  = DataFrame(XLSX.readdata("./Data/GDP3.xlsx", "Quarterly!B8:DP30"));
y  = convert(Matrix,y[[14,15,17,19,20,23],25:end]);
ec2= Dataextract(y);


# ++++++++++++++++++++++++++++++++++++
# Chile
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP5.xlsx", "Quarterly!B8:DU30"));
y  = convert(Matrix,y[[14,15,17,19,20,23],29:end]);
ec3= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# Colombia ***
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP6.xlsx", "Quarterly!B8:DF28"));
y  = y[[],:]

# ++++++++++++++++++++++++++++++++++++
# Peru **
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP9.xlsx", "Quarterly!B8:DJ19"));
y  = convert(Matrix,y[[3,4,6,8,9,12],5:end]);
deflator = y[6,:]';
y  = y ./ deflator;
	# -----------------------
	# Removing the seasonality
	# -----------------------
	aux1 = y[1,:];
	@rput aux1
	R" library(seasonal)";
	R" aux2 = ts(aux1, frequency = 4, start = c(1990, 1))";
	R" plot(aux2)"
	R" m <- seas(aux2)";
	R" plot(m)";
	R" out1 = m$data";
	@rget out1;
	out1 = out1[:,3]; # This is the series without seasonal effects
	seas = aux1./out1
y[1:5,:] = y[1:5,:] ./ (seas');
ec5= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# South Africa
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP10.xlsx", "Quarterly!B8:DI32"));
y  = convert(Matrix,y[[15,16,18,20,21,25],5:end]);
ec6= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# Australia
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP2.xlsx", "Quarterly!B8:DU32"));
y  = convert(Matrix,y[[15,16,18,20,21,25],5:end]);
dc1= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# Canada
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP4.xlsx", "Quarterly!B8:DS29"));
y  = convert(Matrix,y[[12,13,15, 17, 18, 22],5:end]);
dc2= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# New Zealand
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP7.xlsx", "Quarterly!B8:DU32"));
y  = convert(Matrix,y[[15,16, 18,20,21,25],5:end]);
dc3= Dataextract(y);

# ++++++++++++++++++++++++++++++++++++
# Norway
# ++++++++++++++++++++++++++++++++++++
y  = DataFrame(XLSX.readdata("./Data/GDP8.xlsx", "Quarterly!B8:DV30"));
y  = convert(Matrix,y[[14,15,17,19,20,23],5:end]);
dc4= Dataextract(y);
