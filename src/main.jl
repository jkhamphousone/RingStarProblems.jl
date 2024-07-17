


"""
	rspoptimize(pars::SolverParameters, id_instance, optimizer, solutionchecker = false)

Return exit code 0
"""
function rspoptimize(pars, id_instance, optimizer, solutionchecker = false)

	fd_small = joinpath(@__DIR__, "instances", "Instances_small")
	fd_15 = joinpath(@__DIR__, "instances", "Instances_15")
	fd_25 = joinpath(@__DIR__, "instances", "Instances_25")
	fd_40 = joinpath(@__DIR__, "instances", "Instances_40")
	fd_50 = joinpath(@__DIR__, "instances", "Instances_50")
	fd_article = joinpath(@__DIR__, "instances", "Instances_journal_article/journal")

	filenames_arg = Vector{String}[
		["tiny_instance_10_3", "$fd_small/tiny_instance_10_3.txt"], #1
		["tiny_instance_12_2", "$fd_small/tiny_instance_12_2.txt"],
		["Instance_15_1.0_3_1", "$fd_15/Instance_15_1.0_3_1.dat"], #3
		["Instance_15_1.0_5_1", "$fd_15/Instance_15_1.0_5_1.dat"],
		["Instance_25_1.0_3_1", "$fd_25/Instance_25_1.0_3_1.dat"], #5
		["Instance_25_1.0_3_3", "$fd_25/Instance_25_1.0_3_3.dat"],
		["Instance_25_1.0_5_2", "$fd_25/Instance_25_1.0_5_2.dat"], #7
		["Instance_25_3.0_7_1", "$fd_25/Instance_25_3.0_7_1.dat"],
		["Instance_25_1.0_7_4", "$fd_25/Instance_25_1.0_7_4.dat"], #9
		["Instance_25_9.0_9_5", "$fd_25/Instance_25_9.0_9_5.dat"],
		["Instance_40_1.0_9_1", "$fd_40/Instance_40_1.0_9_1.dat"], #11
		["Instance_50_4.0_5_1", "$fd_50/Instance_50_4.0_5_1.dat"],
		String["eil51", "$fd_article/eil51.tsp"], #13
		String["berlin52", "$fd_article/berlin52.tsp"],
		String["brazil58", "$fd_article/brazil58.tsp2"], #15
		String["st70", "$fd_article/st70.tsp"],
		String["eil76", "$fd_article/eil76.tsp"], #17
		String["pr76", "$fd_article/pr76.tsp"],
		String["gr96", "$fd_article/gr96.tsp"], #19
		String["rat99", "$fd_article/rat99.tsp"],
		String["kroA100", "$fd_article/kroA100.tsp"], #21
		String["kroB100", "$fd_article/kroB100.tsp"],
		String["kroC100", "$fd_article/kroC100.tsp"], #23
		String["kroD100", "$fd_article/kroD100.tsp"],
		String["kroE100", "$fd_article/kroE100.tsp"], #25
		String["rd100", "$fd_article/rd100.tsp"],
		String["eil101", "$fd_article/eil101.tsp"], #27
		String["lin105", "$fd_article/lin105.tsp"],
		String["pr107", "$fd_article/pr107.tsp"], #29
		String["gr120", "$fd_article/gr120.tsp2"],
		String["pr124", "$fd_article/pr124.tsp"], #31
		String["bier127", "$fd_article/bier127.tsp"],
		String["ch130", "$fd_article/ch130.tsp"], #33
		String["pr136", "$fd_article/pr136.tsp"],
		String["gr137", "$fd_article/gr137.tsp"], #35
		String["pr144", "$fd_article/pr144.tsp"],
		String["ch150", "$fd_article/ch150.tsp"], #37
		String["kroA150", "$fd_article/kroA150.tsp"],
		String["kroB150", "$fd_article/kroB150.tsp"], #39
		String["pr152", "$fd_article/pr152.tsp"],
		String["u159", "$fd_article/u159.tsp"], #41
		String["rat195", "$fd_article/rat195.tsp"],
		String["d198", "$fd_article/d198.tsp"], #43
		String["kroA200", "$fd_article/kroA200.tsp"],
		String["kroB200", "$fd_article/kroB200.tsp"], #45
		["random_instance", ""], #46
	]

	filename = String[]
	if id_instance > 0
		filename = filenames_arg[id_instance]
	else
		filename = filenames_arg[1]
	end

	if pars.redirect_stdio
		# redirect terminal outputs/stdio to file
		now_file = Dates.format(Dates.now(), "yyyy-mm-dd_HHhMM")
		now_folder = Dates.format(Dates.now(), "yyyy-mm-dd")
		output_path = joinpath(@__DIR__, "debug", "stdio", "$now_folder")
		mkpath(output_path)mkpath
		redirect_stdio(
			stdout = "$output_path/stdout_$(filename[1])_$now_file.txt",
			stderr = "$output_path/stderr_$(filename[1])_$now_file.txt",
		) do
			main(pars, filename)
			GC.gc()
		end
	end
	main(pars, filename ; solutionchecker = false, optimizer)
	GC.gc()
	return 0
