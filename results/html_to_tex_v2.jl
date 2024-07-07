using Formatting, NaturalSort


fmt(str) = Formatting.format(str, commas=true, precision=2)

function main(str)
    data_str = split(str)
    alpha = parse(Int,data_str[2][end-2]) #7
    # @show alpha
    instance_name = replace(data_str[4], r"[0-9]" => "") #eil
    # @show instance_name
    n = parse(Int,data_str[6])
    # @show n
    ilp_out_of_memory, bbc_out_of_memory = true, true
    if data_str[30] == "ILP"
        ilp_out_of_memory = false
    end

    id_Ben = 1
    while id_Ben <= length(data_str) && data_str[id_Ben] != "BD"
        id_Ben += 1
    end
    if id_Ben <= length(data_str) && data_str[id_Ben] == "BD"
        bbc_out_of_memory = false
    end
    
    if !ilp_out_of_memory && !bbc_out_of_memory
        total_shift = 0
        rILP = parse(Int,data_str[32])-1

        total_time_ILP_string = ""
        if data_str[39] == "(TL"
            total_shift += 2
            total_time_ILP_string = "\\mtcN{TL}"
        end
        gapILP = parse(Float64,data_str[40+total_shift])*100
        total_time_ILP_string = total_shift > 0 ? "\\mtcN{TL}" : "\\mtcN{$(parse(Float64,data_str[38]))}"
        LB_ILP, UB_ILP = split(data_str[50 + total_shift], "<=")
        LB_ILP, UB_ILP = parse(Float64, LB_ILP),  parse(Float64, UB_ILP)
        n_subtour_ILP = Int(parse(Float64,data_str[52 + total_shift]))
        n_nodes_ILP = parse(Int, data_str[68 + total_shift])
        F_ILP = parse(Float64, data_str[74 + total_shift])
        F_ILP_string = ""
        if F_ILP == 0
            F_ILP_string = "0"
        elseif F_ILP == 7
            F_ILP_string = "7"
        elseif F_ILP == 31
            F_ILP_string = "31"
        else
            F_ILP_string = "183"
        end

        total_time_Ben_string = ""
        total_shift_ben = 0
        rBen = parse(Int,data_str[2+id_Ben])
        if data_str[id_Ben + 9] == "(TL"
            total_shift_ben += 2
            total_time_Ben_string = "\\mtcN{TL}"
        end
        id_Ben += total_shift_ben
        gapBen = parse(Float64,data_str[id_Ben+ 10])*100
        total_time_Ben_string = total_shift_ben > 0 ? "\\mtcN{TL}" : "\\mtcN{$(parse(Float64,data_str[id_Ben+8]))}"
        LB_Ben, UB_Ben = split(data_str[20 + id_Ben], "<=")
        LB_Ben, UB_Ben = parse(Float64, LB_Ben),  parse(Float64, UB_Ben)

        MP_cost, SP_cost = split(data_str[23+id_Ben],'/')
        MP_cost, SP_cost = parse(Float64, MP_cost),  parse(Float64, SP_cost)
        SP_time = parse(Float64, data_str[29+id_Ben])
        n_subtour_Ben = Int(parse(Float64,data_str[31+id_Ben]))
        n_opt_Ben = Int(parse(Float64,data_str[43+id_Ben]))
        n_nodes_Ben = parse(Int, data_str[57+id_Ben])
        
        @show n_nodes_Ben

        return "\\mtcN{\\tt $instance_name $n-$alpha} & \\mtcN{$F_ILP_string} & $total_time_ILP_string & \\mtcN{$(fmt(gapILP))\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} & \\mtcN{$rILP} &\\mtcN{$n_subtour_ILP} &\\mtcN{$n_nodes_ILP} & $total_time_Ben_string & \\mtcN{$(fmt(SP_time))} & \\mtcN{$(fmt(gapBen))\\%} & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))}& \\mtcN{$rBen} &\\mtcN{$n_subtour_Ben} & \\mtcN{$n_opt_Ben} & \\mtcN{$n_nodes_Ben}  \\\\"
    elseif !ilp_out_of_memory # B&BC out of memory
        total_shift = 0
        rILP = parse(Int,data_str[32])-1

        total_time_ILP_string = ""
        if data_str[39] == "(TL"
            total_shift += 2
            total_time_ILP_string = "\\mtcN{TL}"
        end
        gapILP = parse(Float64,data_str[40+total_shift])*100
        total_time_ILP_string = total_shift > 0 ? "\\mtcN{TL}" : "\\mtcN{$(parse(Float64,data_str[38]))}"
        LB_ILP, UB_ILP = split(data_str[50 + total_shift], "<=")
        LB_ILP, UB_ILP = parse(Float64, LB_ILP),  parse(Float64, UB_ILP)
        n_subtour_ILP = Int(parse(Float64,data_str[52 + total_shift]))
        n_nodes_ILP = parse(Int, data_str[68 + total_shift])
        F_ILP = parse(Float64, data_str[74 + total_shift])
        F_ILP_string = ""
        if F_ILP == 0
            F_ILP_string = "0"
        elseif F_ILP == 7
            F_ILP_string = "7"
        elseif F_ILP == 31
            F_ILP_string = "31"
        else
            F_ILP_string = "183"
        end

        return "\\mtcN{\\tt $instance_name $n-$alpha} & \\mtcN{$F_ILP_string} & $total_time_ILP_string & \\mtcN{$(fmt(gapILP))\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} & \\mtcN{$rILP} &\\mtcN{$n_subtour_ILP} &\\mtcN{$n_nodes_ILP} & \\mtc{9}{M}{OUT OF RAM MEMORY}  \\\\"
    elseif !bbc_out_of_memory # ILP out of memory
        id_Ben += - id_Ben + 30
        @show data_str[2+id_Ben]
        rBen = parse(Int,data_str[2+id_Ben])
        total_shift_ben = 0
        if data_str[id_Ben + 9] == "(TL"
            total_shift_ben += 2
            total_time_Ben_string = "\\mtcN{TL}"
        end
        id_Ben += total_shift_ben
        gapBen = parse(Float64,data_str[id_Ben+ 10])*100
        @show gapBen
        total_time_Ben_string = total_shift_ben > 0 ? "\\mtcN{TL}" : "\\mtcN{$(parse(Float64,data_str[id_Ben+8]))}"
        LB_Ben, UB_Ben = split(data_str[20 + id_Ben], "<=")
        LB_Ben, UB_Ben = parse(Float64, LB_Ben),  parse(Float64, UB_Ben)

        MP_cost, SP_cost = split(data_str[23+id_Ben],'/')
        MP_cost, SP_cost = parse(Float64, MP_cost),  parse(Float64, SP_cost)
        SP_time = parse(Float64, data_str[29+id_Ben])
        n_subtour_Ben = Int(parse(Float64,data_str[31+id_Ben]))
        n_opt_Ben = Int(parse(Float64,data_str[43+id_Ben]))
        n_nodes_Ben = parse(Int, data_str[57+id_Ben])

        @show n_nodes_Ben
        
        returned_str = "\\mtcN{\\tt $instance_name $n-$alpha}
        & \\mtc{8}{M}{OUT OF RAM MEMORY}
        & $total_time_Ben_string & \\mtcN{$(fmt(SP_time))} & \\mtcN{$(fmt(gapBen))\\%} & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))}& \\mtcN{$rBen} &\\mtcN{$n_subtour_Ben} & \\mtcN{$n_opt_Ben} & \\mtcN{$n_nodes_Ben}  \\\\"
        return returned_str
    else # No model out of memory

        # "\\mtcN{\\tt $instance_name $n-$alpha}
        # & \\mtcN{TL}   & \\mtcN{$gapILP\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} &\\mtcN{$rILP} & \\mtcN{$(fmt(n_subtour_ILP))}
        # & \\mtcN{TL}   & \\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))}  \\\\"
        # \mtcN{\tt eil 51-3} & \mtcN{0.31} & \mtcN{TL} & \mtcN{37.0\%} & \mtcN{2,257} & \mtcN{3,588} & \mtcN{50} & \mtcN{121} & \mtcN{78,603}
        return ""
    end
