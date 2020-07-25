
```julia
function part1(dataset, wvar)
	display(cor(wvar););
	#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	[1.3 Figure 2]
		In this part we are just interested in some graphics, then
		I will just consider a light version of each model
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
	p = 2;
	h = 40;
	nc = nfields(dataset)
	tt = size(dataset[1])[1] - p
	U = fill(NaN,tt,nc);
	j = 1
	for y in dataset
		_a1,U[:,j], _a2= GShock.GSstimation(y, p, h, VarGS = 2, NF = false, nmodls = 1000);
		j+=1
	end
	umean = mean(U, dims=2)
	UB = maximum(U, dims=2) - umean
	LB = umean - minimum(U, dims=2)
	umean = umean .- mean(umean);
	gd1 = wvar[end-tt+1:end,1]
	gd1 = gd1 .- mean(gd1);
	pp = plot(1:tt, umean, ribbon = (LB, UB),c = :teal, fillalpha=0.1, w = 1.5,
	    	fg_legend = :transparent, label = "News-augmented comm. shocks",
	    	title = "Figure 2: News-augmented commodity shocks vs G20 growth" ,
	    	titlefontsize = 10,xticks = (1:12:tt, qlabel[end+1-tt:12:end]),
	    	legendfontsize=7, legend=:bottomleft);
	plot!(1:tt,gd1, c=:red, w = 1.25, alpha = 0.85, label= "G20 output");
	savefig(".//Figures//intro2.svg");
	```
	```julia
	#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	[1.5 Correlations]
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
	display(cor([umean gd1]));
	comprice = Array{Float64,2}(undef,tt+p,nc)
	[comprice[:,i] = dataset[i][:,2] for i in 1:10]
	corvec_a = vec(cor(comprice));
	corvec   = corvec_a[corvec_a .<1]
	display(sum(corvec .> 0.9))
	pp= histogram(corvec, fillalpha = 0.4, legend = :false,
		xlabel = "Correlation", lc = :black);
	savefig(".//Figures//histogram.svg");
end
```
