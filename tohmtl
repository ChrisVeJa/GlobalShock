colnames = ["do" "re" "mi" "fa"]
matt = rand(10,4)

io = open("myfile.html", "w");
println(io,"<table style=","""width:80%""",">");
for x in colnames
	println(io,"<th> ",x, String(" </th>"))
end
T, cols = size(matt);
for i in 1:T
	println(io,"<tr>")
	for j in 1:cols
		println(io,"<th> ", string(matt[i,j]), " </th>")
	end
	println(io,"\n</tr>")
end
println(io,"</table>")
close(io);
