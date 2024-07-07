using Formatting

function html_to_tex_both_TL(str, nrand, instance_name, ilp_here)
    
    data_str = split(str)
    idx_shift_ILP = 0
    if ilp_here
        n = parse(Int,data_str[5])
        @show instance_name, nrand, n
        rILP = parse(Int,data_str[17])
        ILP_time = parse(Float64,data_str[23])
        if data_str[24] == "(TL"
            idx_shift_ILP += 2
            ILP_time = "TL"
        end
        gap_digits = split(data_str[25+idx_shift_ILP],'.')[2]
        gapILP = ""
        if length(gap_digits) == 0
            gapILP = "0"
        elseif length(gap_digits) == 1
            gapILP = "$(gap_digits)"
        elseif length(gap_digits) == 2
            gapILP = "$(gap_digits)"
        else
            gapILP = "$(gap_digits[1:2]).$(gap_digits[3:end])"
        end
        LB_ILP, UB_ILP = split(data_str[29+idx_shift_ILP], "<=")
        LB_ILP, UB_ILP = parse(Float64, LB_ILP),  parse(Float64, UB_ILP)
        n_subtour_ILP = parse(Float64,data_str[31+idx_shift_ILP])
    else
        idx_shift_ILP = -56
    end

    idx_shift_ben = idx_shift_ILP+23+8
    # if data_str[37+19][1] == '*'
    #     idx_shift_ben = 7+19
    # end
    @show data_str[42+idx_shift_ben]
    rBen = parse(Int,data_str[42+idx_shift_ben])
    Ben_time = parse(Float64, data_str[48+idx_shift_ben])
    if data_str[49+idx_shift_ben] == "(TL"
        idx_shift_ben += 2
        Ben_time = "TL"
    end
    gap_digits = ""
    @show data_str[50+idx_shift_ben]
    if length(data_str[50+idx_shift_ben]) > 1
        gap_digits = split(data_str[50+idx_shift_ben],'.')[2]
    end
    gapBen = ""
    if length(gap_digits) == 0
        gapBen = "0"
    elseif length(gap_digits) == 1
        gapBen = "$(gap_digits)"
    elseif length(gap_digits) == 2
        gapBen = "$(gap_digits)"
    else
        gapBen = "$(gap_digits[1:2]).$(gap_digits[3:end])"
    end
    LB_Ben, UB_Ben = split(data_str[54+idx_shift_ben], "<=")
    LB_Ben, UB_Ben = parse(Float64, LB_Ben),  parse(Float64, UB_Ben)
    MP_cost, SP_cost = split(data_str[57+idx_shift_ben],'/')
    MP_cost, SP_cost = parse(Float64, MP_cost),  parse(Float64, SP_cost)
    SP_time = parse(Float64, data_str[63+idx_shift_ben])
    n_subtour_Ben = parse(Float64,data_str[65+idx_shift_ben])
    n_opt_Ben = parse(Float64,data_str[77+idx_shift_ben])

    @show UB_Ben
    @show SP_cost
    @show MP_cost
    @assert abs(UB_Ben - SP_cost - MP_cost) < 0.5

    fmt(str) = Formatting.format(str, commas=true)
    if ilp_here
        return "\\mtcN{\\tt $instance_name - $(data_str[5]).$nrand}
        & \\mtcN{$ILP_time}   & \\mtcN{$gapILP\\%} & \\mtcN{$(fmt(LB_ILP))} & \\mtcN{$(fmt(UB_ILP))} &\\mtcN{$rILP} & \\mtcN{$(fmt(n_subtour_ILP))}
        & \\mtcN{$Ben_time}   & \\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))}  \\\\"
    else
        return "\\mtcN{\\tt $instance_name - $(data_str[5]).$nrand}
        & \\mtc{6}{N}{OUT OF RAM MEMORY}
        & \\mtcN{$Ben_time}   & \\mtcN{$gapBen\\%}  & \\mtcN{$(fmt(LB_Ben))} & \\mtcN{$(fmt(UB_Ben))} & \\mtcN{$rBen} &\\mtcN{$(fmt(n_subtour_Ben))} & \\mtcN{$SP_time} & \\mtcN{$(fmt(n_opt_Ben))}  \\\\"
    end
end