end


function html_to_tex_both_TL_all(writef = true)
    i = 0
    rm("html_to_tex.txt")
    file = open("html_to_tex.txt","w")
    instances_arr = String[]
    for dir in readdir("./html/solutions/journal_article_2023")
        if !(dir in ["RAND_article",
                     "clearhtml.jl",
                     ]) && dir[1:3] != "old" # REMOVE kroA150 and 200
            push!(instances_arr, dir)
        end
    end
    function by_dir_name(dir)
        str, alpha = split(dir,"_")
        alpha = alpha[end]
        strname = ""
        strn = ""
        for i in 1:length(str)
            if isdigit(str[i])
                strn *= str[i]
            else
                strname *= str[i]
            end
        end
        return parse(Int, strn), strname, alpha
    end

    sort!(instances_arr, by=x->by_dir_name(x))
    no_rule = 1
    for dir in instances_arr
        dir_name=sort(readdir("./html/solutions/journal_article_2023/$(dir)/"), lt=natural)
        for d in dir_name
            str = ""
            @show d
            str = main(chop(read("./html/solutions/journal_article_2023/$(dir)/"*d, String), head=44))
            @show dir
            if writef
                write(file, str)
                write(file, "\n")
            else
                if length(str) > 0
                    println(str)
                end
            end
            if length(str) > 0
                @show length(dir_name)
                i += 1
                if i == length(dir_name)
                    i = 0
                    if writef && no_rule != length(instances_arr)
                        write(file," \\cmidrule(r){1-18}\n")
                    else
                        println(" \\cmidrule(r){1-18}")
                    end
                end
            end
        end
    end
    no_rule += 1
    close(file)
end

html_to_tex_both_TL_all(true)
