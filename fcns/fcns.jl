# ===============================================
# [1] Concatenate matrices of diferent countries.
# ===============================================

function GSgroups(name,range,nv,h,nrep,cut)
	nc = length(range)
	aux1 = Array{Float32,3}(undef,nv,h,nrep*nc)
	aux2 = Array{Float32,3}(undef,nv,h,nrep*nc)
	aux3 = Array{Float32,3}(undef,nv,h,nrep*nc)
	aux4 = Array{Float32,3}(undef,nv,h,nrep*nc)
	for i in 1:nc
		nam = Symbol.(name.* string(i));
		ex =:(n1 = $nam[3].irfgs);	eval(ex);
		aux1[:,:,nrep*(i-1)+1:nrep*i] = n1;
		ex =:(n1 = $nam[3].fevgs); 	eval(ex);
		aux2[:,:,nrep*(i-1)+1:nrep*i] = n1;
		ex =:(n1 = $nam[3].irfnf); 	eval(ex);
		aux3[:,:,nrep*(i-1)+1:nrep*i] = n1;
		ex =:(n1 = $nam[3].fevnf);  eval(ex);
		aux4[:,:,nrep*(i-1)+1:nrep*i] = n1;
	end
	reddim(x) = dropdims(mean(x, dims = 3), dims = 3)
	Qntls  = GShock.Qntls
	crep = nrep*cut
	crep2 = nrep*(nc-cut)
	qq = [0.16 0.50 0.84]
	g1 = (aux1[:,:,1:crep],aux2[:,:,1:crep],aux3[:,:,1:crep],aux4[:,:,1:crep])
	g2 = (aux1[:,:,crep+1:end],aux2[:,:,crep+1:end],aux3[:,:,crep+1:end],aux4[:,:,crep+1:end])

	ecx = (
		IrfGS = (Mean = reddim(g1[1]), Qntls = Qntls(g1[1], crep, qq, nv, h) ),
		FevGS = (Mean = reddim(g1[2]), Qntls = Qntls(g1[2], crep, qq, nv, h) ),
		IrfNF = (Mean = reddim(g1[3]), Qntls = Qntls(g1[3], crep, qq, nv, h) ),
		FevNF = (Mean = reddim(g1[4]), Qntls = Qntls(g1[4], crep, qq, nv, h) ),
	)
	dcx = (
		IrfGS = (Mean = reddim(g2[1]), Qntls = Qntls(g2[1], crep2, qq, nv, h) ),
		FevGS = (Mean = reddim(g2[2]), Qntls = Qntls(g2[2], crep2, qq, nv, h) ),
		IrfNF = (Mean = reddim(g2[3]), Qntls = Qntls(g2[3], crep2, qq, nv, h) ),
		FevNF = (Mean = reddim(g2[4]), Qntls = Qntls(g2[4], crep2, qq, nv, h) ),
	)
	return ecx, dcx
end
# ===============================================
# [2] Function for graphs.
# ===============================================
function GSGraph(model,	name, labels; colg = :sienna, subdir = "Countries", varI=1, varF = 0)
    nf = nfields(model.FevGS.Qntls)
	if varF==0
		varF = size(model.FevGS.Mean)[1];
	end
    if ~isdir(".//Figures")
        mkdir("Figures");
    end
    if ~isdir(".//Figures//$subdir")
        mkdir(".//Figures//$subdir");
    end
    # ----------------------------------
    # FEVD GLOBAL shocks
	name1 = ".//Figures//$subdir//FEV_" * name;
	data  = model.FevGS;
	ModelGraph(data,nf,varI,varF,name1,labels,colg)
	# ----------------------------------
    # IRF GLOBAL SHOCKS
	name1 = ".//Figures//$subdir//IRF_" * name;
	data  = model.IrfGS;
	ModelGraph(data,nf,varI,varF,name1,labels,colg)
	# ----------------------------------
    # FEVD Non Fundamental shocks
	name1 = ".//Figures//$subdir//FEVNF_" * name;
	data  = model.FevNF;
	ModelGraph(data,nf,varI,varF,name1,labels,colg)
	# ----------------------------------
    # IRF Non Fundamental SHOCKS
	name1 = ".//Figures//$subdir//IRFNF_" * name;
	data  = model.IrfNF;
	ModelGraph(data,nf,varI,varF,name1,labels,colg)
end



function ModelGraph(data,nf,varI,varF,name,labels,colg)
	quint = cat(dims = 3, [data.Qntls[i] for i = 1:nf]...)
	quint = permutedims(quint, [2, 3, 1])
	h, n, nvar = size(quint)
	nrows = Int(ceil((varF-varI+1) / 3))
	if nrows==1
		plot(layout = (nrows, 3),size=(1200,400),title =["Global Output" "Commodity Price" "BAA spread"])
	else
		plot(layout = (nrows, 3))
	end
	j = 1;
	for i = varI:varF
		meanG = data.Mean[i, :]
		line  = quint[:, 2, i]
		LB 	  = line .- quint[:, 1, i]
		UB    = quint[:, 3, i] .- line
		plot!(1:h,
			line;
			ribbon = (LB, UB),
			tickfontsize = 6,
			subplot = j,
			c = [colg],
			xlabel=labels[i],
			w = 1.5,
			fillalpha = 0.2,
			legend = false,
		)
		scatter!(1:h,
			meanG,
			markersize = 1.25,
			c = [colg],
			markershape = :x,
			tickfontsize = 6,
			subplot = j,
		)
		j+=1;
	end
	savefig(name);
end

function GraphAux(raw)
	nvar = size(raw)[1];
	h    = size(raw)[2];
	p = plot(legendfontsize=10,layout=(2,3),size=(1200,800),title =["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"])
	for i in 1:nvar
	        data = raw[i,:,:];
	        if i!=2
	                plot!(1:h,data, label="",
	                        color= [:red :slateblue4], markersize = 3.5,
	                        markershape = [:none :x], w = [2 0.1],
	                        style = [:solid :dot],markerstrokewidth= 0.1,
	                        subplot = i, grid = :false,
	                );
	        else
	                plot!(1:h,data, label=["Global Shock" "Non-fundamental"],
	                        color= [:red :slateblue4], markersize = 3.5,
	                        markershape = [:none :x ], w = [2 0.1],
	                        style = [:solid :dot],markerstrokewidth= 0.1,
	                        subplot=i, fg_legend = :transparent,
							bg_legend = :transparent, grid = :false,
	                );
	        end
	end
	savefig(name);
end

function myplot(data,h,mylabel)
	p1 = plot(1:h,data,
        	label=mylabel, color= [:red :slateblue4 :red :slateblue4],
        	markersize = 2.5, markershape = [:none :none :x :x],
        	w = [2 2 0.1 0.1], style = [:solid :dash :dot :dot],
        	markerstrokewidth= 0.1, fg_legend = :transparent,
			bg_legend = :transparent,
        );
	return p1;
end
# ===============================================
# [3] HTML tables
# ===============================================

function ToHtml(file, matt, colnames)
	io = open(file, "w");
	println(io,"<table style=","""width:80%""",">");
	println(io,"<th> ", "h", " </th>")
	for x in colnames
		println(io,"<th> ",x, String(" </th>"))
	end
	T, cols = size(matt);
	for i in 1:T
		println(io,"<tr>")
		println(io,"<th> ", string(i-1), " </th>")
		for j in 1:cols
			println(io,"<th> ", string(matt[i,j]), " </th>")
		end
		println(io,"\n</tr>")
	end
	println(io,"</table>")
	close(io);
end