function html_to_tex_both_TL_all_rand(writef = true)

    rm("html_to_tex_rand_ClassII.txt")
    output_file_ClassIII = open("html_to_tex_rand_ClassII.txt","w")
    instances_arr_ClassIII = String[]
    for file in readdir("./html/journal_article/RAND_article")
        if file != "not_journal" && length(split(file,"_")[3]) > 2
            push!(instances_arr_ClassIII, file)
        end
    end

    i = 0
    no_rule = 1
    for file in instances_arr_ClassIII
        str = chop(read("./html/journal_article/RAND_article/$file", String), head=40)
        if writef
            if split(file,"_")[3] == "100"
                write(output_file_ClassIII, html_to_tex_both_TL(str, file[end-22], "ClassII", true))
                write(output_file_ClassIII, "\n")
            else
                write(output_file_ClassIII, html_to_tex_both_TL(str, file[end-22], "ClassII", false))
                write(output_file_ClassIII, "\n")
            end
        else
            println(html_to_tex_both_TL(str, file[end-11], "ClassII"))
        end
        i += 1
        if i == 5
            i = 0
            if writef && no_rule != length(instances_arr_ClassIII)
                write(output_file_ClassIII," \\cmidrule(r){1-15}\n")
            elseif !writef
                println(" \\cmidrule(r){1-15}")
            end
        end
        no_rule += 1
    end
    close(output_file_ClassIII)
end

