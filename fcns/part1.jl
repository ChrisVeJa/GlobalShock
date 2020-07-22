function part1()
	display(cor(wvar););
	#= +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	[1.3 Figure 2]
		In this part we are just interested in some graphics, then
		I will just consider a light version of each model
	+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ =#
	nc = length(list);
	nv = div(size(dataset)[2],nc);
	nq = size(dataset)[1]
	p = 2;
	h = 40;
	U = fill(NaN,nq,nc);
	for i in 1:nc
	    start = 1 + nv*(i-1);
	    y = dataset[:, start:nv*i];
		model1, Uaux, _tup1 =
	    GlobalShock.GSstimation(y, p, h, VarGS = 2, NF = false, nmodls = 1000);
	    tt = length(Uaux);
	    U[end+1-tt:end,i] = Uaux;
	end
	umean = [mean(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
	umax  = [maximum(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
	umin  = [minimum(U[i,:][.!isnan.(U[i,:])]) for i in 4:nq];
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
	display(cor([umean gd1]));
	comprice = dataset[:,[2,11,20,29,38,47,56,65,74,83]];
	corcom   = cor(comprice)
	corvec   = Vector{Float64}(undef,div(nc*(nc+1),2)-nc);
	corvec[1] = corcom[2,1]
	for i in 3:nc
		lb = div(((i-1)*(i-2)),2)+1;
		ub = div((i*(i-1)),2);
		corvec[lb:ub] = corcom[i,1:i-1];
	end
end
