


"""
	rspoptimize(pars::SolverParameters, symbolinstance::Symbol, optimizer, solutionchecker = false)

Return exit code 0
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
            GC.gc()
        end
    end
    main(pars, instdataname, optimizer, solutionchecker)
    GC.gc()
    return 0
end




function main(pars::SolverParameters, instdataname, optimizer, solutionchecker = false)

    output_folder = joinpath(@__DIR__, "results", "solutions/")
    extension = ".txt"
    if pars.writeresults == HTML()
        output_folder = joinpath(@__DIR__, "results", "html", "solutions", "experiments/")
        extension = ".html"
    end

    for α in pars.alphas
        for rand_inst_id = pars.nb_runrand[1]:pars.nb_runrand[2]
            benders_table = BDtable()
            ilp_table = ILPtable()

            nstr_random = pars.nrand > 0 ? "_" * "$(pars.nrand)" : ""

            if instdataname[1] == :RandomInstance
                instdataname[2] = "$(instdataname[1])$(nstr_random)_o=$(replace(pars.o_i,":"=>"-"))_$(pars.r_ij)_s($(pars.s_ij))_ID$(rand_inst_id)"
                if pars.r_ij == pars.s_ij
                    instdataname[2] = "$(instdataname[1])$(nstr_random)_o$(replace(pars.o_i,":"=>"-"))_rs=l_ij_ID$(rand_inst_id)"
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

            #WARNING: DO NOT DELLETE TODO: to make functionnal
            # if pars.do_plot && pars.timelimit > 30 && pars.writeresults != ""
            # 	if pars.solve_mod == ILP()
            # 		plot_results_plan_run(pars, inst, filename, ilp_table, true)
            # 	end
            # 	if pars.solve_mod == BranchBendersCut()
            # 		plot_results_plan_run(pars, inst, filename, benders_table, false)
            # 	end
            # end
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
        GC.gc()
    end
    return 0
end