html_to_tex_both_TL_all_rand(true)
#
# function html_to_tex_both_TL_arr(arr_str, writef = true)
#     i = 0
#     file = open("html_to_tex.txt","w")
#     for str in arr_str
#         if writef
#             write(file, html_to_tex_both_TL(str))
#             write(file, "\n")
#         else
#             println(html_to_tex_both_TL(str))
#         end
#         i += 1
#         if i == 3
#             i = 0
#             if writef
#                 write(file," \\cmidrule(r){1-15}\n")
#             else
#                 println(file, " \\cmidrule(r){1-15}")
#             end
#         end
#     end
#     close(file)
# end
#
# arr_str_3 = ["------------------------------------------------------------
#                          α=7 —— kroB100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 12 Apr 2022 13:34:04 —————————
# ILP ——— 4 hubs —— 1-14-16-18-1
# total time    3606.43 (TL 3600)   gap           0.486
# LB <= UB      181233<=352463      subtour       311
# connectivity  0.0
#
# BD  —— 4 hubs —— 1-14-16-18-1
# total time   360096 (TL 3600)   gap                  0.692
# LB <= UB     108670.361<=352463 Master/SP costs      39951/312512
# Master time  3490.233           SP time              109.863
# subtour      15913              connectivity cuts    0
# opt. cuts    1242               SP method            poly
# uc strategy  0                  inst transformation  2
#                                                            ",
# "------------------------------------------------------------
#                          α=7 —— kroC100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 21:24:13 —————————
# ILP ——— 4 hubs —— 1-22-50-83-1
# total time    3605.66 (TL 3600)   gap           0.579
# LB <= UB      171489<=407063      subtour       1005
# connectivity  0.0
#
# BD  —— 4 hubs —— 1-22-50-83-1
# total time   3600.259 (TL 3600) gap                  0.739
# LB <= UB     106231.595<=407063 Master/SP costs      33952/373111
# Master time  3490.454           SP time              109.805
# subtour      19226              connectivity cuts    0
# opt. cuts    1862               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                          α=7 —— kroD100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 23:25:14 —————————
# ILP ——— 4 hubs —— 1-3-6-53-1
# total time    3605.48 (TL 3600)   gap           0.564
# LB <= UB      171490.0<=393163    subtour       903
# connectivity  0.0
#
#
#
# BD  —— 4 hubs —— 1-3-6-53-1
# total time   3600.176 (TL 3600) gap                  0.733
# LB <= UB     104951.507<=393163 Master/SP costs      33787/359376
# Master time  3455.336           SP time              144.84
# subtour      16544              connectivity cuts    0
# opt. cuts    1652               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                          α=3 —— kroE100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 22:22:41 —————————
# ILP ——— 98 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time    3605.72 (TL 3600)   gap           0.395
# LB <= UB      113276<=187144      subtour       783
# connectivity  0.0
#
#
#
# BD  —— 97 hubs —— 1-2-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time   3600.286 (TL 3600) gap                  0.559
# LB <= UB     112048.279<=254074 Master/SP costs      88420/165654
# Master time  3592.478           SP time              7.808
# subtour      6610               connectivity cuts    0
# opt. cuts    965                SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                          α=7 —— kroE100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 12 Apr 2022 01:26:16 —————————
# ILP ——— 4 hubs —— 1-6-91-92-1
# total time    3606.54 (TL 3600)   gap           0.537
# LB <= UB      177529.07<=383418   subtour       629
# connectivity  0.0
#
#
#
# BD  —— 4 hubs —— 1-6-91-92-1
# total time   3600.69 (TL 3600)  gap                  0.719
# LB <= UB     107887.435<=383418 Master/SP costs      50252/333166
# Master time  3466.953           SP time              133.737
# subtour      19201              connectivity cuts    0
# opt. cuts    1585               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                            α=7 —— pr107 —— 107 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 12 Apr 2022 03:27:20 —————————
# ILP ——— 56 hubs —— 1-4-5-8-9-10-11-14-15-18-19-20-21-25-26-27-30-34-35-37-39-43-44-45-46-47-48-50-51-52-53-54-59-62-66-67-68-69-70-71-72-73-75-80-81-84-86-89-91-96-97-98-100-103-104-106-1
# total time    3606.95 (TL 3600)   gap           0.764
# LB <= UB      240260.0<=1018628 subtour       1697
# connectivity  0.0
#
#
#
# BD  —— 4 hubs —— 1-76-86-96-1
# total time   3600.29 (TL 3600)  gap                  0.873
# LB <= UB     152965.207<=1207438 Master/SP costs      143017/164421e6
# Master time  3528.963           SP time              71.327
# subtour      24012              connectivity cuts    0
# opt. cuts    689                SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                            α=7 —— rd100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 12 Apr 2022 13:34:28 —————————
# ILP ——— 4 hubs —— 1-56-95-98-1
# total time    3608.68 (TL 3600)   gap           0.578
# LB <= UB      62678<=148579       subtour       479
# connectivity  0.0
#
#
#
# BD  —— 4 hubs —— 1-56-95-98-1
# total time   3600.117 (TL 3600) gap                  0.73
# LB <= UB     40081.306<=148579  Master/SP costs      13286/135293
# Master time  3464.413           SP time              135.704
# subtour      16683              connectivity cuts    0
# opt. cuts    2061               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    "
#
# ]
#
#
# arr_str=["------------------------------------------------------------
#                             α=3 —— eil51 —— 51 nodes
# ------------------------------------------------------------
#
# *——————— Fri, 11 Mar 2022 15:05:22 —————————
# ILP ——— 51 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-1
# total time    3600.51 (TL 3600)   gap           0.293
# LB <= UB      2329<=3296          subtour       523
# connectivity  0.0
#
#
# BD  —— 50 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-1
# total time   3600.08 (TL 3600)  gap                  0.276
# LB <= UB     2469.95<=3412      Master/SP costs      1320.0/2092
# Master time  3596.92            SP time              3.16
# subtour      6621               connectivity cuts    0.0
# opt. cuts    4324               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=5 —— eil51 —— 51 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 15 Mar 2022 13:10:29 —————————
# ILP ——— 33 hubs —— 1-3-4-6-9-10-12-13-14-15-16-17-18-19-20-21-23-24-25-29-30-33-35-37-38-39-41-44-45-47-48-49-50-1
# total time    3600.57 (TL 3600)   gap           0.248
# LB <= UB      3693<=4913          subtour       805
# connectivity  0.0
#
#
# BD  —— 21 hubs —— 1-2-4-9-10-14-15-18-19-21-23-24-29-33-41-42-44-45-48-49-50-1
# total time   3600.11 (TL 3600)  gap                  0.3
# LB <= UB     3597.66<=5140.0    Master/SP costs      937/4203
# Master time  3556.29            SP time              43.82
# subtour      12621              connectivity cuts    0.0
# opt. cuts    4960.0             SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=7 —— eil51 —— 51 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 12:12:26 —————————
# ILP ——— 4 hubs —— 1-4-17-37-1
# total time    3600.62 (TL 3600)   gap           0.135
# LB <= UB      3610.0<=4171        subtour       418
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-4-17-37-1
# total time   3600.08 (TL 3600)  gap                  0.298
# LB <= UB     2927.13<=4171      Master/SP costs      521/3650.0
# Master time  3548.96            SP time              51.13
# subtour      12998              connectivity cuts    0.0
# opt. cuts    5318               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=3 —— berlin52 —— 52 nodes
# ------------------------------------------------------------
#
# *——————— Fri, 11 Mar 2022 17:05:23 —————————
# ILP ——— 52 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-1
# total time    3600.51 (TL 3600)   gap           0.328
# LB <= UB      41179<=61298        subtour       679
# connectivity  0.0
#
#
# BD  —— 52 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-1
# total time   3600.02 (TL 3600)  gap                  0.288
# LB <= UB     41339.98<=58095    Master/SP costs      22883/35212
# Master time  3596.02            SP time              3.99
# subtour      6418               connectivity cuts    0.0
# opt. cuts    4095               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=5 —— berlin52 —— 52 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 15 Mar 2022 15:10:30 —————————
# ILP ——— 28 hubs —— 1-4-5-6-8-10-11-12-13-15-19-24-25-26-27-28-33-35-36-37-38-39-40-41-43-45-48-51-1
# total time    3600.62 (TL 3600)   gap           0.281
# LB <= UB      63678<=88594        subtour       1344
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-12-26-27-1
# total time   3600.2 (TL 3600)   gap                  0.432
# LB <= UB     56792.64<=99903    Master/SP costs      9576/90327
# Master time  3559.54            SP time              40.66
# subtour      17109              connectivity cuts    0.0
# opt. cuts    5157               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=7 —— berlin52 —— 52 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 14:13:13 —————————
# ILP ——— 4 hubs —— 1-24-37-38-1
# total time    3600.96 (TL 3600)   gap           0.042
# LB <= UB      62577<=65307        subtour       493
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-24-37-38-1
# total time   3600.04 (TL 3600)  gap                  0.254
# LB <= UB     48704.08<=65307    Master/SP costs      4375/60932
# Master time  3555.01            SP time              45.03
# subtour      15473              connectivity cuts    0.0
# opt. cuts    4523               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                              α=3 —— st70 —— 70 nodes
# ------------------------------------------------------------
#
# *——————— Fri, 11 Mar 2022 19:05:27 —————————
# ILP ——— 69 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-1
# total time    3601.41 (TL 3600)   gap           0.336
# LB <= UB      3454<=5203          subtour       577
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-32-40-44-1
# total time   3600.12 (TL 3600)  gap                  0.827
# LB <= UB     3474.63<=20107     Master/SP costs      701/19406
# Master time  3591.52            SP time              8.6
# subtour      10211              connectivity cuts    0.0
# opt. cuts    3676               SP method            poly
# uc strategy  0                  inst transformation  2
#             ",
#                    "------------------------------------------------------------
#                              α=5 —— st70 —— 70 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 15 Mar 2022 15:05:36 —————————
# ILP ——— 50 hubs —— 1-2-4-5-6-8-9-10-11-13-14-15-16-17-19-20-21-22-26-28-29-31-32-33-34-37-38-40-41-43-44-45-46-47-49-50-51-52-54-56-57-58-59-60-61-63-65-67-69-70-1
# total time    3601.43 (TL 3600)   gap           0.409
# LB <= UB      5445<=9208          subtour       912
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-9-32-44-1
# total time   3600.28 (TL 3600)  gap                  0.69
# LB <= UB     4735.43<=15299     Master/SP costs      1132/14167
# Master time  3561.36            SP time              38.92
# subtour      19125              connectivity cuts    0.0
# opt. cuts    3456               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                              α=7 —— st70 —— 70 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 16:14:04 —————————
# ILP ——— 4 hubs —— 1-32-43-44-1
# total time    3602.14 (TL 3600)   gap           0.476
# LB <= UB      5474<=10455         subtour       1302
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-32-43-44-1
# total time   3600.05 (TL 3600)  gap                  0.655
# LB <= UB     3609.71<=10455     Master/SP costs      1359/9096
# Master time  3528.56            SP time              71.49
# subtour      17840.0            connectivity cuts    0.0
# opt. cuts    3739               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=3 —— eil76 —— 76 nodes
# ------------------------------------------------------------
#
# *——————— Fri, 11 Mar 2022 21:05:32 —————————
# ILP ——— 74 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-69-70-71-72-73-74-75-76-1
# total time    3603.54 (TL 3600)   gap           0.476
# LB <= UB      2808<=5358          subtour       1272
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-7-38-46-1
# total time   3600.19 (TL 3600)  gap                  0.769
# LB <= UB     3141.49<=13578     Master/SP costs      347/13231
# Master time  3595.55            SP time              4.64
# subtour      10571              connectivity cuts    0.0
# opt. cuts    3335               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=7 —— eil76 —— 76 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 18:14:59 —————————
# ILP ——— 4 hubs —— 1-7-8-34-1
# total time    3602.93 (TL 3600)   gap           0.383
# LB <= UB      4184<=6777          subtour       1066
# connectivity  0.0
#
#
# BD  —— 18 hubs —— 1-2-5-8-27-28-29-30-34-46-47-48-52-67-68-74-75-76-1
# total time   3600.62 (TL 3600)  gap                  0.493
# LB <= UB     3364.08<=6630.0    Master/SP costs      857/5773
# Master time  3505.44            SP time              95.18
# subtour      14003              connectivity cuts    0.0
# opt. cuts    3394               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                              α=3 —— pr76 —— 76 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 14:17:10 —————————
# ILP ——— 73 hubs —— 1-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-1
# total time    3602.16 (TL 3600)   gap           0.369
# LB <= UB      554460.01<=878168   subtour       918
# connectivity  0.0
#
# BD  —— 74 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-1
# total time   3600.03 (TL 3600)  gap                  0.474
# LB <= UB     530972.78<=1009591 Master/SP costs      358928/650663
# Master time  3595.17            SP time              4.85
# subtour      5363               connectivity cuts    0.0
# opt. cuts    1617               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=3 —— rat99 —— 99 nodes
# ------------------------------------------------------------
#
# *——————— Fri, 11 Mar 2022 23:05:49 —————————
# ILP ——— 99 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-1
# total time    3605.56 (TL 3600)   gap           0.354
# LB <= UB      6347<=9819          subtour       1039
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-59-68-86-1
# total time   3600.06 (TL 3600)  gap                  0.856
# LB <= UB     7051.84<=48884     Master/SP costs      1175/47709
# Master time  3596               SP time              4.06
# subtour      7619               connectivity cuts    0.0
# opt. cuts    1298               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=5 —— rat99 —— 99 nodes
# ------------------------------------------------------------
#
# *——————— Tue, 15 Mar 2022 19:21:00 —————————
# ILP ——— 79 hubs —— 1-3-4-5-6-7-8-9-12-13-14-15-16-17-18-19-20-21-24-25-26-27-28-29-30-32-33-34-35-36-38-40-42-43-45-46-47-48-49-50-52-53-54-55-56-57-58-59-60-62-63-64-65-66-67-68-69-70-72-73-74-75-76-78-79-80-83-84-85-86-87-88-91-92-93-96-97-98-99-1
# total time    3607.7 (TL 3600)    gap           0.501
# LB <= UB      10558<=21167        subtour       892
# connectivity  0.0
#
#
# BD  —— 55 hubs —— 1-2-3-5-6-11-13-14-18-19-22-24-26-27-30-31-33-34-35-38-40-43-44-45-46-47-48-50-51-53-56-57-58-59-61-62-64-65-66-68-72-73-76-77-79-80-84-86-88-90-94-95-96-97-98-1
# total time   3600.57 (TL 3600)  gap                  0.585
# LB <= UB     10203.31<=24605    Master/SP costs      7822/16783
# Master time  3519.06            SP time              81.5
# subtour      14956              connectivity cuts    0.0
# opt. cuts    1854               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                             α=7 —— rat99 —— 99 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 20:16:05 —————————
# ILP ——— 4 hubs —— 1-49-68-77-1
# total time    3605.76 (TL 3600)   gap           0.568
# LB <= UB      10498<=24319        subtour       1095
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-49-68-77-1
# total time   3600.37 (TL 3600)  gap                  0.692
# LB <= UB     7490.32<=24319     Master/SP costs      2422/21897
# Master time  3475.16            SP time              125.21
# subtour      15367              connectivity cuts    0.0
# opt. cuts    1333               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=3 —— kroA100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Sat, 12 Mar 2022 01:05:58 —————————
# ILP ——— 93 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-14-15-16-17-19-20-21-22-23-24-25-26-27-28-29-30-31-32-34-35-36-37-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time    3605.33 (TL 3600)   gap           0.569
# LB <= UB      105940.0<=245894    subtour       940.0
# connectivity  0.0
#
#
# BD  —— 98 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time   3600.18 (TL 3600)  gap                  0.372
# LB <= UB     108230.31<=172353  Master/SP costs      63947/108406
# Master time  3589.63            SP time              10.56
# subtour      8325               connectivity cuts    0.0
# opt. cuts    1470.0             SP method            poly
# uc strategy  0                  inst transformation  2
#             ",
#                    "------------------------------------------------------------
#                          α=5 —— kroA100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 12:13:40 —————————
# ILP ——— 69 hubs —— 1-3-4-5-6-11-12-14-15-16-17-18-19-20-23-24-25-26-27-28-30-32-33-34-35-38-41-43-44-48-49-51-52-54-56-57-58-59-60-61-62-63-65-68-69-71-72-73-74-75-76-77-78-79-80-83-84-86-88-89-90-91-92-93-95-96-97-99-100-1
# total time    3605.49 (TL 3600)   gap           0.526
# LB <= UB      168407<=355359      subtour       857
# connectivity  0.0
#
#
# BD  —— 40 hubs —— 1-2-5-10-13-14-18-19-20-24-33-34-38-39-40-44-45-46-48-49-50-51-53-54-55-60-61-63-64-68-69-73-75-76-79-83-84-85-88-98-1
# total time   3600.28 (TL 3600)  gap                  0.668
# LB <= UB     148442.07<=447706  Master/SP costs      103472/344234
# Master time  3486.75            SP time              113.53
# subtour      14948              connectivity cuts    0.0
# opt. cuts    1793               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=7 —— kroA100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 22:17:07 —————————
# ILP ——— 4 hubs —— 1-29-30-39-1
# total time    3605.49 (TL 3600)   gap           0.524
# LB <= UB      172350.0<=362424    subtour       661
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-29-30-39-1
# total time   3600.27 (TL 3600)  gap                  0.694
# LB <= UB     110759.24<=362424  Master/SP costs      34194/328230.0
# Master time  3466.22            SP time              134.05
# subtour      18740.0            connectivity cuts    0.0
# opt. cuts    1678               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=3 —— kroB100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 16:18:16 —————————
# ILP ——— 4 hubs —— 1-2-45-64-1
# total time    3605.71 (TL 3600)   gap           0.838
# LB <= UB      112141<=693864      subtour       805
# connectivity  0.0
#
# BD  —— 4 hubs —— 1-2-45-64-1
# total time   3600.21 (TL 3600)  gap                  0.841
# LB <= UB     110440.54<=693864  Master/SP costs      19456/674408
# Master time  3592.11            SP time              8.11
# subtour      6999               connectivity cuts    0.0
# opt. cuts    1126               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=5 —— kroB100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 03:41:14 —————————
# ILP ——— 4 hubs —— 1-2-45-64-1
# total time    3606.39 (TL 3600)   gap           0.664
# LB <= UB      175837<=523639      subtour       1132
# connectivity  0.0
#
# BD  —— 42 hubs —— 1-4-5-6-8-11-12-14-16-18-21-22-24-26-29-33-38-39-42-43-45-50-52-53-54-55-56-58-62-64-65-71-73-77-80-82-84-85-88-90-95-100-1
# total time   3600.27 (TL 3600)  gap                  0.664
# LB <= UB     150713.71<=448674  Master/SP costs      102663/346011
# Master time  3526.42            SP time              73.85
# subtour      14184              connectivity cuts    0.0
# opt. cuts    1571               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=3 —— kroC100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 17:18:49 —————————
# ILP ——— 98 hubs —— 1-2-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time    3605.85 (TL 3600)   gap           0.456
# LB <= UB      105448.02<=193835   subtour       1007
# connectivity  0.0
#
# BD  —— 99 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time   3600.1 (TL 3600)   gap                  0.348
# LB <= UB     107965.84<=165584  Master/SP costs      62572/103012
# Master time  3594.23            SP time              5.87
# subtour      5300.0             connectivity cuts    0.0
# opt. cuts    1164               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=5 —— kroC100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 04:41:46 —————————
# ILP ——— 76 hubs —— 1-3-4-6-7-8-9-10-11-12-13-15-16-18-21-22-23-25-26-27-28-29-30-32-33-34-35-36-37-39-40-41-42-44-45-46-47-48-49-50-51-52-56-57-58-59-61-62-63-64-65-66-67-68-69-70-71-72-75-78-79-82-84-85-86-88-89-90-91-92-93-94-95-96-98-100-1
# total time    3605.82 (TL 3600)   gap           0.431
# LB <= UB      170471<=299496      subtour       995
# connectivity  0.0
#
# BD  —— 48 hubs —— 1-4-5-8-9-10-11-12-13-15-19-21-23-26-27-28-29-31-33-34-38-40-42-43-48-54-55-58-60-65-66-68-69-71-72-74-75-78-79-80-82-83-84-85-89-92-96-97-1
# total time   3600.16 (TL 3600)  gap                  0.693
# LB <= UB     148460.19<=484263  Master/SP costs      157991/326272
# Master time  3510.45            SP time              89.71
# subtour      12811              connectivity cuts    0.0
# opt. cuts    1975               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=5 —— kroD100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 05:42:19 —————————
# ILP ——— 73 hubs —— 1-2-3-5-6-7-8-10-11-12-13-14-15-16-18-19-21-22-23-24-25-26-27-29-31-33-34-36-37-38-39-40-41-42-44-47-48-49-51-52-53-54-55-56-57-58-60-61-63-64-67-68-69-71-74-76-77-78-80-82-84-85-87-88-90-91-92-94-96-97-98-99-100-1
# total time    3605.94 (TL 3600)   gap           0.493
# LB <= UB      175108<=345115      subtour       985
# connectivity  0.0
#
# BD  —— 36 hubs —— 1-5-7-10-21-27-30-34-35-36-38-39-41-43-46-47-52-54-55-61-62-64-65-66-67-73-74-75-76-77-80-81-87-88-91-100-1
# total time   3600.55 (TL 3600)  gap                  0.66
# LB <= UB     149373.13<=439685  Master/SP costs      82290.0/357395
# Master time  3517.01            SP time              83.54
# subtour      14302              connectivity cuts    0.0
# opt. cuts    1870.0             SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                          α=5 —— kroE100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 06:42:52 —————————
# ILP ——— 78 hubs —— 1-3-4-5-8-9-10-11-13-14-17-18-19-20-22-23-24-25-26-27-29-30-31-33-34-35-36-38-39-40-41-43-44-45-46-47-49-50-51-53-55-56-58-59-60-61-62-64-65-66-67-68-69-70-71-73-75-76-78-79-80-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time    3605.77 (TL 3600)   gap           0.515
# LB <= UB      179562.09<=370070.0 subtour       1054
# connectivity  0.0
#
# BD  —— 4 hubs —— 1-6-91-92-1
# total time   3600.24 (TL 3600)  gap                  0.738
# LB <= UB     149024.71<=569775  Master/SP costs      35894/533881
# Master time  3545.3             SP time              54.94
# subtour      17387              connectivity cuts    0.0
# opt. cuts    1346               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                            α=3 —— rd100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Wed, 16 Mar 2022 15:17:43 —————————
# ILP ——— 95 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-15-16-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-51-52-53-54-55-56-57-58-59-61-62-63-64-65-66-67-68-69-70-71-72-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-1
# total time    3606.24 (TL 3600)   gap           0.521
# LB <= UB      40037<=83510.0      subtour       798
# connectivity  0.0
#
# BD  —— 97 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-94-95-96-97-98-99-100-1
# total time   3600.82 (TL 3600)  gap                  0.575
# LB <= UB     41630.06<=97909    Master/SP costs      39189/58720.0
# Master time  3592.18            SP time              8.63
# subtour      7071               connectivity cuts    0.0
# opt. cuts    1437               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                            α=5 —— rd100 —— 100 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 02:40:41 —————————
# ILP ——— 4 hubs —— 1-31-56-95-1
# total time    3605.91 (TL 3600)   gap           0.721
# LB <= UB      63318<=226679       subtour       1414
# connectivity  0.0
#
# BD  —— 69 hubs —— 1-2-3-4-5-8-9-10-11-12-15-18-19-21-22-24-25-26-28-30-33-35-37-38-39-40-41-43-47-48-49-51-53-54-56-57-58-59-60-61-62-64-65-66-67-68-69-72-73-75-76-77-78-80-81-82-83-85-87-88-90-91-92-93-94-97-98-99-100-1
# total time   3600.04 (TL 3600)  gap                  0.672
# LB <= UB     56556.33<=172396   Master/SP costs      61409/110987
# Master time  3497.2             SP time              102.84
# subtour      15290.0            connectivity cuts    0.0
# opt. cuts    2300.0             SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                           α=3 —— eil101 —— 101 nodes
# ------------------------------------------------------------
#
# *——————— Sat, 12 Mar 2022 03:06:10 —————————
# ILP ——— 99 hubs —— 1-2-3-4-5-6-7-8-9-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-101-1
# total time    3605.61 (TL 3600)   gap           0.395
# LB <= UB      3225<=5332          subtour       702
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-57-93-98-1
# total time   3600.17 (TL 3600)  gap                  0.769
# LB <= UB     3700.42<=16047     Master/SP costs      288/15759
# Master time  3595.15            SP time              5.02
# subtour      9274               connectivity cuts    0.0
# opt. cuts    1671               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                           α=7 —— eil101 —— 101 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 00:18:10 —————————
# ILP ——— 4 hubs —— 1-93-95-98-1
# total time    3607.68 (TL 3600)   gap           0.342
# LB <= UB      5010.0<=7611        subtour       411
# connectivity  0.0
#
#
# BD  —— 4 hubs —— 1-93-95-98-1
# total time   3600.28 (TL 3600)  gap                  0.469
# LB <= UB     4039.23<=7611      Master/SP costs      584/7027
# Master time  3456.19            SP time              144.08
# subtour      16403              connectivity cuts    0.0
# opt. cuts    1739               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    "------------------------------------------------------------
#                            α=5 —— pr107 —— 107 nodes
# ------------------------------------------------------------
#
# *——————— Thu, 17 Mar 2022 08:44:00 —————————
# ILP ——— 70 hubs —— 1-4-5-9-10-11-13-14-15-16-18-19-21-22-23-24-25-27-28-29-30-31-32-33-36-37-38-39-42-43-44-45-47-48-50-51-53-54-55-56-57-58-64-66-68-70-72-73-74-75-76-77-78-79-81-84-85-86-87-88-89-93-94-95-99-100-101-102-103-107-1
# total time    3607.22 (TL 3600)   gap           0.73
# LB <= UB      222877<=824317      subtour       2326
# connectivity  0.0
#
# BD  —— 62 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-24-25-26-28-30-31-32-34-36-38-40-46-49-50-55-56-57-59-63-64-65-68-76-77-79-81-82-83-84-87-88-91-94-96-97-99-100-101-102-103-104-105-1
# total time   3600.31 (TL 3600)  gap                  0.783
# LB <= UB     218162.14<=1005244 Master/SP costs      325766/679478
# Master time  3531.79            SP time              68.52
# subtour      26468              connectivity cuts    0.0
# opt. cuts    1264               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#
# ]
#
# arr_str_2 = ["------------------------------------------------------------
#                            α=3 —— pr107 —— 107 nodes
# ------------------------------------------------------------
# *——————— Mon, 11 Apr 2022 15:21:52 —————————
# ILP ——— 4 hubs —— 1-77-87-97-1
# total time    3606.53 (TL 3600)   gap           0.936
# LB <= UB      151813<=2.385632e6  subtour       2188
# connectivity  0.0
#
#
# BD  —— 107 hubs —— 1-2-3-4-5-6-7-8-9-10-11-12-13-14-15-16-17-18-19-20-21-22-23-24-25-26-27-28-29-30-31-32-33-34-35-36-37-38-39-40-41-42-43-44-45-46-47-48-49-50-51-52-53-54-55-56-57-58-59-60-61-62-63-64-65-66-67-68-69-70-71-72-73-74-75-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-93-94-95-96-97-98-99-100-101-102-103-104-105-106-107-1
# total time   3600.321 (TL 3600) gap                  0.62
# LB <= UB     163857.979<=431527 Master/SP costs      167022/264505
# Master time  359055             SP time              10.265
# subtour      9166               connectivity cuts    0
# opt. cuts    1311               SP method            poly
# uc strategy  0                  inst transformation  2
#
#             ",
#             "------------------------------------------------------------
#                              α=7 —— pr76 —— 76 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 19:23:11 —————————
# ILP ——— 36 hubs —— 1-3-4-5-6-9-11-12-16-19-27-29-30-32-34-37-40-41-42-43-45-47-48-49-50-51-52-53-54-55-56-57-58-59-60-62-1
# total time    3602.06 (TL 3600)   gap           0.48
# LB <= UB      876169.82<=1684757 subtour       1354
# connectivity  0.0
#
# BD  —— 4 hubs —— 1-33-54-55-1
# total time   3600.197 (TL 3600) gap                  0.674
# LB <= UB     572340.581<=1755899 Master/SP costs     181775/1574124
# Master time  3532.317           SP time              67.88
# subtour      16500              connectivity cuts    0
# opt. cuts    2823               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                           α=5 —— eil101 —— 101 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 19:39:21 —————————
# ILP ——— 77 hubs —— 1-2-4-6-7-8-9-10-11-12-14-15-16-19-20-21-22-23-25-28-29-30-32-34-35-36-39-40-41-42-44-45-46-47-48-49-50-52-53-54-55-56-57-58-59-60-61-63-66-68-71-72-73-76-77-78-79-80-81-82-83-84-85-86-87-88-89-90-91-92-94-95-97-98-99-100-101-1
# total time    3607.06 (TL 3600)   gap           0.42
# LB <= UB      5320.0<=9173        subtour       881
# connectivity  0.0
#
#
# BD  —— 29 hubs —— 1-6-7-11-19-27-31-37-40-47-48-53-58-59-62-82-85-88-91-92-93-94-95-96-97-98-99-100-101-1
# total time   3600.493 (TL 3600) gap                  0.467
# LB <= UB     5446.113<=10212    Master/SP costs      871/9341
# Master time  3495.749           SP time              104.744
# subtour      12460              connectivity cuts    0
# opt. cuts    1605               SP method            poly
# uc strategy  0                  inst transformation  2
#                    ",
#                    "------------------------------------------------------------
#                             α=5 —— eil76 —— 76 nodes
# ------------------------------------------------------------
#
# *——————— Mon, 11 Apr 2022 17:38:17 —————————
# ILP ——— 51 hubs —— 1-2-3-4-5-7-8-9-10-11-13-14-16-17-19-23-24-25-26-28-29-30-34-35-36-37-38-39-40-41-43-44-46-47-48-49-50-52-53-56-60-62-67-68-70-71-72-73-74-75-76-1
# total time    3601.9 (TL 3600)    gap           0.372
# LB <= UB      4529<=7211          subtour       1156
# connectivity  0.0
#
#
#
# BD  —— 30 hubs —— 1-5-7-8-9-10-12-15-17-19-20-23-27-28-29-30-32-34-37-40-41-42-43-46-50-52-58-67-72-75-1
# total time   3600.21 (TL 3600)  gap                  0.496
# LB <= UB     4513.82<=8962      Master/SP costs      2065/6897
# Master time  3527.288           SP time              72.922
# subtour      15036              connectivity cuts    0
# opt. cuts    3253               SP method            poly
# uc strategy  0                  inst transformation  2
#
#
#                    ",
#                    "------------------------------------------------------------
#                              α=5 —— pr76 —— 76 nodes
# ------------------------------------------------------------
# *——————— Thu, 17 Mar 2022 01:40:06 —————————
# ILP ——— 55 hubs —— 1-3-5-6-7-8-9-10-11-12-13-14-15-16-17-18-21-24-26-27-28-29-30-31-32-34-35-36-38-39-40-41-42-43-44-47-48-50-51-53-54-56-57-59-60-61-62-63-64-65-66-67-68-70-71-1
# total time    3602.04 (TL 3600)   gap           0.46
# LB <= UB      861984.35<=1.596890 subtour       990.0
# connectivity  0.0
#
# BD  —— 32 hubs —— 1-2-3-4-5-6-9-10-11-12-20-22-23-24-28-29-32-44-45-46-48-51-52-54-63-64-65-67-68-69-72-73-1
# total time   3600.22 (TL 3600)  gap                  0.598
# LB <= UB     718099.98<=1.786212 Master/SP costs      337444/1448768
# Master time  3556.34            SP time              43.89
# subtour      12766              connectivity cuts    0.0
# opt. cuts    3043               SP method            poly
# uc strategy  0                  inst transformation  2
#
#                    ",
#                    ]
#
# # html_to_tex_both_TL_arr(arr_str)
# # html_to_tex_both_TL_arr(arr_str_2, false)
# # html_to_tex_both_TL_arr(arr_str_3)
