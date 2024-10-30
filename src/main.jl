


"""
	rspoptimize(pars::SolverParameters, symbolinstance::Symbol, optimizer, solutionchecker = false)

Return exit succesful code 0
"""
function rspoptimize(
	pars::SolverParameters,
	symbolinstance::Symbol,
	optimizer,
	solutionchecker = false,
)



	instancenames = generateinstancenames()

	instdataname = symbolinstance, instancenames[symbolinstance]

	if pars.redirect_stdio
		# redirect terminal outputs/stdio to file
		now_file = Dates.format(Dates.now(), "yyyy-mm-dd_HHhMM")
		now_folder = Dates.format(Dates.now(), "yyyy-mm-dd")
		output_path = joinpath(@__DIR__, "debug", "stdio", "$now_folder")
		mkpath(output_path)
		redirect_stdio(
			stdout = "$output_path/stdout_$(symbolinstance)_$now_file.txt",
			stderr = "$output_path/stderr_$(symbolinstance)_$now_file.txt",
		) do
			main(pars, instdataname, optimizer, solutionchecker)
			# GC.gc()
		end
	end
	main(pars, instdataname, optimizer, solutionchecker)
	# GC.gc()
	return 0
end




"""
	rspoptimize(pars::SolverParameters, xycoordinates::Vector{Tuple{Int,Int}}, optimizer, solutionchecker = false)

	Return exit succesful code 0
"""
function rspoptimize(
	pars::SolverParameters,
	xycoordinates::Vector{Tuple{Int,Int}},
	optimizer,
	solutionchecker = false,
)

	instdataname = "xycoordinates_$(length(xycoordinates))", (xycoordinates, length(xycoordinates))

	if pars.redirect_stdio
		# redirect terminal outputs/stdio txycoordinateso file
		now_file = Dates.format(Dates.now(), "yyyy-mm-dd_HHhMM")
		now_folder = Dates.format(Dates.now(), "yyyy-mm-dd")
		output_path = joinpath(@__DIR__, "debug", "stdio", "$now_folder")
		mkpath(output_path)
		redirect_stdio(
			stdout = "$output_path/stdout_$(symbolinstance)_$now_file.txt",
			stderr = "$output_path/stderr_$(symbolinstance)_$now_file.txt",
		) do
			main(pars, instdataname, optimizer, solutionchecker)
			# GC.gc()
		end
	end
	main(pars, instdataname, optimizer, solutionchecker)
	# GC.gc()
	return 0
end



function main(pars::SolverParameters, instdataname, optimizer, solutionchecker = false)



	output_folder = joinpath(@__DIR__, "results", "solutions/")
	extension = ".txt"
	if pars.writeresults == HTML()
		output_folder = joinpath(@__DIR__, "results", "html", "solutions", "experiments/")
		extension = ".html"
	end

	α = pars.alpha
	for rand_inst_id ∈ pars.nb_runrand[1]:pars.nb_runrand[2]
		benders_table = BDtable()
		ilp_table = ILPtable()
		α
		nstr_random = pars.nrand > 0 ? "_" * "$(pars.nrand)" : ""

		if instdataname[1] == :RandomInstance
			instdataname[2][1] = "$(instdataname[1])$(nstr_random)_o=$(replace(pars.o_i,":"=>"-"))_$(pars.r_ij)_s($(pars.s_ij))_ID$(rand_inst_id)"
			if pars.r_ij == pars.s_ij
				instdataname[2][1] = "$(instdataname[1])$(nstr_random)_o$(replace(pars.o_i,":"=>"-"))_rs=l_ij_ID$(rand_inst_id)"
			end
		end

		
		inst = createinstance_rrsp(instdataname[2], α, pars)

		println("\nInstance: ", "$(instdataname[1])")
		pars.log_level > 0 && instdataname[1] != :RandomInstance && @info "α=$α"


		printinst(inst, pars)

		if pars.solve_mod == gF() ||
		   pars.solve_mod in [gFexploreonlyILP(), gFexploreonlyben()]
			rrsp_plot_gF(
				instdataname[1],
				inst,
				pars,
				pars.F_interval[1],
				pars.F_interval[2],
			)
		end

		if pars.solve_mod == BranchBendersCut()
			benders_table = round!(
				rrspcreatebenders_modellazy(instdataname[1], inst, pars; optimizer),
			)

		end

		input_filepath = get_input_filepath(
			output_folder,
			instdataname,
			extension,
			inst,
			pars,
			nstr_random,
			rand_inst_id,
		)
		if pars.solve_mod == ILP()

			ilp_table = round!(
				rrspcreate_ilplazy(
					instdataname[1],
					inst,
					pars,
					optimizer,
					solutionchecker,
				),
			)


		elseif pars.solve_mod == NoOptimize()
			@show input_filepath
			ilp_table = read_ilp_table(input_filepath, pars.plot_id)
		end

		if pars.plotting && pars.writeresults
			if pars.solve_mod == ILP()
				if ilp_table.sol.n != 0
					perform_plot(pars, inst, instdataname[1], ilp_table, true)
				else
					@info "No feasible solution has been found by ILP within the solving time, can not perform plotting"
				end
			end
			if pars.solve_mod == BranchBendersCut()
				if benders_table.sol.n != 0
					perform_plot(pars, inst, instdataname[1], benders_table, false)
				else
					@info "No feasible solution has been found by B&BC within the solving time, can not perform plotting"
				end
			end
		end
		if pars.writeresults != ""
			write_solution_to_file(
				input_filepath,
				instdataname,
				inst,
				pars,
				nstr_random,
				rand_inst_id,
				inst.n,
				benders_table,
				ilp_table,
			)
		end
	end
	# GC.gc()
	return 0
end

"""
	rspoptimize(pars::SolverParameters, x::Vector{Int}, y::Vector{Int}, optimizer, solutionchecker = false)

	Return exit succesful code 0
"""
rspoptimize(
	pars::SolverParameters,
	x, y,
	optimizer,
	solutionchecker,
) = rspoptimize(
	pars,
	tuple.(x, y),
	optimizer,
	solutionchecker,
)
