using Formatting

function main(str)
    data_str = split(str)
    @show data_str
    alpha = parse(Int, data_str[2][end-2]) #7
    @show alpha
    instance_name = replace(data_str[4], r"[0-9]" => "") #eil
    n = parse(Int, data_str[6])
    @show n
    rILP = parse(Int, data_str[18+separate_shift])
    if data_str[25+separate_shift][end-1:end] == "TL"
    end

    function ILP_BBC_both_TL(data_str, alpha, n, str)
        separate_shift = 14
        rILP = parse(Int, data_str[18+separate_shift])
        @assert data_str[25+separate_shift][end-1:end] == "TL"
        gap_digits = split(data_str[28+separate_shift], '.')[2]
        gapILP = ""
        if length(gap_digits) == 1
            gapILP = "$(gap_digits)0"
        elseif length(gap_digits) == 2
            gapILP = "$(gap_digits)"
        else
            gapILP = "$(gap_digits[1:2]).$(gap_digits[3:end])"
        end
        LB_ILP, UB_ILP = split(data_str[32+separate_shift], "<=")
        LB_ILP, UB_ILP = parse(Float64, LB_ILP), parse(Float64, UB_ILP)
        n_subtour_ILP = parse(Float64, data_str[34+separate_shift])

        date_shift = separate_shift
        if data_str[53][1] == '*'
            date_shift = 7
        end

        rBen = parse(Int, data_str[55+date_shift])
        @assert data_str[62+date_shift][end-1:end] == "TL"
        gap_digits = split(data_str[65+date_shift], '.')[2]
        gapBen = ""
        if length(gap_digits) == 1
            gapBen = "$(gap_digits)0"
        elseif length(gap_digits) == 2
            gapBen = "$(gap_digits)"
        else
            gapBen = "$(gap_digits[1:2]).$(gap_digits[3:end])"
        end
        LB_Ben, UB_Ben = split(data_str[69+date_shift], "<=")
        LB_Ben, UB_Ben = parse(Float64, LB_Ben), parse(Float64, UB_Ben)
        MP_cost, SP_cost = split(data_str[72+date_shift], '/')
        MP_cost, SP_cost = parse(Float64, MP_cost), parse(Float64, SP_cost)
        SP_time = parse(Float64, data_str[78+date_shift])
        n_subtour_Ben = parse(Float64, data_str[80+date_shift])
        n_opt_Ben = parse(Float64, data_str[92+date_shift])

        @show UB_Ben
        @show SP_cost
        @show MP_cost
        @assert abs(UB_Ben - SP_cost - MP_cost) < 0.5



        return "\\mtcN{\\tt $instance_name $n-$alpha}
        & \\mtcN{TL}   & \\mtcN{$gapILP\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} &\\mtcN{$rILP} & \\mtcN{$(fmt(n_subtour_ILP))}
        & \\mtcN{TL}   & \\mtcN{$SP_time} &\\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))}  \\\\"
    end

    fmt(str) = Formatting.format(str, commas = true)

    function html_to_tex_both_TL(str) ## OLD
        data_str = split(str)
        @show data_str
        alpha = parse(Int, data_str[2][end-2]) #7
        @show alpha
        instance_name = replace(data_str[4], r"[0-9]" => "") #eil
        n = parse(Int, data_str[6])
        @show n
        fmt(str) = Formatting.format(str, commas = true)
        separate_shift = 14

        if data_str[16+separate_shift] == "ILP"

        end
        if data_str[16+separate_shift] != "ILP"
            #    TODO to uncomment when Benders' ready
            date_shift = separate_shift
            if data_str[9][1] == '*'
                date_shift = 7
            end
            rBen = parse(Int, data_str[11+date_shift])
            @assert data_str[18+date_shift][end-1:end] == "TL"
            gap_digits = split(data_str[21+date_shift], '.')[2]
            gapBen = ""
            if length(gap_digits) == 1
                gapBen = "$(gap_digits)0"
            elseif length(gap_digits) == 2
                gapBen = "$(gap_digits)"
            else
                gapBen = "$(gap_digits[1:2]).$(gap_digits[3:end])"
            end
            LB_Ben, UB_Ben = split(data_str[25+date_shift], "<=")
            LB_Ben, UB_Ben = parse(Float64, LB_Ben), parse(Float64, UB_Ben)
            MP_cost, SP_cost = split(data_str[28+date_shift], '/')
            MP_cost, SP_cost = parse(Float64, MP_cost), parse(Float64, SP_cost)
            SP_time = parse(Float64, data_str[34+date_shift])
            n_subtour_Ben = parse(Float64, data_str[36+date_shift])
            n_opt_Ben = parse(Float64, data_str[48+date_shift])

            @show UB_Ben
            @show SP_cost
            @show MP_cost
            @assert abs(UB_Ben - SP_cost - MP_cost) < 0.5

            fmt(str) = Formatting.format(str, commas = true)

            return "\\mtcN{\\tt $instance_name $n-$alpha}
            & \\mtc{6}{N}{OUT OF RAM MEMORY}
            & \\mtcN{TL}   & \\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))} \\\\"

        else
            separate_shift -= 2

            gap_digits = split(data_str[28+separate_shift], '.')[2]
            gapILP = ""
            if length(gap_digits) == 1
                gapILP = "$(gap_digits)0"
            elseif length(gap_digits) == 2
                gapILP = "$(gap_digits)"
            else
                gapILP = "$(gap_digits[1:2]).$(gap_digits[3:end])"
            end
            shift_blossom = 6
            separate_shift += 6
            LB_ILP, UB_ILP = split(data_str[32+separate_shift], "<=")
            LB_ILP, UB_ILP = parse(Float64, LB_ILP), parse(Float64, UB_ILP)
            n_subtour_ILP = parse(Float64, data_str[34+separate_shift])

            date_shift = separate_shift
            if data_str[53][1] == '*'
                date_shift = 7
            end
            # TODO to uncomment when Benders' ready
            solution_printing_shift = 0
            while data_str[53+date_shift+solution_printing_shift] != "BD" &&
                solution_printing_shift <= 10000
                solution_printing_shift += 1
            end
            @assert solution_printing_shift != 10000
            date_shift += solution_printing_shift
            rBen = parse(Int, data_str[55+date_shift])
            @assert data_str[62+date_shift][end-1:end] == "TL"
            gap_digits = split(data_str[65+date_shift], '.')[2]
            gapBen = ""
            if length(gap_digits) == 1
                gapBen = "$(gap_digits)0"
            elseif length(gap_digits) == 2
                gapBen = "$(gap_digits)"
            else
                gapBen = "$(gap_digits[1:2]).$(gap_digits[3:end])"
            end
            LB_Ben, UB_Ben = split(data_str[69+date_shift], "<=")
            LB_Ben, UB_Ben = parse(Float64, LB_Ben), parse(Float64, UB_Ben)
            MP_cost, SP_cost = split(data_str[72+date_shift], '/')
            MP_cost, SP_cost = parse(Float64, MP_cost), parse(Float64, SP_cost)
            SP_time = parse(Float64, data_str[78+date_shift])
            n_subtour_Ben = parse(Float64, data_str[80+date_shift])
            n_opt_Ben = parse(Float64, data_str[92+date_shift])

            @show UB_Ben
            @show SP_cost
            @show MP_cost
            @assert abs(UB_Ben - SP_cost - MP_cost) < 0.5



            return "\\mtcN{\\tt $instance_name $n-$alpha}
            & \\mtcN{TL}   & \\mtcN{$gapILP\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} &\\mtcN{$rILP} & \\mtcN{$(fmt(n_subtour_ILP))}
            & \\mtcN{TL}   & \\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))}  \\\\"
        end
    end


    function html_to_tex_both_TL_all(writef = true)
        i = 0
        rm("html_to_tex.txt")
        file = open("html_to_tex.txt", "w")
        instances_arr = String[]
        for dir in readdir("./html/solutions/journal_article_2023")
            if !(dir in ["RAND_article", "clearhtml.jl"]) && dir[1:3] != "old" # REMOVE kroA150 and 200
                push!(instances_arr, dir)
            end
        end
        function by_dir_name(dir)
            str, alpha = split(dir, "_")
            alpha = alpha[end]
            strname = ""
            strn = ""
            for i = 1:length(str)
                if isdigit(str[i])
                    strn *= str[i]
                else
                    strname *= str[i]
                end
            end
            return parse(Int, strn), strname, alpha
        end

        sort!(instances_arr, by = x -> by_dir_name(x))
        no_rule = 1
        for dir in instances_arr
            str = ""
            @show dir
            str = html_to_tex_both_TL(
                chop(
                    read(
                        "./html/solutions/journal_article_2023/$(dir)/" *
                        readdir("./html/solutions/journal_article_2023/$(dir)")[end],
                        String,
                    ),
                    head = 44,
                ),
            )
            @show str
            @show dir
            if writef
                write(file, str)
                write(file, "\n")
            else
                println(str)
            end
            i += 1
            if i == 3
                i = 0
                if writef && no_rule != length(instances_arr)
                    write(file, " \\cmidrule(r){1-15}\n")
                else
                    println(" \\cmidrule(r){1-15}")
                end
            end
        end
        no_rule += 1
        close(file)
    end
end
html_to_tex_both_TL_all(true)
