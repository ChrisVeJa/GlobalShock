using Random, DataFrames, XLSX, LinearAlgebra, Statistics,
	StatsBase, Distributions, Plots, CSV;



qlabel = Array{String,2}(undef,164,1)
for i = 1:164
	year = string(1980+div(i-1,4))
	quaterly = "Q" * string(mod(i-1,4)+1)
	qlabel[i] = year * quaterly;
end


# GDP G20
#  link:		https://data.oecd.org/gdp/quarterly-gdp.htm#indicator-chart
# We select volume index
g20 = DataFrame(CSV.File("C:/Users/chris/Downloads/DP_LIVE_14072020212217545.csv"));
g20 = g20[g20.LOCATION .== "G-20",:];
g20 = g20[:,[1,6,7]];

# BAA spread
#  link: https://fred.stlouisfed.org/series/BAAFFM
#  serie: Moody's Seasoned Baa Corporate Bond Minus Federal Funds Rate
#  rename to FRED and save in xlsx format
baa = DataFrame(CSV.File("C:/Users/chris/Downloads/BAAFFM.csv"));
Tmonth = size(baa)[1];
baaq = zeros(Int(floor(Tmonth/3)));
for i in 1:Tmonth
	if mod(i,3)==0
		j = div(i,3);
		baaq[j] = mean(baa[(j-1)*3+1:3*j,2]);
	end
end
# [1.] COMMODITIES PRICES E INDEXES
 #=
 Link: https://www.imf.org/en/Research/commodity-prices
 To obtain the price of differents commodities we can choose
 		COMMODITY DATA PORTAL
 For Commoditi price index by country we choose
 		Commodity terms of trade
		selected: Commodity Export Price Index, Individual Commodites Weighted
					by Ratio of Exports to Total Commodity Exports
 					Recent, Monthly (1980 - present), Fixed Weights,
					Index (June 2012 = 100)"
 =#




m = XLSX.readdata("C:/Users/chris/Downloads/Commodity_Terms_of_Trade_Commodity_.xlsx", "data!A2:AKF184")
dataC = [m[:,1] m[:,2:2:end]]
dataC[1,1] = "Country";
list  = ["Argentina" "Brazil" "Chile" "Colombia" "South Africa" "Peru" "Australia" "Canada" "New Zealand" "Norway"]
index = [ findfirst(x -> x == i, dataC[:,1])  for i in list];
dataC = dropdims(dataC[index,:], dims=1);
dataC = dataC[:,2:end]
# Quaterly
Tmonth = size(dataC)[2];
dataCq = zeros(10,Int(floor(Tmonth/3)));
for i in 1:Tmonth
	if mod(i,3)==0
		j = div(i,3);
		dataCq[:,j] = mean(dataC[:,(j-1)*3+1:3*j],dims=2);
	end
end
dataCq =  log.(dataCq);

dataCqyty  = dataCq[:,5:end] - dataCq[:,1:end-4];
dataCqyty2 = (dataCqyty .- mean(dataCqyty,dims=2)) ./ std(dataCqyty, dims=2);
dataCqyty  = convert(Array,dataCqyty');
dataCqyty2 = dataCqyty2';
T = size(dataCqyty)[1];
p1 = plot(layout=grid(3,2,widths =(0.57,0.43) ), size=(1200,600))
plot!(dataCqyty[:,1:3], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis=false,grid= false,
	label= [list[1] list[2] list[3]],legendfontsize=6, legend=:outertopleft,
	fg_legend = :transparent, subplot=1);
plot!(dataCqyty2[:,1:3], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis = false, grid =false,	label= "", subplot=2);
plot!(dataCqyty[:,4:6], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis=false, grid = false,
	label= [list[4] list[5] list[6]],legendfontsize=5, legend=:outertopleft,
	fg_legend = :transparent, subplot=3);
plot!(dataCqyty2[:,4:6], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis=false, grid= false,label= "", subplot=4);
plot!(dataCqyty[:,7:10], c= [:black :red :teal :purple], markershape=[:none :circle :none :none],
	w= [1 1.5 1 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid :solid], xticks = (1:24:T, qlabel[5:24:T]),grid= false,
	label= [list[7] list[8] list[9] list[10]],legendfontsize=5, legend=:outertopleft,
	fg_legend = :transparent, subplot=5);
plot!(dataCqyty2[:,7:10], c= [:black :red :teal :purple], markershape=[:none :circle :none :none],
	w= [1 1.5 1 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid :solid], xticks = (1:24:T, qlabel[5:24:T]), grid= false,
	label= "", subplot=6);

plot(p1)
savefig("comm1.svg")


p2 = plot(layout=grid(3,1), size=(1000,1000))
plot!(dataCqyty2[:,1:3], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis=false,grid= false,
	label= [list[1] list[2] list[3]],legendfontsize=6, legend=:topleft,
	fg_legend = :transparent, subplot=1);
plot!(dataCqyty2[:,4:6], c= [:black :red :teal], markershape=[:none :circle :none],
	w= [1 1.5 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid], xaxis=false, grid = false,
	label= [list[4] list[5] list[6]],legendfontsize=8, legend=:topleft,
	fg_legend = :transparent, subplot=2);
plot!(dataCqyty2[:,7:10], c= [:black :red :teal :purple], markershape=[:none :circle :none :none],
	w= [1 1.5 1 1],markersize = 2.5, markercolor = :red , markerstrokewidth= 0.1,
	style=[:solid :dot :solid :solid], xticks = (1:24:T, qlabel[5:24:T]),grid= false,
	label= [list[7] list[8] list[9] list[10]],legendfontsize=6, legend=:topleft,
	fg_legend = :transparent, subplot=3);
plot(p2)
savefig("comm2.svg")
