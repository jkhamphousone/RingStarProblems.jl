function log_assert(filename, left_hs, operator, right_hs, error_str="")
    if !operator(left_hs, right_hs)
        open(eval(@__DIR__) * "/debug/$(filename)_$(Dates.format(now(), "yyyy-mm-dd__HHhMM")).txt", "w") do file
            write(file, "left hand side: $left_hs !$operator right hand side: $right_hs\n")
            write(file, error_str)
        end
        @show left_hs, right_hs
        # @assert operator(left_hs, right_hs)
    end
end