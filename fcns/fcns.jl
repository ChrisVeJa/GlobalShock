# ===============================================
# [1] Function that creates code lines.
# ===============================================
function gos_creator(df, col::Int64, name, p, h)
    start = 2 + (col - 1) * 9
    y = :(convert(
        Array{Float64},
        df[:, $start:$start+8][completecases(df[:, $start:$start+8]), :],
    ))
    tupname = Symbol.("Extra" .* string.(name));
    lines    = name[col];
    tuplines = tupname[col];
    ex =:(($lines, UU, $tuplines) = GlobalShock.GSstimation($y, p, h, xblock = true, nx = 3))
    return ex
end
# ===============================================
# [2] Concatenate matrices of diferent countries.
# ===============================================
function GScat(input,quint)
	nf  = nfields(input);
	aux = input[1];
	for i in 2:nf
		aux = cat(aux,input[i],dims=3);
	end
	m,h,nmodls = size(aux);
	auxM = dropdims(mean(aux, dims = 3), dims = 3);
	auxQ = GlobalShock.Qntls(aux, nmodls, quint, m, h);
	out = (Mean = auxM, Qntls = auxQ);
	return out;
end
# ===============================================
# [3] Function for graphs.
# ===============================================
function GSGraph(model,
	name,
	labels;
	colg = :sienna,
	subdir = "Countries",
	varI=1,
	varF = 0,
)
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

function GraphAux(raw, name)
	nvar = size(raw)[1];
	h    = size(raw)[2];
	plot(legendfontsize=6,layout=(2,3),size=(1200,800),title =["GDP" "Consumption" "Investment" "Trade" "REER" "Monetary Policy"])
	for i in 1:nvar
	        data = raw[i,:,:];
	        if i!=2
	                plot!(1:h,data, label="",
	                        color= [:teal :darkgoldenrod], markersize = 3.5,
	                        markershape = [:none :circ], w = [2 0.1],
	                        style = [:solid :dot],markerstrokewidth= 0.1,
	                        subplot = i,
	                );
	        else
	                plot!(1:h,data, label=["Global Shock" "Non-fun ECX"],
	                        color= [:teal :darkgoldenrod], markersize = 3.5,
	                        markershape = [:none :circ ], w = [2 0.1],
	                        style = [:solid :dot],markerstrokewidth= 0.1,
	                        subplot=i,
	                );
	        end
	end
	savefig(name);
end

function myplot(data,h,mylabel)
	p1 = plot(1:h,data,
        	label=mylabel, color= [:red :slateblue4 :teal :darkgoldenrod],
        	markersize = 3.5, markershape = [:none :none :x :circ],
        	w = [2 2 0.1 0.1], style = [:solid :dash :dot :dot],
        	markerstrokewidth= 0.1
        );
	return p1;
end
