# ===============================================
# [1] Function that creates code lines.
# ===============================================
function gos_creator(df, col::Int64, name, p, h)
    start = 2 + (col - 1) * 9
    y = :(convert(
        Array{Float64},
        df[:, $start:$start+8][completecases(df[:, $start:$start+8]), :],
    ))
    irfname = Symbol.("IRF" .* string.(name));
    fevname = Symbol.("FEVD" .* string.(name));
    lines    = name[col];
    IRFlines = irfname[col];
    FEVlines = fevname[col];
    ex =:(($lines , $IRFlines, $FEVlines) = GlobalShock.GSstimation($y, p, h, xblock = true, nx = 3))
    return ex
end

function GSGraph(model, name; colg = :sienna, subdir = "Countries")
    nf = nfields(model.FEVD.Qntls)
    if ~isdir(".//Figures")
        mkdir("Figures");
    end
    if ~isdir(".//Figures//$subdir")
        mkdir(".//Figures//$subdir");
    end
    # ----------------------------------
    # FEVD
    quint = cat(dims = 3, [model.FEVD.Qntls[i] for i = 1:nf]...)
    quint = permutedims(quint, [2, 3, 1])
    h, n, nvar = size(quint)
    nrows = Int(ceil(nvar / 3))
    plot(layout = (nrows, 3))
    for i = 1:nvar
        meanG = model.FEVD.Mean[i, :]
        line = quint[:, 2, i]
        LB = line .- quint[:, 1, i]
        UB = quint[:, 3, i] .- line
        plot!(
            1:h,
            line;
#            ylims = (0, 1);
            ribbon = (LB, UB),
            tickfontsize = 6,
            subplot = i,
            c = [colg],
            w = 1.5,
            fillalpha = 0.2,
            legend = false,
        )
        scatter!(
            1:h,
            meanG,
            markersize = 1.25,
            c = [colg],
            markershape = :x,
            tickfontsize = 6,
            subplot = i,
        )
    end
    name1 = ".//Figures//$subdir//FEVD_" * name
    savefig(name1)
    # ----------------------------------
    # IRF
    quint = cat(dims = 3, [model.IRF.Qntls[i] for i = 1:nf]...)
    quint = permutedims(quint, [2, 3, 1])
    h, n, nvar = size(quint)
    nrows = Int(ceil(nvar / 3))
    plot(layout = (nrows, 3))
    for i = 1:nvar
        meanG = model.IRF.Mean[i, :]
        line = quint[:, 2, i]
        LB = line .- quint[:, 1, i]
        UB = quint[:, 3, i] .- line
        plot!(
            1:h,
            line;
            ribbon = (LB, UB),
            tickfontsize = 6,
            subplot = i,
            c = [colg],
            w = 1.5,
            fillalpha = 0.2,
            legend = false,
        )
        scatter!(
            1:h,
            meanG,
            markersize = 1.25,
            c = [colg],
            markershape = :x,
            tickfontsize = 6,
            subplot = i,
        )
    end
    name2 = ".//Figures//$subdir//IRF_" * name
    savefig(name2)
end

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