end




function main(pars::SolverParameters, filename::Vector{String}, optimizer, solutionchecker = false)
	journal_article_instances_str = [
		"random_instance",
		"berlin52",
		"bier127",
		"brazil58",
		"ch130",
		"ch150",
		"d198",
		"eil51",
		"eil76",
		"eil101",
		"gr96",
		"gr120",
		"gr137",
		"kroA100",
		"kroA150",
		"kroA200",
		"kroB100",
		"kroB150",
		"kroB200",
		"kroC100",
		"kroD100",
		"kroE100",
		"lin105",
		"pr76",
		"pr107",
		"pr124",
		"pr136",
		"pr144",
		"pr152",
		"rat99",
		"rat195",
		"rd100",
		"st70",
		"u159",
	]
	output_folder = joinpath(@__DIR__, "results", "solutions")
	extension = ".txt"
	if pars.writeresults == HTML()
		if filename[1] in journal_article_instances_str
			output_folder =
				joinpath(@__DIR__, "results", "html", "solutions", "journal_article_2023")
		else
			output_folder =
				joinpath(@__DIR__, "results", "html", "solutions", "experiments_2023")
		end
		extension = ".html"
	end

	for α in pars.alphas
		for rand_inst_id ∈ pars.nb_runrand[1]:pars.nb_runrand[2]
			benders_table = BDtable()
			ilp_table = ILPtable()

			nstr_random = pars.nrand > 0 ? "_" * "$(pars.nrand)" : ""

			if filename[1] == "random"
				filename[2] = "$(filename[1])$(nstr_random)_α=$(α)_o=$(replace(pars.o_i,":"=>"-"))_$(rand_inst_id)"
			end
			if filename[1] == "random_instance"
				filename[2] = "$(filename[1])$(nstr_random)_o=$(replace(pars.o_i,":"=>"-"))_$(pars.r_ij)_s($(pars.s_ij))_ID$(rand_inst_id)"
				if pars.r_ij == pars.s_ij
					filename[2] = "$(filename[1])$(nstr_random)_o$(replace(pars.o_i,":"=>"-"))_rs=l_ij_ID$(rand_inst_id)"
				end
			end

			if filename[1] in journal_article_instances_str
				inst = create_instance_robust_journal_article(filename[2], α, pars)
			else
				inst = create_instance_robust(filename, α, pars)
			end
			println("\nInstance: ", "$(filename[1])")
			pars.log_level > 0 && filename[1] != "random_instance" && @info "α=$α"


			print_inst(inst, pars)

			if pars.solve_mod == gF() ||
			   pars.solve_mod in [gFexploreonlyILP(), gFexploreonlyben()]
				rrsp_plot_gF(
					filename[1],
					inst,
					pars,
					pars.F_interval[1],
					pars.F_interval[2],
				)
			end

			if pars.solve_mod in [BranchBendersCut(), Both()]
				benders_table =
					round!(rrspcreatebenders_modellazy(filename[1], inst, pars ; optimizer))

			end

			input_filepath = get_input_filepath(
				output_folder,
				filename,
				extension,
				inst,
				pars,
				nstr_random,
				rand_inst_id,
			)
			if pars.solve_mod in [ILP(), Both()]

				ilp_table = round!(rrspcreate_ilplazy(filename[1], inst, pars, optimizer, solutionchecker))


			elseif pars.solve_mod == NoOptimize()
				@show input_filepath
				ilp_table = read_ilp_table(input_filepath, pars.plot_id)
			end

			if pars.do_plot && pars.timelimit > 30 && pars.writeresults != ""
				if pars.solve_mod in [ILP(), Both()]
					plot_results_plan_run(pars, inst, filename, ilp_table, true)
				end
				if pars.solve_mod in [BranchBendersCut(), Both()]
					plot_results_plan_run(pars, inst, filename, benders_table, false)
				end
			end
			if pars.writeresults != ""
				write_solution_to_file(
					input_filepath,
					filename,
					inst,
					pars,
					nstr_random,
					rand_inst_id,
					inst.n,
					benders_table,
					ilp_table,
				)
			end


			if pars.solve_mod == Both() &&
			   abs(benders_table.UB - ilp_table.UB) > 0.001 &&
			   ilp_table.UB != Inf &&
			   benders_table.UB != Inf &&
			   benders_table.gap < 10e-5 &&
			   ilp_table.gap < 10e-5
				println("Benders opt: ", benders_table.UB)
				println("ILP opt: ", ilp_table.UB)
				pars.assert && @assert abs(benders_table.UB - ilp_table.UB) < 0.01
			end
		end
		GC.gc()
	end
	return 0
end
